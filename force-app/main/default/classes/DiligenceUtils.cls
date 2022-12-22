public class DiligenceUtils {
	
	public static businesshours bh = [select id from businesshours where isdefault= true];
	public static List<Holiday> holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h];
	
	public class DiligenceException extends Exception {
        
    }

	@testVisible
	private static EmailProvider emailSvc = new EmailProviderStandard();

	public static boolean multiSelectFieldContains(String fldValue, String val) {
		boolean ret = false;
		Set<String> multiselectValues = new Set<String>();
 		if (fldValue!=null) {
 			multiSelectValues.addAll(fldValue.split(';'));
 			if (multiSelectValues.contains(val)) ret = true;
 		}	
 		return ret;
    }

	public static void sendCommunityEmails(List<Intake_Item__c> ii, boolean isUpdate) {
		Set<Id> oppIds = new Set<Id>();
		Set<Id> acctIds = new Set<Id>();

		List<Intake_Item__c> toProcess = new List<Intake_Item__c>();
		for (Intake_Item__c i : ii) {
			if (i.Status__c == DiligenceVars.IntakePendingStatus || isUpdate) {
				toProcess.add(i);
				if (i.Is_Ongoing__c) {
					acctIds.add(i.Account_Name__c);
				} else {
					oppIds.add(i.Opportunity__c);
				}
			}
		}

		if (toProcess.isEmpty()) {
			return;
		}

		acctIds.remove(null);
		oppIds.remove(null);

		Map<Id,Account> accts = new Map<Id,Account>();
		if (!acctIds.isEmpty()) {
			accts.putAll([ SELECT Id, ParentId FROM Account WHERE Id IN :acctIds ]);
			acctIds.addAll(SObjectUtil.collectIds(accts.values(), 'ParentId'));
		}

		List<Community_Contact_Role__c> ccrs = new List<Community_Contact_Role__c>();
		if (!oppIds.isEmpty() || !acctIds.isEmpty()) {
			ccrs.addAll([
				SELECT Id, Role__c, Contact__c, Opportunity__c, Account__c
				FROM Community_Contact_Role__c
				WHERE Opportunity__c IN :oppIds OR Account__c IN :acctIds
			]);
		}

		Map<Id,User> userByContactId = new Map<Id,User>();
		if (!ccrs.isEmpty()) {
			for (User u: [ SELECT Id, Email, ProfileId, Profile.Name, ContactId FROM User WHERE ContactId IN :SObjectUtil.collectIds(ccrs, 'Contact__c') ]) {
				userByContactId.put(u.ContactId, u);
			}
		}

		List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

		EmailTemplate tpl = [ SELECT Id FROM EmailTemplate WHERE DeveloperName = 'CSC_Communities_Additional_Info_Needed_Email' ];

		Map<Id,List<Community_Contact_Role__c>> ccrsByParentId = new Map<Id,List<Community_Contact_Role__c>>();
		ccrsByParentId.putAll(SObjectUtil.groupById(ccrs, 'Opportunity__c'));
		ccrsByParentId.putAll(SObjectUtil.groupById(ccrs, 'Account__c'));

		Map<Id,Messaging.SingleEmailMessage> conEmailMap = new Map<Id,Messaging.SingleEmailMessage>();

		for (Intake_Item__c item: toProcess) {
			List<Community_Contact_Role__c> ccrsForItem = new List<Community_Contact_Role__c>();
			if (item.Is_Ongoing__c) {
				Account acct = accts.get(item.Account_Name__c);
				if (acct != null) {
					addAllToList(ccrsForItem, ccrsByParentId.get(acct.Id));
					addAllToList(ccrsForItem, ccrsByParentId.get(acct.ParentId));
				}
			} else {
				addAllToList(ccrsForItem, ccrsByParentId.get(item.Opportunity__c));
			}

			for (Community_Contact_Role__c ccr: ccrsForItem) {
				if (multiSelectFieldContains(item.Assigned_To__c, ccr.Role__c) && !conEmailMap.containsKey(ccr.Contact__c)) {
					Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
					mail.setTemplateId(tpl.Id);
					mail.setReplyTo('noreply@csc.com');
					mail.setSenderDisplayName('CSC Admin');
					mail.setBccSender(false);
					mail.setUseSignature(false);
					mail.setSaveAsActivity(false);
					mail.setWhatId(item.ID); 
					mail.setTargetObjectId(ccr.Contact__c);
					conEmailMap.put(ccr.Contact__c, mail);
				}
			}
		}

		try {
			emailSvc.sendEmail(conEmailMap.values()); 
		} catch (EXception e) {}
	}
    	
    public static void sendErrorEMail(String error, STring subj) {
    	//List<String> toAddresses = new List<String>();
	    //toAddresses.add('salesforce@charterschoolcapital.com');
	    //toAddresses.add('molinger@relationedge.com');
	    List<Id> sysAdmins = new List<Id>();
        sysAdmins = getSystemAdmins();
        
	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    //mail.setToAddresses(toAddresses);
        mail.setToAddresses(sysAdmins);
	 	mail.setReplyTo('noreply@csc.com');
	    mail.setSenderDisplayName('CSC Admin');
	    mail.setSubject('Salesforce Error in Domain: '+ System.Url.getSalesforceBaseUrl().toExternalForm() + ' - ' + subj);
	    mail.setBccSender(false);
	    mail.setUseSignature(false);
	    mail.setPlainTextBody('Exception: ' + error);
	    try {
	    	//System.debug('Sending error email to: ' + toAddresses);
            System.debug('Sending error email to: ' + sysAdmins);
	      	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
	    } catch (EXception e) {
            System.debug('error sending email: ' + error + ' - ' + e.getstacktracestring() + ': '  + e.getmessage());
	    	throw new DiligenceException('Error: ' + error + ' - ' + e.getstacktracestring() + ': '  + e.getmessage());
	    }
	    
    }
    /* deprecated
    public static boolean checkifItisWorkingDay(Date currentDate,List<Holiday> holidays){
    	
    	
        for(Holiday hDay:holidays){
        	
            if(currentDate.daysBetween(hDay.ActivityDate) == 0){
            	System.debug(currentDate + ' is holiday ');
                return false;
            }
        }
        
        System.debug('checking if ' + currentDate + ' is outside business hours: ');
        
        //if (!businesshours.iswithin(bh.id,currentDate)) {
        if (businesshours.add(bh.id, currentDate, 1).day()!=currentDate.day()) {
            	System.debug(currentDate + ' is outside business hours: ');
            	return false;
        }
        
        return true;
        
  }
  */
	public static Date getDateExcludingHollidayAndWeekend(Date startDate, Integer daysForward) {
		
		//deprecated by J Caughie
		return DateUtilities.calculateStartDate(startDate, daysForward);
		

		/*System.debug('****days backward ' + daysForward );
		//
		Date dtIndex = startDate;
		//if (daysForward==0) { System.debug('****adding 0 days '); dtIndex = startDate; return dtIndex; }
		
		for (Integer i=1;i<=daysForward ;i++ ){
			Integer j = 1;
			Integer returnDays = 1;
			while (!checkifItisWorkingDay(dtIndex.addDays(j*-1),holidays)) {
				j++;
				returnDays++;
			}
			dtIndex = dtIndex.addDays(returndays*-1);
		}
		System.debug('****new date:' + dtIndex);
		
		return dtIndex;*/
	}
	
	
	public static List<Intake_Item__c> createFacilitiesPQItems(Id oppId) {
		//STring communityUrl = Network.getLoginUrl(DiligenceVars.community.Id) ;
		//communityUrl = communityUrl.removeEnd('login');
		
		//make sure none are existing already
		
		List<Intake_Item_Template__c> tems = [Select Id,  Action_Item_Mapping__c,Update_PCL__c,Update_AL__c,Copy_Files_to_AL_PCL__c,  Visible_At_Creation__c, Stop_Number__c, Action_URL__c, Action_Item__c, Processing_Order__c, Is_Document__c, Document_Name__c,Name, 
		Assigned_To__c, 
		visible_to__c, Description__c,  
					X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, (Select Id, X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, Path_Number__c
					 from Diligence_Paths__r )  from Intake_Item_Template__c where is_pre_qual__c = true and RecordTypeId=:RecordTypes.IDFacilitiesIntake];
		
		Map<Intake_Item_Template__c, Intake_Item__c> iiMap = new Map<Intake_Item_Template__c, Intake_Item__c>();
		List<Intake_Item__c> iiForInsert = new List<Intake_Item__c>();
		Opportunity o = [select Id, Accelerated_Sales_Process__c from Opportunity where Id=:oppId];
		
		List<Intake_Item__c> exist = [Select Id from Intake_Item__c where opportunity__c =:oppId and name IN:DiligenceVars.PQFacilitiesNames and status__c!=:DiligenceVars.IntakeApprovedStatus];
		if (exist.size()==0) {
				for (Intake_Item_Template__c tem : tems) {
					Intake_Item__c ii = new Intake_Item__c();
					ii.Action_Item_Mapping__c = tem.Action_Item_Mapping__c;
					ii.Update_PCL__c = tem.Update_PCL__c;
					ii.Update_AL__c = tem.Update_AL__c;
					ii.Copy_Files_to_AL_PCL__c = tem.Copy_Files_to_AL_PCL__c;
					ii.Client_Facing_Item_Name__c = tem.Name;
					ii.Stop_Number__c = tem.Stop_Number__c;
					ii.recordtypeid = RecordTypes.IDFacilitiesIntakeItem;
					ii.Comments__c = tem.Description__c;
					ii.Is_Visible_To_Community__c = tem.Visible_At_Creation__c;
					ii.Name = tem.Name;
					ii.CSC_Action_Item__c = null;
					ii.Action_URL__c = tem.Action_URL__c;
					ii.Opportunity__c = oppId;
					ii.Status__c = DiligenceVars.IntakePendingStatus;
					ii.Assigned_To__c = tem.Assigned_To__c;
					ii.Processing_Order__c = tem.Processing_Order__c;
					ii.Visible_To__c =tem.Visible_To__c;
                    ii.Department__c = tem.Department__c;
					
					//iiForInsert.add(ii);
					iiMap.put(tem, ii);
				}
		} else return null;
		
		iiForInsert = linkIntakeItemToActionItem(oppId, iiMap);
		System.debug('**** PQ items: ' + iiForInsert);
		return iiForInsert;
	}
	
	public static Intake_Item__c createPQItem(Id oppId, Id oppRecordTypeId) {
		//make sure none are existing already
		//STring communityUrl = Network.getLoginUrl(DiligenceVars.community.Id) ;
		//communityUrl = communityUrl.removeEnd('login');
		
		//identify record type for the template
		Id templateId;
		Id recordTypeId;
		System.debug('oppRecordTypeId: ' + oppRecordTypeId);
		if(oppRecordTypeId == RecordTypes.ID5DFOpp){
			templateId = RecordTypes.ID5DFIntake;
			recordTypeId = RecordTypes.ID5DFIntakeItem;
		}else if(oppRecordTypeId == RecordTypes.IDFundingOpp){
			templateId = RecordTypes.IDInitialFundingIntake;
			recordTypeId = REcordTypes.IDInitialFundingIntakeItem;
		}

		Intake_Item_Template__c tem;
		System.debug('template Id: ' + templateId);
		try {
			tem = [Select Id, Action_Item_Mapping__c,Update_PCL__c,Update_AL__c,Copy_Files_to_AL_PCL__c, Visible_At_Creation__c, Is_Pre_Qual__c, Action_URL__c, Action_Item__c, Processing_Order__c, Is_Document__c, Document_Name__c,Name, 
			Assigned_To__c, 
			visible_to__c, Description__c,  
					X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, Department__c, (Select Id, X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, Path_Number__c
					 from Diligence_Paths__r )  from Intake_Item_Template__c where is_pre_qual__c = true and RecordTypeId=:templateId limit 1];
		} catch (EXception e) {return null;}
		System.debug('tem: ' + tem);
		Map<Intake_Item_Template__c, Intake_Item__c> iiMap = new Map<Intake_Item_Template__c, Intake_Item__c>();
		Opportunity o = [select Id, Accelerated_Sales_Process__c from Opportunity where Id=:oppId];
				
		List<Intake_Item__c> iiForInsert = new List<Intake_Item__c>();
		// List<Intake_Item__c> exist = [Select Id from Intake_Item__c where opportunity__c =:oppId and name=:DiligenceVars.PQName and status__c!=:DiligenceVars.IntakeApprovedStatus];
		List<Intake_Item__c> exist = [Select Id from Intake_Item__c where opportunity__c =:oppId and Is_Pre_Qual__c = true and status__c!=:DiligenceVars.IntakeApprovedStatus LIMIT 1];
		if (exist.size()==0) {
				Intake_Item__c ii = new Intake_Item__c();
				Decimal days;
				if (o.Accelerated_Sales_Process__c) {
					days = tem.X14_day_Due_Date_Lag__c;
				} else {
					days = tem.X30_day_Due_Date_Lag__c;
				}
				if (days==null) {ii.due_date__c = null;} else {
					//for PQ since we donthave a Target WIre Date we just add 30 days to today
					ii.due_date__c = getDateExcludingHollidayAndWeekend(Date.today().addDays(30),Integer.valueOf(days));
				}
				
				ii.recordtypeid = recordTypeId;
				ii.Action_Item_Mapping__c = tem.Action_Item_Mapping__c;
				ii.Update_PCL__c = tem.Update_PCL__c;
				ii.Update_AL__c = tem.Update_AL__c;
				ii.Copy_Files_to_AL_PCL__c = tem.Copy_Files_to_AL_PCL__c;
				ii.Client_Facing_Item_Name__c = tem.Name;
				ii.Comments__c = tem.Description__c;
				ii.Is_Visible_To_Community__c = tem.Visible_At_Creation__c;
				ii.Name = tem.Name;
				ii.Is_Pre_Qual__c = tem.Is_Pre_Qual__c;
				ii.CSC_Action_Item__c = null;
				ii.Action_URL__c = tem.Action_URL__c;
				ii.Opportunity__c = oppId;
				System.debug('^^^^^ DiligenceVars.IntakePendingStatus: ' + DiligenceVars.IntakePendingStatus);
				ii.Status__c = DiligenceVars.IntakePendingStatus;
				ii.Assigned_To__c = tem.Assigned_To__c;
				ii.Processing_Order__c = tem.Processing_Order__c;
				ii.Visible_To__c =tem.Visible_To__c;
				ii.Department__c = tem.Department__c;
				
				//iiForInsert.add(ii);
				System.debug('^^^^^ creating intake itme in status: ' + ii.Status__c + ' - ' + ii);
				iiMap.put(tem, ii);
		} else return null;
		
		iiForInsert = linkIntakeItemToActionItem(oppId, iiMap);
		return iiForInsert[0];
	}
	/*
	public static Intake_Item__c createOpeningCallItem(Id oppId) {
		
		//make sure none are existing already
		List<Intake_Item__c> exist = [Select Id from Intake_Item__c where opportunity__c =:oppId and name=:DiligenceVars.OpeningCallName and status__c!=:DiligenceVars.IntakeApprovedStatus];
		if (exist.size()==0) {
				Intake_Item__c ii = new Intake_Item__c();
				Integer daysToAdd = numDaysExcludingHollidayAndWeekend(Date.today(),4);
				ii.due_date__c = Date.today().addDays(daysToAdd);
				ii.Comments__c = DiligenceVars.OpeningCallName;
				ii.Name = DiligenceVars.OpeningCallName;
				ii.CSC_Action_Item__c = null;
				ii.Opportunity__c = oppId;
				ii.Action_URL__c = DiligenceVars.IIActionDetails;
				ii.Assigned_To__c = DiligenceVars.CSCRole;
				ii.Visible_To__c = DiligenceVars.SchoolTenantRole+';'+DiligenceVars.CSCRole;
				ii.Status__c = DiligenceVars.IntakePendingStatus;
				return ii;
		} else return null;	
		
	}
	*/
	public static List<Intake_Item__c> linkIntakeItemToActionItem(Id oppId, Map<Intake_Item_Template__c, Intake_Item__c> iiMap) {
		List<CSC_Action_Item__c> ais = [SELECT Id, Order__c, CSC_Action_List__r.Action_List_Name__c FROM CSC_Action_Item__c WHERE CSC_Action_List__r.Opportunity__c=:oppId];
		
		for (Intake_Item_Template__c tem : iiMap.keyset()) {
			if (tem.Action_Item__c!=null) {
				List<String> listIds = tem.Action_Item__c.split('-');
				if (listIds!=null && listids.size()==2) {
					//need to lookup this CSC Action Item
					for (CSC_Action_Item__c ai : ais) {
						//match the Stage # on CSC Action List
						if (ai.CSC_Action_List__r.Action_List_Name__c !=null && ai.CSC_Action_List__r.Action_List_Name__c.startswith('Stage ' + listIds[0])) {
							//match the Order on the CSC Action List Item
							if (String.valueOf(ai.Order__c)==listIds[1]) {
								//found
								iiMap.get(tem).CSC_Action_Item__c = ai.Id;
								
								break;
							}
						}
					}
				}
			}
		}
		
		return iiMap.values();
	}
    
	public static void updateIntakeItemsDueDates(Id oppId) {
		System.debug('***in updateIntakeItemsDueDates');
		Map<String,Intake_Item__c> existingMap = new Map<String,Intake_Item__c>();
		List<Intake_Item__c> existingItems = new List<Intake_Item__c>();
		Map<Intake_Item__c, Id> forUpdate = new Map<Intake_Item__c,Id>();
		
		Date targetwiredate;
		existingItems = [Select Id, Name from Intake_Item__c where Opportunity__c=:oppId and STatus__c!=:DiligenceVars.IntakeApprovedStatus];
		
			Opportunity o = [Select Id, RecordTypeId, Target_Wire_Date__c, Accelerated_Sales_Process__c, Diligence_Path__c from Opportunity where Id=:oppId];
			if (o.Target_Wire_Date__c==null) {
				throw new DiligenceException('Target Wire Date cannot be Blank');
			} else {
				targetWireDate = o.Target_Wire_Date__c;
			}
			
			if (o.recordtypeid == RecordTypes.IDFacilitiesOpp) {
				
			} else if (o.recordtypeid == RecordTypes.IDFundingOpp || o.recordtypeid == RecordTypes.IDFOFOpp || o.recordtypeid == RecordTypes.ID5DFOpp) {
				Id recType;
				if (o.recordtypeid == RecordTypes.IDFundingOpp ) {
					recType = RecordTypes.IDInitialFundingIntake;
				} else if(o.recordtypeid == RecordTypes.ID5DFOpp) {
					recType = RecordTypes.ID5DFIntake;
				} else recType = RecordTypes.IDFOFIntake;
				
				//initial funding
				List<Intake_Item_Template__c> fundTemplates = [select Id, Action_Item_Mapping__c,Update_PCL__c,Update_AL__c,Copy_Files_to_AL_PCL__c, Due_Date_Lag__c, Action_Item__c, Processing_Order__c, Is_Document__c, Document_Name__c,Name, 
				Assigned_To__c, 
				visible_to__c, Description__c,  
					X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, (Select Id, X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, Path_Number__c
					 from Diligence_Paths__r ) 
					from Intake_Item_Template__c where Active__c = true and RecordTypeId=:recType];
							
				Integer count = 1;
				for (Intake_Item_Template__c i :  fundTemplates) {
					//find Intake Item for given Template, and update Due Date
					for (Intake_Item__c item : existingItems) {
						if (item.name==i.name) {
							//Intake_Item__c ii = existingMap.get(i.Name);
							//if (ii!=null) {
								System.debug('*** setting due date for: ' + item.Name);
								item = setDueDate(o, i, item,  targetWireDate);
								forupdate.put(item,item.Id);
							//}
						}
					}
				}
				
				if (forUpdate.size()>0) {
					List<Intake_Item__c> newForUpdate = new List<Intake_Item__c>();
					for (Intake_Item__c i : forUpdate.keyset()) {
						newForUpdate.add(i);
					}
					update newForUpdate;
				}
			}
	}

	public static void createIntakeItems(Id oppId, Integer beforeStopNumber, Intake_Item__c triggeringItem) {
		
		Date targetWireDate;
		List<Intake_Item__c> itemsFOrInsert = new List<Intake_Item__c>();
		List<Intake_Item__c> existingItems = new List<Intake_Item__c>();
		Map<String,Intake_Item__c> existingMap = new Map<String,Intake_Item__c>();
		Map<Intake_Item_Template__c, Intake_Item__c> iiMap = new Map<Intake_Item_Template__c, Intake_Item__c>();
		Map<STring, Intake_Item__c> iiparentMap = new Map<String, Intake_Item__c>();
		
		Opportunity o = [Select 
		Id, State__c, Operating_State__c, Facilities_Client_Type__c, RecordTypeId, Target_Wire_Date__c, Accelerated_Sales_Process__c, 
		Diligence_Path__c from Opportunity where Id=:oppId];
		 
		Id recType;
		
		if (o.RecordTypeId==recordtypes.IDFacilitiesOpp) {
			recType = Recordtypes.IDFacilitiesIntakeItem;
			//for Facilities we need to filter on Facilities CLient TYpe
			existingItems = [Select Id, Name from Intake_Item__c where RecordTypeId=:recType and Opportunity__c=:oppId and Facilities_Client_Type__c =:o.Facilities_Client_Type__c]; //and STatus__c!=:DiligenceVars.IntakeApprovedStatus
		} else if (o.RecordTypeId==recordtypes.IDFundingOpp) {
			recType = Recordtypes.IDInitialFundingIntakeItem;
			existingItems = [Select Id, Name from Intake_Item__c where RecordTypeId=:recType and Opportunity__c=:oppId]; //and STatus__c!=:DiligenceVars.IntakeApprovedStatus
		} else if (o.RecordTypeId==recordtypes.ID5DFOpp) {
			recType = Recordtypes.ID5DFIntakeItem;
			existingItems = [Select Id, Name from Intake_Item__c where RecordTypeId=:recType and Opportunity__c=:oppId]; //and STatus__c!=:DiligenceVars.IntakeApprovedStatus
		} else if (o.RecordTypeId==recordtypes.IDFOFOpp) {
			recType = Recordtypes.IDFOFIntakeItem;
			existingItems = [Select Id, Name from Intake_Item__c where RecordTypeId=:recType and Opportunity__c=:oppId]; //and STatus__c!=:DiligenceVars.IntakeApprovedStatus
		} else {
				System.debug('**** opp record type does nto create Intake Items');
				return;
		}
		 
		
		for (Intake_Item__c i : existingItems) {
			existingMap.put(i.Name, i);
		}
		
		if (o.Target_Wire_Date__c==null) {
				//throw new DiligenceException('Target Wire Date cannot be Blank');
		} else {
				targetWireDate = o.Target_Wire_Date__c;
		}
		
		Date dueDate;
		
		//get Intake Item Templates for this record type
		
		if (o.recordtypeid == RecordTypes.IDFacilitiesOpp) {
			//default the DIligence path to 5 in the case that we are creating INtake Items prior to the Diligence path being set
			if (o.Diligence_Path__c==null) { o.Diligence_Path__c = 1; }
			
			//get the template that has the stop number
			//default the pro order to a large number
			Decimal procOrder = 99999;
			try {
				Intake_Item_Template__c stopTemplate = [select Id, Processing_Order__c from  Intake_Item_Template__c where recordtypeid=:Recordtypes.IDFacilitiesIntake and Facilities_Client_Type__c includes(:o.Facilities_Client_Type__c)  and stop_number__c=:beforeStopNumber limit 1];
				procOrder = stopTemplate.Processing_Order__c;
				SYstem.debug('***stop template: ' + stopTemplate);
			} catch (EXception e)
 			{
 				
 				
 				//no stop found, if it is the last stop number, create the rest of the items
 				if (triggeringItem!=null &&triggeringItem.Is_Last_Stop__c) {
 					//create rest of items	- just set a large procOrder
 					procOrder = 9999999;
 				} else {
 					System.debug('***There is no Intake Template with Stop # ' + beforeStopNumber);
 					return;
 				}
 				//throw new DiligenceException('There is no Intake Template with Stop # ' + beforeStopNumber);
 			}
 				//Facilitie+s
 			String facClientTYpe = o.Facilities_Client_Type__c;
 			
			List<Intake_Item_Template__c> facTemplates = [select Action_Item_Mapping__c,Update_PCL__c,Update_AL__c,Copy_Files_to_AL_PCL__c,Default__c, Comment_Required__c, State__c, Visible_At_Creation__c, 
				Parent_Intake_Item_Template_del__r.Action_Item_Mapping__c,Parent_Intake_Item_Template_del__r.Update_PCL__c,
				Parent_Intake_Item_Template_del__r.Update_AL__c,Parent_Intake_Item_Template_del__r.Copy_Files_to_AL_PCL__c,
				Parent_Intake_Item_Template_del__r.Comment_Required__c, 
				Parent_Intake_Item_Template_del__r.Name, 
				Parent_Intake_Item_Template_del__r.Is_Last_Stop__c, 
				Parent_Intake_Item_Template_del__r.Assigned_To__c, 
				Parent_Intake_Item_Template_del__r.Department__c,
				Parent_Intake_Item_Template_del__r.visible_to__c,Parent_Intake_Item_Template_del__r.action_url__c,
				Parent_Intake_Item_Template_del__r.Processing_Order__c,
				Parent_Intake_Item_Template_del__r.Stop_Number__c,
				Parent_Intake_Item_Template_del__r.Due_Date_Lag__c,
				Parent_Intake_Item_Template_del__r.Is_Pre_Qual__c,	
				Parent_Intake_Item_Template_del__r.Is_Opening_Call__c,
				Parent_Intake_Item_Template_del__r.Visible_At_Creation__c, 
				Parent_Intake_Item_Template_del__r.Default__c, Parent_Intake_Item_Template_del__r.State__c, 
				Parent_Intake_Item_Template_del__c, Id,Is_Last_Stop__c, Is_Opening_Call__c, Is_Pre_Qual__c,Stop_Number__c,Due_Date_Lag__c,  action_url__c, Action_Item__c, Processing_Order__c, Is_Document__c, Document_Name__c,Name, 
				Assigned_To__c, 
				visible_to__c, Description__c,  
				X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, Department__c, (Select Id, Stop_Number__c, Due_Date_Lag__c, action_url__c, Action_Item__c, Processing_Order__c, Is_Document__c, Document_Name__c,Name, 
				Assigned_To__c, 
				visible_to__c, Description__c,  
				X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, Department__c from Intake_Item_Templates_del__r),(Select Id, Stop_Number__c, Path_Number__c
				 from Diligence_Paths__r where path_number__c=:o.Diligence_Path__c) 
				from Intake_Item_Template__c 
				
				where Active__c = true and RecordTypeId=:RecordTypes.IDFacilitiesIntake
				and Facilities_Client_Type__c includes(:facClientTYpe)
				and (Processing_Order__c<=:procOrder OR Parent_Intake_Item_Template_del__c!=null)];
				
			
			//sort based on processing order
	
			Map<Intake_Item_Template__c, Decimal> facTemplateMap = new Map<Intake_Item_Template__c, Decimal>();
			for (Intake_Item_Template__c i : facTemplates) {
				System.debug('***found template: ' + i.Name);
				facTemplateMap.put(i,i.Processing_Order__c);
			}
			
			facTemplateMap.values().sort();
			
			Integer count = 1;
			for (Intake_Item_Template__c i : facTemplateMap.keyset()) {
				//add Default items and any state specific ones
				List<String> states = new List<String>();
				if (i.state__c!=null) {
					for (String s : i.state__c.split(';')) {
						states.add(s.touppercase());
					}
				}
				SYstem.debug('***template ' + i.Name + ' checking state template : ' + i.state__c + ' for opp value: ' + o.Operating_State__c );
				if (i.default__c||(states.size()>0 &&states.contains(o.Operating_State__c.touppercase()))) {
						
					boolean hasChildren = false;
					boolean hasParent = false;
					if (i.Intake_Item_Templates_del__r!=null&&i.Intake_Item_Templates_del__r.size()>0) { hasChildren = true; }
					if (i.Parent_Intake_Item_Template_del__c!=null) { hasParent = true; }
					SYstem.debug('***template ' + i.Name + ' has children: ' +hasChildren );
					
					if (!hasChildren) {
					
						  SYstem.debug('***template ' + i.Name );
						  boolean continueForCHildDoc = true;
						  if (hasParent) {
						  	SYstem.debug('***item ' + i.Name + ' hasParent');
						  	continueForCHildDoc = false;
							//for child docs, need to have a DIligence path that matches the diligence path of the Opp
							if (i.Diligence_Paths__r!=null&&i.Diligence_Paths__r.size()>0) {
								SYstem.debug('***diligence paths: ' + i.Diligence_Paths__r);
								//only create if Stop Date=  StopNumber from Diligence Paths for Child DOcuments
								if (beforeStopNumber==i.Diligence_Paths__r[0].stop_number__c) {
									continueForCHildDoc = true;
									
								}
							}
						  }	
						  System.debug('*** continuing creating child: ' + continueForCHildDoc);
						  if (continueForCHildDoc) {
								Intake_Item__c ii = new Intake_Item__c();
								//set visibility on the item
								ii.Action_Item_Mapping__c = i.Action_Item_Mapping__c;
								ii.Update_PCL__c = i.Update_PCL__c;
								ii.Update_AL__c = i.Update_AL__c;
								ii.Copy_Files_to_AL_PCL__c = i.Copy_Files_to_AL_PCL__c;
								ii.Is_Visible_To_Community__c = i.Visible_At_Creation__c;
								ii.recordtypeid = RecordTypes.IDFacilitiesIntakeItem;
								ii.Name = i.Name;
								ii.Is_Last_Stop__c = i.Is_Last_Stop__c;
								ii.Is_Pre_Qual__c = i.Is_Pre_Qual__c;
								ii.Is_Opening_Call__c = i.Is_Opening_Call__c;
								ii.Facilities_Client_Type__c = o.Facilities_Client_Type__c;
								ii.Processing_Order__c = i.Processing_Order__c;
								ii.Stop_Number__c = i.Stop_Number__c;
								ii.Comments__c = i.Description__c;
								ii.Opportunity__c = o.Id;
								ii.Status__c = DiligenceVars.IntakePendingStatus;
								ii.assigned_to__c = i.Assigned_To__c;
								ii.visible_to__c = i.visible_to__c;
								ii.action_url__c = i.action_url__c;
								ii.Is_Document__c = i.Is_Document__c;
								ii.Document_Name__c = i.Document_Name__c;
								ii.Department__c = i.Department__c;
								ii.Client_Facing_Item_Name__c = i.Name;
								ii.Comment_Required__c = i.Comment_Required__c;
								
								if (hasParent) {
									//these are only for Child documents
								
									//create the Parent 
									Intake_Item__c iiParent = new Intake_Item__c();
									iiParent.Action_Item_Mapping__c = i.Parent_Intake_Item_Template_del__r.Action_Item_Mapping__c;
									iiParent.Update_PCL__c = i.Parent_Intake_Item_Template_del__r.Update_PCL__c;
									iiParent.Update_AL__c = i.Parent_Intake_Item_Template_del__r.Update_AL__c;
									iiParent.Copy_Files_to_AL_PCL__c = i.Parent_Intake_Item_Template_del__r.Copy_Files_to_AL_PCL__c;
									iiParent.Is_Visible_To_Community__c = i.Parent_Intake_Item_Template_del__r.Visible_At_Creation__c;
									iiParent.Is_Last_Stop__c = i.Parent_Intake_Item_Template_del__r.Is_Last_Stop__c;
									iiParent.Facilities_Client_Type__c = o.Facilities_Client_Type__c;
									iiParent.Name = i.Parent_Intake_Item_Template_del__r.Name;
									iiParent.Client_Facing_Item_Name__c = i.Parent_Intake_Item_Template_del__r.Name;
									iiParent.Is_Pre_Qual__c = i.Parent_Intake_Item_Template_del__r.Is_Pre_Qual__c;
									iiParent.Is_Opening_Call__c = i.Parent_Intake_Item_Template_del__r.Is_Opening_Call__c;
									iiParent.Processing_Order__c = i.Parent_Intake_Item_Template_del__r.Processing_Order__c;
									iiParent.recordtypeid = RecordTypes.IDFacilitiesIntakeItem;
									iiParent.Opportunity__c = o.Id;
									iiParent.Status__c = DiligenceVars.IntakePendingStatus;
									iiParent.assigned_to__c = i.Parent_Intake_Item_Template_del__r.Assigned_To__c;
									iiParent.visible_to__c = i.Parent_Intake_Item_Template_del__r.visible_to__c;
									iiParent.action_url__c = i.Parent_Intake_Item_Template_del__r.action_url__c;
									iiParent.Stop_Number__c = i.Parent_Intake_Item_Template_del__r.Stop_Number__c;
									iiParent.Department__c = i.Parent_Intake_Item_Template_del__r.Department__c;
									iiParent.Comment_Required__c = i.Parent_Intake_Item_Template_del__r.Comment_Required__c;
										
									if (iiparentmap.get(iiParent.Name) ==null && existingMap.get(iiParent.Name)==null) { 
										//create the INtake Item and set the lookup
										System.debug('*** creating parent for : ' + iiParent.Name);
									
										insert iiParent;
										iiparentmap.put(iiParent.Name,iiParent);
										ii.Parent_Intake_Item__c = iiParent.Id;
									} else {
										
										String theid = (existingMap.get(iiParent.Name)!=null ? existingMap.get(iiParent.Name).Id : iiparentmap.get(iiParent.Name).Id);
										System.debug('*** setting parent to : ' + theid);
										ii.Parent_Intake_Item__c = theid;
									}
								
								}
						  	//only add if this item does not already exist
							if (existingMap.get(i.Name) ==null) { 
								
									SYstem.debug('***inserting item ' + ii.Name );
									itemsFOrInsert.add(ii); 
									iiMap.put(i,ii);
								
							}
								
						}
				  }
				}
			}
				
		} else if (o.recordtypeid == RecordTypes.IDFundingOpp || o.recordtypeid == RecordTypes.IDFOFOpp || o.recordtypeid==RecordTypes.ID5DFOpp) {
			STring temRecType;
			
			if (o.RecordTypeId==recordtypes.IDFundingOpp) {
					temRecType = RecordTypes.IDInitialFundingIntake;
				} else if (o.RecordTypeId==recordtypes.IDFOFOpp) {
					temRecType = RecordTypes.IDFOFIntake;
				} else if (o.RecordTypeId==recordtypes.ID5DFOpp) {
					temRecType = RecordTypes.ID5DFIntake;
			} 
			
			List<Intake_Item_Template__c> fundTemplates = [SELECT Action_Item_Mapping__c,Update_PCL__c,Update_AL__c,Copy_Files_to_AL_PCL__c,Default__c, Comment_Required__c, State__c, Visible_At_Creation__c, 
				Parent_Intake_Item_Template_del__r.Action_Item_Mapping__c,Parent_Intake_Item_Template_del__r.Update_PCL__c,
				Parent_Intake_Item_Template_del__r.Update_AL__c,Parent_Intake_Item_Template_del__r.Copy_Files_to_AL_PCL__c,
				Parent_Intake_Item_Template_del__r.Comment_Required__c, 
				Parent_Intake_Item_Template_del__r.Name, 
				Parent_Intake_Item_Template_del__r.Assigned_To__c, 
				Parent_Intake_Item_Template_del__r.visible_to__c,Parent_Intake_Item_Template_del__r.action_url__c,
				Parent_Intake_Item_Template_del__r.Processing_Order__c,
				Parent_Intake_Item_Template_del__r.X14_day_Due_Date_Lag__c, Parent_Intake_Item_Template_del__r.X30_day_Due_Date_Lag__c,
				Parent_Intake_Item_Template_del__r.Is_Pre_Qual__c,
				Parent_Intake_Item_Template_del__r.Is_Opening_Call__c,
				Parent_Intake_Item_Template_del__r.Visible_At_Creation__c, 
				Parent_Intake_Item_Template_del__r.Due_Date_Lag__c,
				Parent_Intake_Item_Template_del__r.Default__c, Parent_Intake_Item_Template_del__r.State__c, 
				Parent_Intake_Item_Template_del__c, Id, action_url__c, Is_Opening_Call__c, Is_Pre_Qual__c, Action_Item__c, Processing_Order__c, Is_Document__c, Document_Name__c,Name, 
				Assigned_To__c, 
				visible_to__c, Description__c,  
				X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, Due_Date_Lag__c, Department__c,
				(SELECT Id, action_url__c, Due_Date_Lag__c, Action_Item__c, Processing_Order__c, Is_Document__c, Document_Name__c,Name, 
					Assigned_To__c, visible_to__c, Description__c,  X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c FROM Intake_Item_Templates_del__r),
				(SELECT Id, X14_day_Due_Date_Lag__c, X30_day_Due_Date_Lag__c, Path_Number__c FROM Diligence_Paths__r) 
				FROM Intake_Item_Template__c WHERE Active__c = true AND RecordTypeId=:temRecType];
			
			//sort based on processing order
			Map<Intake_Item_Template__c, Decimal> fundTemplateMap = new Map<Intake_Item_Template__c, Decimal>();
			for (Intake_Item_Template__c i : fundTemplates) {
				fundTemplateMap.put(i,i.Processing_Order__c);
			}
			System.debug('fundTemplateMap: ' + fundTemplateMap);
					
			fundTemplateMap.values().sort();
			
			Integer count = 1;
			for (Intake_Item_Template__c i :  fundTemplateMap.keyset()) {
				
				//add Default items and any state specific ones
				List<String> states = new List<String>();
				if (i.state__c!=null) {
					for (String s : i.state__c.split(';')) {
						states.add(s.touppercase());
					}
				}
				SYstem.debug('***checking state template : ' + i.state__c + ' for opp value: ' + o.Operating_State__c );
				if (i.default__c||(states.size()>0 &&states.contains(o.Operating_State__c.touppercase()))) {
								
					boolean hasChildren = false;
					boolean hasParent = false;
					if (i.Intake_Item_Templates_del__r!=null&&i.Intake_Item_Templates_del__r.size()>0) { hasChildren = true; }
					if (i.Parent_Intake_Item_Template_del__c!=null) { hasParent = true; }
					
					//crate any items with no children (this includes all except the parent holder item)
					if (!hasChildren) {
						Intake_Item__c ii = new Intake_Item__c();
						ii.Action_Item_Mapping__c = i.Action_Item_Mapping__c;
						ii.Update_PCL__c = i.Update_PCL__c;
						ii.Update_AL__c = i.Update_AL__c;
						ii.Copy_Files_to_AL_PCL__c = i.Copy_Files_to_AL_PCL__c;
						ii.recordtypeid = recType;
						ii.Name = i.Name;
						ii.Client_Facing_Item_Name__c = i.Name;
						ii.Processing_Order__c = i.Processing_Order__c;
						ii = setDueDate(o, i, ii,  targetWireDate);
						ii.Is_Visible_To_Community__c = i.Visible_At_Creation__c;
						
						ii.Comments__c = i.Description__c;
						ii.Is_Pre_Qual__c = i.Is_Pre_Qual__c;
						ii.Is_Opening_Call__c = i.Is_Opening_Call__c;
						ii.Opportunity__c = o.Id;
						ii.Status__c = DiligenceVars.IntakePendingStatus;
						ii.assigned_to__c = i.Assigned_To__c;
						ii.visible_to__c = i.visible_to__c;
						ii.action_url__c = i.action_url__c;
						ii.Is_Document__c = i.Is_Document__c;
						ii.Document_Name__c = i.Document_Name__c;
                        ii.Department__c = i.Department__c;
						ii.Comment_Required__c = i.Comment_Required__c;
						
						//create the child
						if (hasParent) {
							Intake_Item__c iiParent = new Intake_Item__c();
							
							iiParent.Name = i.Parent_Intake_Item_Template_del__r.Name;
							iiParent.Client_Facing_Item_Name__c = i.Parent_Intake_Item_Template_del__r.Name;
							iiParent.Is_Visible_To_Community__c = i.Parent_Intake_Item_Template_del__r.Visible_At_Creation__c;
							
							if (iiparentmap.get(iiParent.Name) ==null) { 
								//create the INtake Item and set the lookup
								
								//if (i.Parent_Intake_Item_Template_del__r.Processing_Order__c==null) { iiParent.Processing_Order__c = null; }
								//else { iiParent.Processing_Order__c = count;count++; }
								iiParent.Processing_Order__c = i.Parent_Intake_Item_Template_del__r.Processing_Order__c;
								
								iiParent.Action_Item_Mapping__c = i.Parent_Intake_Item_Template_del__r.Action_Item_Mapping__c;
								iiParent.Update_PCL__c = i.Parent_Intake_Item_Template_del__r.Update_PCL__c;
								iiParent.Update_AL__c = i.Parent_Intake_Item_Template_del__r.Update_AL__c;
								iiParent.Copy_Files_to_AL_PCL__c = i.Parent_Intake_Item_Template_del__r.Copy_Files_to_AL_PCL__c;
								
								iiParent.Opportunity__c = o.Id;
								iiParent.Status__c = DiligenceVars.IntakePendingStatus;
								iiParent.Is_Pre_Qual__c = i.Parent_Intake_Item_Template_del__r.Is_Pre_Qual__c;
								iiParent.Is_Opening_Call__c = i.Parent_Intake_Item_Template_del__r.Is_Opening_Call__c;
								iiParent.recordtypeid = recType;
								iiParent.assigned_to__c = i.Parent_Intake_Item_Template_del__r.Assigned_To__c;
								iiParent.visible_to__c = i.Parent_Intake_Item_Template_del__r.visible_to__c;
								iiParent.action_url__c = i.Parent_Intake_Item_Template_del__r.action_url__c;
								iiParent = setDueDate(o, i.Parent_Intake_Item_Template_del__r, iiParent,  targetWireDate);
								iiParent.Comment_Required__c = i.Parent_Intake_Item_Template_del__r.Comment_Required__c;
								
								System.debug('***Setting due date for parent to: ' + ii.due_date__c);
								
								if (existingMap.get(i.Parent_Intake_Item_Template_del__r.Name) ==null) {
									
										insert iiParent;
										iiparentmap.put(iiParent.Name,iiParent);
										ii.Parent_Intake_Item__c = iiParent.Id;
									
								}
							} else {
								ii.Parent_Intake_Item__c = iiparentmap.get(iiParent.Name).Id;
							}
							
						}
						
						if (existingMap.get(i.Name) ==null) { 
								
							itemsFOrInsert.add(ii); iiMap.put(i,ii);
								
						}
					}
				}
				
			}
			
		}
		
		itemsFOrInsert = linkIntakeItemToActionItem(oppId, iiMap);
		system.debug('!!! itemsFOrInsert = ' + itemsFOrInsert);

		if (itemsFOrInsert.size()>0) {
            insert itemsFOrInsert;
        }
	}
		
	public static Intake_item__c setDueDate(Opportunity o, Intake_Item_Template__c i, Intake_Item__c ii, Date targetWireDate) {
		System.debug('(***targetwiredate: ' + targetWireDate);
		
		//set the Due Date if we have Diligence Path and Targte Wire Date
		
		if (o.recordtypeid == RecordTypes.IDFundingOpp) {
			//INITIAL FUNDING & 5DF
				if (targetWireDate!=null&&o.diligence_path__c!=null) {
					Decimal fourteenDayLag = i.X14_day_Due_Date_Lag__c;
					Decimal thirtyDayLag = i.X30_day_Due_Date_Lag__c;
					if (i.Diligence_Paths__r!=null&&i.Diligence_Paths__r.size()>0) {
						for (Diligence_Path__c d : i.Diligence_Paths__r) {
							if (d.path_number__c==o.diligence_path__c && d.X14_day_Due_Date_Lag__c!=null) {
									fourteenDayLag = d.X14_day_Due_Date_Lag__c;
							}
							if (d.path_number__c==o.diligence_path__c && d.X30_day_Due_Date_Lag__c!=null) {
									thirtyDayLag = d.X30_day_Due_Date_Lag__c;
							}
						}
					}
					if (o.Accelerated_Sales_Process__c) {
						//14 day path
						if (fourteenDayLag==null) {ii.due_date__c = null;} else {
							ii.due_date__c =  getDateExcludingHollidayAndWeekend(targetWireDate, Integer.valueOf(fourteenDayLag));
						}
						System.debug('(***new due date: ' + ii.due_date__c);
						
					} else {
						//30 day path
						if (thirtyDayLag==null) {ii.due_date__c = null;} else {
							ii.due_date__c = getDateExcludingHollidayAndWeekend(targetWireDate, Integer.valueOf(thirtyDayLag));
						}
						System.debug('(***new due date: ' + ii.due_date__c);
						
					}
				}
				
				return ii;
		} else if (o.recordtypeid == RecordTypes.IDFOFOpp || o.recordtypeid == RecordTypes.ID5DFOpp) {
			//FOF
			if (targetWireDate!=null) {
				Decimal dayLag = i.Due_Date_Lag__c;
				if (dayLag==null) {ii.due_date__c = null;} else {
					ii.due_date__c =  getDateExcludingHollidayAndWeekend(targetWireDate,Integer.valueOf(dayLag));
				}
			}
			return ii;
		} else if (o.recordtypeid == RecordTypes.IDFacilitiesOpp) {
			//FACILITIES
			if (targetWireDate!=null&&o.diligence_path__c!=null) {
				Decimal dayLag = i.Due_Date_Lag__c;
				if (dayLag==null) {ii.due_date__c = null;} else {
					ii.due_date__c =  getDateExcludingHollidayAndWeekend(targetWireDate,Integer.valueOf(dayLag));
				}
			}
			
			return ii;
		} else return null;
	
	} 
	
    public static List<Id> getSystemAdmins(){
        Map<Id, User> mapSystemAdmins = new Map<Id, User>([SELECT Id, Name, Profile.Name FROM User WHERE Profile.Name = 'CSC - System Administrator' AND IsActive = True]);
        List<Id> sysAdmins = new List<Id>(mapSystemAdmins.keySet());
        return sysAdmins;
    }	

	public static Map<String, String> getClientFriendlyStatuses{
        get{
            if (getClientFriendlyStatuses == null) {
            	Map<String, String> getClientFriendlyStatuses = new Map<String, String>();
            	Schema.DescribeFieldResult fieldResult = Intake_Item__c.Status__c.getDescribe();
				List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

				for( Schema.PicklistEntry v : values) {
				    getClientFriendlyStatuses.put(v.getValue(), v.getLabel());
				}
            	return getClientFriendlyStatuses;
            }
            return getClientFriendlyStatuses;
        }
        private set;
    }

    private class IntakeItemCloneWrapper {
        public IntakeItemCloneWrapper parent { get; set; }
        public Intake_Item__c item { get; set; }

        public IntakeItemCloneWrapper(Intake_Item__c ii) {
            this.item = ii;
        }
    }

    private static List<IntakeItemCloneWrapper> cloneIntakeItemTemplates(List<Intake_Item_Template__c> templates, CSC_Action_Item__c actionItem, Id recType) {
        List<IntakeItemCloneWrapper> wrappers = new List<IntakeItemCloneWrapper>();

        Map<String,IntakeItemCloneWrapper> parentMap = new Map<String,IntakeItemCloneWrapper>();
        for (Intake_Item_Template__c i: templates) {
            boolean hasChildren = false;
            boolean hasParent = false;

            if (i.Intake_Item_Templates_del__r!=null&&i.Intake_Item_Templates_del__r.size()>0) { hasChildren = true; }
            if (i.Parent_Intake_Item_Template_del__c!=null) { hasParent = true; }

            if (!hasChildren) {
                Intake_Item__c ii = new Intake_Item__c();
                ii.CSC_Action_Item__c = actionItem.Id;
                ii.Action_Item_Mapping__c = i.Action_Item_Mapping__c;
                ii.Update_PCL__c = i.Update_PCL__c;
                ii.Update_AL__c = i.Update_AL__c;
                ii.Copy_Files_to_AL_PCL__c = i.Copy_Files_to_AL_PCL__c;
                ii.RecordTypeId = recType;
                ii.Name = i.Name;
                ii.Client_Facing_Item_Name__c = i.Name;
                ii.Processing_Order__c = i.Processing_Order__c;
                ii.Due_Date__c = actionItem.CP_Item_Due_Date__c;
                ii.Is_Visible_To_Community__c = i.Visible_At_Creation__c;
                ii.Comments__c = i.Description__c;
                ii.Is_Pre_Qual__c = i.Is_Pre_Qual__c;
                ii.Is_Opening_Call__c = i.Is_Opening_Call__c;
                ii.Account_Name__c = actionItem.Account_Id__c;
                ii.Status__c = DiligenceVars.IntakePendingStatus;
                ii.Assigned_To__c = i.Assigned_To__c;
                ii.Visible_To__c = i.Visible_To__c;
                ii.Action_url__c = i.Action_url__c;
                ii.Is_Document__c = i.Is_Document__c;
                ii.Document_Name__c = i.Document_Name__c;
                ii.Department__c = i.Department__c;
                ii.Comment_Required__c = i.Comment_Required__c;
                ii.Is_Last_Stop__c = i.Is_Last_Stop__c;
                ii.Stop_Number__c = i.Stop_Number__c;
                ii.Update_Lease_Compliance__c = i.Update_Lease_Compliance__c;
                ii.Client_Alert_Days__c = i.Client_Alert_Days__c;
                ii.Automatically_make_visible_in_Portal__c = i.Automatically_make_visible_in_Portal__c;
                ii.days_prior_to_due_date_to_make_visible__c = i.days_prior_to_due_date_to_make_visible__c;
                IntakeItemCloneWrapper wrapper = new IntakeItemCloneWrapper(ii);

                if (hasParent) {
                    IntakeItemCloneWrapper parentWrapper = parentMap.get(i.Parent_Intake_Item_Template_del__r.Name);
                    if (parentWrapper == null) {
                        Intake_Item__c iiParent = new Intake_Item__c();
                        iiParent.CSC_Action_Item__c = actionItem.Id;
                        iiParent.Name = i.Parent_Intake_Item_Template_del__r.Name;
                        iiParent.Client_Facing_Item_Name__c = i.Parent_Intake_Item_Template_del__r.Name;
                        iiParent.Is_Visible_To_Community__c = i.Parent_Intake_Item_Template_del__r.Visible_At_Creation__c;
                        iiParent.Processing_Order__c = i.Parent_Intake_Item_Template_del__r.Processing_Order__c;
                        iiParent.Action_Item_Mapping__c = i.Parent_Intake_Item_Template_del__r.Action_Item_Mapping__c;
                        iiParent.Update_PCL__c = i.Parent_Intake_Item_Template_del__r.Update_PCL__c;
                        iiParent.Update_AL__c = i.Parent_Intake_Item_Template_del__r.Update_AL__c;
                        iiParent.Copy_Files_to_AL_PCL__c = i.Parent_Intake_Item_Template_del__r.Copy_Files_to_AL_PCL__c;
                        iiParent.Account_Name__c = actionItem.Account_Id__c;
                        iiParent.Status__c = DiligenceVars.IntakePendingStatus;
                        iiParent.Is_Pre_Qual__c = i.Parent_Intake_Item_Template_del__r.Is_Pre_Qual__c;
                        iiParent.Is_Opening_Call__c = i.Parent_Intake_Item_Template_del__r.Is_Opening_Call__c;
                        iiParent.RecordTypeId = recType;
                        iiParent.Assigned_To__c = i.Parent_Intake_Item_Template_del__r.Assigned_To__c;
                        iiParent.Visible_To__c = i.Parent_Intake_Item_Template_del__r.Visible_To__c;
                        iiParent.Action_url__c = i.Parent_Intake_Item_Template_del__r.Action_url__c;
                        iiParent.Due_Date__c = actionItem.CP_Item_Due_Date__c;
                        iiParent.Comment_Required__c = i.Parent_Intake_Item_Template_del__r.Comment_Required__c;
                        iiParent.Is_Last_Stop__c = i.Parent_Intake_Item_Template_del__r.Is_Last_Stop__c;
                        iiParent.Stop_Number__c = i.Parent_Intake_Item_Template_del__r.Stop_Number__c;
                        iiParent.Department__c = i.Parent_Intake_Item_Template_del__r.Department__c;
                        iiParent.Update_Lease_Compliance__c = i.Parent_Intake_Item_Template_del__r.Update_Lease_Compliance__c;
                        iiParent.Client_Alert_Days__c = i.Parent_Intake_Item_Template_del__r.Client_Alert_Days__c;
                        iiParent.Automatically_make_visible_in_Portal__c = i.Parent_Intake_Item_Template_del__r.Automatically_make_visible_in_Portal__c;
                        iiParent.days_prior_to_due_date_to_make_visible__c = i.Parent_Intake_Item_Template_del__r.days_prior_to_due_date_to_make_visible__c;
                        parentWrapper = new IntakeItemCloneWrapper(iiParent);
                        parentMap.put(iiParent.Name, parentWrapper);
                    }
                    wrapper.parent = parentWrapper;
                }

                wrappers.add(wrapper);
            }
        }

        return wrappers;
    }

    private static void insertWrappers(List<IntakeItemCloneWrapper> wrappers) {
        Set<IntakeItemCloneWrapper> parentSet = new Set<IntakeItemCloneWrapper>();
        for (IntakeItemCloneWrapper wrapper: wrappers) {
            if (wrapper.parent != null) {
                parentSet.add(wrapper.parent);
            }
        }

        List<Intake_Item__c> parentItems = new List<Intake_Item__c>();
        List<Intake_Item__c> childItems = new List<Intake_Item__c>();

        for (IntakeItemCloneWrapper parent: parentSet) {
            parentItems.add(parent.item);
        }

        insert parentItems;

        for (IntakeItemCloneWrapper wrapper: wrappers) {
            if (wrapper.parent != null) {
                wrapper.item.Parent_Intake_Item__c = wrapper.parent.item.Id;
            }
            childItems.add(wrapper.item);
        }

        insert childItems;
    }

    public static void createNewOngoingDiligence(List<CSC_Action_Item__c> actionItems) {
        Set<String> states = new Set<String>();
        Set<String> mappings = new Set<String>();

        for (CSC_Action_Item__c actionItem: actionItems) {
            states.add(getOperatingState(actionItem));
            mappings.add(actionItem.Action_Item_Mapping__c);
        }

        states.remove(null);
        mappings.remove(null);

        List<Intake_Item_Template__c> templates = new List<Intake_Item_Template__c>();
        if (!mappings.isEmpty()) {
            templates.addAll([
                SELECT
                    Id,
                    Name,
                    Action_Item_Mapping__c,
                    Action_url__c,
                    Assigned_To__c,
                    Client_Alert_Days__c,
                    Comment_Required__c,
                    Copy_Files_to_AL_PCL__c,
                    Default__c,
                    Department__c,
                    Description__c,
                    Document_Name__c,
                    Facilities_Client_Type__c,
                    Is_Document__c,
                    Is_Last_Stop__c,
                    Is_Opening_Call__c,
                    Is_Pre_Qual__c,
                    Processing_Order__c,
                    State__c,
                    Stop_Number__c,
                    Update_AL__c,
                    Update_Lease_Compliance__c,
                    Update_PCL__c,
                    Visible_At_Creation__c,
                    Visible_to__c,
										Automatically_make_visible_in_Portal__c,
										days_prior_to_due_date_to_make_visible__c,
                    Parent_Intake_Item_Template_del__c,
                    Parent_Intake_Item_Template_del__r.Id,
                    Parent_Intake_Item_Template_del__r.Name,
                    Parent_Intake_Item_Template_del__r.Action_Item_Mapping__c,
                    Parent_Intake_Item_Template_del__r.Action_url__c,
                    Parent_Intake_Item_Template_del__r.Assigned_To__c,
                    Parent_Intake_Item_Template_del__r.Comment_Required__c,
                    Parent_Intake_Item_Template_del__r.Client_Alert_Days__c,
                    Parent_Intake_Item_Template_del__r.Copy_Files_to_AL_PCL__c,
                    Parent_Intake_Item_Template_del__r.Default__c,
                    Parent_Intake_Item_Template_del__r.Department__c,
                    Parent_Intake_Item_Template_del__r.Description__c,
                    Parent_Intake_Item_Template_del__r.Document_Name__c,
                    Parent_Intake_Item_Template_del__r.Facilities_Client_Type__c,
                    Parent_Intake_Item_Template_del__r.Is_Document__c,
                    Parent_Intake_Item_Template_del__r.Is_Last_Stop__c,
                    Parent_Intake_Item_Template_del__r.Is_Opening_Call__c,
                    Parent_Intake_Item_Template_del__r.Is_Pre_Qual__c,
                    Parent_Intake_Item_Template_del__r.Processing_Order__c,
                    Parent_Intake_Item_Template_del__r.State__c,
                    Parent_Intake_Item_Template_del__r.Stop_Number__c,
                    Parent_Intake_Item_Template_del__r.Update_AL__c,
                    Parent_Intake_Item_Template_del__r.Update_Lease_Compliance__c,
                    Parent_Intake_Item_Template_del__r.Update_PCL__c,
                    Parent_Intake_Item_Template_del__r.Visible_At_Creation__c,
                    Parent_Intake_Item_Template_del__r.Visible_to__c,
										Parent_Intake_Item_Template_del__r.Automatically_make_visible_in_Portal__c,
										Parent_Intake_Item_Template_del__r.days_prior_to_due_date_to_make_visible__c,
                    (SELECT Id FROM Intake_Item_Templates_del__r)
                FROM Intake_Item_Template__c
                WHERE Is_Ongoing__c = true
                AND Action_Item_Mapping__c IN :mappings
            ]);
        }

        Map<String,List<Intake_Item_Template__c>> templatesByKey = new Map<String,List<Intake_Item_Template__c>>();

        for (Intake_Item_Template__c template: templates) {
            List<String> keys = new List<String>();

            if (template.Default__c) {
                keys.add(template.Action_Item_Mapping__c);
            } else if (String.isNotBlank(template.State__c)) {
                for (String state: template.State__c.split(';')) {
                    keys.add(String.join(new List<String> { template.Action_Item_Mapping__c, state.trim() }, ':'));
                }
            }

            for (String key: keys) {
                List<Intake_Item_Template__c> templatesForKey = templatesByKey.get(key);
                if (templatesForKey == null) {
                    templatesForKey = new List<Intake_Item_Template__c>();
                    templatesByKey.put(key, templatesForKey);
                }
                templatesForKey.add(template);
            }
        }

        List<IntakeItemCloneWrapper> wrappers = new List<IntakeItemCloneWrapper>();
        for (CSC_Action_Item__c actionItem: actionItems) {
            if (String.isNotBlank(actionItem.Action_Item_Mapping__c)) {
                List<Intake_Item_Template__c> templatesForItem = new List<Intake_Item_Template__c>();

                String defaultKey = actionItem.Action_Item_Mapping__c;

                List<Intake_Item_Template__c> defaultTemplates = templatesByKey.get(defaultKey);

                if (defaultTemplates != null) {
                    templatesForItem.addAll(defaultTemplates);
                }

                if (String.isNotBlank(getOperatingState(actionItem))) {
                    String stateKey = String.join(new List<String> {
                        actionItem.Action_Item_Mapping__c,
                        getOperatingState(actionItem)
                    }, ':');

                    List<Intake_Item_Template__c> stateTemplates = templatesByKey.get(stateKey);

                    if (stateTemplates != null) {
                        templatesForItem.addAll(stateTemplates);
                    }
                }

                wrappers.addAll(cloneIntakeItemTemplates(templatesForItem, actionItem, RecordTypes.IDOngoingIntakeItem));
            }
        }

        insertWrappers(wrappers);
    }

    private static String getOperatingState(CSC_Action_Item__c actionItem) {
        String stateName = actionItem.CSC_Action_List__r.Account__r.Operating_State__r.State_Name__c;
        return String.isBlank(stateName) ? null : stateName.toUpperCase();
    }

    public static void createOngoingDiligence(Set<Id> actionItemIds) {
        createOngoingDiligence([
            SELECT
                Account_Id__c,
                Action_Item_Mapping__c,
                CP_Item_Due_Date__c,
                CSC_Action_List__r.Account__r.Operating_State__r.State_Name__c
            FROM CSC_Action_Item__c
            WHERE Id IN :actionItemIds
        ]);
    }

    public static void createOngoingDiligence(List<CSC_Action_Item__c> actionItems) {
        Set<String> mappings = new Set<String>();
        Set<Id> acctIds = new Set<Id>();

        for (CSC_Action_Item__c actionItem: actionItems) {
            mappings.add(actionItem.Action_Item_Mapping__c);
            acctIds.add(actionItem.Account_Id__c);
        }

        mappings.remove(null);
        acctIds.remove(null);

        Map<String,List<Intake_Item__c>> itemsByKey = new Map<String,List<Intake_item__c>>();

        List<Intake_Item__c> allItems = new List<Intake_Item__c>();
        if (!mappings.isEmpty() && !acctIds.isEmpty()) {
            allItems.addAll([
                SELECT Id, Account_Name__c, Account_Name__r.ParentId, Action_Item_Mapping__c
                FROM Intake_Item__c
                WHERE Status__c != :DiligenceVars.IntakeApprovedStatus
                AND Is_Ongoing__c = true
                AND Action_Item_Mapping__c IN :mappings
                AND (Account_Name__c IN :acctIds OR Account_Name__r.ParentId IN :acctIds)
								AND (Due_Date__c >= TODAY
								OR Is_Visible_To_Community__c = FALSE)
            ]);
        }

        for (Intake_Item__c item: allItems) {
            List<String> keys = new List<String>();

            if (item.Account_Name__c != null) {
                keys.add(String.join(new List<String> { item.Action_Item_Mapping__c, item.Account_Name__c }, ':'));
            }

            if (item.Account_Name__r.ParentId != null) {
                keys.add(String.join(new List<String> { item.Action_Item_Mapping__c, item.Account_Name__r.ParentId }, ':'));
            }

            for (String key: keys) {
                List<Intake_Item__c> itemsForKey = itemsByKey.get(key);
                if (itemsForKey == null) {
                    itemsForKey = new List<Intake_Item__c>();
                    itemsByKey.put(key, itemsForKey);
                }
                itemsForKey.add(item);
            }
        }

        List<CSC_Action_Item__c> actionItemsToCreateNewDiligence = new List<CSC_Action_Item__c>();
        List<Intake_Item__c> itemsToUpdate = new List<Intake_Item__c>();

        for (CSC_Action_Item__c actionItem: actionItems) {
            if (String.isNotBlank(actionItem.Action_Item_Mapping__c) && String.isNotBlank(actionItem.Account_Id__c)) {
                String key = String.join(new List<String> { actionItem.Action_Item_Mapping__c, Id.valueOf(actionItem.Account_Id__c) }, ':');
                List<Intake_Item__c> items = itemsByKey.get(key);
                if (items != null && !items.isEmpty()) {
                    for (Intake_Item__c item: items) {
                        item.Due_Date__c = actionItem.CP_Item_Due_Date__c;
                        item.Client_Alert_Sent__c = false;
                    }
                    itemsToUpdate.addAll(items);
                } else {
                    actionItemsToCreateNewDiligence.add(actionItem);
                }
            }
        }

        createNewOngoingDiligence(actionItemsToCreateNewDiligence);

        update itemsToUpdate;
    }

    private static void addAllToList(List<SObject> target, List<SObject> toAdd) {
        if (toAdd != null) {
            target.addAll(toAdd);
        }
    }

    private static void addToMapByKey(Map<Id,List<SObject>> dataMap, SObject record, Id key) {
        if (key != null) {
            List<SObject> recordsForKey = dataMap.get(key);
            if (recordsForKey == null) {
                recordsForKey = new List<SObject>();
                dataMap.put(key, recordsForKey);
            }
            recordsForKey.add(record);
        }
    }

    private static void addToMapByKeyField(Map<Id,List<SObject>> dataMap, SObject record, SObjectField keyField) {
        addToMapByKey(dataMap, record, (Id)record.get(keyField));
    }

    public static void shareIntakeItems(List<Community_Contact_Role__c> ccrs) {
			System.debug('***ccrs***' + ccrs);
        Set<Id> contactIds = new Set<Id>();
        for (Community_Contact_Role__c ccr: ccrs) {
            contactIds.add(ccr.Contact__c);
        }
        contactIds.remove(null);

        if (!contactIds.isEmpty()) {
            calculateSharing([
                SELECT Id, ContactId
                FROM User
                WHERE ContactId IN :contactIds
                AND IsActive = true
            ]);
        }
    }

    public static void shareIntakeItems(List<Intake_Item__c> items) {
        Set<Id> relatedIds = new Set<Id>();

        if (items.isEmpty()) {
            return;
        }

        items = [
            SELECT Id, Account_Name__c, Account_Name__r.ParentId, Opportunity__c, Is_Ongoing__c
            FROM Intake_Item__c
            WHERE Id IN :new Map<Id,Intake_Item__c>(items).keySet()
            AND Is_Visible_To_Community__c = true
        ];

        for (Intake_Item__c item: items) {
            if (item.Is_Ongoing__c) {
                relatedIds.add(item.Account_Name__c);
                relatedIds.add(item.Account_Name__r.ParentId);
            } else {
                relatedIds.add(item.Opportunity__c);
            }
        }

        if (!relatedIds.isEmpty()) {
						System.debug('***relatedids***' + relatedIds);
						Set<ID> setRelatedIds = new Set<Id>(relatedIds);
						setRelatedIds.remove(null);
						System.debug('***setRelatedIds***' + setRelatedIds);
            shareIntakeItems([
                SELECT Id, Contact__c
                FROM Community_Contact_Role__c
                WHERE (Account__c IN :setRelatedIds OR Opportunity__c IN :setRelatedIds)
            ]);
        }
    }

    public static void calculateSharing(Set<Id> userIds) {
        calculateSharing([
            SELECT Id, ContactId
            FROM User
            WHERE Id IN :userIds
        ]);
    }

    private static void calculateSharing(List<User> users) {
        Set<Id> userIds = new Map<Id,User>(users).keySet();
        Set<Id> contactIds = new Set<Id>();
        Map<Id,User> usersByContactId = new Map<Id,User>();

        for (User u: users) {
            if (u.ContactId != null) {
                contactIds.add(u.ContactId);
                usersByContactId.put(u.ContactId, u);
            }
        }

        List<Community_Contact_Role__c> allCCRs = new List<Community_Contact_Role__c>();
        if (!contactIds.isEmpty()) {
            allCCRs.addAll([
                SELECT Contact__c, Account__c, Opportunity__c
                FROM Community_Contact_Role__c
                WHERE Contact__c IN :contactIds
            ]);
        }

        Set<Id> acctIds = new Set<Id>();
        Set<Id> opptyIds = new Set<Id>();
        for (Community_Contact_Role__c ccr: allCCRs) {
            acctIds.add(ccr.Account__c);
            opptyIds.add(ccr.Opportunity__c);
        }

        acctIds.remove(null);
        opptyIds.remove(null);

        Map<Id,List<Community_Contact_Role__c>> ccrsByContactId = new Map<Id,List<Community_Contact_Role__c>>();
        for (Community_Contact_Role__c ccr: allCCRs) {
            addToMapByKey(ccrsByContactId, ccr, ccr.Contact__c);
        }

        Map<Id,List<Intake_Item__c>> itemsByParentId = new Map<Id,List<Intake_Item__c>>();
        if (!acctIds.isEmpty() || !opptyIds.isEmpty()) {
            for (Intake_Item__c item: [
                SELECT Id, Account_Name__c, Account_Name__r.ParentId, Opportunity__c, Is_Ongoing__c
                FROM Intake_Item__c
                WHERE Is_Visible_To_Community__c = true
                AND (
                    (Is_Ongoing__c = true AND (Account_Name__c IN :acctIds OR Account_Name__r.ParentId IN :acctIds))
                    OR (Is_Ongoing__c = false AND Opportunity__c IN :opptyIds)
                )
            ]) {
                if (item.Is_Ongoing__c) {
                    addToMapByKey(itemsByParentId, item, item.Account_Name__c);
                    addToMapByKey(itemsByParentId, item, item.Account_Name__r.ParentId);
                } else {
                    addToMapByKey(itemsByParentId, item, item.Opportunity__c);
                }
            }
        }

        Map<Id,Account> acctMap = new Map<Id,Account>();
        if (!acctIds.isEmpty()) {
            acctMap.putAll([
                SELECT Id, (SELECT Id FROM ChildAccounts)
                FROM Account
                WHERE Id IN :acctIds
            ]);
        }

        Map<String,SObject> existingShares = new Map<String,SObject>();
        if (!userIds.isEmpty()) {
            for (Intake_Item__Share share: [ SELECT Id, ParentId, UserOrGroupId FROM Intake_Item__Share WHERE UserOrGroupId IN :userIds AND RowCause = 'Manual' ]) {
                existingShares.put(share.UserOrGroupId+':'+share.ParentId, share);
            }
            for (AccountShare share: [ SELECT Id, AccountId, UserOrGroupId FROM AccountShare WHERE UserOrGroupId IN :userIds AND RowCause = 'Manual' ]) {
                existingShares.put(share.UserOrGroupId+':'+share.AccountId, share);
            }
            for (OpportunityShare share: [ SELECT Id, OpportunityId, UserOrGroupId FROM OpportunityShare WHERE UserOrGroupId IN :userIds AND RowCause = 'Manual' ]) {
                existingShares.put(share.UserOrGroupId+':'+share.OpportunityId, share);
            }
        }

        Map<String,SObject> createShares = new Map<String,SObject>();
        for (User u: users) {
            List<Community_Contact_Role__c> ccrs = ccrsByContactId.get(u.ContactId);
            if (ccrs == null) {
                continue;
            }
            for (Community_Contact_Role__c ccr: ccrs) {
                List<Intake_Item__c> itemsToShare = new List<Intake_Item__c>();
                List<Account> acctsToShare = new List<Account>();
                addAllToList(itemsToShare, itemsByParentId.get(ccr.Account__c));
                addAllToList(itemsToShare, itemsByParentId.get(ccr.Opportunity__c));
                if (ccr.Account__c != null) {
                    Account acct = acctMap.get(ccr.Account__c);
                    acctsToShare.add(acct);
                    acctsToShare.addAll(acct.ChildAccounts);
                }
                for (Intake_Item__c item: itemsToShare) {
                    createShares.put(u.Id+':'+item.Id, new Intake_Item__Share(
                        ParentId = item.Id,
                        UserOrGroupId = u.Id,
                        AccessLevel = 'Edit'
                    ));
                }
                for (Account acct: acctsToShare) {
                    createShares.put(u.Id+':'+acct.Id, new AccountShare(
                        AccountId = acct.Id,
                        UserOrGroupId = u.Id,
                        AccountAccessLevel = 'Edit',
                        OpportunityAccessLevel = 'Read'
                    ));
                }
                if (ccr.Opportunity__c != null) {
                    createShares.put(u.Id+':'+ccr.Opportunity__c, new OpportunityShare(
                        OpportunityId = ccr.Opportunity__c,
                        UserOrGroupId = u.Id,
                        OpportunityAccessLevel = 'Edit'
                    ));
                }
            }
        }

        List<SObject> toDelete = new List<SObject>();
        for (String key: existingShares.keySet()) {
            SObject share = existingShares.get(key);
            if (createShares.containsKey(key)) {
                // do not re-create the share if it exists
                createShares.remove(key);
            } else {
                // delete any shares that are not in the newly calculated map
                toDelete.add(share);
            }
        }

        for (List<SObject> records: groupByType(toDelete).values()) {
            delete records;
        }
        for (List<SObject> records: groupByType(createShares.values()).values()) {
            insert records;
        }
    }

    /** 
     * Order a list of SObjects by the type of each record. This is useful
     * before performing a DML operation on a list of generic SObjects.
     */
    public static Map<SObjectType,List<SObject>> groupByType(List<SObject> records) {
        Map<SObjectType,List<SObject>> recordsByType = new Map<SObjectType,List<SObject>>();
        for (SObject record: records) {
            SObjectType type = record.getSObjectType();
            List<SObject> it = recordsByType.get(type);
            if (it == null) {
                it = new List<SObject>();
                recordsByType.put(type, it);
            }
            it.add(record);
        }
        return recordsByType;
    }
}