/**=====================================================================
 * Appirio, Inc
 * Name: UpdateExistingRPA_BatchTest
 * Description: Test Class for UpdateExistingRPA_Batch
 * Created Date: [06/18/2014]
 * Created By: [Rahul Agrawal] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
@isTest
private class UpdateExistingRPA_BatchTest {
	static testMethod void updateExistingRPATestMethod(){
        /*List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test' +'@tesclass.com',
                               email = 'test' +'@testclass',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'
                               //hire_date__c = date.parse('1/12/2013')
                                );*/
		Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;

		List<RPA__c> lstRPA = new List<RPA__c>();
        List<Terms_Letter__c> lstTermLetter = new List<Terms_Letter__c>();
        List<Program_Fee__c> lstProgramFee = new List<Program_Fee__c>();

        for(Integer i=0;i<=200;i++){
            lstRPA.add(TestHelper.createRPA(acc.Id));
        }
        insert lstRPA;

        for(Integer i=0;i<=200;i++){
            lstTermLetter.add(TestHelper.createTermsLetter(acc.Id, lstRPA[i].ID));
        }
        insert lstTermLetter;

        for(Integer i=0;i<=200;i++){
            lstProgramFee.add(TestHelper.createProgramFee(lstTermLetter[i].id));
        }
        insert lstProgramFee;

		UpdateExistingRPA_Batch dcb = new UpdateExistingRPA_Batch();

        dcb.start(null);

        dcb.execute(null, lstRPA);

        RPA__c rpaValidate = [select id, Current_Program_Fee_Value__c, Current_Program_Fee_Months__c from RPA__c where id =: lstRPA[0].Id];
        Program_Fee__c fee = [Select Program_Fee__c, Start_Date__c, End_Date__c, Terms_Letter__r.RPA__c
									from Program_Fee__c
									where Terms_Letter__r.RPA__c = : lstRPA[0].Id];
        system.assertEquals(rpaValidate.Current_Program_Fee_Value__c, fee.Program_Fee__c);
        system.assertEquals(rpaValidate.Current_Program_Fee_Months__c, fee.Start_Date__c.monthsBetween(fee.End_Date__c));

        dcb.finish(null);
    }

     static testmethod void testScheduler(){
        test.startTest();
        System.schedule('DrawInterestCalculation_Batch Job','0 0 1 1 * ?', new UpdateExistingRPA_Batch());
        test.stopTest();
        System.assert(true);
    }
}