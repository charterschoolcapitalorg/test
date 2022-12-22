global class SendSubmissionNeededEmails {
	//implements Database.Batchable<sObject>, Database.AllowsCallouts {   
    //THIS CLASS IS DEPRECATED AND REPLACED WITH CreateWeeklyClientStatusEmail and CreateConsolidatedOppEmail
    /*
	@TestVisible static Integer emailLimits;

    global Database.querylocator start(Database.BatchableContext bc) {     
		String query = 'Select Id from opportunity LIMIT 1'; 
		System.debug('Executing query: ' + query);
		return Database.getQueryLocator(query);          
    }

    global void execute(Database.BatchableContext ScheduledNotifications, List<Opportunity> scope) {
        if(scope.size()>0){                
            //get each rule
            List<CustomPortalEmailsToSend__mdt> configs = [Select Id, DeveloperName, Copy_Paralegal__c, Copy_Account_Manager__c, 
                Email_Template_Developer_Name__c, Days_Before_Due_Date__c, 
                Email_Receiver__c, Intake_Item_Name__c, 
                Opp_Record_Type_Name__c, Status__c from CustomPortalEmailsToSend__mdt];
            
            Set<String> emailTemNames = new Set<STring>();
            for (CustomPortalEmailsToSend__mdt c : configs) {
                emailTemNames.add(c.Email_Template_Developer_Name__c);
            }
          
            List<EmailTemplate> ets = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN:emailTemNames];
            
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Map<Id, Intake_Item__c> iiSent = new Map<Id, Intake_Item__c>();
             
             
            for (CustomPortalEmailsToSend__mdt c : configs) {
                //Calculate due date for Portal alert 
                Date portalAlertDate = DateUtilities.addBusinessDays(Date.today(), c.Days_Before_Due_Date__c.intValue());
                System.debug('Next business date ' + portalAlertDate);

                System.debug('***** using rule: ' + c);
                //get oppids for each config
                LIst<STring> statuses = new List<String>();
                Map<Id,Intake_Item__c> oppIIMap = new Map<Id,Intake_Item__c>();
                List<String> untrimmedStatuses = c.Status__c.split(';');
                for(String s : untrimmedStatuses){
                	statuses.add(s.trim());
                }
                Id rid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(c.Opp_Record_Type_Name__c).getRecordTypeId();
                List<Intake_Item__c> ii = [Select Id, Name, Primary_Contact_First_Name__c, Due_Date__c, 
                        Opportunity__c, Assigned_To__c, Status__c
                        from Intake_Item__c where 
                        Opportunity__r.recordtypeid=:rid
                        and Opportunity__r.Whiteboard_Opportunity_WC__c = true
                        and (Name=:c.Intake_Item_Name__c or Parent_Intake_Item__r.Name=:c.Intake_Item_Name__c)
                        and Status__c NOT IN:statuses 
                        and Due_Date__c=:portalAlertDate
                        and Is_Visible_To_Community__c = true
                        ];
                
                System.debug('***** items matching rule: ' + ii);
                
                Set<Id> oppIds = new Set<Id>();
                Map<Id,Id> intakeOppMap = new Map<Id,Id>();
                    
                for (Intake_Item__c i : ii) {
                    oppIIMap.put(i.opportunity__c, i);
                    oppIds.add(i.opportunity__c);
                    intakeOppMap.put(i.id, i.opportunity__c);
            	}
                    
                    
	            //get contact roles for the opps
	            List<Opportunity> oo;
	            if (c.Email_Receiver__c=='All Community Users') {
	                oo = [Select Id, Name, Paralegal_UW_email__c, Owner_Email__c, Owner.Name, Owner.Email, (Select Id, ROle__c, Contact__c, contact__r.email from 
	                    Community_Contact_Roles__r) from Opportunity where Id IN:oppIds ];
	            } else {
	                 oo = [Select Id, Name, Paralegal_UW_email__c, Owner_Email__c, Owner.Name, Owner.Email, (Select Id, ROle__c, Contact__c, contact__r.email from 
	                    Community_Contact_Roles__r where role__c=:c.Email_Receiver__c) from Opportunity where Id IN:oppIds ];
	            }
	            
	            System.debug('***** opps matching rule: ' + oo);
	            
	            Set<Id> oppsForEmailSent = new Set<Id>();
	            Map<Id, Set<String>> toAddressOppMap = new Map<Id, Set<String>>();
	            Map<Id, Id> oppTargetObjMap = new Map<Id, String>();
	            
	            //loop through opps to build the toAddresses for that Opp
	            for (Opportunity o : oo) {
	                System.debug('&&&&& building email for opp: ' + o.Name);
	                
	                Id targetObjId;
	                Set<String> toAddresses = new Set<String>();
	                    
	                for (Intake_Item__c iItem : ii) {
	                    
	                    if (intakeOppMap.get(iItem.Id)==o.Id) {
	                        
	                        System.debug('*****: ' + iITem.Name + ' assigned to: ' + iItem.Assigned_To__c);
	                        
	                        if (o.Community_Contact_Roles__r!=null && o.Community_Contact_Roles__r.size()>0) {
	                            
	                            //get the Contact, and see if they are a a Community User, and if they match the Assigned To on the Item
	                            for (Community_Contact_Role__c ccr : o.Community_Contact_Roles__r) {
	                                System.debug('##### CCR: ' + ccr);
	                                //System.debug('****iItem.Assigned_To__c: ' + iItem.Assigned_To__c);
	                                if (DiligenceUtils.multiSelectFIeldContains(iItem.Assigned_To__c,ccr.role__c)) {
	                                    toaddresses.add(ccr.contact__r.email);
	                                    System.debug('##### for Opp: ' + o.Id + ' adding email: ' + ccr.contact__r.email);
	                                    targetObjId = ccr.contact__c;
	                                }
	                            }
	                        }
	                    }
	                }   
	                toAddressOppMap.put(o.Id, toaddresses);
	                oppTargetObjMap.put(o.Id, targetObjId);
	            }
	                    
	            //for each opp we send a different email
	            for (Opportunity o : oo) {
	                Set<STring> sAddr = toAddressOppMap.get(o.Id);
	                List<STring> toaddresses;
	                if (toAddressOppMap.get(o.Id)!=null) toaddresses = new List<STring>(sAddr);	                
	                
	                if (toaddresses!=null&&toaddresses.size()>0) {
	                        
	                        System.debug('^^^^^ opp for email send: ' + o.Name);
	                        System.debug('^^^^^ intake item: ' + oppIIMap.get(o.Id));
	                        System.debug('^^^^^ setTargetObjectId: ' + oppTargetObjMap.get(o.Id));
	                        if (c.Copy_Account_Manager__c && o.Owner_Email__c!=null)  toaddresses.add(o.Owner_Email__c);
	                        if (c.Copy_Paralegal__c && o.Paralegal_UW_email__c!=null) toAddresses.add(o.Paralegal_UW_email__c);
	                        System.debug('^^^^^ toaddresses: ' + toaddresses);          
	                            
	                    
	                        EmailTemplate et = null;
	                        for (EmailTemplate e : ets) {
	                            if (e.DeveloperName.equalsignorecase(c.Email_Template_Developer_Name__c)) {
	                                et = e;
	                                break;
	                            }
	                        }
	                        
	                        //construct email
	                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	                        if (et.Id!=null) {System.debug('***setting templateId: ' + et.Id);
	                            mail.setTemplateId(et.Id);
	                        }
	                        mail.setToAddresses(toAddresses);
	                        mail.setReplyTo(o.Owner.Email);
	                        //mail.setSenderDisplayName('Charter School Capital');
	                        mail.setSenderDisplayName(o.Owner.Name);
	                        mail.setBccSender(false);
	                        mail.setUseSignature(false);
	                        mail.setSaveAsActivity(false);
	                        mail.setWhatId(oppIIMap.get(o.Id).Id);  //link whatId to the main Intake Item
	                        mail.setTargetObjectId(oppTargetObjMap.get(o.Id)); //set target to any  Contact from COntact Roles
	                        mails.add(mail);
	                        System.debug('@@@ rule name: ' + c.DeveloperName);
	                        System.debug('@@@ opp: ' +o.Name + ' adding mail to send to:  ' + toaddresses );
	                        //System.debug('***mail:  ' + mail);
	                        
	                        
	                    } //end has toAddresses
	                            
	                
	            } //end loop through opps
                    
                    
			} //end for each rule loop
        
	        if (mails.size()>0){// && !test.isrunningtest()) {
	            System.debug('***sending emails ' + mails);
	            Messaging.sendEmail(mails);
	            SendSubmissionNeededEmails.emailLimits = Limits.getEmailInvocations();                
	        }
            
        } // if(scope.size()>0)
        
    } // global void execute

  global void finish(Database.BatchableContext ScheduledNotifications){

  }
    
   
  */
}