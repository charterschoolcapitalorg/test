public with sharing class MarketRateTriggerHandler {
    
    public static Boolean triggerActive = true;

    public static void determineIfActivatingRate(List<Market_Rate__c> triggerRates) {
        if (!triggerActive) return;
        for (Market_Rate__c newRate : triggerRates) {
            if (newRate.Current_Monthly_Rate__c) {
                launchPricingRateDuplicationBatch();
                break;
            }
        }
    }

    public static void determineIfActivatingRate(List<Market_Rate__c> triggerRates, Map<Id, Market_Rate__c> oldRates) {
        if (!triggerActive) return;
        for (Market_Rate__c updRate : triggerRates) {
            Market_Rate__c oldRate = oldRates.get(updRate.Id);
            if (updRate.Current_Monthly_Rate__c && !oldRate.Current_Monthly_Rate__c) {
                launchPricingRateDuplicationBatch();
                break;
            }
        }
    }

    private static void launchPricingRateDuplicationBatch() {
        if (!triggerActive) return;
        CloneAllActivePricingRatesBatch b = new CloneAllActivePricingRatesBatch();
        Database.executeBatch(b);
    }
}