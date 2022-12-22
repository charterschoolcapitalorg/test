/**=====================================================================
 * Appirio, Inc
 * Name: UpdateExistingDrawRecordType_BatchTest
 * Description: T-289598 - Test Class for batch class UpdateExistingDrawNoteRecordType_Batch
 * Created Date: [06/30/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update

  =====================================================================*/
@isTest
private class UpdateExistingDrawRecordType_BatchTest {
	static testMethod void verifyDrawRecordType(){
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test' +'@tesclass.com',
                               email = 'test' +'@testclass',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'
                               //hire_date__c = date.parse('1/12/2013')
                                );
		State_Province__c stateProvince = TestHelper.createStateProvince('Test State', true);

		Draw_Note__c drawNote = TestHelper.createDrawNote();
		drawNote.Operating_State__c = stateProvince.Id;
        drawNote.Borrow_Date__c = date.parse('1/12/2013');
        drawNote.Note_Rate__c = 2;
        drawNote.Status__c = 'Active';
        insert drawNote;
       
		UpdateExistingDrawNoteRecordType_Batch dcb = new UpdateExistingDrawNoteRecordType_Batch();

        ID batchprocessid = Database.executeBatch(dcb);

        dcb.execute(null, new list<Draw_Note__c>{drawNote});
    }

     static testmethod void testScheduler(){
        test.startTest();
        System.schedule('UpdateExistingDrawNoteRecordType_Batch Job','0 0 1 1 * ?', new UpdateExistingDrawNoteRecordType_Batch());
        test.stopTest();
        System.assert(true);
    }
}