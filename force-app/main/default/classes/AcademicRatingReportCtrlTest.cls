@IsTest
private class AcademicRatingReportCtrlTest {
  @isTest
  static void testGetSchoolData(){
    TestFacilities.facSetup();
    List<Account> schools = [SELECT Id, Name FROM Account WHERE RecordType.DeveloperName = 'School'];
    System.debug(schools);
    List<Lease__c> leases = [SELECT Id, Name FROM Lease__c];
    System.debug(leases);
    for(Lease__c ls : leases){
      ls.Lease_Status__c = 'Active';
    }
    update leases;
    Lease_School__c leaseSchool = new Lease_School__c();
    leaseSchool.Account_School__c = schools[0].Id;
    leaseSchool.Lease__c = leases[0].Id;
    insert leaseSchool;

    List<School_Attendance__c> saList = new List<School_Attendance__c>();
    Id facilitiesTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'School_Attendance__c' AND DeveloperName = 'Facilities' LIMIT 1].Id;
    for(Integer i = 0; i <= 3; i++){
      School_Attendance__c sa = new School_Attendance__c();
      sa.School__c = schools[0].Id;
      sa.RecordTypeId = facilitiesTypeId;
      sa.Attendance_Type__c = 'Q4';
      sa.Report_Date__c = Date.today().addDays(-i * 365);
      sa.Fiscal_Year__c = DateUtilities.getFiscalYear(sa.Report_Date__c);
      sa.Total_Attendance_manual__c = 200 - (i * 50);
      saList.add(sa);
    }
    insert saList;
    
      Id state = [SELECT Id FROM State_Province__c LIMIT 1].Id;
      List<Academic_Rating__c> arList = new List<Academic_Rating__c>();
      Academic_Rating__c ar = new Academic_Rating__c(
      	  Account__c = schools[0].Id,
          FY__c = '19-20',
          State_Province__c = state
      );
      arList.add(ar);
      
      Academic_Rating__c ar1 = new Academic_Rating__c(
      	  Account__c = schools[0].Id,
          FY__c = '20-21',
          State_Province__c = state
      );
      arList.add(ar1);
      
      Academic_Rating__c ar2 = new Academic_Rating__c(
      	  Account__c = schools[0].Id,
          FY__c = '21-22',
          State_Province__c = state
      );
      arList.add(ar2);
      
      Academic_Rating__c ar3 = new Academic_Rating__c(
      	  Account__c = schools[0].Id,
          FY__c = '22-23',
          State_Province__c = state
      );
      arList.add(ar3);
      
      insert arList;

    Charter_Term__c terms = new Charter_Term__c();
    terms.School__c = schools[0].Id;
    terms.Start_Date__c = Date.today().addDays(-365);
    terms.End_Date__c = Date.today().addDays(365);
    terms.No_Cap_Limit__c = true;
    insert terms;
    Test.startTest();
    List<AcademicRatingReportCtrl.SchoolDataWrapper> sdw = AcademicRatingReportCtrl.getSchoolData();
    System.assertEquals(sdw[0].CharterCapacity, 'No limit', 'capacity not matching');
    System.assertEquals(sdw[0].EnrollmentCurrentYear, 200, 'current year enrollment off'); // changing from 150
    System.assertEquals(sdw[0].EnrollmentPreviousYear, 150, 'previous year enrollment off'); // changing from 100
    System.assertEquals(sdw[0].CharterExpirationDate, Date.today().addDays(365), 'charter terms end date wrong');
    Test.stopTest();
  }
}