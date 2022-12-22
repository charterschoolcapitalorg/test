public with sharing class ActionListOngoingDiligenceCreation {

    @InvocableMethod(label='Create Std Action Lists Lists')
    public static void createLists(List<CreateActionListsRequest> requests) {
        final String AUDIT = 'Audit/Financials';
        final String FAM = 'Facilities - Asset Management';
        final String SCHOOLFILE = 'File Review - School';
        final String CHARTERFILE = 'File Review - Charter Holder';

        Set<String> templatesNeeded = new Set<String>();
        Set<Id> schoolsListed = new Set<Id>();
        // Set<Id> actionListTemplateIds = new Set<Id>();
        List<CSC_Action_List__c> newLists = new List<CSC_Action_List__c>();
        Map<String, CSC_Action_List__c> stateAuditListMap = new Map<String, CSC_Action_List__c>();
        Map<String, CSC_Action_List__c> stateFacilitesListMap = new Map<String, CSC_Action_List__c>();
        Map<String, CSC_Action_List__c> stateSchoolFileListMap = new Map<String, CSC_Action_List__c>();
        Map<String, CSC_Action_List__c> stateCharterFileListMap = new Map<String, CSC_Action_List__c>();

        //parse schools and tempaltes needed
        for(CreateActionListsRequest calr : requests){
            schoolsListed.add(calr.schoolId);
            if(calr.audit_AL == true && !templatesNeeded.contains(AUDIT)) templatesNeeded.add(AUDIT);
            if(calr.fam_AL == true && !templatesNeeded.contains(FAM)) templatesNeeded.add(FAM);
            if(calr.fileSchool_AL == true && !templatesNeeded.contains(SCHOOLFILE)) templatesNeeded.add(SCHOOLFILE);
            if(calr.fileCharter_AL == true && !templatesNeeded.contains(CHARTERFILE)) templatesNeeded.add(CHARTERFILE);
        }

        //get School data and State List
        Set<Id> states = new Set<Id>();
        Map<Id, Account> idSchoolMap = new Map<Id, Account>();
        for(Account school : [SELECT Id, Charter_Holder__r.Id, Operating_State__c FROM Account WHERE id IN :schoolsListed]){
            idSchoolMap.put(school.Id, School);
            states.add(school.Operating_State__c);
        }

        //Fields needed that aren't on the CSC Action List object
        List<String> additionalFields = new List<String>();
        additionalFields.add('Account__r.Operating_State__c');
        
        //get templates
        Set<Id> clonedTemplateListIdSet = new Set<Id>();
        for(CSC_Action_List__c template :  (List<CSC_Action_List__c>) Database.query(CloneUtility.getCSCActionListBaseQuery(additionalFields) + ' WHERE Template__c = true AND (Account__r.Operating_State__c IN :states OR Account__r.Operating_State__c = NULL) AND Action_List_Mapping__c IN :templatesNeeded'))
                                            {   
                                                // actionListTemplateIds.add(template.Id);
                                                clonedTemplateListIdSet.add(template.Id);
                                                String stateId = 'XX';
                                                if(template.Account__r.Operating_State__c != null) stateId = template.Account__r.Operating_State__c;
                                                if(template.Action_List_Mapping__c == AUDIT) stateAuditListMap.put(stateId, template);
                                                if(template.Action_List_Mapping__c == FAM) stateFacilitesListMap.put(stateId, template);
                                                if(template.Action_List_Mapping__c == SCHOOLFILE) stateSchoolFileListMap.put(stateId, template);
                                                if(template.Action_List_Mapping__c == CHARTERFILE) stateCharterFileListMap.put(stateId, template);
                                            }
        
        //clone lists required
        for(CreateActionListsRequest calr : requests){
            if(!(calr.audit_AL == false && calr.fam_AL == false && calr.fileSchool_AL == false && calr.fileCharter_AL == false)){
                CSC_Action_List__c newActionList = new CSC_Action_List__c();
                String stateId = idSchoolMap.get(calr.schoolId).Operating_State__c;
                if(calr.audit_AL == true) {
                    if(stateAuditListMap.containsKey(stateId)){
                        newActionList = stateAuditListMap.get(stateId).clone(false, true, false, false);
                        newActionList.Source_List__c = stateAuditListMap.get(stateId).Id;
                    } else {
                        newActionList = stateAuditListMap.get('XX').clone(false, true, false, false);
                        newActionList.Source_List__c = stateAuditListMap.get('XX').Id;
                    }
                    newActionList.Account__c = calr.schoolId;
                }
                if(calr.fam_AL == true) {
                    if(stateFacilitesListMap.containsKey(stateId)){
                        newActionList = stateFacilitesListMap.get(stateId).clone(false, true, false, false);
                        newActionList.Source_List__c = stateFacilitesListMap.get(stateId).Id;
                    } else {
                        newActionList = stateFacilitesListMap.get('XX').clone(false, true, false, false);
                        newActionList.Source_List__c = stateFacilitesListMap.get('XX').Id;
                    }
                    newActionList.Account__c = calr.schoolId;
                }
                if(calr.fileSchool_AL == true) {
                    if(stateSchoolFileListMap.containsKey(stateId)){
                        newActionList = stateSchoolFileListMap.get(stateId).clone(false, true, false, false);
                        newActionList.Source_List__c = stateSchoolFileListMap.get(stateId).Id;
                    } else {
                        newActionList = stateSchoolFileListMap.get('XX').clone(false, true, false, false);
                        newActionList.Source_List__c = stateSchoolFileListMap.get('XX').Id;
                    }
                    newActionList.Account__c = calr.schoolId;
                }
                if(calr.fileCharter_AL == true) {
                    if(stateCharterFileListMap.containsKey(stateId)){
                        newActionList = stateCharterFileListMap.get(stateId).clone(false, true, false, false);
                        newActionList.Source_List__c = stateCharterFileListMap.get(stateId).Id;
                    } else {
                        newActionList = stateCharterFileListMap.get('XX').clone(false, true, false, false);
                        newActionList.Source_List__c = stateCharterFileListMap.get('XX').Id;
                    }
                    newActionList.Account__c = idSchoolMap.get(calr.schoolId).Charter_Holder__c;
                }
                newActionList.Status__c = 'New';
                newActionList.Active_OD__c = true;
                newActionList.Template__c = false;
                newLists.add(newActionList);
            }
        }

        System.debug('# lists: ' + newLists.size());
        if(newLists.size()>0){
            insert newLists;

            //get CSC Action List items for required templates
            Map<Id, List<CSC_Action_Item__c>> templateToListItemsMap = new Map<Id, List<CSC_Action_Item__c>>();
            for(CSC_Action_Item__c origItem : (List<CSC_Action_Item__c>) Database.query(CloneUtility.getCSCActionItemBaseQuery() + ' WHERE CSC_Action_List__c IN :clonedTemplateListIdSet ORDER BY CSC_Action_List__c, Order__c')) {
                if(!templateToListItemsMap.containsKey(origItem.CSC_Action_List__c)){
                    templateToListItemsMap.put(origItem.CSC_Action_List__c, new List<CSC_Action_Item__c>{origItem});
                } else {
                    List<CSC_Action_Item__c> items = templateToListItemsMap.get(origItem.CSC_Action_List__c);
                    items.add(origItem);
                    templateToListItemsMap.put(origItem.CSC_Action_List__c, items);
                }
            }

            //clone items to new templates
            List<CSC_Action_Item__c> cloneItems = new List<CSC_Action_Item__c>();
            for(CSC_Action_List__c al : newLists){
                for(CSC_Action_Item__c ai : templateToListItemsMap.get(al.Source_List__c)){
                    CSC_Action_Item__c newItem = ai.clone(false, true, false, false);
                    newItem.CSC_Action_List__c = al.Id;
                    cloneItems.add(newItem);
                }
            }

            System.debug(cloneItems);
            Flags.SkipActionItemOrderResequencing = true;
            try {
                insert cloneItems;
            } finally {
                Flags.SkipActionItemOrderResequencing = false;
            }
        }



    }    



    public class CreateActionListsRequest {
        @InvocableVariable(label='School Account Id' required=true)
        public ID schoolId;
    
        @InvocableVariable(label='School Audit AL needed?' required=true)
        public Boolean audit_AL;
    
        @InvocableVariable(label='School FAM AL needed?' required=true)
        public Boolean fam_AL;
    
        @InvocableVariable(label='School File Review AL needed?' required=true)
        public Boolean fileSchool_AL;

        @InvocableVariable(label='Charter File Review AL needed?' required=true)
        public Boolean fileCharter_AL;

      }



}