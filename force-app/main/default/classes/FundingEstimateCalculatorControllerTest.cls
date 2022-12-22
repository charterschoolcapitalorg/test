/**=====================================================================
 * Appirio, Inc
 * Name: FundingEstimateCalculatorControllerTest
 * Description: T-269750: Funding Estimate Tool - First Jaipur Spec
 * Created Date: [04/11/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
public with sharing class FundingEstimateCalculatorControllerTest {
	static Opportunity opp;
	static List<Funding_Estimate_Receivable__c> listReceivable;
	static Funding_Estimates__c fundingEst;


	static testmethod void createFundingEstimateRecordTest(){
		Test.StartTest();
			createTestData();
			//Test.setCurrentPage(Page.FundingEstimateCalculator);
			system.debug(fundingEst);
			ApexPages.StandardController stdController = new ApexPages.StandardController(fundingEst);
			FundingEstimateCalculatorController controller = new FundingEstimateCalculatorController(null);
			system.assert(controller.FundingEst.Id == null);

			controller = new FundingEstimateCalculatorController(stdController);

			system.assert(controller.FundingEst.Id <> null);
			system.assertEquals(listReceivable.size(), controller.listFER.size());

			for(Funding_Estimate_Receivable__c fer : controller.listFER){
				fer.Included_In_Estimate__c = false;
			}
			controller.NextOnStep1();

			system.assert(controller.listFER_Step2.size() == 0);


			for(Funding_Estimate_Receivable__c fer : controller.listFER){
				fer.Included_In_Estimate__c = true;
			}
			controller.NextOnStep1();

			system.assert(controller.listFER_Step2.size() <> 0);
			controller.fundingEst.Discount__c = 50.00;
			controller.fundingEst.Transaction_Fee__c = 25.00;
			controller.NextOnStep2();

			system.assert(controller.listFER_Step3.size() <> 0);
			system.assert(fundingEst.Discount__c == 50.00);
			system.assert(fundingEst.Transaction_Fee__c == 25.00);
			controller.PreviousOnStep2();
			controller.saveOnStep1();
			controller.saveOnStep2();
			controller.saveOnStep3();
			controller.saveAndGenerateInternalSummary();
			controller.PreviousOnStep3();

		Test.StopTest();
	}

	private static void createTestData() {
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
}