global class CreateLeaseComplianceNotifications implements  Database.Batchable<SObject> {

    public static ID expired = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Expired').getRecordTypeId();
    public static ID pending = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Pending').getRecordTypeId();
    public static ID current = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Current').getRecordTypeId();

      
    
    public static Id fromAddress;
    public static Id facMgmtGrp;
    static {
    	try {
		    OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'mdillon@charterschoolcapital.com'];
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			if ( owea.size() > 0 ) {
			    fromAddress = owea.get(0).Id;
			}  
			CollaborationGroup g =  [SELECT Id,Name From CollaborationGroup WHERE CollaborationType='Public' and Name = 'FAM - Facilities Asset Management Team'];
			facMgmtGrp = g.Id;
			
    	} catch (Exception e) {}
    }
    
    global CreateLeaseComplianceNotifications() {
        
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(this,50);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        /*STring query = 'Select Id, Name, Property_Name__c, Client_Alert_Deactivated__c, Start_Date__c, lease__c, lease__r.Tenant__r.Tenant__c, Client_Notification_Role__c, lease__r.Property__c, Lease_Compliance_Name__c, Created_Follow_Up_Record__c, Expiration_Date__c, end_date__c, ' + 
        		' Type__c, Period__c from Lease_Compliance__c where Client_Alert_Date__c <= TODAY and (Client_Notification_Role__c = \'Financial\' or Client_Notification_Role__c = \'Facilities\')' + 
        		' and (recordtypeid=:pending or recordtypeid=:current) and Client_Notifications_Sent__c = false';*/

        STring query = 'Select Id, Name, Property_Name__c, Client_Alert_Deactivated__c, Start_Date__c, lease__c, lease__r.Tenant__r.Tenant__c, Client_Notification_Role__c, lease__r.Property__c, Lease_Compliance_Name__c, Created_Follow_Up_Record__c, Expiration_Date__c, end_date__c, ' + 
        		' Type__c, Period__c, Client_Notifications_Sent__c, Client_Second_Alert_Sent__c, Client_Final_Alert_Sent__c, Due_Date__c,' +
        		' Second_Alert_Date__c, Second_Client_Alert_Active__c, Final_Alert_Active__c, Client_Alert_Date__c from Lease_Compliance__c' +
        		' where (recordtypeid=:pending or recordtypeid=:current) and Received_Date__c = null and (Client_Notification_Role__c = \'Financial\' or Client_Notification_Role__c = \'Facilities\')' +
        		' and(' +
	        		' (Client_Alert_Date__c <= today and Client_Notifications_Sent__c = false)' +
	        		' or ' +
	        		' (Client_Notifications_Sent__c = true and Second_Alert_Date__c <= today and Second_Client_Alert_Active__c = true and Client_Second_Alert_Sent__c = false)' +
	        		' or ' +
	        		' (Client_Notifications_Sent__c = true and Client_Second_Alert_Sent__c = true and Final_Alert_Active__c = true and Client_Final_Alert_Sent__c = false and Due_Date__c <= today)' +
        		')';

        System.debug('Executing query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    private ConnectApi.FeedItemInput postFeedElement(Id lcId, String name, String prop) {
    	ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
		ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
		ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
		messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
		
		
		ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
		mentionSegmentInput.id = facMgmtGrp;
		messageBodyInput.messageSegments.add(mentionSegmentInput);
		textSegmentInput.text = 'Client Alert is deactivated on ' + name + ' for '+ prop + '.  Please double check that this LC item is still needed before communicating with them directly.';
		messageBodyInput.messageSegments.add(textSegmentInput);
		feedItemInput.body = messageBodyInput;
		feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
		feedItemInput.subjectId = lcId+'';
		System.debug('****posting feed for group id : ' + facMgmtGrp);
		return feedItemInput;
		
		
    }
    
    private List<Messaging.SingleEmailMessage> addEmail(List<String> toAddr, List<Messaging.SingleEmailMessage> mails, Id lcId, Id temId, Id conId, String replyTo) {
    								
    								
    								//construct email
								    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
								    System.debug('***setting templateId: ' + temId + ' for lease compliance: ' + lcId);
								    mail.setTemplateId(temId);
								    
								    mail.setToAddresses(toAddr);
								 	mail.setReplyTo(replyTo);
								 	if (CreateLeaseComplianceNotifications.fromAddress!=null)
    								{
								 		mail.setOrgWideEmailAddressId(CreateLeaseComplianceNotifications.fromAddress);
    								} else mail.setSenderDisplayName('Charter School Capital');
    								
								    mail.setBccSender(false);
								    mail.setUseSignature(false);
								    mail.setSaveAsActivity(true);
								    
								    mail.setWhatId(lcId);  //link whatId to the main Lease COmpliance record
							  		mail.setTargetObjectId(conId); //set target to any Contact from COntact Roles
							  		
							  		mails.add(mail);
							  		return mails;
							  		
    }
    
    global void execute(Database.BatchableContext BC, List<Lease_Compliance__c> scope) {
        
        //Map<Id,Lease_Compliance__c> forUpdate = new Map<Id,Lease_Compliance__c>();
        Map<Id, Id> leasecompPropMap = new Map<Id, Id>();
        Map<Id, Id> leasecompTenantMap = new Map<Id, Id>();
        System.debug('scope: ' + scope);
        
        if (scope.size()>0) {
        	boolean addedFeed = false;	
            List<ConnectApi.BatchInput> postItems = new List<ConnectApi.BatchInput>();
            
            //get facilities and financials contacts from the related Conyacts on Lease->Tenant and Lease->Property
            for (Lease_Compliance__c l : scope) {
            	
            	if (!l.Client_Alert_Deactivated__c) {
	            	leasecompPropMap.put(l.Id, l.lease__r.Property__c);
	            	leasecompTenantMap.put(l.Id, l.lease__r.Tenant__r.Tenant__c);
            	}
            }
            
            List<Related_Contact__c> propRCs = [Select Id, account__c, Contact__r.email, Contact__c, Financial_Contact__c, Facilities_Contact__c from Related_Contact__c 
            		where (Financial_Contact__c = true or Facilities_Contact__c = true) and Account__c IN: leasecompPropMap.values()];
            		
            List<Related_Contact__c> tenantRCs = [Select Id, account__c, Contact__r.email, Contact__c, Financial_Contact__c, Facilities_Contact__c from Related_Contact__c 
            		where (Financial_Contact__c = true or Facilities_Contact__c = true) and Account__c IN: leasecompTenantMap.values()];
            		
            
            System.debug('**** propRCs: ' + propRCs);
            System.debug('**** tenantRCs: ' + tenantRCs);
            
            //TODO consolidate logic
            EmailTemplate facTem_1st = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName ='Lease_Compliance_External_Facilities'];
            EmailTemplate facTem_2nd = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName ='Lease_Compliance_External_Facilities_2nd_alert'];
            EmailTemplate facTem_3rd = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName ='Lease_Compliance_External_Facilities_final_alert'];
            EmailTemplate finTem = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName ='Lease_Compliance_External_Finance'];
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            String replyToFin = '';
            String replyToFac = '';
            
            try {
	          	LeaseComplianceNotifications__c fcEmailTemplates = LeaseComplianceNotifications__c.getOrgDefaults();
	          	replyToFin = fcEmailTemplates.FinancialsReplyTo__c;
	          	replyToFac = fcEmailTemplates.FacilitiesReplyTo__c;
            } catch (Exception e) {}					
          				
            for (Lease_Compliance__c l : scope) {
            	System.debug('**** processing lease compliance record: ' + l.Name + ' - ' + l);
				EmailTemplate facilitiesEmailTemplate = new EmailTemplate();


            	if (l.Client_Alert_Date__c <= Date.today() && l.Client_Notifications_Sent__c == false){
        			System.debug('First alert');
        			facilitiesEmailTemplate = facTem_1st;
        		} else if (l.Client_Notifications_Sent__c == true && l.Second_Alert_Date__c <= Date.today() && l.Second_Client_Alert_Active__c == true && l.Client_Second_Alert_Sent__c == false){
            		System.debug('Second alert');
            		facilitiesEmailTemplate = facTem_2nd;
            		l.Client_Second_Alert_Sent__c = true;
            	} else if(l.Client_Notifications_Sent__c == true && l.Client_Second_Alert_Sent__c == true && l.Final_Alert_Active__c == true && l.Client_Final_Alert_Sent__c == false && l.Due_Date__c <= Date.today()){
        			System.debug('Final alert');
        			facilitiesEmailTemplate = facTem_3rd;
        			l.Client_Final_Alert_Sent__c = true;
        		} else {
            		System.debug('Not grouped');
            	}

            	if (l.Client_Alert_Deactivated__c) {
            		System.debug('**** Client_Alert_Deactivated__c is true for : ' + l.Name);
            		ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(postFeedElement(l.Id,l.Name,l.Property_Name__c));
            		postItems.add(batchInput);
            		//mark so we dont post another feed
            		l.Client_Notifications_Sent__c = true;
            		addedFeed = true;
            	} else {
	            	set<STring> toAddresses = new set<String>();
	            	Id propId;
	            	Id tenantId;
	            	Id conId;
	            	propId = leasecompPropMap.get(l.Id);
	            	tenantId = leasecompTenantMap.get(l.Id);
	            	System.debug('**** Client_Notification_Role__c: ' + l.Client_Notification_Role__c);
	            	System.debug('**** propId: ' + propId);
	            	System.debug('**** tenantId: ' + tenantId);
	                if (l.Client_Notification_Role__c =='Financial') {
	                	
	                	//for Financial only need to pull from Related Contacts on the Tenant
	                	for (Related_Contact__c rc : tenantRCs) {
	                		System.debug('FINANCIALS TENANT RC: email: ' + rc.Contact__r.email + ' rc.Financial_Contact__c: '  + rc.Financial_Contact__c);
	                		if (rc.account__c==tenantId && rc.Financial_Contact__c) {
	                			toAddresses.add(rc.Contact__r.email);
	                			conId = rc.contact__c;
	                		}
	                	}
	                	if (toAddresses.size()>0) {
	                		System.debug('**** toAddresses: ' + toAddresses + ' for  lease compliance finance record: ' + l);
		                	List<String> toAddr=new List<String>();
							toAddr.addAll(toAddresses);
		                	mails = addEmail(toAddr, mails, l.Id, finTem.Id, conId, replyToFin);
		                	//mark email as being sent
		                	l.Client_Notifications_Sent__c = true;
	                	}
	                	
	                } else if (l.Client_Notification_Role__c =='Facilities') {
	                	//for Facilities contacts could come from the Tenant or Property related contacts 
	                	for (Related_Contact__c rc : tenantRCs) {
	                		System.debug('FACILITIES TENANT RC: email: ' + rc.Contact__r.email + ' rc.Facilities_Contact__c: '  + rc.Facilities_Contact__c);
	                		if (rc.account__c==tenantId && rc.Facilities_Contact__c) {
	                			toAddresses.add(rc.Contact__r.email);
	                			conId = rc.contact__c;
	                		}
	                	}
	                	for (Related_Contact__c rc : propRCs) {
	                		System.debug('FACILITIES PROP RC: email: ' + rc.Contact__r.email + ' rc.Facilities_Contact__c: '  + rc.Facilities_Contact__c);
	                		if (rc.account__c==propId && rc.Facilities_Contact__c) {
	                			toAddresses.add(rc.Contact__r.email);
	                			conId = rc.contact__c;
	                		}
	                	}
	                	
	                	if (toAddresses.size()>0) {
	                		System.debug('**** toAddresses: ' + toAddresses + ' for  lease compliance facilities record: ' + l);
		                	List<String> toAddr=new List<String>();
							toAddr.addAll(toAddresses);
		                	//mails = addEmail(toAddr, mails, l.Id, facTem.Id, conId, replyToFac);
		                	//2019.11.01 J Caughie - replaced with logic to determine which template to use
		                	mails = addEmail(toAddr, mails, l.Id, facilitiesEmailTemplate.Id, conId, replyToFac);
		                	//mark email as being sent
		                	l.Client_Notifications_Sent__c = true;
	                	}
	                	
	                }
            	}            
                
            }
            
            //if ((addedFeed || mails.size()>0) && !test.isrunningtest()) {
            if (addedFeed || mails.size()>0) {
            	
            	if (mails.size()>0) {
		          	System.debug('***sending emails ' + mails);
				    Messaging.sendEmail(mails);
            	}
            	
            	if (postItems.size()>0 && !test.isrunningtest()) {
            		ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), postItems);
            	}
            	update scope;
			    
          	}
		    
		    
		    
            
        }
    }
    
    global void finish(Database.BatchableContext BC) {

    }
   
}