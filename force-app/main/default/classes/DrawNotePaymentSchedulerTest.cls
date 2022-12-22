@isTest
private class DrawNotePaymentSchedulerTest {

   static testmethod void paymentSchedulerTest() {

		Draw_Note__c dn = new Draw_Note__c();
		dn.Note_Rate__c = 5.0;
		dn.RecordTypeId = RecordTypeUtils.DrawCreditLine.Id;
		insert dn;

		List<Drawdown__c> drawdowns = new List<Drawdown__c>();
		Drawdown__c ddn1 = new Drawdown__c();
		ddn1.Amount_Requested__c = 50000;
		ddn1.Disbursement_Date__c = Date.today();
		ddn1.Status__c = 'Pending';
		ddn1.Draw_Note__c = dn.Id;
		drawdowns.add(ddn1);

		Drawdown__c ddn2 = new Drawdown__c();
		ddn2.Amount_Requested__c = 50000;
		ddn2.Disbursement_Date__c = Date.today();
		ddn2.Status__c = 'Completed';
		ddn2.Draw_Note__c = dn.Id;
		drawdowns.add(ddn2);

		Drawdown__c ddn3 = new Drawdown__c();
		ddn3.Amount_Requested__c = 70000;
		ddn3.Disbursement_Date__c = Date.today();
		ddn3.Status__c = 'Pending';
		ddn3.Draw_Note__c = dn.Id;
		drawdowns.add(ddn3);

		insert drawdowns;

	   	Test.startTest();
			// Test batch
			DrawNotePaymentScheduler dnps = new DrawNotePaymentScheduler();
			dnps.execute(null);

		Test.stopTest();

		Draw_Entry__c[] entries = [Select Id, Name, Activity_Date__c, Principal_Paid__c, Ending_Principal__c FROM Draw_Entry__c ORDER BY Ending_Principal__c DESC];
		System.debug(entries);
		System.assertEquals(entries.size(), 2, 'Incorrect number of entries');
		System.assertEquals(entries[0].Ending_Principal__c, 120000, 'Wrong ending balance');

   }
}