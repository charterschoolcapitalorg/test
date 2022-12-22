@isTest
private class AccountManagementReportCtrlTest {
  @testSetup static void setupData() {
    //Create operating state
    //Create Charter
    //Create Payout Date
    TestHelper.createSeedDataForTesting();   
    Id charterId = [SELECT Id FROM Account LIMIT 1].Id;

    //Create Funded Receivables
    RPA__c rpa = TestHelper.createRPA(charterId);
    insert rpa;
    Payout_Date__c pd = [SELECT Id FROM Payout_Date__c LIMIT 1];
    Funded_Receivable__c fr = TestHelper.createFundedReceivable(pd.Id, 100000, charterId, rpa.Id);
    insert fr;

  }

  @isTest static void getAccountDataTestUndated(){
    Test.startTest();
    List<AccountManagementReportWrapper> amrw = AccountManagementReportCtrl.getAccountData();
    Test.stopTest();
    System.assertEquals(100000, amrw[0].faceValueDue, 'FV due doesn\t match');
    System.assertEquals('Not calculable', amrw[0].boughtUntil, 'Receivable dates don\'t match');
    System.assertEquals('n/a', amrw[0].nextWhiteboardOpp, 'No WB opps');
  }

  @isTest static void getAccountDataTestDated(){
    //get payout date from FR
    Funded_Receivable__c fr = [SELECT Id, Source_Payout_Date_Record__r.Id FROM Funded_Receivable__c LIMIT 1];

    Payout_Date__c pd = [Select Id, Name, Receivable_Representative_Date__c FROM Payout_Date__c WHERE id=:fr.Source_Payout_Date_Record__r.Id];
    pd.Receivable_Representative_Date__c = Date.newInstance(2020, 10, 1);
    update pd;
    
    Test.startTest();
    List<AccountManagementReportWrapper> amrw = AccountManagementReportCtrl.getAccountData();
    Test.stopTest();
    System.assertEquals(100000, amrw[0].faceValueDue, 'FV due doesn\t match');
    System.assertEquals('Oct 20', amrw[0].boughtUntil, 'Receivable dates don\'t match');
    System.assertEquals('n/a', amrw[0].nextWhiteboardOpp, 'No WB opps');
  }

  @isTest static void getAccountDataTestNonSystem(){
    //get payout date from FR
    Funded_Receivable__c fr = [SELECT Id, Source_Payout_Date_Record__r.Id FROM Funded_Receivable__c LIMIT 1];
    fr.Source_Payout_Date_Record__c = null;
    update fr;
    
    Test.startTest();
    List<AccountManagementReportWrapper> amrw = AccountManagementReportCtrl.getAccountData();
    Test.stopTest();
    System.assertEquals(100000, amrw[0].faceValueDue, 'FV due doesn\t match');
    System.assertEquals('Not calculable', amrw[0].boughtUntil, 'Receivable dates don\'t match');
    System.assertEquals('n/a', amrw[0].nextWhiteboardOpp, 'No WB opps');
  }

}