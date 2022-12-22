//
// Charter School Capital
// Name: AUM Checklist
// Description: Provides summary of the Action List and Client Portal items related to an Asset Management Facility and Tenant
//
// Last update: 2022-08-10
// Test class: DiligenceCheckListControllerTest
//

public with sharing class DiligenceCheckListController {
    @AuraEnabled
    public static List<reportWrapper> getInitialData(String mappingToSearch, 
                                                        String ownerToSearch, 
                                                        String statusToSearch, 
                                                        Date startDateToSearch, 
                                                        Date endDateToSearch, 
                                                        String assignedToSearch, 
                                                        String propertyToSearch) {
                
        Boolean hasSearchMapping = String.isNotBlank(mappingToSearch) && mappingToSearch.length() >= 2 && mappingToSearch != 'All';
        Boolean hasSearchOwner = String.isNotBlank(ownerToSearch) && ownerToSearch.length() >= 2 && ownerToSearch != 'All';
        Boolean hasSearchStatus = String.isNotBlank(statusToSearch) && statusToSearch.length() >= 2 && statusToSearch != 'All';
        Boolean hasSearchStartDate = startDateToSearch != null;
        Boolean hasSearchEndDate = endDateToSearch != null;
        Boolean hasSearchAssigned = String.isNotBlank(assignedToSearch) && assignedToSearch.length() >= 2 && assignedToSearch != 'All';
        Boolean hasSearchProperty = String.isNotBlank(propertyToSearch) && propertyToSearch.length() >= 2 && propertyToSearch != 'All';

        Id chRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Charter Holder').getRecordTypeId();
        Id schRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
        // Exit if no search values
        if (!hasSearchMapping && !hasSearchOwner && !hasSearchStatus && !hasSearchAssigned && !hasSearchProperty && !hasSearchStartDate && !hasSearchEndDate) {
            return null;
        }
        
        Set<Id> cpAIIDSet = new Set<Id>();
        //look at the submitt date and approved date
        List<Intake_Item__c> cpAIRecords = [SELECT Id, CSC_Action_Item__c, Due_Date__c 
                                            FROM Intake_Item__c 
                                            //WHERE Due_Date__c >= :startDateToSearch AND Due_Date__c <= :endDateToSearch
                                            // and is ongoing diligence
                                            WHERE CSC_Action_Item__c != null
                                            ];
        //system.debug('*** cpAIRecords = ' + cpAIRecords);
        for(Intake_Item__c cpai: cpAIRecords) {
            if(cpai.CSC_Action_Item__c != null){
                if(!cpAIIDSet.contains(cpai.CSC_Action_Item__c)){
                    cpAIIDSet.add(cpai.CSC_Action_Item__c);
                }
            }
        }
        
        String exTemplate = 'Template';
        String queryString = 'SELECT Id, Must_have_CP_item__c, Action_Item_Name__c, Review_Date__c, Comments__c, Action_Item_Mapping__c, Assigned_To__c, Assigned_To__r.Name, CSC_Action_List__r.Account__c, CSC_Action_List__r.Account__r.Id, CSC_Action_List__r.Account__r.Name, CSC_Action_List__r.Account__r.RecordTypeId, CSC_Action_List__r.Account__r.Owner_Portfolio_Formula__c, CSC_Action_List__r.Account__r.Paralegal_1__r.Name, CSC_Action_List__r.Account__r.Financial_Review__r.Name, CSC_Action_List__r.Account__r.Related_Property__r.Name, CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c, CSC_Action_List__r.Account__r.Charter_Holder__r.Id, CSC_Action_List__r.Account__r.Charter_Holder__r.Name, (select id, name from intake_items__r) FROM CSC_Action_Item__c';
        String whereString = ' WHERE Active_OD__c = true AND ((NOT CSC_Action_List__r.Account__r.Charter_Holder__r.Name LIKE '+'\''+exTemplate+'\') OR (NOT CSC_Action_List__r.Account__r.Name LIKE '+'\''+exTemplate+'\'))';

        if (hasSearchMapping || hasSearchStatus || hasSearchAssigned || hasSearchProperty) {

            whereString += ' AND (';
        
            if (hasSearchMapping) {
                whereString += ' Action_Item_Mapping__c = '+'\''+mappingToSearch+'\'';
            }
            
            if (hasSearchProperty) {
                whereString += ' CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c = '+'\''+propertyToSearch+'\'';
            }

            if (hasSearchStatus) {
                if(hasSearchOwner || hasSearchMapping || hasSearchProperty){
                    whereString += ' AND Id IN :cpAIIDSet';
                }else if(hasSearchProperty){
                    whereString += ' CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c = '+'\''+propertyToSearch+'\'';
                }else{
                    whereString += ' Id IN :cpAIIDSet';
                }
            } 
            if (hasSearchAssigned) {
                if(hasSearchOwner || hasSearchStatus || hasSearchMapping || hasSearchProperty){
                    whereString += ' AND Assigned_To__c = '+'\''+assignedToSearch+'\'';
                }else if(hasSearchProperty){
                    whereString += ' CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c = '+'\''+propertyToSearch+'\'';
                }else{
                    whereString += ' Assigned_To__c = '+'\''+assignedToSearch+'\'';
                }
            } 
            
            whereString += ')';
        }

        queryString += whereString;
        
        //Main query
        List<CSC_Action_Item__c> aiRecords = Database.query(queryString);

        Set<Id> aiIdSet = new Set<Id>();

        Set<Id> aiCharterIds = new Set<Id>();
        Set<Id> aiSchoolIds = new Set<Id>();
        Set<Id> schoolIds = new Set<Id>();
    
        for(CSC_Action_Item__c aid: aiRecords) {
            aiIdSet.add(aid.Id);
            if(aid.CSC_Action_List__r.Account__c != null){
            // For Results with an Account with a record Type of Charter Holder need to Query Schools>Lease SChool to get Property Info and Owner
            if(aid.CSC_Action_List__r.Account__r.RecordTypeId == chRecordTypeId){
                    if(!aiCharterIds.contains(aid.CSC_Action_List__r.Account__c)){
                        aiCharterIds.add(aid.CSC_Action_List__r.Account__c);
                    }
                // For Results with an Account with a record Type of School need to Query Lease SChool to get Property Info and Owner
                } else if(aid.CSC_Action_List__r.Account__r.RecordTypeId == schRecordTypeId){
                    if(!aiSchoolIds.contains(aid.CSC_Action_List__r.Account__c)){
                        aiSchoolIds.add(aid.CSC_Action_List__r.Account__c);
                    }
                } else {
                    if(!schoolIds.contains(aid.CSC_Action_List__r.Account__c)){
                        schoolIds.add(aid.CSC_Action_List__r.Account__c);
                    }
                }
            }
        }

        Map<Id, Account> schoolMap = new Map<Id, Account>();
        List<Account> schools = [SELECT Id,RecordTypeId,Name,Owner_Portfolio_Formula__c,Related_Property__r.Name,Related_Property__r.Nick_Name__c,Charter_Holder__c 
                                    FROM Account 
                                    WHERE Id In :aiSchoolIds];

        for(Account sch: schools) {  
            schoolIds.add(sch.Id);      
                if(!schoolMap.containsKey(sch.Id) || schoolMap.get(sch.Id) == null) {
                    schoolMap.put(sch.Id, sch);
                }
        }

        List<Account> chSchools = [SELECT Id,RecordTypeId,Name,Owner_Portfolio_Formula__c,Related_Property__r.Name,Related_Property__r.Nick_Name__c,Charter_Holder__c FROM Account WHERE Charter_Holder__c In :aiCharterIds];
        for(Account chSch: chSchools) {  
            schoolIds.add(chSch.Id);      
                if(!schoolMap.containsKey(chSch.Charter_Holder__c) || schoolMap.get(chSch.Charter_Holder__c) == null) {
                    schoolMap.put(chSch.Charter_Holder__c, chSch);
                }
        }

        //we need to add a query for the lease_school__c record
        List<Lease_School__c> leaseSchools = [SELECT Id, 
                                                    Name, 
                                                    Account_School__c,
                                                    Lease__c,
                                                    Account_School__r.Name, 
                                                    Account_School__r.Owner_Portfolio_Formula__c, 
                                                    Account_School__r.Grade_Level_Served__c, 
                                                    Account_School__r.Operating_State__r.Name, 
                                                    Lease__r.Property__r.Name, 
                                                    Lease__r.Owner_Portfolio__c, 
                                                    Lease__r.Property__r.Nick_Name__c, 
                                                    Lease_Status__c, 
                                                    Lease__r.Property__r.Equity_Investor__r.Name 
                                                    FROM Lease_School__c 
                                                    WHERE  Account_School__c IN :schoolIds 
                                                    AND Lease_Status__c = 'Active'];

        Set<Id> leaseIds = new Set<Id>();
        Map<Id, Id> leaseSchoolsMap = new Map<Id, Id>();
        for(Lease_School__c ls : leaseSchools) {
            if(ls.id != null){
                leaseIds.add(ls.Lease__c);
                if(!leaseSchoolsMap.containsKey(ls.Account_School__c)){
                    leaseSchoolsMap.put(ls.Lease__c, ls.Account_School__c);
                }
            }
        }

        Map<Id, Lease__c> leaseMap = new Map<Id, Lease__c>();
        List<Lease__c> leases;
        if (hasSearchOwner) {
            leases = [SELECT Id, 
                            Account__c, 
                            Account__r.Id, 
                            Owner_Portfolio__c, 
                            Property__r.Id, 
                            Property_Nick_Name__c 
                            FROM Lease__c 
                            WHERE Id IN :leaseIds 
                            AND Lease_Status__c = 'Active' 
                            AND Owner_Portfolio__c = :ownerToSearch];
        }else{
            leases = [SELECT Id,
                            Account__c,
                            Account__r.Id,
                            Owner_Portfolio__c,
                            Property__r.Id,
                            Property_Nick_Name__c 
                            FROM Lease__c 
                            WHERE Id IN :leaseIds 
                            AND Lease_Status__c = 'Active'];
        }
        
        //add accounts to leases 
        for(Lease__c lease : leases) { 
            lease.Account__c = leaseSchoolsMap.get(lease.Id);
            if(!leaseMap.containsKey(lease.Account__c)) {
                leaseMap.put(lease.Account__c, lease);
            } 
        }

        //todo-- make a condition if(hasSearchStartDate && hasSearchEndDate)
        Map<Id, Intake_Item__c> cpByAIIdMap = new Map<Id, Intake_Item__c>();
        List<Intake_Item__c> cpRecords = [SELECT Id, 
                                                CSC_Action_Item__c, 
                                                Is_Visible_To_Community__c, 
                                                Due_Date__c, 
                                                Submitted_Date__c, 
                                                Approved_Date__c 
                                                FROM Intake_Item__c 
                                                WHERE CSC_Action_Item__c IN :aiIdSet 
                                                AND Due_Date__c >= :startDateToSearch AND Due_Date__c <= :endDateToSearch
                                                ];
        for(Intake_Item__c cp: cpRecords) {        
            if(!cpByAIIdMap.containsKey(cp.CSC_Action_Item__c)) {
                cpByAIIdMap.put(cp.CSC_Action_Item__c, cp);
            }
        }
        
        List<reportWrapper> diligenceRecords = new List<reportWrapper>();
        for(CSC_Action_Item__c ai: aiRecords) {
            // check if it's suppose to have a CP item -- create a checkbox on the AI object
            // if it should have one and it doesn't -- Has CP item has to be red X, others blank 
            // CheckBox has to be on AI object -- should match OD CP item template report
            
            //re-work 
            Account school = schoolMap.get(ai.CSC_Action_List__r.Account__c);
            Lease__c lease;
            if(school != null){
                lease = leaseMap.get(school.Id);
                if(lease != null){
                    //standard part here
                    Boolean assigned = false;
                    Boolean hasCP = false;
                    Boolean cpVisible;
                    Boolean cpDueDate;
                    Boolean cpSubDate;
                    Boolean cpAppDate;
                    Boolean aiRevDate;
                    String accName;
                    String accId;
                    String aiName = ai.Action_Item_Mapping__c;

                    if(ai.Action_Item_Mapping__c == null ){ aiName = ai.Action_Item_Name__c; }
                    if(ai.Assigned_To__c != null ) { assigned = true; }
                    if(ai.CSC_Action_List__r.Account__r.Charter_Holder__c != null ){
                        accName = ai.CSC_Action_List__r.Account__r.Charter_Holder__r.Name;
                        accId = ai.CSC_Action_List__r.Account__r.Charter_Holder__r.Id;
                    }else{
                        accName = ai.CSC_Action_List__r.Account__r.Name;
                        accId = ai.CSC_Action_List__r.Account__r.Id;
                    }

                    //when AI should have a CP item
                    if(ai.Must_have_CP_item__c == true) {
                        //when CP item is not null
                        if(ai.intake_items__r.size() != 0) {
                            //do full evaluation based on CP record data
                            if(cpByAIIdMap.containsKey(ai.Id)) {
                                Intake_Item__c tempCPs = cpByAIIdMap.get(ai.Id);
                                if(tempCPs != null){
                                    hasCP = true;
                                    if (tempCPs.Is_Visible_To_Community__c == true) {
                                        cpVisible = true;
                                    } else {cpVisible = false;}
                                    if (tempCPs.Due_Date__c != null) {
                                        cpDueDate = true;
                                    } else { cpDueDate = false;}
                                    if (tempCPs.Submitted_Date__c != null) {
                                        cpSubDate = true;
                                    } else {cpSubDate = false;}
                                    if (tempCPs.Approved_Date__c != null) {
                                        cpAppDate = true;
                                    } else {cpAppDate = false;}
                                }
                            }
                            reportWrapper odr = new reportWrapper(ai.Id, 
                                                                    aiName, 
                                                                    lease.Owner_Portfolio__c, 
                                                                    lease.Property__r.Id, 
                                                                    lease.Property_Nick_Name__c, 
                                                                    accId, 
                                                                    accName, 
                                                                    ai.Assigned_To__r.Name, 
                                                                    assigned, 
                                                                    hasCP, 
                                                                    cpVisible, 
                                                                    cpDueDate, 
                                                                    cpSubDate, 
                                                                    cpAppDate, 
                                                                    aiRevDate, 
                                                                    ai.Comments__c);
                            diligenceRecords.add(odr); 
                        }
                        //if AI should have a CP item but doesn't
                        if (ai.intake_items__r.size() == 0) {
                            reportWrapper odr = new reportWrapper(ai.Id, 
                                                                        aiName, 
                                                                        lease.Owner_Portfolio__c, 
                                                                        lease.Property__r.Id, 
                                                                        lease.Property_Nick_Name__c, 
                                                                        accId, 
                                                                        accName, 
                                                                        ai.Assigned_To__r.Name, 
                                                                        assigned, 
                                                                        hasCP, 
                                                                        cpVisible, 
                                                                        cpDueDate, 
                                                                        cpSubDate, 
                                                                        cpAppDate, 
                                                                        aiRevDate, 
                                                                        ai.Comments__c);
                            diligenceRecords.add(odr); 
                        }
                    
                    // if it doen't have to have a CP item -- populate review date
                    } else {
                        if (ai.Review_Date__c >= startDateToSearch && ai.Review_Date__c <= endDateToSearch) {
                                    aiRevDate = true;
                                } else { aiRevDate = false;}

                        reportWrapper odr = new reportWrapper(ai.Id, 
                                                                    aiName, 
                                                                    lease.Owner_Portfolio__c, 
                                                                    lease.Property__r.Id, 
                                                                    lease.Property_Nick_Name__c, 
                                                                    accId, 
                                                                    accName, 
                                                                    ai.Assigned_To__r.Name, 
                                                                    assigned, 
                                                                    hasCP, 
                                                                    cpVisible, 
                                                                    cpDueDate, 
                                                                    cpSubDate, 
                                                                    cpAppDate, 
                                                                    aiRevDate, 
                                                                    ai.Comments__c);
                        diligenceRecords.add(odr); 
                    }
                }
            }
        }
        return diligenceRecords;
    }

    @AuraEnabled
    public static Map<String, List<PicklistOption>> getPicklists() {
        
        try {
            
            Map<String, List<PicklistOption>> result = new Map<String, List<PicklistOption>>();
            
            result.put('mapping', getValues('mapping'));
            result.put('status', getPicklistOptions(Intake_Item__c.Status__c, true));
            result.put('owners', getValues('Owner'));
            result.put('assignedTo', getValues('AssignedTo'));
            result.put('property', getValues('Property'));
            
            return result;
            
        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            AuraHandledException ahe = new AuraHandledException(e.getMessage());
            ahe.setMessage(e.getMessage());
            throw ahe;
        }
        
    }

    private static List<PicklistOption> getPicklistOptions(Schema.SObjectField field, Boolean addBlank) {
        
        List<PicklistOption> result = new List<PicklistOption>();
        
        if (addBlank) {
            result.add(new PicklistOption('', ''));
            result.add(new PicklistOption('All', 'All'));
        }
        
        for (Schema.PicklistEntry ple : field.getDescribe().getPicklistValues()) {
            if (ple.isActive()) {
                result.add(new PicklistOption(ple.getValue(), ple.getLabel()));
            }
        }
        
        return result;
        
    }

    private static List<PicklistOption> getValues(String optionType) {
        
        List<PicklistOption> result = new List<PicklistOption>();
        
        result.add(new PicklistOption('', ''));
        result.add(new PicklistOption('All', 'All'));
        
        List<CSC_Action_Item__c> itemList = [SELECT Assigned_To__r.Id, Action_Item_Mapping__c, CSC_Action_List__r.Account__r.RecordTypeId, Assigned_To__r.Name, CSC_Action_List__r.Account__r.Owner_Portfolio_Formula__c FROM CSC_Action_Item__c WHERE Active_OD__c = true];
        
        if(optionType == 'Owner'){
        Set<Id> aiCharterIds = new Set<Id>();
        Set<Id> aiSchoolIds = new Set<Id>();
        Set<Id> schoolIds = new Set<Id>();

        Id chRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Charter Holder').getRecordTypeId();
        Id schRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
    
        for(CSC_Action_Item__c aid: itemList) {
            if(aid.CSC_Action_List__r.Account__c != null){
            // For Results with an Account with a record Type of Charter Holder need to Query Schools>Lease SChool to get Property Info and Owner
                if(aid.CSC_Action_List__r.Account__r.RecordTypeId == chRecordTypeId){
                    if(!aiCharterIds.contains(aid.CSC_Action_List__r.Account__c)){
                        aiCharterIds.add(aid.CSC_Action_List__r.Account__c);
                    }
                // For Results with an Account with a record Type of School need to Query Lease SChool to get Property Info and Owner
                } else if(aid.CSC_Action_List__r.Account__r.RecordTypeId == schRecordTypeId){
                    if(!aiSchoolIds.contains(aid.CSC_Action_List__r.Account__c)){
                        aiSchoolIds.add(aid.CSC_Action_List__r.Account__c);
                    }
                } else {
                    if(!schoolIds.contains(aid.CSC_Action_List__r.Account__c)){
                        schoolIds.add(aid.CSC_Action_List__r.Account__c);
                    }
                }
            }
        }
        Map<Id, Account> schoolMap = new Map<Id, Account>();
        List<Account> schools = [SELECT Id,RecordTypeId,Name,Owner_Portfolio_Formula__c,Related_Property__r.Name,Related_Property__r.Nick_Name__c,Charter_Holder__c FROM Account WHERE Id In :aiSchoolIds];
        for(Account sch: schools) {  
            schoolIds.add(sch.Id);      
                if(!schoolMap.containsKey(sch.Id) || schoolMap.get(sch.Id) == null) {
                    system.debug('adding school to schoolMap == '+sch);
                    schoolMap.put(sch.Id, sch);
                }
        }

        List<Account> chSchools = [SELECT Id,RecordTypeId,Name,Owner_Portfolio_Formula__c,Related_Property__r.Name,Related_Property__r.Nick_Name__c,Charter_Holder__c FROM Account WHERE Charter_Holder__c In :aiCharterIds];
        for(Account chSch: chSchools) {  
            schoolIds.add(chSch.Id);      
                if(!schoolMap.containsKey(chSch.Charter_Holder__c) || schoolMap.get(chSch.Charter_Holder__c) == null) {
                    system.debug('adding to schoolMap == '+chSch);
                    schoolMap.put(chSch.Charter_Holder__c, chSch);
                }
                
        }

        //we need to add a query for the lease_school__c record
        List<Lease_School__c> leaseSchools = [SELECT Id, 
                                                    Name, 
                                                    Account_School__c,
                                                    Lease__c,
                                                    Account_School__r.Name, 
                                                    Account_School__r.Owner_Portfolio_Formula__c, 
                                                    Account_School__r.Grade_Level_Served__c, 
                                                    Account_School__r.Operating_State__r.Name, 
                                                    Lease__r.Property__r.Name, 
                                                    Lease__r.Owner_Portfolio__c, 
                                                    Lease__r.Property__r.Nick_Name__c, 
                                                    Lease_Status__c, 
                                                    Lease__r.Property__r.Equity_Investor__r.Name 
                                                    FROM Lease_School__c 
                                                    WHERE  Account_School__c IN :schoolIds 
                                                    AND Lease_Status__c = 'Active'];

        Set<Id> leaseIds = new Set<Id>();
        Map<Id, Id> leaseSchoolsMap = new Map<Id, Id>();
        for(Lease_School__c ls : leaseSchools) {
            if(ls.id != null){
                leaseIds.add(ls.Lease__c);
                if(!leaseSchoolsMap.containsKey(ls.Account_School__c)){
                    system.debug('*** adding lease school = '+ ls);
                    leaseSchoolsMap.put(ls.Lease__c, ls.Account_School__c);
                }
            }
        }
        
        Map<Id, Lease__c> leaseMap = new Map<Id, Lease__c>();
        List<Lease__c> leases = [SELECT Id,Account__c,Account__r.Id,Owner_Portfolio__c,Property__r.Name,Property_Nick_Name__c FROM Lease__c WHERE Id IN :leaseIds AND Lease_Status__c = 'Active'];
        
        for(Lease__c lease : leases) { 
            lease.Account__c = leaseSchoolsMap.get(lease.Id);
            if(!leaseMap.containsKey(lease.Account__c)) {
                system.debug('adding to leaseMap == '+lease);
                leaseMap.put(lease.Account__c, lease);
            } 
        }
        
        system.debug('leaseMap == '+leaseMap);

            Set<String> owners = new Set<String>();
            for (CSC_Action_Item__c member : itemList) {
                Account school = schoolMap.get(member.CSC_Action_List__r.Account__c);
                system.debug('school == '+school);
                Lease__c lease;
                if(school != null){
                    lease = leaseMap.get(school.Id);

                    system.debug('*** lease = ' + lease); 

                    if(lease?.Owner_Portfolio__c != null){
                        if(!owners.contains(lease.Owner_Portfolio__c)){
                            owners.add(lease.Owner_Portfolio__c);
                            system.debug('*** lease.Owner_Portfolio__c = ' + lease.Owner_Portfolio__c);
                            result.add(new PicklistOption(lease.Owner_Portfolio__c, lease.Owner_Portfolio__c));
                        }
                    }
                }
            }   
        }
        
        if(optionType == 'AssignedTo'){
            Set<Id> assigned = new Set<Id>();
            for (CSC_Action_Item__c member : itemList) {
                if(member.Assigned_To__r.Name != null){
                    if(!assigned.contains(member.Assigned_To__r.Id)){
                        assigned.add(member.Assigned_To__r.Id);
                        result.add(new PicklistOption(member.Assigned_To__r.Id, member.Assigned_To__r.Name));
                    }
                }
            }
        }

        if(optionType == 'mapping'){
            Set<String> mapping = new Set<String>();
            for (CSC_Action_Item__c member : itemList) {
                if(member.Action_Item_Mapping__c != null){
                    if(!mapping.contains(member.Action_Item_Mapping__c)){
                        mapping.add(member.Action_Item_Mapping__c);
                        result.add(new PicklistOption(member.Action_Item_Mapping__c, member.Action_Item_Mapping__c));
                    }
                }
            }
        }

        if(optionType == 'Property'){
            Set<String> property = new Set<String>();
            List<CSC_Action_Item__c> propertyList = [SELECT Id, 
                                            Action_Item_Name__c, 
                                            CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c,
                                            CSC_Action_List__r.Account__r.Charter_Holder__r.Name,
                                            CSC_Action_List__r.Account__r.Name
                                            FROM CSC_Action_Item__c
                                            WHERE 
                                            Active_OD__c = true 
                                            AND ((NOT CSC_Action_List__r.Account__r.Charter_Holder__r.Name LIKE '%Template%') 
                                            OR (NOT CSC_Action_List__r.Account__r.Name LIKE '%Template%'))];

            for (CSC_Action_Item__c prty : propertyList) {
                if(prty.CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c != null){
                    if(!property.contains(prty.CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c)){
                        property.add(prty.CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c);
                        result.add(new PicklistOption(prty.CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c, prty.CSC_Action_List__r.Account__r.Related_Property__r.Nick_Name__c));
                    }
                }
            }
        }
        
        return result;
    }

    public class PicklistOption {
        public PicklistOption() { }
        public PicklistOption (String value, String label) {
            this.value = value;
            this.label = label;
        }
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Boolean selected { get; set; }
    }

    public class reportWrapper{
        @AuraEnabled public String ActionItemId {get; set;}
        @AuraEnabled public String ActionItem {get; set;}
        @AuraEnabled public String Owner {get; set;}
        @AuraEnabled public String PropertyId {get; set;}
        @AuraEnabled public String PropertyName {get; set;}
        @AuraEnabled public String AccId {get; set;}
        @AuraEnabled public String AccName {get; set;}
        @AuraEnabled public String AssignedTo {get; set;}
        @AuraEnabled public Boolean Assigned {get; set;}
        @AuraEnabled public Boolean HasCP {get; set;}
        @AuraEnabled public Boolean CPVisible {get; set;}
        @AuraEnabled public Boolean HasDueDate {get; set;}
        @AuraEnabled public Boolean CPSubmitted {get; set;}
        @AuraEnabled public Boolean HasApprovedDate {get; set;}
        @AuraEnabled public Boolean aiReviewDate {get; set;}
        @AuraEnabled public String Comments {get; set;}
        
        public reportWrapper(String aid, String ai, String own, String propId, String prop, String accid, String accn, String asto, Boolean assigned, Boolean hasCP, Boolean cpVisible, Boolean hasDueDate, Boolean cpSubmitted, Boolean hasApprovedDate, Boolean aiReviewDate, String com) {
            this.ActionItemId = aid;
            this.ActionItem = ai;
            this.Owner = own;
            this.PropertyId = propId;
            this.PropertyName = prop;
            this.AccId = accid;
            this.AccName = accn;
            this.AssignedTo = asto;
            this.Assigned = assigned;
            this.HasCP = hasCP;
            this.CPVisible = cpVisible;
            this.HasDueDate = hasDueDate;
            this.CPSubmitted = cpSubmitted;
            this.HasApprovedDate = hasApprovedDate;
            this.aiReviewDate = aiReviewDate;
            this.Comments = com;
        }
    }
}