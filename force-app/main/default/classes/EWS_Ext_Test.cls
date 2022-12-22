/**=====================================================================
 * Name: EWX_Ext_Test
 * Description: Test Class EWS_Ext
 * Created Date: 2017.02.17
 * Created By: John Caughie
 *
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest
private class EWS_Ext_Test {
	
	static testMethod void testActivation() {

		//insert school accounts
		List<Account> schools = new List<Account>();
		Account school1 = new Account(name = 'Test School1');
		schools.add(school1);
		Account school2 = new Account(name = 'Test School2');
		schools.add(school2);
		insert schools;
		
		//insert EWS records
		List<EWS__c> ewsRecordsBefore = new List<EWS__c>();
		EWS__c isActiveSchool1 = getEWS(schools[0].Id, True, RecordTypeUtils.EWSFinanceActive.Id);
		ewsRecordsBefore.add(isActiveSchool1);
		EWS__c isInactiveSchool1a = getEWS(schools[0].Id, False, RecordTypeUtils.EWSFinanceInactive.Id);
		ewsRecordsBefore.add(isInactiveSchool1a);
		EWS__c isInactiveSchool1b = getEWS(schools[0].Id, False, RecordTypeUtils.EWSFinanceInactive.Id);
		ewsRecordsBefore.add(isInactiveSchool1b);
		EWS__c isActiveSchool2 = getEWS(schools[1].Id, True, RecordTypeUtils.EWSFinanceActive.Id);
		ewsRecordsBefore.add(isActiveSchool2);
		EWS__c isInactiveSchool2 = getEWS(schools[1].Id, False, RecordTypeUtils.EWSFinanceActive.Id);
		ewsRecordsBefore.add(isInactiveSchool2);		
		insert ewsRecordsBefore;
		
		//record to activate
		EWS__c updateEWS = [SELECT Id, Account__r.Name, Active__c, RecordType.DeveloperName, RecordTypeId FROM EWS__c WHERE id = :isInactiveSchool1a.Id];

		//instantiate record and activate
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(updateEWS);
		EWS_Ext cont = new EWS_Ext(sc);
		
		Test.startTest();
		cont.updateRecordStatus();
		Test.stopTest();

		//Test record updates
		System.assertEquals(1, [SELECT Count() FROM EWS__c WHERE Account__c = :school1.Id AND Active__c = True]);
		System.assertEquals(2, [SELECT Count() FROM EWS__c WHERE Account__c = :school1.Id AND Active__c = False]);
		System.assertEquals(1, [SELECT Count() FROM EWS__c WHERE Account__c = :school2.Id AND Active__c = True]);
		//inactive record should now be activated
		System.assertEquals(True, [SELECT Active__c FROM EWS__c WHERE id = :isInactiveSchool1a.Id].Active__c, 'wrong record activated');
	}

	public static EWS__c getEWS(Id accId, Boolean status, Id recordType){
		EWS__c e = new EWS__c();
		e.RecordTypeId = recordType;
		e.Account__c = accId;
		e.Review_Date__c = Date.today();
		e.Fiscal_Year__c = '16-17';
		e.Quarter_Ending_FY__c = 'Q1';
		e.Active__c = status;
		e.FDA_County__c = 'Yes';
		e.FDA_District__c = 'Yes';
		e.Date_Opened__c = Date.today();
		e.Num_of_Shortfalls_Current_FY__c = 0;
		e.Audit_Information__c = 'Minor Issues';
		e.Net_Assets__c = 0;
		e.Non_Facilities_Liabilities__c = 0;
		e.Annual_Rent_Expense__c = 0;
		e.Prior_Year_Surplus_Deficit__c = 0;
		e.Budgeted_Revenue__c = 100000;
		e.Budgeted_Donations__c = 0;
		e.Budgeted_Surplus_Deficit__c = 0;
		e.Budgeted_Attendance__c = 100;
		e.Attendance_Current__c = 200;
		e.Attendance_Prior__c = 150;
		e.Year_1_Latest__c = 200;
		e.Year_2__c = 200;
		e.Year_3_Oldest__c = 150;
		e.Number_of_Months_Outstanding__c = 0;
		e.Number_of_Fundings_per_Year__c = 3;
		e.Avg_percentage_of_Face_Funded__c = 85;
		e.Cross_Year_Funding_Amount__c = 0;
		e.Avg_Days_Notice_given__c = 40;
		return e;
	}


}
	



/*

1 - create new active record
2 - create new inactive record

3 - activate record 2
4 - test record 1 is inactive & 2 is active

*/