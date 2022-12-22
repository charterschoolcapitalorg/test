//
// (c) 2014 Appirio, Inc.
//
// A Test class for an OpportunityService class
//
//  April 10,  2014     Harshit Jain       Original
//
@isTest
private class OpportunityServiceTest {

    static testMethod void testOppStageUpdation() {
    	Action_List_Settings__c actionListSettings = new Action_List_Settings__c(
      SetupOwnerId = UserInfo.getOrganizationId(),
      Order_Threshold__c = 0);
	    insert actionListSettings;

	    BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
	                                            Triggers_Disabled__c = false,
	                                            Validation_Rules_Disabled__c = false,
	                                            Workflow_Rules_Disabled__c = false);
	    insert ProfileCustomSettings;

    	Account testAccount = CSCTestUtil.createAccount('Test Account 1');
      insert testAccount;

      Opportunity opportunity = CSCTestUtil.createOpportunity(testAccount.Id, 'Unit Test Opp', 'Stage 1 - Projected');
      insert opportunity;

      Test.startTest();
      String msg =  OpportunityService.updateOpportunityToClosedLost(opportunity.Id);
      system.assertNotEquals('', msg);
      Test.stopTest();

    }

    static testMethod void testOppStageOpen() {
      Action_List_Settings__c actionListSettings = new Action_List_Settings__c(
                                                                        SetupOwnerId = UserInfo.getOrganizationId(),
                                                                        Order_Threshold__c = 0);
      insert actionListSettings;

      BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
                                              Triggers_Disabled__c = false,
                                              Validation_Rules_Disabled__c = false,
                                              Workflow_Rules_Disabled__c = false);
      insert ProfileCustomSettings;

      Account testAccount = CSCTestUtil.createAccount('Test Account 1');
      insert testAccount;

      Opportunity opp = CSCTestUtil.createOpportunity(testAccount.Id, 'Unit Test Opp', 'Stage 1 - Projected');
      opp.Probability = 10;
      insert opp;
      system.debug(opp);

      String msg =  OpportunityService.updateOpportunityToClosedLost(opp.Id);
      Opportunity opp1 = ([Select Id, StageName, Probability from Opportunity where id = :opp.id]);
      System.debug(opp1);

      Test.startTest();
      msg =  OpportunityService.updateOpportunityFromClosedLost(opp1.Id);
      system.assertEquals('Stage has been successfully updated.', msg);
      Test.stopTest();

    }

    static testMethod void testOppStageNotChange() {
      Action_List_Settings__c actionListSettings = new Action_List_Settings__c(
                                                                        SetupOwnerId = UserInfo.getOrganizationId(),
                                                                        Order_Threshold__c = 0);
      insert actionListSettings;

      BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
                                              Triggers_Disabled__c = false,
                                              Validation_Rules_Disabled__c = false,
                                              Workflow_Rules_Disabled__c = false);
      insert ProfileCustomSettings;

      Account testAccount = CSCTestUtil.createAccount('Test Account 1');
      insert testAccount;

      Opportunity opp = CSCTestUtil.createOpportunity(testAccount.Id, 'Unit Test Opp', 'Stage 1 - Projected');
      opp.Probability = 10;
      insert opp;
      system.debug(opp);

      Test.startTest();
      String msg =  OpportunityService.updateOpportunityFromClosedLost(opp.Id);
      system.assertEquals('This opportunity is already open.', msg);
      Test.stopTest();
    }


}