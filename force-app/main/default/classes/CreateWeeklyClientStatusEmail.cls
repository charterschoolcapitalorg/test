global class CreateWeeklyClientStatusEmail implements Database.Batchable<SObject>, Database.Stateful {

	public static final Integer EMAIL_QUEUE_LIMIT = 50;

	public static final String OPP_SECTION_HEADER = System.Label.Weekly_Client_Status_Email_Opps;
	public static final String ACCT_SECTION_HEADER = System.Label.Weekly_Client_Status_Email_Accts;
	public static final String DUE_SOON_SECTION_HEADER = System.Label.Weekly_Client_Status_Email_Due_Soon;
	public static final String PAST_DUE_SECTION_HEADER = System.Label.Weekly_Client_Status_Email_Past_Due;
	public static final String UPCOMING_SECTION_HEADER = System.Label.Weekly_Client_Status_Email_Upcoming;

	public static String EMAIL_FROM_ADDRESS;
	public static Id EMAIL_FROM_ID;

	public static final Date REFERENCE_DATE = Date.newInstance(1900,1,8);

	private static final List<String> II_QUERY_FIELDS = new List<String> {
		'Id',
		'Name',
		'Primary_Contact_First_Name__c',
		'Due_Date__c',
		'Opportunity__c',
		'Assigned_To__c',
		'Account_Name__c',
		'Account_Name__r.ParentId',
		'Client_Facing_Item_Name__c',
		'Client_Alert_Sent__c',
		'Is_Ongoing__c',
		'Account_Name__r.Owner.Name',
		'Account_Name__r.Owner.Phone',
		'Account_Name__r.Owner.MobilePhone',
		'Account_Name__r.Owner.Email',
		'Opportunity__r.Owner.Name',
		'Opportunity__r.Owner.Phone',
		'Opportunity__r.Owner.MobilePhone',
		'Opportunity__r.Owner.Email'
	};

	@testVisible
	private List<EmailData> queuedEmails = new List<EmailData>();

	static {
		try {
			if (Client_Portal_Email_Settings__c.getOrgDefaults() != null &&  Client_Portal_Email_Settings__c.getOrgDefaults().WeeklyClientStatusEmailFromAddress__c != null) {
				OrgWideEmailAddress[] owea = [select Id, Address from OrgWideEmailAddress where Address =:Client_Portal_Email_Settings__c.getOrgDefaults().WeeklyClientStatusEmailFromAddress__c];
				
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				if ( owea.size() > 0 ) {
					EMAIL_FROM_ADDRESS = owea.get(0).Address;
					EMAIL_FROM_ID = owea.get(0).Id;
				}
			}
		} catch (Exception e) {}
	}

	global CreateWeeklyClientStatusEmail() {
		
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'Select Id, DeveloperName, Copy_Paralegal__c, Copy_Account_Manager__c, Email_Template_Developer_Name__c, Days_Before_Due_Date__c, Email_Receiver__c, Intake_Item_Name__c, Opp_Record_Type_Name__c, Status__c from CustomPortalEmailsToSend__mdt';

		System.debug('Executing query: ' + query);
		return Database.getQueryLocator(query);
	}

	public static Boolean matchesRole(CustomPortalEmailsToSend__mdt c, Intake_Item__c iItem, Community_Contact_Role__c ccr) {
		return (c.Email_Receiver__c == 'All Community Users' || ccr.Role__c == c.Email_Receiver__c)
			&& DiligenceUtils.multiSelectFieldContains(iItem.Assigned_To__c, ccr.role__c);
	}

	private static List<String> split(String values) {
		List<String> results = new List<String>();
		if (String.isNotBlank(values)) {
			results.addAll(values.trim().split('\\s*;\\s*'));
		}
		return results;
	}

	public void executeSend(List<CustomPortalEmailsToSend__mdt> scope, Id accountId, Set<Id> contactFilters) {
		Set<String> emailTemNames = new Set<STring>();
		for (CustomPortalEmailsToSend__mdt c : scope) {
			emailTemNames.add(c.Email_Template_Developer_Name__c);
		}

		Map<String,EmailTemplate> tplMap = new Map<String,EmailTemplate>();
		for (EmailTemplate tpl: [ SELECT Id, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :emailTemNames ]) {
			tplMap.put(tpl.DeveloperName, tpl);
		}

		List<Messaging.SingleEmailMessage> mailsToSend = new List<Messaging.SingleEmailMessage>();
		Map<Id, Intake_Item__c> iiSent = new Map<Id, Intake_Item__c>();

		Date today = Date.today();

		for (CustomPortalEmailsToSend__mdt c : scope) {
			System.debug('***** using rule: ' + c);

			List<String> statuses = split(c.Status__c);
			
			List<String> recordtypes = split(c.Opp_Record_Type_Name__c);
			List<Id> recordtypeids = new List<Id>();
			for (string s : recordtypes) {
				Id rid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(s).getRecordTypeId();
				recordtypeids.add(rid);
			}

			String iiQuery = 'Select '+String.join(II_QUERY_FIELDS, ',')+' '
				+ 'from Intake_Item__c '
				+ 'where ((Opportunity__r.recordtypeid IN:recordtypeids AND Opportunity__r.IsClosed = False) or (Is_Ongoing__c = true AND Account_Name__r.Account_Status__c != \'Legal Issue (Do Not Contact)\'))'
				+ 'and (Parent_Intake_Item__c != null or Is_Ongoing__c = true) '
				+ 'and Status__c NOT IN:statuses '
				+ 'and Send_Weekly_Reminder__c = true ' 
				+ 'and Is_Visible_To_Community__c = true';

			if (c.Intake_Item_Name__c != 'ALL') {
				iiQuery += ' and (Name = :c.Intake_Item_Name__c or Parent_Intake_Item__r.Name = :c.Intake_Item_Name__c)';
			}
			if (accountId != null) {
				iiQuery += ' and (Account_Name__c = :accountId OR Account_Name__r.ParentId = :accountId)';
			}

			System.debug('***** using query: ' + iiQuery);
			List<Intake_Item__c> items = Database.query(iiQuery);
			System.debug('***** items matching rule: ' + items);
			
			Set<Id> oppIds = new Set<Id>();
			Set<Id> acctIds = new Set<Id>();

			for (Intake_Item__c item : items) {
				Set<Id> relatedIds = new Set<Id>();

				if(item.Is_Ongoing__c) {
					acctIds.add(item.Account_Name__c);
					acctIds.add(item.Account_Name__r.ParentId);
				} else {
					oppIds.add(item.Opportunity__c);
				}
			}

			acctIds.remove(null);

			//get contact roles for the opps
			Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([
				SELECT
					Id, Name, Paralegal_UW_email__c, Owner_Email__c,
					(SELECT Id, Role__c, Contact__c, Contact__r.FirstName, Contact__r.Email FROM Community_Contact_Roles__r)
				FROM Opportunity
				WHERE Id IN :oppIds
			]);

			//get contact roles for accounts
			Map<Id,Account> acctMap = new Map<Id,Account>([
				SELECT
					Id, Name, Paralegal_1__r.Email, Owner.Email, ParentId,
					(SELECT Id, Role__c, Contact__c, Contact__r.FirstName, Contact__r.Email FROM Community_Contact_Roles__r)
				FROM Account
				WHERE Id IN:acctIds
			]);

			Map<Id,EmailData> emailDataByContactId = new Map<Id,EmailData>();

			EmailTemplate tpl = tplMap.get(c.Email_Template_Developer_Name__c);

			//loop through opps to build the map of contact to Opps 
			for (Intake_Item__c item: items) {
				List<Community_Contact_Role__c> allCCRs = new List<Community_Contact_Role__c>();

				if (item.Is_Ongoing__c) {
					Set<Id> itemAcctIds = new Set<Id> { item.Account_Name__c, item.Account_Name__r.ParentId };

					itemAcctIds.remove(null);
					
					for (Id acctId: itemAcctIds) {
						allCCRs.addAll(acctMap.get(acctId).Community_Contact_Roles__r);
					}
				} else {
					allCCRs.addAll(oppMap.get(item.Opportunity__c).Community_Contact_Roles__r);
				}

				//get the Contact, and see if they are a a Community User, and if they match the Assigned To on the Item
				for (Community_Contact_Role__c ccr: allCCRs) {
					if (matchesRole(c, item, ccr) && (contactFilters == null || contactFilters.contains(ccr.Contact__c))) {
						EmailData data = emailDataByContactId.get(ccr.Contact__c);
						if (data == null) {
							data = new EmailData(tpl, ccr.Contact__r, oppMap, acctMap, today);
							emailDataByContactId.put(ccr.Contact__c, data);
						}
						data.addItem(item);
					}
				}
			}
			
			//for each contact we send a different email
			for (EmailData data: emailDataByContactId.values()) {
				if (!data.con.Email.endswith('.cscfull')) {
					queuedEmails.add(data);
				}
			}
			
			//update Client_Notifications_Sent__c to true for all items
			for(Intake_Item__c item : items) {
				item.Client_Alert_Sent__c = true;
			}

			update items;

		} // end loop through rules
	}

	global void execute(Database.BatchableContext BC, List<CustomPortalEmailsToSend__mdt> scope) {
		this.executeSend(scope, null, null);
	}

	global void finish(Database.BatchableContext BC) {
		new QueueableEmails(queuedEmails).enqueueJob();
	}

	public static void sendClientStatusEmailForAccount(Id accountId, List<Contact> contacts) {
		CreateWeeklyClientStatusEmail statusEmail = new CreateWeeklyClientStatusEmail();
		Database.QueryLocator ql = statusEmail.start(null);
		List<CustomPortalEmailsToSend__mdt> scope = Database.query(ql.getQuery());
		statusEmail.executeSend(scope, accountId, SObjectUtil.collectIds(contacts));
		statusEmail.finish(null);
	}

	public static Date getFirstDayOfWeek(Date today) {
		return today - Math.mod(REFERENCE_DATE.daysBetween(today), 7);
	}

	public static Date getLastDayOfWeek(Date today) {
		return getFirstDayOfWeek(today).addDays(7);
	}

	private static List<Intake_Item__c> filterPastDueItems(List<Intake_Item__c> items, Date today) {
		List<Intake_Item__c> pastDueItems = new List<Intake_Item__c>();
		for (Intake_Item__c item: items) {
			if (item.Due_Date__c < today) {
				pastDueItems.add(item);
			}
		}
		return pastDueItems;
	}

	private static List<Intake_Item__c> filterOngoingItems(List<Intake_Item__c> items) {
		List<Intake_Item__c> ongoingItems = new List<Intake_Item__c>();
		for (Intake_Item__c item: items) {
			if (item.Is_Ongoing__c) {
				ongoingItems.add(item);
			}
		}
		return ongoingItems;
	}

	private static List<Intake_Item__c> filterUpcomingItems(List<Intake_Item__c> items, Date today) {
		List<Intake_Item__c> upcomingItems = new List<Intake_Item__c>();
		for (Intake_Item__c item: items) {
			if (today < getFirstDayOfWeek(item.Due_Date__c)) {
				upcomingItems.add(item);
			}
		}
		return upcomingItems;
	}

	private static List<Intake_Item__c> filterOpportunityItems(List<Intake_Item__c> items) {
		List<Intake_Item__c> opportunityItems = new List<Intake_Item__c>();
		for (Intake_Item__c item: items) {
			if (!item.Is_Ongoing__c) {
				opportunityItems.add(item);
			}
		}
		return opportunityItems;
	}

	private static Map<Date,List<Intake_Item__c>> groupByDueDate(List<Intake_Item__c> items) {
		Map<Date,List<Intake_Item__c>> itemsByDueDate = new Map<Date,List<Intake_Item__c>>();
		for (Intake_Item__c item: items) {
			if (item.Due_Date__c != null) {
				List<Intake_Item__c> itemsForDueDate = itemsByDueDate.get(item.Due_Date__c);
				if (itemsForDueDate == null) {
					itemsForDueDate = new List<Intake_Item__c>();
					itemsByDueDate.put(item.Due_Date__c, itemsForDueDate);
				}
				itemsForDueDate.add(item);
			}
		}
		return itemsByDueDate;
	}

	public static String formatSectionHtml(String heading, List<String> items) {
		return items.isEmpty() ? '' : '<h3 style="padding-left: 20px">'+heading+'</h3><ul><li>'+String.join(items, '</li><li>')+'</li></ul>';
	}

	public static String formatSectionText(String heading, List<String> items) {
		return items.isEmpty() ? '' : heading+':\n * '+String.join(items, '\n * ')+'\n\n';
	}

	private class EmailData implements QueueableEmails.QueueableEmail {
		private final Contact con;
		private final EmailTemplate tpl;
		private final Map<Id,Intake_Item__c> items = new Map<Id,Intake_Item__c>();
		private final Map<Id,Opportunity> oppMap;
		private final Map<Id,Account> acctMap;
		private final Date today;
		private User owner;

		public EmailData(EmailTemplate tpl, Contact con, Map<Id,Opportunity> oppMap, Map<Id,Account> acctMap, Date today) {
			this.tpl = tpl;
			this.con = con;
			this.oppMap = oppMap;
			this.acctMap = acctMap;
			this.today = today;
		}

		public void addItem(Intake_Item__c item) {
			this.items.put(item.Id, item);

			if (this.owner == null) {
				this.owner = item.Opportunity__c == null ? item.Account_Name__r.Owner : item.Opportunity__r.Owner;
			}
		}

		private List<String> renderByDueDate(Map<Id,List<Intake_Item__c>> itemsByParentId, Map<Id,SObject> parentMap) {
			List<String> items = new List<String>();
			for (Id parentId: itemsByParentId.keySet()) {
				SObject parent = parentMap.get(parentId);
				Map<Date,List<Intake_Item__c>> itemsByDate = groupByDueDate(itemsByParentId.get(parentId));
				String parentName = (String)parent.get('Name');

				//for each day of week, look for items due
				for (Date d = today; d < getLastDayOfWeek(today); d = d.addDays(1)) {
					List<Intake_Item__c> itemsDue = itemsByDate.get(d);
					if (itemsDue != null && !itemsDue.isEmpty()) {
						items.add(parentName + ': ' + itemsDue.size() + ' Outstanding Diligence Item(s) (as of this email), due by ' + d.format());
					}
				}
			}
			return items;
		}

		public List<String> renderOpps() {
			Map<Id,List<Intake_Item__c>> itemsByOppId = SObjectUtil.groupById(filterOpportunityItems(items.values()), 'Opportunity__c');
			return renderByDueDate(itemsByOppId, oppMap);
		}

		public List<String> renderAccts() {
			Map<Id,List<Intake_Item__c>> itemsByAcctId = SObjectUtil.groupById(filterOngoingItems(items.values()), 'Account_Name__c');
			return renderByDueDate(itemsByAcctId, acctMap);
		}

		public List<String> renderPastDue() {
			List<String> pastDue = new List<String>();
			for (Intake_Item__c item: filterPastDueItems(items.values(), today)) {
				pastDue.add(item.Client_Facing_Item_Name__c + ' was due on ' + item.Due_Date__c.format());
			}
			return pastDue;
		}
		
		public List<String> renderUpcoming() {
			List<String> upcoming = new List<String>();
			for (Intake_Item__c item: filterUpcomingItems(items.values(), today)) {
				upcoming.add(item.Client_Facing_Item_Name__c + ' is due on ' + item.Due_Date__c.format());
			}
			return upcoming;
		}

		public Messaging.SingleEmailMessage render() {
			Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(tpl.Id, con.Id, null);
			System.debug('got email body: ' + email.getHtmlBody());
			String htmlBody = email.getHtmlBody();
			String textBody = email.getPlainTextBody();
			String week = getLastDayOfWeek(today).format();

			List<String> oppItems = renderOpps();
			List<String> acctItems = renderAccts();
			List<String> pastDueItems = renderPastDue();
			List<String> upcomingItems = renderUpcoming();
			List<String> dueSoonItems = new List<String>();

			dueSoonItems.addAll(oppItems);
			dueSoonItems.addAll(acctItems);

			String ownerEmail = null;
			String ownerName = null;
			String ownerPhone = null;

			if (owner != null) {
				ownerEmail = owner.Email;
				ownerName = owner.Name;
				ownerPhone = owner.Phone == null ? owner.MobilePhone : owner.Phone;
			}

			if (htmlBody!=null) {
				htmlBody = htmlBody.replace('{FirstName}', con.FirstName == null ? '' : con.FirstName);
				htmlBody = htmlBody.replace('{DueSoonList}', formatSectionHtml(DUE_SOON_SECTION_HEADER, dueSoonItems));
				htmlBody = htmlBody.replace('{OppList}', formatSectionHtml(OPP_SECTION_HEADER, oppItems));
				htmlBody = htmlBody.replace('{AcctList}', formatSectionHtml(ACCT_SECTION_HEADER, acctItems));
				htmlBody = htmlBody.replace('{PastDueList}', formatSectionHtml(PAST_DUE_SECTION_HEADER, pastDueItems));
				htmlBody = htmlBody.replace('{UpcomingList}', formatSectionHtml(UPCOMING_SECTION_HEADER, upcomingItems));
				htmlBody = htmlBody.replace('{Week}', week);
				htmlBody = htmlBody.replace('{OwnerName}', (ownerName!=null) ? ownerName : '');
				htmlBody = htmlBody.replace('{OwnerEmail}', (ownerEmail!=null) ? ownerEmail : '');
				htmlBody = htmlBody.replace('{OwnerPhone}', (ownerPhone!=null) ? ownerPhone : '');
			}

			if (textBody!=null) {
				textBody = textBody.replace('{FirstName}', con.FirstName == null ? '' : con.FirstName);
				textBody = textBody.replace('{DueSoonList}', formatSectionText(DUE_SOON_SECTION_HEADER, dueSoonItems));
				textBody = textBody.replace('{OppList}', formatSectionText(OPP_SECTION_HEADER, oppItems));
				textBody = textBody.replace('{AcctList}', formatSectionText(ACCT_SECTION_HEADER, acctItems));
				textBody = textBody.replace('{PastDueList}', formatSectionText(PAST_DUE_SECTION_HEADER, pastDueItems));
				textBody = textBody.replace('{UpcomingList}', formatSectionText(UPCOMING_SECTION_HEADER, upcomingItems));
				textBody = textBody.replace('{Week}', week);
				textBody = textBody.replace('{OwnerName}', (ownerName!=null) ? ownerName : '');
				textBody = textBody.replace('{OwnerEmail}', (ownerEmail!=null) ? ownerEmail : '');
				textBody = textBody.replace('{OwnerPhone}', (ownerPhone!=null) ? ownerPhone : '');
			}

			//build the email message
			Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();

			mail.setReplyTo(EMAIL_FROM_ADDRESS);

			if (EMAIL_FROM_ID != null) {
				mail.setOrgWideEmailAddressId(EMAIL_FROM_ID);
			} else {
				mail.setSenderDisplayName('Charter School Capital');
			}

			mail.setBccSender(false);
			mail.setUseSignature(false);
			mail.setSaveAsActivity(true);
			mail.setTargetObjectId(con.Id);
			mail.setSubject(tpl.Subject);
			mail.setHtmlBody(htmlBody);
			mail.setPlainTextBody(textBody);
			return mail;
		}
	}
}