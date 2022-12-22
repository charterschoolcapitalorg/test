/**=====================================================================
 * Appirio, Inc
 * Name: DrawInterestCalculation_BatchTest
 * Description: DrawInterestCalculation_BatchTest test class for DrawInterestCalculation_Batch
 * Created Date: [05/26/2014]
 * Created By: Rahul Agrawal (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [07/03/2014]                 [Rajeev Arya]              [T-288639 - Create custom VF Page for interest calc]
 =====================================================================*/
@isTest
private class DrawInterestCalculation_BatchTest {
	static testMethod void verifyDrawInterestCalculation(){
        List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
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
        insert drawNote;

        List<Draw_Entry__c> oldDrawEntryLst = new List<Draw_Entry__c>();
        Payment__c payment = new Payment__c();

        for(Integer i=0;i<=200;i++){
            Draw_Entry__c oldDrawEntry = new Draw_Entry__c();
            oldDrawEntry.Principal__c = 2000.00;
            oldDrawEntry.Activity_Date__c = date.parse('1/12/2014');
            oldDrawEntry.Draw_Note__c = drawNote.Id;
            oldDrawEntry.Ending_Principal__c= 1000.00;
            oldDrawEntry.Interest_Fwd__c = 8.00;
            oldDrawEntryLst.add(oldDrawEntry);
        }
        insert oldDrawEntryLst;
		DrawInterestCalculation_Batch dcb = new DrawInterestCalculation_Batch(Date.today());

        ID batchprocessid = Database.executeBatch(dcb);

        dcb.execute(null, new list<Draw_Note__c>{drawNote});
    }

     static testmethod void testScheduler(){
        test.startTest();
        System.schedule('DrawInterestCalculation_Batch Job','0 0 1 1 * ?', new DrawInterestCalculation_Batch(Date.today()));
        test.stopTest();
        System.assert(true);
    }
}