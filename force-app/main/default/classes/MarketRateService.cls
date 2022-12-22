public inherited sharing class MarketRateService {
    
    private static Market_Rate__c activeMarketRate;

    public static Market_Rate__c getActiveMarketRate() {
        if (activeMarketRate==null || Test.isRunningTest()) activeMarketRate = fetchActiveMarketRate();
        return activeMarketRate;
    }

    private static Market_Rate__c fetchActiveMarketRate() { 
        return [SELECT Id, Reporting_Date__c FROM Market_Rate__c WHERE Current_Monthly_Rate__c = true ORDER BY Reporting_Date__c ASC LIMIT 1];
    }
}