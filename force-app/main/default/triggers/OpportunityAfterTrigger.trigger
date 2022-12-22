//
// (c) 2014 Appirio, Inc.
// Oppurtunity trigger for after events
//
//
// 01 April 2014     Abhishek Pareek(JDC)       Original
// 19 Aug 2022 Slava K adding Broker network opps
trigger OpportunityAfterTrigger on Opportunity (after insert, after update) {


    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance(UserInfo.getUserId());
    // 05/06/2014 : Manisha Gupta : Add null check (T-276525)
    if(ProfileCustomSettings.Trigger_Objects__c == null){
        ProfileCustomSettings.Trigger_Objects__c = '';
    }
    if(ProfileCustomSettings.Triggers_Disabled__c == null){
        ProfileCustomSettings.Triggers_Disabled__c = false;
    }
    if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('opportunity') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        if(Trigger.isInsert) {
            new OpportunityHelper().onAfterInsert(Trigger.newMap);
        } else if(Trigger.isUpdate){
            new OpportunityHelper().onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }

        //molinger - 03/23 - Create PQ Intake_Item when new Initial Funding Opp is created
        //04/09 - also update due dates if target wire date or diligence path changes
        
        //molinger - 06/28 - for bulk inserts get the accounts here
        Set<Id> acctIds = new Set<Id>();
        Map<Id,Account> acctMap = new Map<Id,Account>();
        if (trigger.isafter&&trigger.isinsert) {
          for (Opportunity o : trigger.new) {          
            //molinger - 06/05 - for Fac and IF Opps, create PQ FOrm on Opp creation
            
            if (o.RecordTypeId==RecordTypes.IDFacilitiesOpp|| o.RecordTypeId==RecordTypes.IDFundingOpp || o.recordtypeid==RecordTypes.ID5DFOpp) {
              acctIds.add(o.AccountId);
            }
            
          }
        }
        if (acctids.size()>0) {
            acctMap = new Map<Id,Account>([Select Id, Name,  parentId, RecordTypeId from Account where Id IN:acctIds]);
        }                            
                            
        if(Trigger.isInsert || Trigger.isUpdate) {

            List<Intake_Item__c> ii = new List<Intake_Item__c>();
            Set<Id> oppIdsForPQCreation = new Set<Id>();
            
            for (Opportunity o : trigger.new) {
                if (trigger.isupdate) {
                    system.debug('*** RecordTypes.IDBrokerNetworkOpp = ' + RecordTypes.IDBrokerNetworkOpp);
                    system.debug('*** o.RecordTypeid = ' + o.recordtypeid);
                    //molinger - 06/05 - for FOF create the Intake Items and box folder structures when FOF Opp hits Stage 3
                    if (o.recordtypeid==RecordTypes.IDFOFOpp 
                        && o.stagename==Diligencevars.fofStageToTriggerIntakeItemCreation&& 
                        trigger.oldmap.get(o.Id).StageName!=Diligencevars.fofStageToTriggerIntakeItemCreation) {
                        //create all intake items
                        DiligenceUtils.createIntakeItems(o.Id, 1, null);
                    }
                    
                    //molinger - 06/05 - for FOF set due dates when target wire date changes
                    if (o.recordtypeid==RecordTypes.IDFOFOpp 
                        && o.target_wire_date__c!=null 
                        &&trigger.oldmap.get(o.Id).target_wire_date__c!=o.target_wire_date__c) {
                            DiligenceUtils.updateIntakeItemsDueDates(o.Id);
                    }
                    
                    if (o.recordtypeid==RecordTypes.IDFacilitiesOpp 
                        && o.stagename==Diligencevars.facStageToTriggerIntakeItemCreation&& 
                        trigger.oldmap.get(o.Id).StageName!=Diligencevars.facStageToTriggerIntakeItemCreation) {
                        //for Facilities, create the Stop 1 Items 
                        if (CreateIntakeItemsStatic.runonce()) {
                            DiligenceUtils.createIntakeItems(o.Id,1, null);
                        }   
                    }
                        
                    //for INitial Funding, create the PQ and Box structure when the Opp is created
                    if (o.recordtypeid==RecordTypes.IDFundingOpp && trigger.oldmap.get(o.Id).RecordTypeId!=o.recordTYpeId ) {
                        //create the Box Folder Structure
                        if (CreateBoxFoldersStatic.runonce()) {
                            Intake_Item__c i = DiligenceUtils.createPQItem(o.Id, o.recordtypeid);
                            if (i!=null) { ii.add(i); }
                        }
                    }

                    //for 5DF, create the PQ and Box structure when the Opp is created
                    //2021.03.25 - J CAughie - disabled auto-creation of Box folders for 5DF
                    if (o.recordtypeid==RecordTypes.ID5DFOpp && trigger.oldmap.get(o.Id).RecordTypeId!=o.recordTYpeId ) {
                        //create the Box Folder Structure
                        if (CreateBoxFoldersStatic.runonce()) {
                            Intake_Item__c i = DiligenceUtils.createPQItem(o.Id, o.recordtypeid);
                            if (i!=null) { ii.add(i); }
                        }
                        DiligenceUtils.createIntakeItems(o.Id, 1, null);
                    }
                    
                    if (o.recordtypeid==RecordTypes.IDFacilitiesOpp && trigger.oldmap.get(o.Id).RecordTypeId!=o.recordTYpeId) {
                        //create the Box Folder Structure
                        if (CreateBoxFoldersStatic.runonce()) {
                            BoxAPIUtils.createOppFolders(o.Id);
                        }
                    }
                        
                    //for IF and Facilities, update due dates
                    if ((o.recordtypeid==RecordTypes.IDFacilitiesOpp || o.recordtypeid==RecordTypes.IDFundingOpp || o.recordtypeid==RecordTypes.ID5DFOpp) 
                        && (o.target_wire_date__c!=null && trigger.oldmap.get(o.Id).target_wire_date__c!=null&&trigger.oldmap.get(o.Id).target_wire_date__c!=o.target_wire_date__c) 
                        || (o.diligence_path__c!=null && trigger.oldmap.get(o.Id).diligence_path__c!=null&&trigger.oldmap.get(o.Id).diligence_path__c!=o.diligence_path__c)) {
                        
                        //diligence_path__c or target wire date changed
                        DiligenceUtils.updateIntakeItemsDueDates(o.Id);
                    }

                } else {
                    if (trigger.isafter&&trigger.isinsert) {                        
                        //molinger - 06/05 - for Fac and IF Opps, create PQ FOrm on Opp creation
                        if (o.RecordTypeId==RecordTypes.IDFacilitiesOpp|| o.RecordTypeId==RecordTypes.IDFundingOpp || o.recordtypeid==RecordTypes.ID5DFOpp) {
                            Account a;
                            for (Id i : acctMap.keyset()) {
                                if (o.AccountId==i) {
                                    a = acctMap.get(i);
                                    oppIdsForPQCreation.add(o.Id);
                                }
                            }
                            if (a==null) {throw new DiligenceUtils.DiligenceException('Account not found for opp: ' + o.Id);}
                        }   
                    }
                    
                    if (o.recordtypeid==RecordTypes.IDFundingOpp) {
                        //create the PQ Item
                        Intake_Item__c i = DiligenceUtils.createPQItem(o.Id, o.recordtypeid);
                        if (i!=null) { ii.add(i); }
                    }

                    if (o.recordtypeid==RecordTypes.ID5DFOpp) {
                      //create the PQ Item
                      DiligenceUtils.createIntakeItems(o.Id, 1, null);
                    }

                    if (o.recordtypeid==RecordTypes.IDLoanOpp) {
                        //create the Box Folder Structure
                        if (CreateBoxFoldersStatic.runonce()) {
                            BoxAPIUtils.createOppFolders(o.Id);
                        }                     
                    }

                    if (o.recordtypeid==RecordTypes.IDEMOpp) {
                        //create the Box Folder Structure
                        if (CreateBoxFoldersStatic.runonce()) {
                            BoxAPIUtils.createOppFolders(o.Id);
                        }                     
                    }

                    if (o.recordtypeid==RecordTypes.IDFacilitiesOpp) {
                        //create the Box Folder Structure
                        if (CreateBoxFoldersStatic.runonce()) {
                            BoxAPIUtils.createOppFolders(o.Id);
                        }
                    }

                    //for IDBrokerNetworkOpp opportunity
                    if (o.recordtypeid==RecordTypes.IDBrokerNetworkOpp) {
                        //create the Box Folder Structure
                        if (CreateBoxFoldersStatic.runonce()) {
                            BoxAPIUtils.createOppFolders(o.Id);
                        }
                    }
                }
            }
            
            
          //Create PQ FOrms
          if (oppIdsForPQCreation.size()>0) {
              List<PQ_Form__c> pqFOrInsert = new List<PQ_Form__c>();
              //make sure doesnt exist already
              List<PQ_Form__c> pqs = [Select Id, Opportunity__c from PQ_Form__c where Opportunity__c IN:oppIdsForPQCreation];
              for (Opportunity o : trigger.new) {
                if (trigger.isafter&&trigger.isinsert) {
                  boolean bFound = false;
                  for (PQ_Form__c pq : pqs) {
                    if (pq.opportunity__c==o.Id) {
                      bFound = true;
                      break;
                    }
                  }
                  if (!bFound && oppIdsForPQCreation.contains(o.Id)) {
                    //create
                    PQ_Form__c pq = new PQ_Form__c();
                                    //pq.Name = o.Account.Name + ' Form';
                                    pq.Name = acctMap.get(o.AccountId).name + ' Form';
                                    pq.opportunity__c = o.Id;
                                    if (o.RecordTypeId==RecordTypes.IDFacilitiesOpp) {
                                        pq.recordtypeid = RecordTypes.IDFacilitiesPQ;
                                    } else if (o.RecordTypeId==RecordTypes.IDFundingOpp) {
                                        pq.recordtypeid = RecordTypes.IDInitialFundingPQ;
                                    } else if (o.RecordTypeId==RecordTypes.ID5DFOpp) {
                                      pq.recordtypeid = RecordTypes.ID5DFPQ;
                                  }
                                    pqFOrInsert.add(pq);
                                    System.debug('&&&created PQ form: ' + pq.Id + ' for opp: ' + o.Id);
                  }
                }
              }
              if (pqFOrInsert.size()>0) insert pqFOrInsert;
          }
            
                    
            if (ii.size()>0) { 
                insert ii;
                
            }
        }
        
        //create FC form objects for Initial FUnding, FOF and Loan Opps
        // this hsould be done after CSC Action Items are created as some of that data is pulled into the records
        if (trigger.isafter&&trigger.isinsert) {
          if(!test.isrunningtest() && !FeatureManagement.checkPermission('Bulk_Data_Load')) {
            for (Opportunity o : trigger.new) {
              if (o.RecordTypeId==RecordTypes.IDFOFOpp|| o.RecordTypeId==RecordTypes.IDFundingOpp|| o.RecordTypeId==RecordTypes.IDLoanOpp || o.recordtypeid==recordtypes.IDFacilitiesOpp || o.recordtypeid==RecordTypes.ID5DFOpp) {
              // if (o.RecordTypeId==RecordTypes.IDFOFOpp|| o.RecordTypeId==RecordTypes.IDFundingOpp|| o.RecordTypeId==RecordTypes.IDLoanOpp || o.recordtypeid==recordtypes.IDFacilitiesOpp) {
                
                System.debug('******* creating fc forms');
                List<FC_FOrm__c> forms = FCFormUtils.createFCForms(o);
                System.debug('******* populateHeaderFieldsFromSFData: ' + forms);
                FCFOrmUtils.populateHeaderFieldsFromSFData(forms);
                System.debug('******* populateHeaderCommentFieldsFromSFData: ' + forms);
                FCFOrmUtils.populateHeaderCommentFieldsFromSFData(forms);
              }
            }
          }
        }
    }
}