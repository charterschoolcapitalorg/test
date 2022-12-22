/**=====================================================================
 * Name: OpportunityAddActionLists
 * Description: Test Class for OpportunityAddActionLists
 * Created Date: [12/18/2014]
 * Created By: [John Caughie]
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
@isTest
private class OpportunityAddActionListsTest {
  private static Account testAccount;
  private static Opportunity opportunity;


  static testMethod void testAddActionList() {
    Test.startTest();

      createTestData();
      opportunity = CSCTestUtil.createOpportunity(testAccount.Id, 'Unit Test Opp', 'Stage 1 - Projected');
      insert opportunity;

      ApexPages.StandardController sc = new ApexPages.StandardController(Opportunity);

      OpportunityAddActionLists oppAddLists = new OpportunityAddActionLists(sc);
      oppAddLists.addActionLists();

      //Assert to double the count as the opp insert trigger will add the Lists and the addACtionLists method will add them giving 2x the lists
      System.assertEquals(10, [Select Id From CSC_Action_List__c Where Opportunity__c =: opportunity.Id].size());

      update opportunity;

    Test.stopTest();
  }

  private static void createTestData() {
    //Custom Settings
    Action_List_Settings__c actionListSettings = new Action_List_Settings__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      Order_Threshold__c = 0
    );
    insert actionListSettings;

    BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
                                            Triggers_Disabled__c = false,
                                            Validation_Rules_Disabled__c = false,
                                            Workflow_Rules_Disabled__c = false);
    insert ProfileCustomSettings;


    testAccount = CSCTestUtil.createAccount('Test Account 1');
    insert testAccount;

    //Create Action List records
    CSC_Action_List__c actionList1 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 1 - Projected' ,'Finance', 1, true, true);
    CSC_Action_List__c actionList2 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 2 - Request' ,'Finance', 2, true, true);
    CSC_Action_List__c actionList3 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 3 - Review' ,'Finance', 3, true, true);
    CSC_Action_List__c actionList4 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 4 - Client Response' ,'Finance', 4, true, true);
    CSC_Action_List__c actionList5 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 5 - FC Review' ,'Finance', 5, true, true);
    Flags.SkipActionListOrderResequencing = true;
    insert new List<CSC_Action_List__c> { actionList1, actionList2, actionList3, actionList4, actionList5 };
    Flags.reset();


    //create Action List Items
    CSC_Action_Item__c item1 = CSCTestUtil.createActionItem(actionList1.Id, 1);
    CSC_Action_Item__c item2 = CSCTestUtil.createActionItem(actionList1.Id, 2);
    CSC_Action_Item__c item3 = CSCTestUtil.createActionItem(actionList1.Id, 3);
    CSC_Action_Item__c item4 = CSCTestUtil.createActionItem(actionList1.Id, 4);
    CSC_Action_Item__c item5 = CSCTestUtil.createActionItem(actionList1.Id, 5);
    CSC_Action_Item__c item6 = CSCTestUtil.createActionItem(actionList2.Id, 1);
    CSC_Action_Item__c item7 = CSCTestUtil.createActionItem(actionList2.Id, 2);
    CSC_Action_Item__c item8 = CSCTestUtil.createActionItem(actionList3.Id, 1);
    CSC_Action_Item__c item9 = CSCTestUtil.createActionItem(actionList3.Id, 2);
    CSC_Action_Item__c item10 = CSCTestUtil.createActionItem(actionList3.Id, 3);
    CSC_Action_Item__c item11 = CSCTestUtil.createActionItem(actionList4.Id, 1);
    CSC_Action_Item__c item12 = CSCTestUtil.createActionItem(actionList4.Id, 2);
    CSC_Action_Item__c item13 = CSCTestUtil.createActionItem(actionList4.Id, 3);
    CSC_Action_Item__c item14 = CSCTestUtil.createActionItem(actionList5.Id, 1);
    CSC_Action_Item__c item15 = CSCTestUtil.createActionItem(actionList5.Id, 2);
    Flags.SkipActionItemOrderResequencing = true;
    insert new List<CSC_Action_Item__c> { item1, item2, item3, item4, item5,item6, item7, item8, item9, item10,item11, item12, item13, item14, item15 };
    Flags.reset();

  }
}