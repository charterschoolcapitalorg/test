global with sharing class FinancialObjRevenueData extends lwcc.ChartDataProvider {
    // public FinancialObjDataProvider() {

    // }
    private static string recordId;

    public override void init(final Object initParameter) {
        // System.debug('initParameter: ' + initParameter);
        recordId = (String)initParameter;
      }    

    public override List<lwcc.ChartDataProvider.ChartData> getData() {

        final List<lwcc.ChartDataProvider.ChartData> chartDatas = new List<lwcc.ChartDataProvider.ChartData>();
        lwcc.ChartDataProvider.ChartData aChartData = new lwcc.ChartDataProvider.ChartData();
        aChartData.labels = DATA_LABELS;
        // aChartData.bgColor = color;
        aChartData.detail = getRevenueData();
        chartDatas.add(aChartData);
        return chartDatas;
    }
    
    public static final List<String> DATA_LABELS = new List<String>{ 'Federal', 'State', 'Local', 'Donations', 'Other' };
//   public static List<Decimal> data = new List<Decimal>();
//   public static final String color = 'rgba(0,0,0,0.5);';

    private static List<Decimal> getRevenueData(){
    Financial__c financialRecord = [SELECT Id, Federal_Revenue__c, State_Revenue__c, Local_Revenue__c, Donations__c, Other_Revenue__c, Total_Revenue__c FROM Financial__c WHERE id = :recordId];
    List<Decimal> data = new List<Decimal>();
    data.add(financialRecord.Federal_Revenue__c == null ? 0 : (financialRecord.Federal_Revenue__c/financialRecord.Total_revenue__c*100.0).setScale(2));
    data.add(financialRecord.State_Revenue__c == null ? 0 : (financialRecord.State_Revenue__c/financialRecord.Total_revenue__c*100.0).setScale(2));
    data.add(financialRecord.Local_Revenue__c == null ? 0 : (financialRecord.Local_Revenue__c/financialRecord.Total_revenue__c*100.0).setScale(2));
    data.add(financialRecord.Donations__c == null ? 0 : (financialRecord.Donations__c/financialRecord.Total_revenue__c*100.0).setScale(2));
    data.add(financialRecord.Other_Revenue__c == null ? 0 : (financialRecord.Other_Revenue__c/financialRecord.Total_revenue__c*100.0).setScale(2));
    System.debug('data' + data);
    return data;
    }

}