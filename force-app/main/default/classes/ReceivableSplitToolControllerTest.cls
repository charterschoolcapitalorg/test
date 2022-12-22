/**=====================================================================
 * Appirio, Inc
 * Name: ReceivableSplitToolControllerTest
 * Description: Test class [Task T-272509 : Receivable Split VF Page - Jaipur first spec]
 * Created Date: [05/19/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
@isTest
private class ReceivableSplitToolControllerTest {

	static testmethod void testReceivableSplitTool(){
		Test.StartTest();
		Payor__c statePayor = TestHelper.createPayor('California');

        //Create Receivable Types.
        Receivable_Type__c type1 = TestHelper.createReceivableType(statePayor,'CA-In Lieu');

        //Create Calculations.
        Calculation__c c1 = TestHelper.createCalculation(type1,'calc_CA_InLieu');

        //Create Payout Dates for both calculations.
        Payout_Date__c payoutDate = TestHelper.createPayoutDate(50,c1,Date.newInstance(2014,6,1),'June');

		Account acc = TestHelper.createAccountForIndustryType('test');
		insert acc;

		RPA__c rpa = TestHelper.createRPA(acc.Id);
		insert rpa;

		State_Province__c stateProvince = new State_Province__c (
		    Name = 'test value'
		);
		insert stateProvince;


		Draw_Note__c drawNote = testHelper.createDrawNote();
		drawNote.Operating_State__c = stateProvince.Id;
		insert drawNote;



        List<Funded_Receivable__c> listFundedReceivable = new list<Funded_Receivable__c>();
        listFundedReceivable.add(TestHelper.createFundedReceivable(payoutDate.Id, 1000.00, acc.Id, rpa.Id));
        listFundedReceivable.add(TestHelper.createFundedReceivable(payoutDate.Id, 2000.00, acc.Id, rpa.Id));
        listFundedReceivable.add(TestHelper.createFundedReceivable(payoutDate.Id, 3000.00, acc.Id, rpa.Id));
        listFundedReceivable.add(TestHelper.createFundedReceivable(payoutDate.Id, 4000.00, acc.Id, rpa.Id));
        insert listFundedReceivable;

        List<Draw_Note_TX__c> listDrawNoteTx = new list<Draw_Note_TX__c>();

        for(Funded_Receivable__c fundedRec : listFundedReceivable){
        	for(Integer i = 0 ; i < 10 ; i++){
        		listDrawNoteTx.add(TestHelper.createDrawNoteTx(DrawNote.Id, fundedRec.Id, 1000));
        	}
        }

        insert listDrawNoteTx;

        map<Id, Funded_Receivable__c> mapFundedRec = new map<Id, Funded_Receivable__c>();

        for(Funded_Receivable__c fundedRec : listFundedReceivable){
        	mapFundedRec.put(fundedRec.Id, fundedRec);
        }

        ApexPages.StandardController stdController = new ApexPages.StandardController(payoutDate);
        ReceivableSplitToolController controller = new ReceivableSplitToolController(stdController);

        system.assert(controller.listWrapperTab1.size() == 4);

        for(ReceivableSplitToolController.ReceivableSplitWrapper wrapper : controller.listWrapperTab1){
        	wrapper.isSelected = true;
        }

        controller.splitPercent = 50.00;
        controller.calculateSplits();
        controller.applySplits();

        controller.dummyReceivable.Name = 'test rec';
        controller.dummyReceivable.Expected_Pay_Date__c = date.today().addDays(10);

        controller.applySplits();


        Test.StopTest();

	}
}