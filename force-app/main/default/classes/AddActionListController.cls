//
// (c) 2014 Appirio, Inc.
// Helper Class to handle all Oppurtunity trigger events
//
//
// 16 April 2014    Harshit Jain(JDC)       [T-271732]
// Remove sales process dependancy on checkboxes
public with sharing class AddActionListController {
    public List<ActionList> actionLists { get; private set; }
    public Boolean useState { get; private set; }
    public Boolean useCatchAll { get; private set; }
    private ApexPages.StandardController stdController;
    private Id acctId;
    private Id oppId;
    private Account acct;
    private Opportunity opp;
    private static Set<String> OPPORTUNITY_TYPE = new Set<String>{'FOF', 'Facilities', 'Initial Funding','LOI', 'Loan'};        //2016.05.12 J Caughie - added Loan as a type

    public AddActionListController(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        acctId = this.stdController.getId();
        actionLists = new List<ActionList>();

        Map<String, String> paramMap = ApexPages.currentPage().getParameters();
        useState = paramMap.containsKey('state') && !paramMap.get('state').equals('0');
        useCatchAll = paramMap.containsKey('catchall') && !paramMap.get('catchall').equals('0');

        if(!useState && !useCatchAll) {
            useState = true;
            useCatchAll = true;
        }

        try {
            oppId = paramMap.get('oppId');
        } catch(StringException e) {}
    }

    public void init() {
        List<CSC_Action_List__c> cscActionLists =  new List<CSC_Action_List__c>();
        acct = [SELECT Id, Operating_State__c FROM Account WHERE Id = :acctId];

        if(oppId != null) {
          opp = [SELECT Id, RecordTypeId, RecordType.Name FROM Opportunity WHERE Id = :oppId];
        }
          cscActionLists = [SELECT Id, Action_List_Name__c, Library_Type__c, Opportunity__c, Account__c,
                               Account__r.Operating_State__c, Account__r.Catch_All__c, Opportunity_Record_Type__c
                         FROM  CSC_Action_List__c
                        WHERE  Template__c = true
                          AND  Account__c != null
                          AND  (Account__r.Operating_State__c = :acct.Operating_State__c OR Account__r.Catch_All__c = true) ORDER BY Action_List_Name__c];

        buildList(cscActionLists);

        if(useState && !useCatchAll && actionLists.isEmpty()) {
            useCatchAll = true;
            buildList(cscActionLists);
        }
    }

    //2015.07.17 J Caughie - Added for use on Account Layout -> CSC Action List related list -> Add Facilities button
    public void initFacilities() {
        List<CSC_Action_List__c> cscActionLists =  new List<CSC_Action_List__c>();
        acct = [SELECT Id, Operating_State__c FROM Account WHERE Id = :acctId];

        cscActionLists = [SELECT Id, Action_List_Name__c, Library_Type__c, Opportunity__c, Account__c,
                               Account__r.Operating_State__c, Account__r.Catch_All__c, Opportunity_Record_Type__c
                         FROM  CSC_Action_List__c
                        WHERE  Template__c = true
                          AND  (Facilities__c = true AND Opportunity_Record_Type__c = '') ORDER BY Action_List_Name__c];

        buildList(cscActionLists);
    }

    private void buildList(List<CSC_Action_List__c> cscActionLists) {
        for(CSC_Action_List__c cscActionList : cscActionLists) {
            System.debug(cscActionList);
            Account templateAccount = cscActionList.Account__r;
            if((useState && templateAccount.Operating_State__c == acct.Operating_State__c) || (useCatchAll && templateAccount.Catch_All__c)) {
                    if(oppId != null && cscActionList.Opportunity_Record_Type__c == opp.RecordType.Name) {
                      actionLists.add(new ActionList(cscActionList));
                    } else {
                        if(!OPPORTUNITY_TYPE.contains(cscActionList.Opportunity_Record_Type__c)) {
                          actionLists.add(new ActionList(cscActionList));
                        }
                    }
            }
        }
    }

    public PageReference save() {
        Set<Id> selectedIds = new Set<Id>();

        for(ActionList actList : actionlists) {
            if(actList.selected) {
                selectedIds.add(actList.listId);
            }
        }

        if(!selectedIds.isEmpty()) {
            Map<Id, CSC_Action_List__c> cloneMap = new Map<Id, CSC_Action_List__c>();
            List<CSC_Action_Item__c> cloneItems = new List<CSC_Action_Item__c>();

            for(CSC_Action_List__c origList : (List<CSC_Action_List__c>) Database.query(CloneUtility.getCSCActionListBaseQuery() + ' WHERE Id IN :selectedIds')) {
                CSC_Action_List__c newList = origList.clone(false, true, false, false);
                newList.Source_List__c = origList.Id;
                newList.Account__c = acctId;
                newList.Opportunity__c = oppId;
                newList.Status__c = 'New';
                newList.Template__c = false;
                cloneMap.put(origList.Id, newList);
            }

            insert cloneMap.values();

            for(CSC_Action_Item__c origItem : (List<CSC_Action_Item__c>) Database.query(CloneUtility.getCSCActionItemBaseQuery() + ' WHERE CSC_Action_List__c IN :selectedIds ORDER BY CSC_Action_List__c, Order__c')) {
                CSC_Action_Item__c newItem = origItem.clone(false, true, false, false);
                CSC_Action_List__c newList = cloneMap.get(origItem.CSC_Action_List__c);
                newItem.CSC_Action_List__c = newList.Id;
                cloneItems.add(newItem);
            }

            Flags.SkipActionItemOrderResequencing = true;
            try {
                insert cloneItems;
            } finally {
                Flags.SkipActionItemOrderResequencing = false;
            }
        }

        return new PageReference('/' + (oppId != null ? oppId : acctId));
    }

    public class ActionList {
        public Boolean selected { get; set; }
        public Id listId { get; private set; }
        public String listName { get; private set; }
        public String libraryType { get; private set; }

        public ActionList(CSC_Action_List__c cscActionList) {
            selected = false;
            listId = cscActionList.Id;
            listName = cscActionList.Action_List_Name__c;
            libraryType = cscActionList.Library_Type__c;
        }
    }
}