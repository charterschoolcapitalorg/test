global class ReportingWeeklyInitialFunding implements Database.Batchable<SObject>, Schedulable{


    /*** SCHEDULABLE INTERFACE Method ***/
    global void execute(SchedulableContext sc) {
        id batchId = Database.executeBatch(new ReportingWeeklyInitialFunding());
        System.debug('\n\n==> batchId = ' + batchId);
    }
    
    /*** BATCHABLE INTERFACE Methods ***/
    global Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'SELECT Id, Name, Action_Item_Name__c, Date_Completed__c, Opportunity_Ref__c, CSC_Action_List__r.Opportunity__r.Date_Submitted__c, CSC_Action_List__r.Opportunity__r.Accelerated_Sales_Process__c, ';
        query += 'Status__c, Opportunity_Close_Date__c, BD_Green_Level_Accelerated__c, BD_Green_Level_Standard__c, BD_Red_Level_Accelerated__c, BD_Red_Level_Standard__c, CSC_Action_List__r.Opportunity__r.State__c, ';
        query += 'Comments__c, Opportunity_Name__c, Opp_Stage__c, CSC_Action_List__r.Opportunity__r.CreatedDate, Opportunity_Owner__c, CSC_Action_List__r.Opportunity__r.AccountId, ';
        query += 'CSC_Action_List__r.Opportunity__r.Owner.Name, CSC_Action_List__r.Opportunity__r.Account.Operating_State__r.Name ';
        query += 'FROM CSC_Action_Item__c ';
        query += 'WHERE Action_Item_Name__c IN (\'Complete Pre-Qualification Form\', \'Opening Call Conducted\', \'Client Completes MSA (FDA)\', \'W-9 Obtained\', \'OIL Docs Received (Underwriting)\', \'OIL Docs Received (Finance)\') ';
        query += 'AND CSC_Action_List__r.Opportunity__r.RecordType.DeveloperName = \'Initial_Funding\' ';
        query += 'AND Opportunity_on_Whiteboard__c = True ';
        query += 'ORDER BY Opportunity_Close_Date__c ASC, Opportunity_Ref__c ASC, CSC_Action_List__r.Sort_Order__c ASC, Sort_Order__c ASC';
        System.debug(query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context, List<SOBject> objects) {
        List<CSC_Action_Item__c> items = (List<CSC_Action_Item__c>) objects;
        updateInitialFundingReport(items);
    }

    global void finish(Database.BatchableContext context) {
        List<String> recipients = new List<String>();
        recipients.add('jcaughie@charterschoolcapital.com');
        EmailUtils.sendTextEmail(recipients, 'Weekly IF Report', 'Weekly IF status report ran.');
    }



    
    public static void updateInitialFundingReport(List<CSC_Action_Item__c> items){
        //Maps for storing steps and final output
        Map<String, Snapshot_Report__c> oppSnapshotMap = new Map<String, Snapshot_Report__c>();
        
        for(CSC_Action_Item__c i : items){
            System.debug('item: ' + i);    
            //create or add snapshot record if map doesn't exist for this opportunity
            if(oppSnapshotMap.size() == 0 || !oppSnapshotMap.containsKey(i.Opportunity_Ref__c)){
                Snapshot_Report__c snapshot = new Snapshot_Report__c();
                snapshot.Record_Name__c = i.Opportunity_Name__c;
                snapshot.Opportunity_Stage__c = i.Opp_Stage__c;
                snapshot.Date_Created__c = i.CSC_Action_List__r.Opportunity__r.CreatedDate.date();
                snapshot.Date_Submitted__c = i.CSC_Action_List__r.Opportunity__r.Date_Submitted__c;
                snapshot.Close_Date__c = i.Opportunity_Close_Date__c;
                snapshot.Report_Run_Date__c = Date.today();
                snapshot.Owner_Name__c = i.CSC_Action_List__r.Opportunity__r.Owner.Name;
                snapshot.Report_Name__c = 'Weekly IF Report';
                snapshot.Account__c = i.CSC_Action_List__r.Opportunity__r.AccountId;
                snapshot.Operating_State__c = i.CSC_Action_List__r.Opportunity__r.Account.Operating_State__c;
                snapshot.Opportunity_Stage__c = i.Opp_Stage__c;
                oppSnapshotMap.put(i.Opportunity_Ref__c, snapshot);
            }
            
            System.debug('Map: ' + oppSnapshotMap);
            
            String itemStatus;
            Integer numberRedDays = 0;
            Integer numberGreenDays = 0;
            Date redDate, greenDate, baselineDate;
            
            //if item is marked complete, use the completed date, otherwise it is open and "today" should be used
            if(i.Status__c == 'Completed'){
                baselineDate = i.Date_Completed__c;
            } else {
                baselineDate = Date.today();
            }
            System.debug('Baseline date: ' + baselineDate);
            
            //if the funding is urgent use the accelerated processing time
            if(i.CSC_Action_List__r.Opportunity__r.Accelerated_Sales_Process__c){
                numberRedDays = (Integer)i.BD_Red_Level_Accelerated__c;
                numberGreenDays = (Integer)i.BD_Green_Level_Accelerated__c;
            } else {
                numberRedDays = (Integer)i.BD_Red_Level_Standard__c;
                numberGreenDays = (Integer)i.BD_Green_Level_Standard__c;
            }
            redDate = DateUtilities.calculateStartDate(i.Opportunity_Close_Date__c, numberRedDays);
            greenDate = DateUtilities.calculateStartDate(i.Opportunity_Close_Date__c, numberGreenDays);
            System.debug(redDate);
            System.debug(greenDate);
            
            if(i.Action_Item_Name__c == 'Complete Pre-Qualification Form'){
                itemStatus = '';
                if(baselineDate <= greenDate){
                    itemStatus = 'Green';
                } else {
                    itemStatus = 'Red';
                }
                System.debug(itemStatus);
                //update existing snapshot record
                oppSnapshotMap.get(i.Opportunity_Ref__c).PQ_Form_Status__c = itemStatus;
            }
            
            if(i.Action_Item_Name__c == 'W-9 Obtained'){
                System.debug('W-9');
                itemStatus = '';
                System.debug('State name: ' + i.CSC_Action_List__r.Opportunity__r.Account.Operating_State__r.Name);
                if(i.CSC_Action_List__r.Opportunity__r.Account.Operating_State__r.Name == 'AZ'){
                    itemStatus = 'Green';
                } else {
                    itemStatus = CalculateStatus(baselineDate, redDate, greenDate);
                }
                System.debug(itemStatus);
                oppSnapshotMap.get(i.Opportunity_Ref__c).W9_Obtained_Status__c = itemStatus;
            }   
            
            if(i.Action_Item_Name__c == 'Opening Call Conducted'){
                System.debug('OC');
                itemStatus = '';
                //System.debug('Comments: ' + i.Comments__c);
                /*if(String.isBlank(i.Comments__c)){
                    itemStatus = 'Red';
                } else {
                    itemStatus = 'Green';
                }*/
                // J Caughie 2018.07.31 - removed no comment rule as per Drew
                System.debug(itemStatus);
                itemStatus = CalculateStatus(baselineDate, redDate, greenDate);
                oppSnapshotMap.get(i.Opportunity_Ref__c).Opening_Call_Status__c = itemStatus;
            } 
            
            if(i.Action_Item_Name__c == 'Client Completes MSA (FDA)'){
                System.debug('MSA');
                itemStatus = '';
                //System.debug(i.CSC_Action_List__r.Opportunity__r.State__c);
                if(i.CSC_Action_List__r.Opportunity__r.Account.Operating_State__r.Name == 'AZ'){
                    itemStatus = 'Green';
                } else {
                    itemStatus = CalculateStatus(baselineDate, redDate, greenDate);
                }
                System.debug(itemStatus);
                oppSnapshotMap.get(i.Opportunity_Ref__c).Completed_MSA_Status__c = itemStatus;
            }  
            
            if(i.Action_Item_Name__c == 'OIL Docs Received (Underwriting)'){
                System.debug('UW');
                itemStatus = '';
                //System.debug(i.CSC_Action_List__r.Opportunity__r.State__c);
                itemStatus = CalculateStatus(baselineDate, redDate, greenDate);
                System.debug(itemStatus);
                oppSnapshotMap.get(i.Opportunity_Ref__c).OIL_Rec_UW_Status__c = itemStatus;
            }  
            
            if(i.Action_Item_Name__c == 'OIL Docs Received (Finance)'){
                System.debug('FN');
                itemStatus = '';
                //System.debug(i.CSC_Action_List__r.Opportunity__r.State__c);
                itemStatus = CalculateStatus(baselineDate, redDate, greenDate);
                System.debug(itemStatus);
                oppSnapshotMap.get(i.Opportunity_Ref__c).OIL_Rec_FN_Status__c = itemStatus;
            }
            
            System.debug('#################################################################');
        }
        
        //update Snapshot item status based on items
        for(Snapshot_Report__c sr : oppSnapshotMap.values()){
            if(Date.today().addDays(45) < sr.Close_Date__c){
                sr.Opp_Status__c = 'Blue';
            } else if(sr.PQ_Form_Status__c == 'Red' || sr.W9_Obtained_Status__c == 'Red' || sr.Opening_Call_Status__c == 'Red'
                      || sr.Completed_MSA_Status__c == 'Red' || sr.OIL_Rec_UW_Status__c == 'Red' || sr.OIL_Rec_FN_Status__c == 'Red') {
                          sr.Opp_Status__c = 'Red';
                      } else if(sr.PQ_Form_Status__c == 'Yellow' || sr.W9_Obtained_Status__c == 'Yellow' || sr.Opening_Call_Status__c == 'Yellow'
                                || sr.Completed_MSA_Status__c == 'Yellow' || sr.OIL_Rec_UW_Status__c == 'Yellow' || sr.OIL_Rec_FN_Status__c == 'Yellow') {
                                    sr.Opp_Status__c = 'Yellow';
                                } else {
                                    sr.Opp_Status__c = 'Green';
                                }
            
        }
        
        
        System.debug(oppSnapshotMap.values());
        insert oppSnapshotMap.values();
    }
    
    
    private static String CalculateStatus(Date dateCompleted, Date redDate, Date greenDate){
        String itemStatus = '';
        if(dateCompleted <= greenDate){
            itemStatus = 'Green';
        } else if(dateCompleted > redDate) {
            itemStatus = 'Red';
        } else {
            itemStatus = 'Yellow';
        }
        return itemStatus;
    }
    
}