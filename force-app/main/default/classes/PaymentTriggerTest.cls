/**=====================================================================
 * Appirio, Inc
 * Name: PaymentTriggerTest
 * Description: Test class for PaymentTrigger
 * Created Date: [05/21/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 05/20/2014					Manisha Gupta					Writing the logic for the task T-275864
 *
 =====================================================================*/
@isTest
private class PaymentTriggerTest {

	static testmethod void paymentAfterInsertTest_InterestCalculation(){
		Test.StartTest();

		Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;

		RPA__c RPA = TestHelper.createRPA(acc.Id);
		insert RPA;

		State_Province__c opState = TestHelper.createOperatingState();
		insert opState;

		Draw_Note__c drawNote = TestHelper.createDrawNote();
		drawNote.Operating_State__c = opState.Id;
		insert drawNote;

		Funded_Receivable__c fundedRec = TestHelper.createFundedRec(acc.Id, RPA.Id);
		insert fundedRec;

		list<Draw_Note_TX__c> listDrawNoteTx = new list<Draw_Note_TX__c>();

		for(Integer i = 0 ; i < 10 ; i++){
			listDrawNoteTx.add(TestHelper.createDrawNoteTx(drawNote.Id, fundedRec.Id, 1000));
		}

		insert listDrawNoteTx;

		Payment_Sub__c paymentSub = TestHelper.createPaymentSub(drawNote.Id, 5000);
		insert paymentSub;

		paymentSub = TestHelper.createPaymentSub(drawNote.Id, 50000);
		insert paymentSub;

		Payment__c payment = TestHelper.createPayment(drawNote.Id, 5000, paymentSub.Id);
		insert payment;

		payment = TestHelper.createPayment(drawNote.Id, 50000, paymentSub.Id);
		insert payment;

		list<Draw_Entry__c> listDrawEntry = [Select Id
												from Draw_Entry__c
												where Draw_Note__c = :drawNote.Id];
		system.assert(listDrawEntry.size() == 2);

		payment = TestHelper.createPayment(drawNote.Id, 1, paymentSub.Id);
		insert payment;

		listDrawEntry = [Select Id
												from Draw_Entry__c
												where Draw_Note__c = :drawNote.Id];
		system.assert(listDrawEntry.size() == 2);

		Test.StopTest();


	}
}