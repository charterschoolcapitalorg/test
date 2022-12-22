/**=====================================================================
 * Appirio, Inc
 * Manager Class Name: FundingEstimateReceivableTriggerManager
 * Description: Case :00001565 - Identify receivables being purchased on a weekend or holiday
 * Created Date:[09/09/2019]
 * Created By: Johnno
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
@isTest
private class FundingEstimateReceivableTriggerManTest {
	
	@testSetup static void createTestData() {
		
		//create test data
		TestHelper.createSeedDataForTesting();

		//get opp school
		Opp_School__c os = [Select Id from Opp_School__c limit 1];

		//create FE
		Funding_Estimates__c fe = new Funding_Estimates__c();
		insert fe;

		//create FE Receviables
		List<Funding_Estimate_Receivable__c> fers = new List<Funding_Estimate_Receivable__c>();
		for(Integer i = 0; i < 100; i++){
			Funding_Estimate_Receivable__c fer = new Funding_Estimate_Receivable__c();
			fer.Funding_Estimate__c = fe.Id;
			fer.Purchase_Date__c = Date.newInstance(2019, 09, 02);
			fer.Opp_School__c = os.Id;
			fers.add(fer);
		}
		insert fers;
	}

	@isTest static void testWorkingDays(){
		List<Funding_Estimate_Receivable__c> fers = new List<Funding_Estimate_Receivable__c>();
		fers = [Select Id, Purchase_Date__c from Funding_Estimate_Receivable__c];
		for(Funding_Estimate_Receivable__c fer : fers){
			fer.Purchase_Date__c = Date.newInstance(2019, 09, 04);
		}
		update fers;
		fers = [Select Id, Purchase_Date__c from Funding_Estimate_Receivable__c where Is_not_a_Business_Day__c = false];
		System.assertEquals(100, fers.size(), 'All should be holidays');
	}

	@isTest static void testHolidays(){
		List<Funding_Estimate_Receivable__c> fers = new List<Funding_Estimate_Receivable__c>();
		fers = [Select Id, Purchase_Date__c from Funding_Estimate_Receivable__c where Is_not_a_Business_Day__c = false];
		System.assertEquals(0, fers.size(), 'All should be holidays');
	}

	@isTest static void testWeekend(){
		List<Funding_Estimate_Receivable__c> fers = new List<Funding_Estimate_Receivable__c>();
		fers = [Select Id, Purchase_Date__c from Funding_Estimate_Receivable__c];
		for(Funding_Estimate_Receivable__c fer : fers){
			fer.Purchase_Date__c = Date.newInstance(2019, 09, 01);
		}
		update fers;
		fers = [Select Id, Purchase_Date__c from Funding_Estimate_Receivable__c where Is_not_a_Business_Day__c = false];
		System.assertEquals(0, fers.size(), 'All should be holidays');
	}

}