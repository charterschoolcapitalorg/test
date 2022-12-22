@isTest
private class DrawNoteInterestSchedulerTest {

   static testmethod void interestTest() {

		Draw_Note__c dn = new Draw_Note__c();
		dn.Note_Rate__c = 5.0;
		dn.RecordTypeId = RecordTypeUtils.DrawCreditLine.Id;
		dn.Status__c = 'Active';
		insert dn;

		Draw_Entry__c drawEntry = new Draw_Entry__c();
		drawEntry.Principal_Paid__c = 500000;
		drawEntry.Activity_Date__c = Date.today().addDays(-1);
		drawEntry.Ending_Principal__c = 500000;
		drawEntry.Activity_Type__c = 'Drawdown';
		drawEntry.Draw_Note__c = dn.Id;

		insert drawEntry;

	   	Test.startTest();
			// Test batch
			DrawNoteInterestScheduler dnps = new DrawNoteInterestScheduler();
			dnps.execute(null);

		Test.stopTest();

		Draw_Entry__c[] entries = [Select Id, Name, Activity_Date__c, Principal_Paid__c, Ending_Principal__c, Activity_Type__c, Interest_Fwd__c FROM Draw_Entry__c WHERE Activity_Type__c = 'Daily Interest'];
		System.debug(entries);
		//System.assertEquals(entries.size(), 2, 'Incorrect number of entries');
		System.assertEquals(entries[0].Interest_Fwd__c, 69.44, 'Wrong ending balance');
	}

}