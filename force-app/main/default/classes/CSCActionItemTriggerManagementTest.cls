// Created by
// (c) 2014 Appirio, Inc.
//
// Test class for CSCActionItemTriggerManagement
//
//  Eddited:
//  April 07,  2014     Harshit Jain       Original
//  Nov 3, 2022         Slava Krel         Opp Notifications
//  Nov 29, 2022        Slava Krel         api version update
//  Nov 29, 2022        Slava Krel         @isTest
//  Nov 29, 2022        Slava Krel         testPipelineStatus() method added

@isTest
private class CSCActionItemTriggerManagementTest {
    private static Account testAccount;
    private static Opportunity opportunity;
    private static CSC_Action_List__c actionList1, actionList2, actionList3, actionList4, actionList5;
    private static CSC_Action_Item__c item1,item2,item3,item4,item5,item6,item7,item8,item9,item10,item11,item12,item13,item14,item15;
    private static User u1, u2;
    private static Contact con;

    @isTest
    public static void myUnitTest() {
        createTestData();
        List<CSC_Action_List__c> actionList = [Select Id From CSC_Action_List__c Where Opportunity__c =: opportunity.Id order by Action_List_Name__c];
        List<CSC_Action_Item__c> actionItemList = [Select Id From CSC_Action_Item__c Where CSC_Action_List__c =:actionList.get(0).Id];

        Test.startTest();
            actionItemList.get(0).Status__c = 'Completed';
            actionItemList.get(0).Assigned_To__c = u1.Id;
            actionItemList.get(0).Date_Completed__c = Date.today();
            update actionItemList.get(0);

            system.assertEquals('Stage 2 - Request', [Select Id, StageName From Opportunity Where Id =:opportunity.Id].StageName);
        Test.stopTest();
    }

    @isTest
    public static void testExpiredEmail() {
        createTestData();
        List<CSC_Action_List__c> actionList = [Select Id From CSC_Action_List__c Where Opportunity__c =: opportunity.Id order by Action_List_Name__c];
        List<CSC_Action_Item__c> actionItemList = [Select Id From CSC_Action_Item__c Where CSC_Action_List__c =:actionList.get(0).Id];

        Test.startTest();
            actionItemList.get(0).IsSendTimeBasedNotification__c = true;
            update actionItemList.get(0);

            system.assertEquals(false, [Select Id, IsSendTimeBasedNotification__c From CSC_Action_Item__c Where Id =:actionItemList.get(0).Id].IsSendTimeBasedNotification__c);
        Test.stopTest();
    }

    //2015.06.24 J Caughie - Test for email notification
    @isTest
    public static void testSendEmail() {
        createTestData();
        List<CSC_Action_List__c> actionList = [Select Id From CSC_Action_List__c Where Opportunity__c =: opportunity.Id order by Action_List_Name__c];
        List<CSC_Action_Item__c> actionItemList = [Select Id, Opportunity_Notifications__c, Status__c, RecordTypeId, Assigned_To__c, Date_Completed__c, Opp_Paralegal_Record__c From CSC_Action_Item__c Where CSC_Action_List__c =:actionList.get(0).Id];

        CSC_Action_Item__c testItem = new CSC_Action_Item__c();
        testItem = actionItemList.get(0);

        opportunity.Paralegal__c = u2.Id;
        update opportunity;

        testItem.Opportunity_Notifications__c = 'Paralegal';
        testItem.RecordTypeId = RecordTypeUtils.CSCActionItemSalesProcess.Id;
        testItem.Assigned_To__c = u1.Id;
        testItem.Date_Completed__c = Date.today();
        update testItem;
        
        testItem = [SELECT Id, Opportunity_Notifications__c, Status__c, RecordTypeId, Assigned_To__c, Date_Completed__c, Opp_Paralegal_Record__c, CSC_Action_List__r.Opportunity__r.Paralegal__c 
                    FROM CSC_Action_Item__c 
                    WHERE CSC_Action_List__c =:actionList.get(0).Id];
        testItem.Status__c = 'Completed';

        Test.startTest();
            update testItem;
        Test.stopTest();
    }

    @isTest
    public static void testDueDate(){
        createTestData();
        CSC_Action_Item__c ai = new CSC_Action_Item__c();
        ai = [SELECT Id, Opp_Close_Date_Hidden__c, Item_Status__c, Business_Days_Due_Before_Close__c, Delay_Alert_On__c, RecordTypeId, Opp_Closed_HIDDEN_AI__c, Item_Due_Date__c FROM CSC_Action_Item__c LIMIT 1];
        Test.startTest();
        ai.Opp_Close_Date_Hidden__c = Date.newInstance(2018, 7, 5);
        ai.Business_Days_Due_Before_Close__c = 2;
        update ai;
        Test.stopTest();
        ai = [SELECT Id, Opp_Close_Date_Hidden__c, Item_Status__c, Business_Days_Due_Before_Close__c, Delay_Alert_On__c, RecordTypeId, Opp_Closed_HIDDEN_AI__c, Item_Due_Date__c FROM CSC_Action_Item__c LIMIT 1];
        Date expectedDueDate = Date.newInstance(2018, 07, 2);
        System.assertEquals(expectedDueDate, ai.Item_Due_Date__c, 'Due date is incorrect!');
    } 

    @isTest
    public static void testBulkDueDate(){
        createTestData();
        List<CSC_Action_Item__c> aiList = new List<CSC_Action_Item__c>();
        aiList = [SELECT Id, Opp_Close_Date_Hidden__c, Item_Status__c, Business_Days_Due_Before_Close__c, Delay_Alert_On__c, RecordTypeId, Opp_Closed_HIDDEN_AI__c, Item_Due_Date__c FROM CSC_Action_Item__c];
        for(CSC_Action_Item__c ai : aiList){
            ai.Opp_Close_Date_Hidden__c = Date.newInstance(2018, 7, 5);
            ai.Business_Days_Due_Before_Close__c = 2;
        }
        Test.startTest();
        update aiList;
        Test.stopTest();
        CSC_Action_Item__c ai = [SELECT Id, Opp_Close_Date_Hidden__c, Item_Status__c, Business_Days_Due_Before_Close__c, Delay_Alert_On__c, RecordTypeId, Opp_Closed_HIDDEN_AI__c, Item_Due_Date__c FROM CSC_Action_Item__c LIMIT 1];
        Date expectedDueDate = Date.newInstance(2018, 07, 2);
        System.assertEquals(expectedDueDate, ai.Item_Due_Date__c, 'Due date is incorrect!');
    } 

    private static void createTestData() {
        //Custom Settings
        Action_List_Settings__c actionListSettings = new Action_List_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(),Order_Threshold__c = 0);
        insert actionListSettings;

        BypassRulesandTriggers__c ProfileCustomSettings = 
            new BypassRulesandTriggers__c ( Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
                                            Triggers_Disabled__c = false,
                                            Validation_Rules_Disabled__c = false,
                                            Workflow_Rules_Disabled__c = false);
        insert ProfileCustomSettings;

        //2017.04.06 - J Caughie - added State/Province to Account
        State_Province__c state = new State_Province__c(Name = 'CA', State_Name__c = 'California');
        insert state;

        testAccount = CSCTestUtil.createAccount('Test Account 1');
        testAccount.Operating_State__c = state.Id;//2017.04.06 - J Caughie - added State/Province to Account
        insert testAccount;

        //Create Action List records
        actionList1 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 1 - Projected' ,'Finance', 1, true, true);
        actionList2 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 2 - Request' ,'Finance', 2, true, true);
        actionList3 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 3 - Review' ,'Finance', 3, true, true);
        actionList4 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 4 - Client Response' ,'Finance', 4, true, true);
        actionList5 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 5 - FC Review' ,'Finance', 5, true, true);
        Flags.SkipActionListOrderResequencing = true;
        insert new List<CSC_Action_List__c> { actionList1, actionList2, actionList3, actionList4, actionList5 };
        Flags.reset();

        //create Action List Items
        item1 = CSCTestUtil.createActionItem(actionList1.Id, 1);
        item2 = CSCTestUtil.createActionItem(actionList2.Id, 2);
        item3 = CSCTestUtil.createActionItem(actionList2.Id, 3);
        item4 = CSCTestUtil.createActionItem(actionList2.Id, 4);
        item5 = CSCTestUtil.createActionItem(actionList2.Id, 5);
        item6 = CSCTestUtil.createActionItem(actionList3.Id, 1);
        item7 = CSCTestUtil.createActionItem(actionList3.Id, 2);
        item8 = CSCTestUtil.createActionItem(actionList3.Id, 1);
        item9 = CSCTestUtil.createActionItem(actionList3.Id, 2);
        item10 = CSCTestUtil.createActionItem(actionList3.Id, 3);
        item11 = CSCTestUtil.createActionItem(actionList4.Id, 1);
        item12 = CSCTestUtil.createActionItem(actionList4.Id, 2);
        item13 = CSCTestUtil.createActionItem(actionList4.Id, 3);
        item14 = CSCTestUtil.createActionItem(actionList5.Id, 1);
        item15 = CSCTestUtil.createActionItem(actionList5.Id, 2);
        Flags.SkipActionItemOrderResequencing = true;
        insert new List<CSC_Action_Item__c> { item1, item2, item3, item4, item5,item6, item7, item8, item9, item10,item11, item12, item13, item14, item15 };
        Flags.reset();

        opportunity = CSCTestUtil.createOpportunity(testAccount.Id, 'Unit Test Opp', 'Stage 1 - Projected');
        opportunity.User__c = Userinfo.getUserId();
        insert opportunity;

        //Create users for send email test
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        u1 = CSCTestUtil.createUser('Unit1', 'Caughie', 'caughie.csc+unittest1@gmail.com', 'UT1', prof.Id);
        u2 = CSCTestUtil.createUser('Unit2', 'Test2', 'caughie.csc+unittest2@gmail.com', 'UT2', prof.Id);
        insert new List<User> { u1, u2 };

        con = new Contact();
        con.LastName = 'Caughie';
        con.Email = 'caughie.csc+unittest3@gmail.com';
        insert con;
    }
    
    @isTest
    public static void testPipelineStatus() {
        
        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');

        Set<String> oppIds = new Set<String>();

		//create account
		Account acctWon = new Account();
		acctWon.name = 'Test Acct Won';
		insert acctWon;
        
        //create opportunity Tenant/School Won
        Opportunity oppTenantWon = new Opportunity();
        oppTenantWon.name = 'Test OppTenantWon';
        oppTenantWon.StageName = 'Stage 3 - Review';
        oppTenantWon.accountId = acctWon.id;
        oppTenantWon.CloseDate = System.today();
        oppTenantWon.Facilities_Channel__c = 'Tenant/School';
        oppTenantWon.Estimated_Project_Cost__c = 100;
        insert oppTenantWon;

        oppIds.add(oppTenantWon.id);

        //create Action Lists Tenant Won
        CSC_Action_List__c actionListTenantWon = new CSC_Action_List__c();
        actionListTenantWon.Action_List_Name__c = 'List Name Tenant Won';
        actionListTenantWon.Account__c = acctWon.Id;
        actionListTenantWon.Opportunity__c = oppTenantWon.Id;
        actionListTenantWon.Library_Type__c = 'Underwriting';
        actionListTenantWon.Status__c = 'New';
        actionListTenantWon.Order__c = 1;
        actionListTenantWon.Template__c = false;
        actionListTenantWon.Opportunity_Record_Type__c = 'FOF';
        insert actionListTenantWon;
        
        //create Action Items Tenant Won
        List<CSC_Action_Item__c> itemsTenantWon = new List<CSC_Action_Item__c>();
        for(Integer i = 0; i < 11; i++){
            CSC_Action_Item__c item = CSCTestUtil.createActionItem(actionListTenantWon.Id, i);
            switch on i{
                when 0 {item.Action_Item_Name__c = 'Approve Phase 1 Opportunity';}
                when 1 {item.Action_Item_Name__c = 'FC Pre-Approval Prepared and Presented';}
                when 2 {item.Action_Item_Name__c = 'Deliver LOI to Seller';}
                when 3 {item.Action_Item_Name__c = 'Sign LOI';}
                when 4 {item.Action_Item_Name__c = 'Deliver Lease Proposal (MOU)';}
                when 5 {item.Action_Item_Name__c = 'Receive Lease Proposal (MOU) Approval';}
                when 6 {item.Action_Item_Name__c = 'Sign PSA';}
                when 7 {item.Action_Item_Name__c = 'Sign Lease';}
                when 8 {item.Action_Item_Name__c = 'Present Opportunity and Receive Final FC Approval';}
                when 9 {item.Action_Item_Name__c = 'Waive Diligence';}
                when else {
                    item.Action_Item_Name__c = 'Fund Acquisition';
                    item.Status__c = 'Completed';
                }
            }
            itemsTenantWon.add(item);
        }
        insert itemsTenantWon;

        CSC_Action_Item__c ai = [SELECT Id, Name, Action_Item_Name__c, Comments__c FROM CSC_Action_Item__c WHERE Action_Item_Name__c = 'Approve Phase 1 Opportunity' LIMIT 1];
        ai.Comments__c = 'comment';
        
        Test.startTest();
        update ai;
        CSCActionItemTriggerManagement.validateOpportunityPipelineStatus(oppIds);
        Test.stopTest();
    }
}