/**=====================================================================
 * Appirio, Inc
 * Trigger Name: ActivateDraw_Test
 * Description: T-279016 : Test Class for ActivateDraw class
 * Created Date: [05/21/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * [01/24/2017]            		[John Caughie]             	[Added drawEntry.Payment_Amount__c value]
 =====================================================================*/
@isTest
private class ActivateDraw_Test {
	static Boolean activeDraw;
	static testMethod void myUnitTest() {
        Test.StartTest();
        Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;

		RPA__c RPA = TestHelper.createRPA(acc.Id);
		insert RPA;
		
		map<String,RecordType> rtMap = new map<String,RecordType>(); 
		rtMap = TestHelper.createRecordTypeMap();
		
		Account investor = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'PCSRC Inv');

		State_Province__c stateProvince = TestHelper.createStateProvince('Test State', true);

		Draw_Note__c drawNote = TestHelper.createDrawNote();
		drawNote.Status__c = 'Draft';
		drawNote.Investor__c = investor.Id;
		drawNote.Operating_State__c = stateProvince.Id;
		insert drawNote;

		Draw_Note__c drawNote1 = TestHelper.createDrawNote();
		drawNote1.Status__c = 'Active';
		drawNote1.Investor__c = investor.Id;
		drawNote1.Operating_State__c = stateProvince.Id;
		insert drawNote1;

		Draw_Entry__c drawEntry = TestHelper.createDrawEntry(drawNote1.Id);
		drawEntry.Principal_Paid__c = 10.0;
		drawEntry.Payment_Amount__c = 10.0;
		insert drawEntry;

		Funded_Receivable__c fundedRec = TestHelper.createFundedRec(acc.Id, RPA.Id);
		insert fundedRec;

		list<Draw_Note_TX__c> lstDrawTX = new list<Draw_Note_TX__c>();
		activeDraw = ActivateDraw.ActivateDrawNoteTX(drawNote.Id);
		System.assertEquals(false,activeDraw);
		for(Integer i = 0; i<3; i++){
        	Draw_Note_TX__c drNoteTX = new Draw_Note_TX__c();
        	drNoteTX.Status__c = 'Draft';
        	drNoteTX.Draw_Note__c = drawNote.Id;
        	drNoteTX.Class__c = 're';
        	drNoteTX.Amount_Borrowed__c = 23.00;
        	drNoteTX.Funded_Receivable__c = fundedRec.Id;
        	lstDrawTX.add(drNoteTX);
        }
        Draw_Note_TX__c drNoteTX1 = new Draw_Note_TX__c();
    	drNoteTX1.Status__c = 'Active';
    	drNoteTX1.Draw_Note__c = drawNote1.Id;
    	drNoteTX1.Class__c = 're';
    	drNoteTX1.Amount_Borrowed__c = 23.00;
    	drNoteTX1.Funded_Receivable__c = fundedRec.Id;
    	lstDrawTX.add(drNoteTX1);

        insert lstDrawTX;

        activeDraw = ActivateDraw.ActivateDrawNoteTX(drawNote.Id);
		System.assertEquals(true,activeDraw);

        ActivateDraw.cancelDraw(drawNote.Id);
        drawNote = [select id, Status__c from Draw_Note__c where id =: drawNote.Id];
        System.assertEquals(drawNote.Status__c ,'Cancelled');

		Test.StopTest();
	}


	static testMethod void addTxTest() {
        
        Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;

		RPA__c RPA = TestHelper.createRPA(acc.Id);
		insert RPA;
		
		map<String,RecordType> rtMap = new map<String,RecordType>(); 
		rtMap = TestHelper.createRecordTypeMap();
		
		Account investor = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'PCSRC Inv');

		State_Province__c stateProvince = TestHelper.createStateProvince('Test State', true);

		Draw_Note__c drawNote = TestHelper.createDrawNote();
		drawNote.Status__c = 'Draft';
		drawNote.Investor__c = investor.Id;
		drawNote.Operating_State__c = stateProvince.Id;
		insert drawNote;

		Draw_Note__c drawNote1 = TestHelper.createDrawNote();
		drawNote1.Status__c = 'Active';
		drawNote1.Investor__c = investor.Id;
		drawNote1.Operating_State__c = stateProvince.Id;
		insert drawNote1;

		Draw_Entry__c drawEntry = TestHelper.createDrawEntry(drawNote1.Id);
		drawEntry.Principal_Paid__c = 10.0;
		drawEntry.Payment_Amount__c = 10.0;
		insert drawEntry;

		Funded_Receivable__c fundedRec = TestHelper.createFundedRec(acc.Id, RPA.Id);
		insert fundedRec;

		list<Draw_Note_TX__c> lstDrawTX = new list<Draw_Note_TX__c>();
		activeDraw = ActivateDraw.ActivateDrawNoteTX(drawNote.Id);
		System.assertEquals(false,activeDraw);
		for(Integer i = 0; i<3; i++){
        	Draw_Note_TX__c drNoteTX = new Draw_Note_TX__c();
        	drNoteTX.Status__c = 'Draft';
        	drNoteTX.Draw_Note__c = drawNote.Id;
        	drNoteTX.Class__c = 're';
        	drNoteTX.Amount_Borrowed__c = 23.00;
        	drNoteTX.Funded_Receivable__c = fundedRec.Id;
        	lstDrawTX.add(drNoteTX);
        }
        Draw_Note_TX__c drNoteTX1 = new Draw_Note_TX__c();
    	drNoteTX1.Status__c = 'Active';
    	drNoteTX1.Draw_Note__c = drawNote1.Id;
    	drNoteTX1.Class__c = 're';
    	drNoteTX1.Amount_Borrowed__c = 23.00;
    	drNoteTX1.Funded_Receivable__c = fundedRec.Id;
    	lstDrawTX.add(drNoteTX1);

        insert lstDrawTX;

        Test.StartTest();
	        activeDraw = ActivateDraw.AddDrawNoteTX(drawNote.Id);
		Test.StopTest();
		System.assertEquals(true,activeDraw);
		List<Draw_Note_TX__c> txs = [SELECT ID, Status__c FROM Draw_Note_TX__c WHERE Draw_Note__c = :drawNote.Id AND Status__c = 'Active'];
		System.assertEquals(txs.size(), 3, 'Should be 3 active receivables');
		List<Draw_Note_TX__c> txs1 = [SELECT ID, Status__c FROM Draw_Note_TX__c WHERE Draw_Note__c = :drawNote1.Id AND Status__c = 'Refinanced'];
		System.assertEquals(txs1.size(), 1, 'One should have been marked refinanced');
	}



}