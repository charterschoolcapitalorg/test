global class CreateLeaseComplianceBatchable implements  Database.Batchable<SObject> {

    public static ID expired = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Expired').getRecordTypeId();
    public static ID pending = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Pending').getRecordTypeId();
    public static ID current = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Current').getRecordTypeId();

        
    private Date getEndDate (Lease_Compliance__c l, Lease_Compliance_Template__c t) {
        
        Date day = l.start_date__c;
        if (t.period__c=='Monthly') {
            return day.addmonths(1);
        } else if (t.period__c=='Quarterly') {
            return day.addmonths(3);
        } else if (t.period__c=='Biannually') {
            return day.addmonths(6);
        } else if (t.period__c=='Annually') {
            return day.addyears(1);
        } else return null;
        
    }
    
    private Lease_Compliance__c newLC (Lease_Compliance__c l, Lease_Compliance_Template__c t) {
        Lease_Compliance__c nl = l.clone(false,true,false,false);
        
        nl.lease__c = l.lease__c;
        nl.Received_Date__c = null;
        nl.Start_Date__c = l.End_Date__c.adddays(1);
        nl.Lease_Compliance_Name__c = nl.Lease_Compliance_Name__c;
        
        //nl.Expiration_Date__c = nl.Start_Date__c.adddays(Integer.valueof(t.Expire_Days__c));  
        //nl.Client_Alert_Date__c = nl.Start_Date__c.adddays(Integer.valueof(t.Client_Alert_Days__c));  
        //nl.FAM_Alert_Date__c = nl.Start_Date__c.adddays(Integer.valueof(t.FAM_Alert_Days__c));    
        //nl.Due_Date__c = nl.Start_Date__c.adddays(Integer.valueof(t.Due_Days__c));    
        
        nl.Due_Days__c = t.Due_Days__c;
        nl.Client_Alert_Days__c = t.Client_Alert_Days__c;
        nl.Expire_Days__c = t.Expire_Days__c;
        nl.FAM_Alert_Days__c = t.FAM_Alert_Days__c;
        //nl.Client_Notification_Role__c = t.Client_Notification_Role__c;

        nl.Final_Alert_Active__c = t.Final_Alert_Active__c;
        nl.Second_Client_Alert_Active__c = t.Client_Second_Alert_Active__c;
        nl.Second_Client_Alert_Days__c = t.Client_Second_Alert_Days__c;
        nl.Action_Item_Mapping__c = t.Action_Item_Mapping__c; //copied over from template

        
        nl.End_Date__c = getEndDate(nl,t).addDays(-1);
        nl.RecordTypeId = pending;
        
        return nl;
    }
    
    global CreateLeaseComplianceBatchable() {
        
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(this,50);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        
        /*STring query = 'Select Id, Start_Date__c, lease__c, Lease_Compliance_Name__c, Created_Follow_Up_Record__c, Expiration_Date__c, end_date__c, Type__c, Period__c from Lease_Compliance__c where (Expiration_Date__c <= TODAY or (end_date__c <= TODAY AND Created_Follow_Up_Record__c = false)) and ' +
            ' (recordtypeid=:pending or recordtypeid=:current)';*/
        //2019.09.03 J Caughie - changed search to look for items based on Next_Record_Trigger_Date__c as the client alert for this may be before both the end and expiration date.
        STring query = 'Select Id, Start_Date__c, lease__c, Lease_Compliance_Name__c, Created_Follow_Up_Record__c, Expiration_Date__c, end_date__c, Type__c, Period__c, Next_Record_Trigger_Date__c from Lease_Compliance__c where ((Expiration_Date__c <= TODAY or Next_Record_Trigger_Date__c <= TODAY or end_date__c <= TODAY) AND Created_Follow_Up_Record__c = false) and ' +
            ' (recordtypeid=:pending or recordtypeid=:current)';

        System.debug('Executing query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lease_Compliance__c> scope) {
        List<Lease_Compliance__c> forInsert = new List<Lease_Compliance__c>();
        Map<Id,Lease_Compliance__c> forUpdate = new Map<Id,Lease_Compliance__c>();
        Map<Id,CSC_Action_Item__c> CSCupdates = new Map<Id,CSC_Action_Item__c>();
        Map<Id, Lease__c> leaseCompLeases = new Map<Id, Lease__c>();
        Map<Id, List<Lease_School__c>> leaseToSchool = new Map<Id, List<Lease_School__c>>();
        Set<String> actionItems = new Set<String>();
        Map<Id, List<CSC_Action_Item__c>> leaseCompActionItems = new Map<Id, List<CSC_Action_Item__c>>();
        
        if (scope.size()>0) {
            //get config objects
            List<Lease_Compliance_Template__c> tem= [Select Id, Due_Days__c,  
                Client_Alert_Days__c, Expire_Days__c, FAM_Alert_Days__c, Period__c, Client_Second_Alert_Active__c, Client_Second_Alert_Days__c, Final_Alert_Active__c,
                Type__c, Action_Item_Mapping__c from Lease_Compliance_Template__c];
                
            Map<String, Lease_Compliance_Template__c> configMap = new map<String,Lease_Compliance_Template__c>();
            for (Lease_Compliance_Template__c t : tem) {
                configMap.put(t.type__c, t);
            }
            
            for (Lease_Compliance__c l : scope) {
                //if (l.type__c=='Property Tax') {
                    //
                //}else {
                    if (configmap.get(l.type__c)!=null) {
                        Lease_Compliance_Template__c t =configmap.get(l.type__c);
                        
                        System.debug('****Lease Compliance: ' + l);
                        //create new ones for end date of today
                        //if (l.end_Date__c <= date.today().adddays(-1) && !l.Created_Follow_Up_Record__c) {                    //2019.09.03 J Caughie - changed as client alert may be before end date
                        if (l.Next_Record_Trigger_Date__c <= date.today().adddays(-1) && !l.Created_Follow_Up_Record__c) {
                        	System.debug('****creating new record ');
                            forinsert.add(newLC(l,t));
                            l.Created_Follow_Up_Record__c = true;
                            forUpdate.put(l.Id, l);
                        }
                        
                        //change record type to expired on expiration date  
                        if (l.Expiration_Date__c <= date.today().adddays(-1)) {
                        	System.debug('****changing ' + l.Id + ' to expired');
                            l.recordtypeid = expired; 
                            forUpdate.put(l.Id, l);
                        } 
                        
                    }
                //}
            }
            
            if (forinsert.size()>0) {
                insert forinsert;
            }
            if (forupdate.size()>0) {
                update forupdate.values();
            }

            List<Id> leaseIds = new List<Id>();
            for(Lease_Compliance__c l : forInsert){
                if(l.Action_Item_Mapping__c != null){
                    leaseIds.add(l.Lease__c);
                    actionItems.add(l.Action_Item_Mapping__c);
                }
            }

            List<Lease__c> leases = [SELECT Id, Tenant__c, Tenant__r.Tenant__c, Tenant__r.Tenant__r.ParentId, Account__c, Account__r.ParentId FROM Lease__c WHERE Id IN: leaseIds];
            List<Lease_School__c> leaseSchools = [SELECT Id, Account_School__c, Account_School__r.ParentId, Lease__c FROM Lease_School__c WHERE Lease__c IN: leases];

            for(Lease_Compliance__c lc: forInsert){
                for(Lease__c l: leases){
                    if(lc.Lease__c == l.Id){
                        leaseCompLeases.put(lc.Id, l);
                    }
                }
            }

            for(Lease__c l: leases){
                List<Lease_School__c> schools = new List<Lease_School__c>();
                for(Lease_School__c ls: leaseSchools){
                    if(l.Id == ls.Lease__c){
                        schools.add(ls);
                    }
                }
                leaseToSchool.put(l.Id, schools);
            }

            Set<Id> tenants = new Set<Id>();
            Set<Id> tenantParents = new Set<Id>();
            Set<Id> acc = new Set<Id>();
            Set<Id> accParents = new Set<Id>();
            Set<Id> leaseSchoolAccounts = new Set<Id>();
            Set<Id> leaseSchoolAccountParents = new Set<Id>();

            for(Lease__c l: leases){
                if(l.Tenant__r.Tenant__c != null){
                    tenants.add(l.Tenant__r.Tenant__c);
                }

                if(l.Tenant__r.Tenant__r.ParentId != null){
                    tenantParents.add(l.Tenant__r.Tenant__r.ParentId);
                }

                if(l.Account__c != null){
                    acc.add(l.Account__c);
                }

                if(l.Account__r.ParentId != null){
                    accParents.add(l.Account__r.ParentId);
                }
            }

            for(Lease_School__c ls : leaseSchools){
                if(ls.Account_School__c != null){
                    leaseSchoolAccounts.add(ls.Account_School__c);
                }

                if(ls.Account_School__r.ParentId != null){
                    leaseSchoolAccountParents.add(ls.Account_School__r.ParentId);
                }
            }

            System.debug(acc);
            System.debug(actionItems);

            List<CSC_Action_Item__c> items = [SELECT Id, Account__c, CSC_Action_List__r.Account__c, CSC_Action_List__r.Account__r.RecordTypeId, Next_Action_Date__c, Expiration_Date__c, 	Status__c, Action_Item_Mapping__c
                                                FROM CSC_Action_Item__c
                                                WHERE ((CSC_Action_List__r.Account__r.RecordTypeId =: RecordTypes.IdCharterAccount AND 
                                                            (( CSC_Action_List__r.Account__c IN: tenants OR CSC_Action_List__r.Account__c IN: tenantParents) 
                                                                    OR (CSC_Action_List__r.Account__c IN: acc OR CSC_Action_List__r.Account__c IN: accParents)
                                                                    OR (CSC_Action_List__r.Account__c IN: leaseSchoolAccountParents))
                                                        ) OR (CSC_Action_List__r.Account__r.RecordTypeId =: RecordTypes.IdSChoolAccount AND 
                                                            CSC_Action_List__r.Account__c IN: leaseSchoolAccounts ))
                                                        AND Action_Item_Mapping__c IN: actionItems];

            for(Lease_Compliance__c lc: forInsert){
                List<CSC_Action_Item__c> actItems = new List<CSC_Action_Item__c>();

                for(CSC_Action_Item__c ai: items){
                    if(ai.Action_Item_Mapping__c == lc.Action_Item_Mapping__c){
                        Lease__c theLease = leaseCompLeases.get(lc.Id);
                        List<Lease_School__c> theSchool = leaseToSchool.get(theLease.Id);
                        Set<Id> schoolAccounts = new Set<Id>();
                        Set<Id> schoolAccountParents = new Set<Id>();

                        for(Lease_School__c ls: theSchool){
                            if(ls.Account_School__c != null){
                                schoolAccounts.add(ls.Account_School__c);
                            }
            
                            if(ls.Account_School__r.ParentId != null){
                                schoolAccountParents.add(ls.Account_School__r.ParentId);
                            }
                        }

                        if(theLease.Account__c == ai.CSC_Action_List__r.Account__c ||
                            theLease.Account__r.ParentId == ai.CSC_Action_List__r.Account__c ||
                            theLease.Tenant__r.Tenant__c == ai.CSC_Action_List__r.Account__c ||
                            theLease.Tenant__r.Tenant__r.ParentId == ai.CSC_Action_List__r.Account__c ||
                            schoolAccounts.contains(ai.CSC_Action_List__r.Account__c) ||
                            schoolAccountParents.contains(ai.CSC_Action_List__r.Account__c)){
                                actItems.add(ai);
                        }
                    }
                }

                leaseCompActionItems.put(lc.Id, actItems);
            }

            List<Lease_Compliance__c> queriedFields = [SELECT Id, Client_Alert_Date__c, Due_Date__c, Type__c, Expiration_Date__c FROM Lease_Compliance__c WHERE Id IN: leaseCompActionItems.keySet()];

            for(Lease_Compliance__c lc: queriedFields){
                for(CSC_Action_Item__c ai: leaseCompActionItems.get(lc.Id)){
                    ai.Next_Action_Date__c = lc.Client_Alert_Date__c;
                    ai.CP_Item_Due_Date__c = lc.Due_Date__c;
                    ai.Diligence_Notification_Sent__c = false;
                    ai.Status__c = 'New';
                    if (lc.Type__c == 'Property Insurance' || lc.Type__c == 'Tenant Insurance' || lc.Type__c == 'Flood Insurance') {
                        ai.Expiration_Date__c = lc.Expiration_Date__c;
                    }
                    CSCupdates.put(ai.Id, ai);
                }
            }

            if(CSCupdates.size() > 0){
                update CSCupdates.values();
            }

        }
    }
    
    global void finish(Database.BatchableContext BC) {

    }
    

}