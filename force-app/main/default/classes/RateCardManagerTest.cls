/**=====================================================================
 * Appirio, Inc
 * Name: RateCard Trigger
 * Description: Test class Manager Class for Rate Card Trigger
 * Created Date: [06/02/2014]
 * Created By: [Manisha] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
@isTest
private class RateCardManagerTest {

	private static testmethod void makeOldCardsInActive(){
		Test.StartTest();
		State_Province__c state = TestHelper.createState();
		insert state;
		Account district = TestHelper.createAccountForIndustryType('Test');
		insert district;

		Rate_Card__c rateCard1 = TestHelper.createRateCardForDistrict(district.Id);
		rateCard1.Active__c = true;
		insert rateCard1;

		Rate_Card__c rateCard2 = TestHelper.createRateCardForDistrict(district.Id);
		rateCard2.Active__c = true;
		insert rateCard2;

		rateCard1 = [Select Active__c
					FROM Rate_Card__c
					Where Id = :rateCard1.Id];

		system.assertEquals(false, rateCard1.Active__c);


		Rate_Card__c rateCard3 = TestHelper.createRateCardForState(state.Id);
		rateCard3.Active__c = true;
		insert rateCard3;

		Rate_Card__c rateCard4 = TestHelper.createRateCardForState(state.Id);
		rateCard4.Active__c = true;
		insert rateCard4;

		rateCard3 = [Select Active__c
					FROM Rate_Card__c
					Where Id = :rateCard3.Id];

		system.assertEquals(false, rateCard3.Active__c);

		Test.StopTest();
	}
}