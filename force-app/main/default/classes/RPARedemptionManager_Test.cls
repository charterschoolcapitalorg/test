/**=====================================================================
 * Appirio, Inc
 * Name: RPARedemptionManager_Test
 * Description: T-280412 : Test Class for the Manager Class RPARedemptionManager, for the trigger CommissionFromRPARedemption
 * Created Date: [05/26/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 *
 =====================================================================*/
@isTest
private class RPARedemptionManager_Test {
	static testMethod void myUnitTest() {
        Test.StartTest();

        TestHelper.createCustomSettingToByPassTriggersAndRules('RPA_Redemption__c;Funded_Receivable__c');

        State_Province__c opState = TestHelper.createOperatingState();
        insert opState;

        Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;

		Account acc1 = TestHelper.createRPAAccount(acc.id);
		acc1.Operating_State__c = opState.id;
		acc1.First_Purchase_Date__c = Date.Today();
		insert acc1;

		RPA__c RPA = TestHelper.createRPA(acc1.Id);
		insert RPA;

		Opportunity opp = TestHelper.createOpportunity(acc, 'Test Opp');
		opp.RPA__c = rpa.Id;
		opp.AccountId = acc.id;
		insert Opp;

		Funded_Receivable__c fRec = TestHelper.createFundedRec(acc1.Id, RPA.Id);
		fRec.Source_Opportunity__c = opp.id;
		insert fRec;

		Account accnt = [select first_purchase_date__c, Account_Commission_Status__c from Account where id=:acc1.Id];

		Redemption__c red = TestHelper.createRedemption(acc1.id);
		red.Face_Amount_Applied_Fee__c = 10;
		insert red;

		RPA_Redemption__c RPARed = TestHelper.createRPARedemption(RPA.Id,red.Id);
		insert RPARed;

		red = [select id, Face_Amount_Applied_Fee__c from Redemption__c where id =: red.Id];
		//red.Face_Amount_Applied_Fee__c = red.Face_Amount_Applied_Fee__c + RPA_Redemption__c.Program_Fee_Collected__c
		system.assertEquals(red.Face_Amount_Applied_Fee__c, 210);

		list<Commission__c> lstComm = [select id from Commission__c where RPA_Redemption__c =: RPARed.Id ];
		//system.assertEquals(lstComm.size(), 1);
		Test.StopTest();
	}
}