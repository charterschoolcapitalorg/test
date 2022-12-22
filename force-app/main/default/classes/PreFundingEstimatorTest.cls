@isTest
private class PreFundingEstimatorTest {
	
	@testSetup static void setup() {
        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity');

		Account acc = new Account();
		acc.Name = 'Test School';
		insert acc;
		System.debug(acc);

		State_Province__c state = new State_Province__c();
		state.Name = 'OH';
		state.Annual_Funding_FTE__c = 6000;
		state.PreFE_Tool_Available__c = true;
		state.FE_Advance_Rate__c = 0.75;
		state.FE_Discount_Rate__c = 0.07;
		state.FE_Repayment_Day_of_Month__c = '15';
		state.FE_Repayment_Month_Ahead__c = '0';
		insert state;

		Opportunity opp = new Opportunity();
		opp.Name = 'Test Opp';
		opp.CloseDate = Date.today();
		opp.StageName = 'Stage 1';
		opp.AccountId = acc.Id;
		opp.RecordTypeId = RecordTypeUtils.OpportunityFOF.Id;
		insert opp;

    }


	static testmethod void installmentTest() {		

		Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];

		Pre_Funding_Estimate__c pf = new Pre_Funding_Estimate__c();
		pf.State__c = 'OH';
		pf.Transaction_Type__c = 'Receivable Purchase';
		pf.Installments__c = 2;
		pf.Program_Fee_Rate__c = 0;
		pf.Transaction_Fee_Rate__c = 0;
		pf.Target_Effective_Rate__c = 12;
		pf.State_Rate__c = 6000;
		pf.Advance_Rate__c = 0.75;
		pf.Discount_Rate__c = 0.07;
		pf.Installment_Month_Offset__c = 0;
		pf.Installment_Payment_Date__c = 15;
		pf.Funding_Date__c = Date.newInstance(2018, 10, 16);
		pf.Student_Count__c = 237;
		pf.Opportunity__c = opp.Id;

		System.debug('js'+ JSON.serialize(pf));
		Test.startTest();	
			List<Pre_FE_Installment__c> installments = PreFundingEstimator.getInstallments(JSON.serialize(pf));
		Test.stopTest();
		System.debug(installments);
		System.assertEquals(2, installments.size(), 'Incorrect number of installments');
		System.assertEquals('December, 2018', installments[0].Name__c, 'Should be December');	
 
	}


	static testmethod void saveTest(){
		
		Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];

		Pre_Funding_Estimate__c pf = new Pre_Funding_Estimate__c();
		pf.State__c = 'OH';
		pf.Transaction_Type__c = 'Receivable Purchase';
		pf.Installments__c = 2;
		pf.Program_Fee_Rate__c = 0;
		pf.Transaction_Fee_Rate__c = 0;
		pf.Target_Effective_Rate__c = 12;
		pf.State_Rate__c = 6000;
		pf.Advance_Rate__c = 0.75;
		pf.Discount_Rate__c = 0.07;
		pf.Installment_Month_Offset__c = 0;
		pf.Installment_Payment_Date__c = 15;
		pf.Funding_Date__c = Date.newInstance(2018, 10, 16);
		pf.Student_Count__c = 237;
		pf.Opportunity__c = opp.Id;

		Test.startTest();
			String result = PreFundingEstimator.saveRecords(opp.Id, JSON.serialize(pf));
		Test.stopTest();
		Pre_Funding_Estimate__c insertedPFE = [SELECT id FROM Pre_Funding_Estimate__c];
		System.assertEquals(insertedPFE.Id, result, 'Incorrect record Id');

		List<Pre_FE_Installment__c> installs = [SELECT Id FROM Pre_FE_Installment__c];
		System.assertEquals(2, installs.size(), 'Two should have been inserted');

	}




}