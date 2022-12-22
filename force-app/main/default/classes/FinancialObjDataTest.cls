@isTest
private class FinancialObjDataTest {
    
    @testSetup 
    static void dataSetUp() {
        TestHelper.createSeedDataForTesting();
        Account acc = [SELECT Id, Name FROM Account WHERE RecordType.DeveloperName = 'Charter_Holder' LIMIT 1];
        Financial__c finRecord = new Financial__c();
        finRecord.Account__c = acc.Id;
        finRecord.Federal_Revenue__c = 100000;
        finRecord.State_Revenue__c = 200000;
        finRecord.Local_Revenue__c = 50000;
        finRecord.Total_Revenue__c = 500000;
        finRecord.Rent__c = 10000;
        finRecord.Utilities__c = 5000;
        finRecord.Salaries_Benefits__c = 50000; 
        finRecord.Management_Fee__c = 10000;
        finRecord.Total_Expense__c = 100000;
        insert finRecord;

    }
  
    @isTest
    static void testGetRevenueData() {
      Test.startTest();
      final FinancialObjRevenueData finObjData = new FinancialObjRevenueData();
      Financial__c finRecord = [SELECT Id FROM Financial__c LIMIT 1];
      finObjData.init(finRecord.id);
      final List<lwcc.ChartDataProvider.ChartData> chartDatas = finObjData.getData();
      lwcc.ChartDataProvider.ChartData aChartData = chartDatas[0];
      Test.stopTest();
      System.debug('chartDatas ' + chartDatas);
      System.assertEquals(aChartData.labels[0], 'Federal', 'label does not match');
      System.assertEquals(aChartData.detail[0], 20.00, 'value does not match');
    //   System.assertEquals(finObjData.color, chartDatas[0].bgColor, 'chartDatas.bgColor must equals ' + finObjData.color);
    }

    @isTest
    static void testGetExpenseData() {
      Test.startTest();
      final FinancialObjExpenseData finObjData = new FinancialObjExpenseData();
      Financial__c finRecord = [SELECT Id FROM Financial__c LIMIT 1];
      finObjData.init(finRecord.id);
      final List<lwcc.ChartDataProvider.ChartData> chartDatas = finObjData.getData();
      lwcc.ChartDataProvider.ChartData aChartData = chartDatas[0];
      Test.stopTest();
      System.debug('chartDatas ' + chartDatas);
      System.assertEquals(aChartData.labels[0], 'Rent', 'label does not match');
      System.assertEquals(aChartData.detail[0], 10, 'value does not match');
    //   System.assertEquals(finObjData.color, chartDatas[0].bgColor, 'chartDatas.bgColor must equals ' + finObjData.color);
    }    


}