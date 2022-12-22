/**=====================================================================
 * Name: DrawPayment_BatchTest
 * Description: Test class for DrawPayment_Batch
 * Created Date: [01/03/2017]
 * Created By: John Caughie
 *
 * Date Modified                Modified By                  Description of the update
 * [xx/xx/xxxx]                 [xxxxx xxxxx]              []
 =====================================================================*/
@isTest
private class DrawPayment_BatchTest {
	static testMethod void verifyDrawPayment(){

		//Create Operating State
		State_Province__c stateProvince = TestHelper.createStateProvince('Test State', true);
		System.debug(TestHelper.createRecordTypeMap().get('Investor'));

		//Create Investor account of type Investor for above operating state
		Account investor = new Account(Name = 'East West Bank', Operating_State__c = stateProvince.Id, RecordTypeId = TestHelper.createRecordTypeMap().get('Investor').Id);
		insert investor;
		System.debug('inv: ' + investor);

		//Create draws for above investor
		List<Draw_Note__c> draws = new List<Draw_Note__c>();
		for (Integer i = 0; i < 100; i++){
			Draw_Note__c d = TestHelper.createDrawNoteDetailed(100000, investor, stateProvince);
			draws.add(d);
		}
		System.debug('no: ' + draws.size());
		//Draw_Note__c drawNote = TestHelper.createDrawNoteDetailed(100000, investor, stateProvince);
        insert draws;
        draws = [SELECT Id, Interest_Due__c, Borrow_Date__c, Last_Activity_Date__c, Note_Rate__c, Principal_Due__c
						FROM Draw_Note__c WHERE Status__c = 'Active' AND Investor__R.Name = 'East West Bank'];
		System.debug('note: ' + draws[0]);

        Test.startTest();
		DrawPayment_Batch dpb = new DrawPayment_Batch(Date.today(), 'East West Bank');
		Test.stopTest();

        ID batchprocessid = Database.executeBatch(dpb);

        dpb.execute(null, draws);

        Draw_Entry__c de = [SELECT Id, Source_Payment_Type__c, Interest_Paid__c FROM Draw_Entry__c WHERE Draw_Note__c = :draws[0].Id AND Activity_Type__c = 'Quarterly Interest' LIMIT 1];
        System.debug('de: ' + de);
        System.assertEquals(1666.67, de.Interest_Paid__c, '60 days interest principal = 100,000 @ 10% = 1,666.67');
    }



}