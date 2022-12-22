global with sharing class FinancialObjExpenseData extends lwcc.ChartDataProvider {
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
        aChartData.detail = getExpenseData();
        chartDatas.add(aChartData);
        return chartDatas;
      }
    
    public static final List<String> DATA_LABELS = new List<String>{ 'Rent', 'Utilities', 'Salary & Benefits', 'Management Fees', 'Other' };
//   public static List<Decimal> data = new List<Decimal>();
//   public static final String color = 'rgba(0,0,0,0.5);';

    private static List<Decimal> getExpenseData(){
    Financial__c financialRecord = [SELECT Id, Rent__c, Utilities__c, Salaries_Benefits__c, Other_Opex__c, Management_Fee__c, Total_Opex_Ex__c FROM Financial__c WHERE id = :recordId];
    List<Decimal> data = new List<Decimal>();
    data.add(financialRecord.Rent__c == null ? 0 : (financialRecord.Rent__c/financialRecord.Total_Opex_Ex__c*100.0).setScale(2));
    data.add(financialRecord.Utilities__c == null ? 0 : (financialRecord.Utilities__c/financialRecord.Total_Opex_Ex__c*100.0).setScale(2));
    data.add(financialRecord.Salaries_Benefits__c == null ? 0 : (financialRecord.Salaries_Benefits__c/financialRecord.Total_Opex_Ex__c*100.0).setScale(2));
    data.add(financialRecord.Management_Fee__c == null ? 0 : (financialRecord.Management_Fee__c/financialRecord.Total_Opex_Ex__c*100.0).setScale(2));
    data.add(financialRecord.Other_Opex__c == null ? 0 : (financialRecord.Other_Opex__c/financialRecord.Total_Opex_Ex__c*100.0).setScale(2));
    System.debug('data' + data);
    return data;
    }

}