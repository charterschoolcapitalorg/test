/**=====================================================================
 * Appirio, Inc
 * Name: DrawEntryTriggerManagerTest
 * Description: I-119205 : Test Class for manager class DrawEntryTriggerManager
 * Created Date: [06/27/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
@isTest
private class DrawEntryTriggerManagerTest {

	static testMethod void DrawEntryAfterInsert(){
		State_Province__c stateProvince = TestHelper.createStateProvince('Test State', true);

		Draw_Note__c drawNote = TestHelper.createDrawNote();
		drawNote.Operating_State__c = stateProvince.Id;
		insert drawNote;

		Draw_Entry__c drawEntry = TestHelper.createDrawEntry(drawNote.Id);
		drawEntry.Interest_Fwd__c = 23.50;
		insert drawEntry;

		drawNote = [select id, Interest_Due__c from Draw_Note__c where id =: drawNote.Id];
		system.assertEquals(drawNote.Interest_Due__c, drawEntry.Interest_Fwd__c);

		Draw_Entry__c drawEntry1 = TestHelper.createDrawEntry(drawNote.Id);
		drawEntry1.Interest_Fwd__c = 46.67;
		insert drawEntry1;
		
		drawNote = [select id, Interest_Due__c from Draw_Note__c where id =: drawNote.Id];
		system.assertEquals(drawNote.Interest_Due__c, drawEntry1.Interest_Fwd__c);
	}
}