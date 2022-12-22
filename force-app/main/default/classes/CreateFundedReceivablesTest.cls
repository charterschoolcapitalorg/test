/**=====================================================================
 * Appirio, Inc
 * Name: CreateFundedReceivablesTest
 * Description: [T-281129 "Create Funded Receivables" button and functionality]
 * Created Date: [05/22/2014]
 * Created By: [Rahul Agrawal] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
@isTest
private with sharing class CreateFundedReceivablesTest {

	static Opportunity opp;
	static List<Funding_Estimate_Receivable__c> listReceivable;
	static Funding_Estimates__c fundingEst;

	private static void createTestData(){
		TestHelper.createCustomSettingToByPassTriggersAndRules('Account, RPA__c, Opportunity, Funding_Estimate_Receivable__c, Funding_Estimates__c, '+
																'Opp_School__c');



		Account acc = TestHelper.createAccountForIndustryType('School');
		insert acc;

		Account RPAAccount = TestHelper.createRPAAccount(acc.Id);
		insert RPAAccount;


		RPA__c rpa = new RPA__c();
		rpa.Account__c = RPAAccount.Id;
		insert rpa;

		opp = TestHelper.createOpportunity(acc, 'Test Opp');
		opp.RPA__c = rpa.Id;
		opp.AccountId = acc.id;
		insert Opp;

		fundingEst = TestHelper.createFundingEstimate(opp.Id);
		insert fundingEst;

		Opp_School__c oppSchool = testHelper.createOppSchool(opp, acc);

		listReceivable = new list<Funding_Estimate_Receivable__c>();
		listReceivable.add(TestHelper.createFundingEstimateReceivable(fundingEst.Id, oppSchool.Id));
		listReceivable.add(TestHelper.createFundingEstimateReceivable(fundingEst.Id, oppSchool.Id));
		listReceivable.add(TestHelper.createFundingEstimateReceivable(fundingEst.Id, oppSchool.Id));
		insert listReceivable;
	}

	static testmethod void createFundedReceivablesTest(){
		Test.StartTest();
			createTestData();
			//Test.setCurrentPage(Page.FundingEstimateCalculator);
			system.debug(fundingEst);
			CreateFundedReceivables.wsCreateFundedReceivables(fundingEst.Id);

			list<Funded_Receivable__c> lst = [select id from Funded_Receivable__c where Source_Funding_Estimate_Receivable__c in: listReceivable];

			system.assertEquals(lst.size(), listReceivable.size());
		Test.StopTest();
	}

	static testmethod void testCreateFundedReceivableCtrlTest(){
		Test.StartTest();
			createTestData();
			//Test.setCurrentPage(Page.FundingEstimateCalculator);
			system.debug(fundingEst);
			CreateFundedReceivablesCtrl.createReceivables(fundingEst.Id);

		Test.StopTest();
		list<Funded_Receivable__c> lst = [select id from Funded_Receivable__c where Source_Funding_Estimate_Receivable__c in: listReceivable];
		system.assertEquals(lst.size(), listReceivable.size());
	}

	static testmethod void testCreateFundedReceivableCtrlGetterTest(){
		Test.StartTest();
			createTestData();
			//Test.setCurrentPage(Page.FundingEstimateCalculator);
			system.debug(fundingEst);
		Test.StopTest();
		Funding_Estimates__c estimate = CreateFundedReceivablesCtrl.getEstimate(fundingEst.Id);
		system.assertEquals(fundingEst.Id, estimate.Id);
	}


}