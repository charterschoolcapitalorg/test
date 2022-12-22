//
// (c) 2014 Appirio, Inc.
//
// Test Class for FundingEstimate_InternalSummary.
//
//  9 JUNE 2014 Aditi Bhardwaj original.
//
//
@isTest
private class FundingEstimate_InternalSummaryTest {

    static testMethod void fundingEstimate_InternalSummaryTest() {
    	Test.startTest();

    	TestHelper.createCustomSettingToByPassTriggersAndRules('Account, RPA__c, Opportunity, Funding_Estimate_Receivable__c, Funding_Estimates__c, '+
																'Opp_School__c');

    	//Initialize Record Type.
      Map<String,RecordType> rtMap = TestHelper.createRecordTypeMap();
    	//Create School
      /*Account school = TestHelper.createAccountForRecordType((rtMap.get('School')).Id,'ABC School 1');


      RPA__c rpa = new RPA__c();
      rpa.Account__c = school.Id;
      insert rpa;

    	Opportunity opp = new Opportunity();
      opp.Name = 'opp';
      opp.CloseDate = Date.today().addDays(20);
      opp.StageName = 'Prospecting';
      opp.RPA__c = rpa.Id;
      opp.Funded_Date__c = System.today();
      opp.NET_Amount_Requested__c = 100;
      insert opp;*/

      Account school = TestHelper.createAccountForRecordType((rtMap.get('School')).Id,'ABC School 1');

      Account acc = TestHelper.createAccountForIndustryType('School');
		insert acc;

		Account RPAAccount = TestHelper.createRPAAccount(acc.Id);
		insert RPAAccount;


		RPA__c rpa = new RPA__c();
		rpa.Account__c = RPAAccount.Id;
		insert rpa;

		Opportunity opp = TestHelper.createOpportunity(acc, 'Test Opp');
		insert Opp;



      Opp_School__c oppSch = new Opp_School__C();
      oppSch.Opportunity__c = opp.Id;
     	oppSch.School__c = school.Id;
      insert oppSch;


      Funding_Estimates__c fundingEstimate = new Funding_Estimates__c();
      fundingEstimate.Opportunity__c = opp.Id;
      fundingEstimate.Discount__c = 7;
      fundingEstimate.Program_Fees_Collected__c = 12;
      fundingEstimate.Unpaid_Balance_Receivables_Collected__c = 50;
      fundingEstimate.Description_of_Unpaid_Balance_Receivable__c = 'description ';
      fundingEstimate.Application_Fee_Credit__c = 78;
      fundingEstimate.Penalty_Interest__c = 15;
      fundingEstimate.Blocked_Account_Fee_Collected__c = 100;
      fundingEstimate.Bond_or_Other_Payment__c = 123;
      fundingEstimate.Refund_Reimbursements__c = 20;
      fundingEstimate.Transaction_Fee__c = 10;
      fundingEstimate.Net_to_School__c = 200;

      insert fundingEstimate;

      Funding_Estimate_Receivable__c fundingEstimateReceivable = new Funding_Estimate_Receivable__c();
      fundingEstimateReceivable.Name = 'xyz';
      fundingEstimateReceivable.Purchase_Date__c = System.today();
      fundingEstimateReceivable.Maturity_Buffer__c = 4;
      fundingEstimateReceivable.Initial_Purchase_Factor__c = 2;
      fundingEstimateReceivable.Included_in_Estimate__c = true;
      fundingEstimateReceivable.GRV_Amount__c = 10;
      fundingEstimateReceivable.Expected_Pay_Date__c = System.today()+2;

      fundingEstimateReceivable.Funding_Estimate__c = fundingEstimate.Id;
      fundingEstimateReceivable.Opp_School__c = oppSch.id;
      insert fundingEstimateReceivable;

      PageReference pageRef = Page.FundingEstimate_InternalSummary;
      Test.setCurrentPage(pageRef);

       // Add parameters to page URL
       ApexPages.currentPage().getParameters().put('Id', fundingEstimate.Id);


    	FundingEstimate_InternalSummary fCalc  =  new FundingEstimate_InternalSummary();
    	System.assertNotEquals(fCalc.fundingEst, null);
    	System.assertNotEquals(fCalc.opp, null);

        Test.stopTest();


    }
}