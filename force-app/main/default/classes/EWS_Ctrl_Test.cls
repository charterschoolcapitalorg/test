@istest
private class EWS_Ctrl_Test {

	@testSetup static void createRecords(){
		//insert school account
		Account school = new Account(name = 'Test School1');
		insert school;

		//insert EWS records
		List<EWS__c> ewsRecordsBefore = new List<EWS__c>();
		EWS__c isActiveSchool1 = getEWS(school.Id, True, RecordTypeUtils.EWSFinanceActive.Id);
		ewsRecordsBefore.add(isActiveSchool1);
		EWS__c isInactiveSchool1a = getEWS(school.Id, True, RecordTypeUtils.EWSUnderwritingActive.Id);
		ewsRecordsBefore.add(isInactiveSchool1a);
		insert ewsRecordsBefore;

	}

	@isTest static void testFinanceCloneMethod(){
		List<EWS__c> ewsList = new List<EWS__c>();
		ewsList = [SELECT Id, RecordTypeId FROM EWS__c WHERE RecordTypeId = :RecordTypeUtils.EWSFinanceActive.Id LIMIT 1];
		EWS__c clonedEWS = EWS_Ctrl.getRecord(ewsList[0].Id);
		System.assertNotEquals(ewsList[0].RecordTypeId, clonedEWS.RecordTypeId, 'Record types should not match');
		System.assertEquals(RecordTypeUtils.EWSFinanceInactive.Id, clonedEWS.RecordTypeId, 'Record types should be inactive');
	}

	@isTest static void testUnderwritingCloneMethod(){
		List<EWS__c> ewsList = new List<EWS__c>();
		ewsList = [SELECT Id, Account__c, RecordTypeId FROM EWS__c WHERE RecordTypeId = :RecordTypeUtils.EWSUnderwritingActive.Id LIMIT 1];
		EWS__c clonedEWS = EWS_Ctrl.getRecord(ewsList[0].Id);
        Academic_Rating__c ar = EWS_Ctrl.getRatings(ewsList[0].Account__c, '20-21');
		System.assertNotEquals(ewsList[0].RecordTypeId, clonedEWS.RecordTypeId, 'Record types should not match');
		System.assertEquals(RecordTypeUtils.EWSUnderwritingInactive.Id, clonedEWS.RecordTypeId, 'Record types should be inactive');
	}

	static EWS__c getEWS(Id accId, Boolean status, Id recordType){
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