/**=====================================================================
 * Name: SchoolAttDeepCloneWithRegionalAtt_Test
 * Description: Regional Attendance "Full Clone" tool project(2014.11.17)
 * Created Date: [02/12/2015]
 * Created By: [John Caughie]
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/

@isTest
private class SchoolAttDeepCloneWithRegionalAtt_Test {

    private static testMethod void testSchAttDeepCloneController() {

        
    	Map<String, RecordType> accTypes = TestHelper.createRecordTypeMap();
    	Map<String, RecordType> attTypes = TestHelper.createAttendanceRecordTypeMap();

		TestHelper.createCustomSettingToByPassTriggersAndRules('Account, RPA__c, Opportunity, Funding_Estimate_Receivable__c, Funding_Estimates__c, '+
																'Opp_School__c');
        
        // create & insert a School
        Account testSchool = TestHelper.createAccountForRecordType(accTypes.get('School').Id , 'Test School');
        //System.debug(testSchool);

        // create & insert School Attendance
        School_Attendance__c schoolAtt = TestHelper.createSchoolAttendance(testSchool);
        System.debug('orig att ' + schoolAtt.id);

        // create Districts
        list<Account> listDists = new list<Account>();
        for(Integer i = 0; i < 5; i++){
        	listDists.add(TestHelper.createAccountForRecordTypeNoInsert(accTypes.get('COE_District').Id , 'Test District'));
        }
        //insert Districts
        insert listDists;

        // create Regional Attendances
        list<Regional_Attendance__c> schRegAtt = new list<Regional_Attendance__c>();
        for(Account dist : listDists){
        	schRegAtt.add(TestHelper.createRegionalAttendanceNoInsert(listDists[0].Id, schoolAtt));
        }
        //insert Regional Attendance records
        insert schRegAtt;

        // Construct the standard controller
        ApexPages.StandardController stdCon = new ApexPages.StandardController(schoolAtt);

        // create the controller
        SchoolAttDeepCloneWithRegionalAtt controller = new SchoolAttDeepCloneWithRegionalAtt(stdCon);

        // Switch to test context
        Test.startTest();

        // call the CloneWithRegionalAtt method
        PageReference ref = controller.cloneWithRegionalAtt();

        list<Regional_Attendance__c> origList = [Select Name from Regional_Attendance__c where School_Attendance__c = :schoolAtt.Id];
        list<Regional_Attendance__c> listClonedReg = [Select Name from Regional_Attendance__c where School_Attendance__c = :controller.clonedSchoolAtt.Id];

        System.debug('original ' + origList.size());
        System.debug(origList);
        System.debug('clone '+ listClonedReg.size());
        System.debug(listClonedReg);
        System.assertEquals(origList.size(),listClonedReg.size());

        Test.stopTest();

    }

}