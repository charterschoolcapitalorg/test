global without sharing class RescoreAllCurrentPricingRatesBatch implements Database.Batchable<sObject> {
    
    private static final String CLASS_NAME = 'RescoreAllCurrentPricingRatesBatch';

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Market_Rate__c activeMR = MarketRateService.getActiveMarketRate();
        return Database.getQueryLocator([SELECT Id FROM Pricing_Rate__c WHERE Market_Rate__c =: activeMR.Id AND Active__c = false]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        ExceptionLogger.flushable = true;
        Pricing_Rate__c pRate = (Pricing_Rate__c)scope[0];
        try {
            PricingRateScore score = new PricingRateScore(pRate.Id);
            score.rescore();
            if (score.errors!=null) {
                for (String recId : score.errors.keySet()) { 
                    String erStr = score.errors.get(recId);
                    ExceptionLogger.log(new DMLOperation.DMLOpException(erStr), 'Pricing_Rate__c', CLASS_NAME, 'execute');
                }
            }
        } catch (Exception e) {
            ExceptionLogger.log(e, 'Pricing_Rate__c', CLASS_NAME, 'execute'); 
        }
        ExceptionLogger.flushLogCache();
    }

    public void finish(Database.BatchableContext BC) {} 
}