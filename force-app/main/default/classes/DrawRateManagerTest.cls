/**=====================================================================
 * Appirio, Inc
 * Name: DrawRateManagerTest
 * Description: Test Class for DrawRateManager
 * Created Date: [06/16/2014]
 * Created By: [Rahul Agrawal] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 * 	08/10/2017                  John Caughie                 Changed the draw days for the first to -10
 =====================================================================*/
@isTest
private class DrawRateManagerTest {

	static testMethod void DrawRateAfterInsert(){
		State_Province__c stateProvince = TestHelper.createStateProvince('Test State', true);

		Draw_Note__c drawNote = TestHelper.createDrawNote();
		drawNote.Operating_State__c = stateProvince.Id;
		insert drawNote;

		Draw_Rate__c drawRate = TestHelper.createDrawRate(drawNote.Id, 1.00);
		drawRate.Start_Date__c = Date.Today().addDays(-10);
		insert drawRate;

		drawNote = [select id, Note_Rate__c from Draw_Note__c where id =: drawNote.Id];
		system.assertEquals(drawNote.Note_Rate__c, drawRate.Interest_Rate__c);

		Draw_Rate__c drawRate1 = TestHelper.createDrawRate(drawNote.Id, 5.00);
		drawRate1.Start_Date__c = Date.Today().addDays(-1);
		insert drawRate1;

		drawRate = [select id, Bypass_Validation__c, End_Date__c from Draw_Rate__c where id =: drawRate.Id];
		system.debug('drawRate: '+ drawRate);
		drawRate1 = [select id, Bypass_Validation__c, End_Date__c, Start_Date__c from Draw_Rate__c where id =: drawRate1.Id];
		system.debug('drawRate1: '+ drawRate1);
		system.assertEquals(drawRate.Bypass_Validation__c, true);
		system.assertEquals(drawRate.End_Date__c, drawRate1.Start_Date__c);

		Draw_Note__c updatedNote = [Select Note_Rate__c from Draw_Note__c where id = :drawNote.Id Limit 1];
		System.assertEquals(updatedNote.Note_Rate__c, 5.00);
	}
}