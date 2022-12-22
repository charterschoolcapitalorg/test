@isTest
private class ActionListTests {
    private static State_Province__c state1;
    private static Account acct1, acct2;
    private static Opportunity opp;
    private static CSC_Action_List__c actionList1, actionList2, actionList3, actionList4, actionList5;
    private static CSC_Action_Item__c item1, item2, item3, item4, item5;
    private static Legal_Doc__c legal;
    private static RPA__c rpa;
    private static Terms_Letter__c tl;
    private static Resolution__c res;

    private static void setupActionListOrderTests() {
        setupBase();
        setupActionLists(false);
    }

    private static void setupActionItemOrderTests() {
        setupBase();
        setupActionLists(false);
        setupActionItems();
    }

    private static void setupAddActionListControllerTests(Boolean oppTests) {
        setupBase();
        actionList1 = createActionList(acct1, 'Finance', 1, true, oppTests);
        insert actionList1;
        setupActionItems();

        opp = new Opportunity(
            Name = 'Unit Test Opp',
            CloseDate = System.today(),
            StageName = 'Prospecting',
            AccountId = acct2.Id,
            RecordTypeId = RecordTypeUtils.OpportunityFOF.Id
        );
        insert opp;
    }

    private static void setupBase() {
        BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
                                            Triggers_Disabled__c = false,
                                            Validation_Rules_Disabled__c = false,
                                            Workflow_Rules_Disabled__c = false);
    insert ProfileCustomSettings;

        Action_List_Settings__c actionListSettings = new Action_List_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Order_Threshold__c = 50
        );
        insert actionListSettings;

        state1 = new State_Province__c(
            Name = 'CA',
            Active__c = true
        );
        insert state1;

        acct1 = new Account(
            Name = 'Unit Test Account 1',
            Catch_All__c = true
        );
        acct2 = new Account(
            Name = 'Unit Test Account 2',
            Operating_State__c = state1.Id
        );
        insert new List<Account> { acct1, acct2 };
    }

    private static void setupActionLists(Boolean fof) {
        actionList1 = createActionList(acct1, 'Finance', 1, false, fof);
        actionList2 = createActionList(acct1, 'Finance', 2, false, fof);
        actionList3 = createActionList(acct1, 'Finance', 3, false, fof);
        actionList4 = createActionList(acct1, 'Finance', 4, false, fof);
        actionList5 = createActionList(acct1, 'Finance', 5, false, fof);
        Flags.SkipActionListOrderResequencing = true;
        insert new List<CSC_Action_List__c> { actionList1, actionList2, actionList3, actionList4, actionList5 };
        Flags.reset();
    }

    private static void setupActionItems() {
        item1 = createActionItem(actionList1, 1);
        item2 = createActionItem(actionList1, 2);
        item3 = createActionItem(actionList1, 3);
        item4 = createActionItem(actionList1, 4);
        item5 = createActionItem(actionList1, 5);
        Flags.SkipActionItemOrderResequencing = true;
        insert new List<CSC_Action_Item__c> { item1, item2, item3, item4, item5 };
        Flags.reset();
    }

    private static CSC_Action_List__c createActionList(Account acct, String libType, Integer ord, Boolean template, Boolean fof) {
        return new CSC_Action_List__c(
            Action_List_Name__c = 'Prospecting',//'Unit Test Action List ' + ord,
            Account__c = acct.Id,
            Library_Type__c = libType,
            Status__c = 'New',
            Order__c = ord,
            Template__c = template,
            Opportunity_Record_Type__c = fof ? 'FOF' : ''
        );
    }

    private static CSC_Action_Item__c createActionItem(CSC_Action_List__c actionList, Integer ord) {
        return new CSC_Action_Item__c(
            CSC_Action_List__c = actionList.Id,
            Status__c = 'New',
            Order__c = ord
        );
    }

    private static CSC_Action_List__c loadActionList(Id listId) {
        return [SELECT Id, Account__c, Order__c FROM CSC_Action_List__c WHERE Id = :listId];
    }

    private static List<CSC_Action_List__c> loadActionLists(Id acctId) {
        return [SELECT Id, Account__c, Order__c, Source_List__c, Template__c, Opportunity__c FROM CSC_Action_List__c WHERE Account__c = :acctId];
    }


    private static CSC_Action_Item__c loadActionItem(Id itemId) {
        return [SELECT Id, CSC_Action_List__c, Order__c FROM CSC_Action_Item__c WHERE Id = :itemId];
    }

    private static List<CSC_Action_Item__c> loadActionItems(Id listId) {
        return [SELECT Id, CSC_Action_List__c, Order__c FROM CSC_Action_Item__c WHERE CSC_Action_List__c = :listId];
    }

    static testMethod void testMultipleActionListResequenceInsert() {
        setupActionListOrderTests();
        CSC_Action_List__c actionList6 = createActionList(acct1, 'Finance', 6, false, false);
        CSC_Action_List__c actionList7 = createActionList(acct1, 'Finance', 7, false, false);

        try {
            insert new List<CSC_Action_List__c> { actionList6, actionList7 };
            System.assert(false, 'This should have failed.');
        } catch(DmlException e) {}
    }

    static testMethod void testActionListInsertFirstItem() {
        setupBase();

        actionList1 = createActionList(acct1, 'Finance', CSCUtils.ActionListOrderThreshold - 1, false, false);
        insert actionList1;

        actionList1 = loadActionList(actionList1.Id);
        System.assertEquals(1, actionList1.Order__c);
    }

    static testMethod void testActionListInsertAboveThreshold() {
        setupActionListOrderTests();
        CSC_Action_List__c actionList6 = createActionList(acct1, 'Finance', CSCUtils.ActionListOrderThreshold + 1, false, false);
        insert actionList6;

        actionList6 = loadActionList(actionList6.Id);
        System.assert(actionList6.Order__c >= CSCUtils.ActionListOrderThreshold); // not testing a specific value because workflow can alter it
    }

    static testMethod void testActionListResequnceInsertFrontOfList() {
        setupActionListOrderTests();
        CSC_Action_List__c actionList6 = createActionList(acct1, 'Finance', 1, false, false);
        insert actionList6;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);
        actionList6 = listMap.get(actionList6.Id);

        System.assertEquals(2, actionList1.Order__c);
        System.assertEquals(3, actionList2.Order__c);
        System.assertEquals(4, actionList3.Order__c);
        System.assertEquals(5, actionList4.Order__c);
        System.assertEquals(6, actionList5.Order__c);
        System.assertEquals(1, actionList6.Order__c);
    }

    static testMethod void testActionListResequnceInsertMiddleOfList() {
        setupActionListOrderTests();
        CSC_Action_List__c actionList6 = createActionList(acct1, 'Finance', 3, false, false);
        insert actionList6;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);
        actionList6 = listMap.get(actionList6.Id);

        System.assertEquals(1, actionList1.Order__c);
        System.assertEquals(2, actionList2.Order__c);
        System.assertEquals(4, actionList3.Order__c);
        System.assertEquals(5, actionList4.Order__c);
        System.assertEquals(6, actionList5.Order__c);
        System.assertEquals(3, actionList6.Order__c);
    }

    static testMethod void testActionListResequnceInsertEndOfList() {
        setupActionListOrderTests();
        CSC_Action_List__c actionList6 = createActionList(acct1, 'Finance', CSCUtils.ActionListOrderThreshold - 1, false, false);
        insert actionList6;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);
        actionList6 = listMap.get(actionList6.Id);

        System.assertEquals(1, actionList1.Order__c);
        System.assertEquals(2, actionList2.Order__c);
        System.assertEquals(3, actionList3.Order__c);
        System.assertEquals(4, actionList4.Order__c);
        System.assertEquals(5, actionList5.Order__c);
        System.assertEquals(6, actionList6.Order__c);
    }

    static testMethod void testActionMultipleListResequenceUpdate() {
        setupActionListOrderTests();
        actionList1.Order__c = 2;
        actionList2.Order__c = 1;

        try {
            update new List<CSC_Action_List__c> { actionList1, actionList2 };
            System.assert(false, 'This should have failed.');
        } catch(DmlException e) {}
    }

    static testMethod void testActionListResequnceUpdateFromAboveThreshold() {
        setupActionListOrderTests();
        CSC_Action_List__c actionList6 = createActionList(acct1, 'Finance', CSCUtils.ActionListOrderThreshold + 1, false, false);
        insert actionList6;
        actionList6.Order__c = 1;
        update actionList6;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);
        actionList6 = listMap.get(actionList6.Id);

        System.assertEquals(2, actionList1.Order__c);
        System.assertEquals(3, actionList2.Order__c);
        System.assertEquals(4, actionList3.Order__c);
        System.assertEquals(5, actionList4.Order__c);
        System.assertEquals(6, actionList5.Order__c);
        System.assertEquals(1, actionList6.Order__c);
    }

    static testMethod void testActionListResequnceUpdateToAboveThreshold() {
        setupActionListOrderTests();
        actionList1.Order__c = CSCUtils.ActionListOrderThreshold;
        update actionList1;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);

        System.assert(actionList1.Order__c >= CSCUtils.ActionListOrderThreshold); // not testing a specific value because workflow can alter it
        System.assertEquals(1, actionList2.Order__c);
        System.assertEquals(2, actionList3.Order__c);
        System.assertEquals(3, actionList4.Order__c);
        System.assertEquals(4, actionList5.Order__c);
    }

    static testMethod void testActionListResequnceUpdateFrontOfList() {
        setupActionListOrderTests();
        actionList5.Order__c = 1;
        update actionList5;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);

        System.assertEquals(2, actionList1.Order__c);
        System.assertEquals(3, actionList2.Order__c);
        System.assertEquals(4, actionList3.Order__c);
        System.assertEquals(5, actionList4.Order__c);
        System.assertEquals(1, actionList5.Order__c);
    }

    static testMethod void testActionListResequnceUpdateMiddleOfList() {
        setupActionListOrderTests();
        actionList5.Order__c = 3;
        update actionList5;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);

        System.assertEquals(1, actionList1.Order__c);
        System.assertEquals(2, actionList2.Order__c);
        System.assertEquals(4, actionList3.Order__c);
        System.assertEquals(5, actionList4.Order__c);
        System.assertEquals(3, actionList5.Order__c);
    }

    static testMethod void testActionListResequnceUpdateEndOfList() {
        setupActionListOrderTests();
        actionList1.Order__c = 5;
        update actionList1;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);

        System.assertEquals(5, actionList1.Order__c);
        System.assertEquals(1, actionList2.Order__c);
        System.assertEquals(2, actionList3.Order__c);
        System.assertEquals(3, actionList4.Order__c);
        System.assertEquals(4, actionList5.Order__c);
    }

    static testMethod void testActionListResequnceDelete() {
        setupActionListOrderTests();
        delete actionList1;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);

        System.assertEquals(1, actionList2.Order__c);
        System.assertEquals(2, actionList3.Order__c);
        System.assertEquals(3, actionList4.Order__c);
        System.assertEquals(4, actionList5.Order__c);
    }

    static testMethod void testActionListResequnceUndelete() {
        setupActionListOrderTests();
        delete actionList1;
        undelete actionList1;

        Map<Id, CSC_Action_List__c> listMap = new Map<Id, CSC_Action_List__c>(loadActionLists(acct1.Id));
        actionList1 = listMap.get(actionList1.Id);
        actionList2 = listMap.get(actionList2.Id);
        actionList3 = listMap.get(actionList3.Id);
        actionList4 = listMap.get(actionList4.Id);
        actionList5 = listMap.get(actionList5.Id);

        System.assert(actionList1.Order__c >= CSCUtils.ActionListOrderThreshold); // not testing a specific value because workflow can alter it
        System.assertEquals(1, actionList2.Order__c);
        System.assertEquals(2, actionList3.Order__c);
        System.assertEquals(3, actionList4.Order__c);
        System.assertEquals(4, actionList5.Order__c);
    }

    static testMethod void testMultipleActionItemResequenceInsert() {
        setupActionItemOrderTests();
        CSC_Action_Item__c item6 = createActionItem(actionList1, 6);
        CSC_Action_Item__c item7 = createActionItem(actionList1, 7);

        try {
            insert new List<CSC_Action_Item__c> { item6, item7 };
            System.assert(false, 'This should have failed.');
        } catch(DmlException e) {}
    }

    static testMethod void testActionItemInsertFirstItem() {
        setupBase();
        setupActionLists(false);

        item1 = createActionItem(actionList1, CSCUtils.ActionListOrderThreshold - 1);
        insert item1;

        item1 = loadActionItem(item1.Id);
        System.assertEquals(1, item1.Order__c);
    }

    static testMethod void testActionItemInsertAboveThreshold() {
        setupActionItemOrderTests();
        CSC_Action_Item__c item6 = createActionItem(actionList1, CSCUtils.ActionListOrderThreshold + 1);
        insert item6;

        item6 = loadActionItem(item6.Id);
        System.assert(item6.Order__c >= CSCUtils.ActionListOrderThreshold); // not testing a specific value because workflow can alter it
    }

    static testMethod void testActionItemResequnceInsertFrontOfList() {
        setupActionItemOrderTests();
        CSC_Action_Item__c item6 = createActionItem(actionList1, 1);
        insert item6;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);
        item6 = itemMap.get(item6.Id);

        System.assertEquals(2, item1.Order__c);
        System.assertEquals(3, item2.Order__c);
        System.assertEquals(4, item3.Order__c);
        System.assertEquals(5, item4.Order__c);
        System.assertEquals(6, item5.Order__c);
        System.assertEquals(1, item6.Order__c);
    }

    static testMethod void testActionItemResequnceInsertMiddleOfList() {
        setupActionItemOrderTests();
        CSC_Action_Item__c item6 = createActionItem(actionList1, 3);
        insert item6;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);
        item6 = itemMap.get(item6.Id);

        System.assertEquals(1, item1.Order__c);
        System.assertEquals(2, item2.Order__c);
        System.assertEquals(4, item3.Order__c);
        System.assertEquals(5, item4.Order__c);
        System.assertEquals(6, item5.Order__c);
        System.assertEquals(3, item6.Order__c);
    }

    static testMethod void testActionItemResequnceInsertEndOfList() {
        setupActionItemOrderTests();
        CSC_Action_Item__c item6 = createActionItem(actionList1, CSCUtils.ActionListOrderThreshold - 1);
        insert item6;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);
        item6 = itemMap.get(item6.Id);

        System.assertEquals(1, item1.Order__c);
        System.assertEquals(2, item2.Order__c);
        System.assertEquals(3, item3.Order__c);
        System.assertEquals(4, item4.Order__c);
        System.assertEquals(5, item5.Order__c);
        System.assertEquals(6, item6.Order__c);
    }

    static testMethod void testActionMultipleItemResequenceUpdate() {
        setupActionItemOrderTests();
        item1.Order__c = 2;
        item2.Order__c = 1;

        try {
            update new List<CSC_Action_Item__c> { item1, item2 };
            System.assert(false, 'This should have failed.');
        } catch(DmlException e) {}
    }

    static testMethod void testActionItemResequnceUpdateFromAboveThreshold() {
        setupActionItemOrderTests();
        CSC_Action_Item__c item6 = createActionItem(actionList1, CSCUtils.ActionListOrderThreshold + 1);
        insert item6;
        item6.Order__c = 1;
        update item6;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);
        item6 = itemMap.get(item6.Id);

        System.assertEquals(2, item1.Order__c);
        System.assertEquals(3, item2.Order__c);
        System.assertEquals(4, item3.Order__c);
        System.assertEquals(5, item4.Order__c);
        System.assertEquals(6, item5.Order__c);
        System.assertEquals(1, item6.Order__c);
    }

    static testMethod void testActionItemResequnceUpdateToAboveThreshold() {
        setupActionItemOrderTests();
        item1.Order__c = CSCUtils.ActionListOrderThreshold;
        update item1;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);

        System.assert(item1.Order__c >= CSCUtils.ActionListOrderThreshold); // not testing a specific value because workflow can alter it
        System.assertEquals(1, item2.Order__c);
        System.assertEquals(2, item3.Order__c);
        System.assertEquals(3, item4.Order__c);
        System.assertEquals(4, item5.Order__c);
    }

    static testMethod void testActionItemResequnceUpdateFrontOfList() {
        setupActionItemOrderTests();
        item5.Order__c = 1;
        update item5;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);

        System.assertEquals(2, item1.Order__c);
        System.assertEquals(3, item2.Order__c);
        System.assertEquals(4, item3.Order__c);
        System.assertEquals(5, item4.Order__c);
        System.assertEquals(1, item5.Order__c);
    }

    static testMethod void testActionItemResequnceUpdateMiddleOfList() {
        setupActionItemOrderTests();
        item5.Order__c = 3;
        update item5;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);

        System.assertEquals(1, item1.Order__c);
        System.assertEquals(2, item2.Order__c);
        System.assertEquals(4, item3.Order__c);
        System.assertEquals(5, item4.Order__c);
        System.assertEquals(3, item5.Order__c);
    }

    static testMethod void testActionItemResequnceUpdateEndOfList() {
        setupActionItemOrderTests();
        item1.Order__c = 5;
        update item1;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);

        System.assertEquals(5, item1.Order__c);
        System.assertEquals(1, item2.Order__c);
        System.assertEquals(2, item3.Order__c);
        System.assertEquals(3, item4.Order__c);
        System.assertEquals(4, item5.Order__c);
    }

    static testMethod void testActionItemResequnceDelete() {
        setupActionItemOrderTests();
        delete item1;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);

        System.assertEquals(1, item2.Order__c);
        System.assertEquals(2, item3.Order__c);
        System.assertEquals(3, item4.Order__c);
        System.assertEquals(4, item5.Order__c);
    }

    static testMethod void testActionItemResequnceUndelete() {
        setupActionItemOrderTests();
        delete item1;
        undelete item1;

        Map<Id, CSC_Action_Item__c> itemMap = new Map<Id, CSC_Action_Item__c>(loadActionItems(actionList1.Id));
        item1 = itemMap.get(item1.Id);
        item2 = itemMap.get(item2.Id);
        item3 = itemMap.get(item3.Id);
        item4 = itemMap.get(item4.Id);
        item5 = itemMap.get(item5.Id);

        System.assert(item1.Order__c >= CSCUtils.ActionListOrderThreshold); // not testing a specific value because workflow can alter it
        System.assertEquals(1, item2.Order__c);
        System.assertEquals(2, item3.Order__c);
        System.assertEquals(3, item4.Order__c);
        System.assertEquals(4, item5.Order__c);
    }

    static testMethod void testAddActionListControllerNoOpp() {
        setupAddActionListControllerTests(false);

        PageReference pr = Page.AddActionList;
        Map<String, String> paramMap = pr.getParameters();
        paramMap.put('id', acct2.Id);
        paramMap.put('state', '1');
        paramMap.put('catchall', '0');
        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(acct2);
        AddActionListController controller = new AddActionListController(stdController);
        controller.init();
        System.assertNotEquals(null, controller.actionLists);
       // System.assertEquals(0, controller.actionLists.size());

        //controller.actionLists.get(0).selected = true;
        controller.save();

        /*
        List<CSC_Action_List__c> clonedLists = loadActionLists(acct2.Id);
        System.assertEquals(1, clonedLists.size());

        CSC_Action_List__c clonedList = clonedLists.get(0);
        System.assertEquals(false, clonedList.Template__c);
        System.assertNotEquals(actionList1.Id, clonedList.Id);
        System.assertEquals(actionList1.Id, clonedList.Source_List__c);

        List<CSC_Action_Item__c> clonedItems = loadActionItems(clonedList.Id);
        System.assertEquals(5, clonedItems.size());
        */
    }

    static testMethod void testAddActionListControllerWithOpp() {
        setupAddActionListControllerTests(true);

        PageReference pr = Page.AddActionList;
        Map<String, String> paramMap = pr.getParameters();
        paramMap.put('id', acct2.Id);
        paramMap.put('oppId', opp.Id);
        paramMap.put('state', '1');
        paramMap.put('catchall', '0');
        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(acct2);
        AddActionListController controller = new AddActionListController(stdController);
        controller.init();
        System.assertNotEquals(null, controller.actionLists);
        System.assertEquals(1, controller.actionLists.size());

        controller.actionLists.get(0).selected = true;
        controller.save();

        List<CSC_Action_List__c> clonedLists = loadActionLists(acct2.Id);
        System.assertEquals(2, clonedLists.size());

        CSC_Action_List__c clonedList = clonedLists.get(0);
        System.assertEquals(false, clonedList.Template__c);
        System.assertNotEquals(actionList1.Id, clonedList.Id);
        System.assertEquals(actionList1.Id, clonedList.Source_List__c);
        System.assertEquals(opp.Id, clonedList.Opportunity__c);

        List<CSC_Action_Item__c> clonedItems = loadActionItems(clonedList.Id);
        System.assertEquals(5, clonedItems.size());
    }

    // 2020.05.06 J Caughie - Removing attachment trigger
    // static testMethod void testAttachmentToContent() {
    //     setupActionItemOrderTests();
    //     Attachment attach = new Attachment(
    //         Name = 'Unit Test Attachment',
    //         ParentId = item1.Id,
    //         Body = Blob.valueOf('Q: What do black holes and making up unit test data have in common?\nA: They both suck!'),
    //         ContentType = 'text/plain'
    //     );
    //     Test.startTest();
    //     insert attach;
    //     Test.stopTest();

    //     List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :item1.Id];
    //     System.assertEquals(0, attachments.size());

    //     List<ContentVersion> contentVers = [SELECT Id FROM ContentVersion WHERE CSC_Action_Item__c = :item1.Id];
    //     System.assertEquals(1, contentVers.size());
    // }

    // 2016.07.26 J Caughie - split test method to test other scenarios

    /*static testMethod void testAddContent() {
        setupActionItemOrderTests();
        ContentVersion ver = new ContentVersion(
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Q: What do black holes and making up unit test data have in common?\nA: They both suck!')
        );

        PageReference pr = Page.AddContent;
        Map<String, String> paramMap = pr.getParameters();
        paramMap.put('aiid', item1.Id);
        paramMap.put('alid', actionList1.Id);
        paramMap.put('aid', actionList1.Account__c);
        paramMap.put('lt', actionList1.Library_Type__c);
        paramMap.put('saveURL', EncodingUtil.urlEncode('/' + item1.Id, 'UTF-8'));
        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(ver);
        AddContentController controller = new AddContentController(stdController);
        controller.init();
        controller.save();

        List<ContentVersion> contentVers = [SELECT Id FROM ContentVersion WHERE CSC_Action_Item__c = :item1.Id];
        System.assertEquals(1, contentVers.size());
    }*/

    static testMethod void testContentActionListLookup() {
        setupActionItemOrderTests();
        item1 = [SELECT Id, CSC_Action_List__c FROM CSC_Action_Item__c WHERE Id = :item1.Id];
        System.assertNotEquals(null, item1.CSC_Action_List__c);

		// 06/20/2014 : Manisha Gupta : Modifying to fix test failure
        //ContentWorkspace workspace = [SELECT Id, Name FROM ContentWorkspace WHERE Name = 'Underwriting'];

        list<ContentWorkspace> workspaceList = [SELECT Id, Name FROM ContentWorkspace WHERE Name = 'Underwriting'];
		if(!workspaceList.isEmpty()){
			ContentWorkspace workspace = workspaceList[0];
	        ContentVersion ver = new ContentVersion(
	            FirstPublishLocationId = workspace.Id,
	            PathOnClient = 'test.txt',
	            VersionData = Blob.valueOf('Q: What do black holes and making up unit test data have in common?\nA: They both suck!'),
	            Related_Action_Item__c = item1.Id
	        );
	        insert ver;

	        ver = [SELECT Id, Related_Action_List__c FROM ContentVersion WHERE Id = :ver.Id];
	        System.assertEquals(item1.CSC_Action_List__c, ver.Related_Action_List__c);
		}

    }

    //2016.07.26 J Caughie - added additional test for other record types and removed code adding helper classes

    private static PageReference testAddingContentHelper(String contentType){
        
        PageReference pr = Page.AddContent;
        Map<String, String> paramMap = pr.getParameters();
        if(contentType == 'Action Item'){
            paramMap.put('aiid', item1.Id);
        }
        if(contentType == 'Opportunity'){
            paramMap.put('oid', opp.Id);
        }
        if(contentType == 'Legal Doc'){
            paramMap.put('ldid', legal.Id);
        }
        if(contentType == 'RPA'){
            paramMap.put('rpaid', rpa.Id);
        }
        if(contentType == 'Terms Letter'){
            paramMap.put('tlid', tl.Id);
        }
        if(contentType == 'Resolution'){
            paramMap.put('rid', res.Id);
        }
        paramMap.put('alid', actionList1.Id);
        paramMap.put('aid', actionList1.Account__c);
        paramMap.put('lt', actionList1.Library_Type__c);
        paramMap.put('saveURL', EncodingUtil.urlEncode('/' + item1.Id, 'UTF-8'));
        return pr;

    }

    private static ContentVersion addContentHelper(){

        ContentVersion ver = new ContentVersion(
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Q: What do black holes and making up unit test data have in common?\nA: They both suck!')
        );
        return ver;
    }

    static testMethod void testAddContentActionItem() {
        setupActionItemOrderTests();
        ContentVersion ver = addContentHelper();
        PageReference pr = testAddingContentHelper('Action Item');

        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(ver);
        AddContentController controller = new AddContentController(stdController);
        controller.init();
        controller.save();

        List<ContentVersion> contentVers = [SELECT Id FROM ContentVersion WHERE CSC_Action_Item__c = :item1.Id];
        System.assertEquals(1, contentVers.size());
        System.assertEquals(1, controller.getListContent().size(), 'There may only be one!');
    }    

    static testMethod void testAddContentOpportunity() {
        setupAddActionListControllerTests(False);
        ContentVersion ver = addContentHelper();
        PageReference pr = testAddingContentHelper('Opportunity');

        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(ver);
        AddContentController controller = new AddContentController(stdController);
        controller.init();
        controller.save();

        List<ContentVersion> contentVers = [SELECT Id FROM ContentVersion WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, contentVers.size());
        System.assertEquals(1, controller.getListContent().size(), 'There may only be one!');
    } 

    static testMethod void testAddContentLegalDoc() {
        setupActionItemOrderTests();
        acct1 = new Account(Name = 'Unit Test Account 1');
        insert acct1;
        legal = new Legal_Doc__c(Account__c = acct1.Id);
        insert legal;
        ContentVersion ver = addContentHelper();
        PageReference pr = testAddingContentHelper('Legal Doc');

        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(ver);
        AddContentController controller = new AddContentController(stdController);
        controller.init();
        controller.save();

        List<ContentVersion> contentVers = [SELECT Id FROM ContentVersion WHERE Legal_Doc__c = :legal.Id];
        System.assertEquals(1, contentVers.size());
        System.assertEquals(1, controller.getListContent().size(), 'There may only be one!');
    } 

    static testMethod void testAddContentRPA() {
        setupActionItemOrderTests();
        acct1 = new Account(Name = 'Unit Test Account 1');
        insert acct1;
        rpa = new RPA__c(Account__c = acct1.Id);
        insert rpa;
        ContentVersion ver = addContentHelper();
        PageReference pr = testAddingContentHelper('RPA');

        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(ver);
        AddContentController controller = new AddContentController(stdController);
        controller.init();
        controller.save();

        List<ContentVersion> contentVers = [SELECT Id FROM ContentVersion WHERE RPA__c = :rpa.Id];
        System.assertEquals(1, contentVers.size());
        System.assertEquals(1, controller.getListContent().size(), 'There may only be one!');
    }

    static testMethod void testAddContentTL() {
        setupActionItemOrderTests();
        acct1 = new Account(Name = 'Unit Test Account 1');
        insert acct1;
        rpa = new RPA__c(Account__c = acct1.Id);
        insert rpa;
        tl = new Terms_Letter__c(RPA__c = rpa.Id);
        insert tl;
        ContentVersion ver = addContentHelper();
        PageReference pr = testAddingContentHelper('Terms Letter');

        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(ver);
        AddContentController controller = new AddContentController(stdController);
        controller.init();
        controller.save();

        List<ContentVersion> contentVers = [SELECT Id, RPA__c, Terms_Letter__c FROM ContentVersion WHERE Terms_Letter__c = :tl.Id];
        System.assertEquals(1, contentVers.size());
        System.assertEquals(1, controller.getListContent().size(), 'There may only be one!');
    }

    static testMethod void testAddContentResolution() {
        setupActionItemOrderTests();
        acct1 = new Account(Name = 'Unit Test Account 1');
        insert acct1;
        res = new Resolution__c(School__c = acct1.Id);
        res.Status__c = 'Active';
        insert res;
        ContentVersion ver = addContentHelper();
        PageReference pr = testAddingContentHelper('Resolution');

        Test.setCurrentPage(pr);
        ApexPages.StandardController stdController = new ApexPages.StandardController(ver);
        AddContentController controller = new AddContentController(stdController);
        controller.init();
        controller.save();

        List<ContentVersion> contentVers = [SELECT Id FROM ContentVersion WHERE Resolution__c = :res.Id];
        System.assertEquals(1, contentVers.size());
        System.assertEquals(1, controller.getListContent().size(), 'There may only be one!');
    }

}