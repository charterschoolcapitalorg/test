/* 
Test class: TestFC
Change by Slava K 20220628:
- afterUpdate Carter Holder creation automation
- API version has been changed (38->45)
*/
trigger LeadConversionAfterUpdate on Lead (after update) {
	
    
    if (trigger.isafter&&trigger.isupdate) {
    	SYSTEM.DEBUG('+++++ in LeadConversionAfterUpdate');
    	Id chRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Charter Holder').getRecordTypeId();
    	for (Lead lead : trigger.new) {
    		if (Trigger.oldmap.get(lead.Id).isConverted == false && 
    			Trigger.newmap.get(lead.Id).isConverted == true)  {
    		  try {
    				if (lead.RecordTypeId==RecordTypes.IDGeneralLead || lead.RecordTypeId==RecordTypes.IDFacilitiesLead) {
    				
	    				Account a = [SELECT Id, 
											Name, 
											parentId, 
											RecordTypeId 
											FROM Account 
											WHERE Id=:lead.ConvertedAccountId];
						//Opportunity o = [Select RecordTypeId, Id, Name from Opportunity where Id=:lead.ConvertedOpportunityId];
    					//Contact c = [Select Id, FirstName,LastName, Email, Phone, Title from Contact where Id=:lead.ConvertedContactId];    				 
		    			
		    			//after conversion
						//create charter holder acct if a schoolaccount is created
	                	if (lead.Lead_Type__c.equalsIgnoreCase('School') && a.ParentId==null) {
	                		Account charterHolder = a.clone(false, false, false, false);
							charterHolder.recordtypeid = chRecordTypeId;
							charterHolder.name = a.Name;
							charterHolder.operating_state__c = lead.operating_state__c;
							insert charterHolder;

							a.Charter_Holder__c = charterHolder.id;
							update a;
	                	}
    				}
    			} catch (EXception e) {
    		  		SYSTEM.DEBUG('+++++ ConvertLead: Exception converting lead: ' + e.getstacktracestring() + '- ' + e.getMessage());
    		  	}
    		}
    	}
    }
    	 
    
    if (trigger.isafter&&trigger.isupdate) {
    	SYSTEM.DEBUG('+++++ in LeadConversionAfterUpdate bottom');
    	List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
    	
    	for (Lead lead : trigger.new) {
		    //see if Do Automatic COnversion field has changed
		    if (trigger.oldMap.get(lead.Id).do_automatic_conversion__c == false 
		    	&& lead.do_automatic_conversion__c == true) 
            { 
                SYSTEM.DEBUG('+++++ in LeadConversionAfterUpdate auto convert flag set');
		        Database.LeadConvert lc = new Database.LeadConvert();
		        if (lead.DoNot_Create_Opportunity_On_Lead_Convert__c) {
		        	lc.setDoNotCreateOpportunity(True);
		        }
		        
                //look for existing contact/account
                Contact con;
                List<Contact> cons = [Select Id,AccountId, email from Contact where email=:lead.email];
                if (cons.size()>0) {
                	//existing contact, set contact and account ids for conversion
                	lc.setContactId(cons[0].Id);
		        	lc.setAccountId(cons[0].AccountId);
                }
                
                lc.setLeadId(lead.Id);
				lc.setConvertedStatus('Converted');

				//set opportunity name
				String oppName;
				switch on lead.Opportunity_Type__c {
					when 'Energy'{
						oppName = 'ENG - ';
					}
					when 'Facilities'{
						oppName = 'FA - ';
					}
					when 'Enrollment Marketing'{
						oppName = 'EM - ';
					}
					when 'Initial Funding'{
						oppName = 'Initial Funding - ';
					}
					when 'Loan'{
						oppName = 'Loan - ';
					}
					when 'Medicaid'{
						oppName = 'MD - ';
					}
					when else {
						oppName = '';
					}
				}
				oppName += lead.Company;
				lc.setOpportunityName(oppName);

				leadConverts.add(lc);
				
            }
    	}      
        
        //do conversion
		SYSTEM.DEBUG('+++++ trying to convert leads: ' + leadConverts);
		List<Database.LeadConvertResult> lcrs;
		try {
			lcrs = Database.convertLead(leadConverts, false);
		} catch (EXception e) {
			System.debug('***exception converting: ' + e.getstacktracestring()  + ' ' + e.getmessage());
		}
		
        for (Database.LeadConvertResult lcr : lcrs) 
		{
			if (!lcr.isSuccess())  {
		    	SYSTEM.DEBUG('+++++ ConvertLead: Exception converting lead: ' + lcr.getErrors()[0].getMessage());
		    	//update lead with exception
		    	Lead l = [Select Id from Lead where Id=:lcr.getLeadId()];
		    	l.Lead_Conversion_Error__c = lcr.getErrors()[0].getMessage();
		    	l.apply_diligence_rules__c=false;
		    	l.do_automatic_conversion__c=false;
		    	update l;
			} else {
				Opportunity o = [Select RecordTypeId, Id, Name from Opportunity where Id=:lcr.getOpportunityId()];
    			System.debug('****opp1 after convert: ' + o);
    				
		    	SYSTEM.DEBUG('+++++ ConvertLead: Successfully converted lead to account - ' + lcr.getAccountId()
		    	+ ' and opportunity: ' + lcr.getOpportunityId()
		    	+ ' and contact: ' + lcr.getContactId() );
			}
        }
    }
    
}