trigger MarketRateEvents on Market_Rate__c (after insert, after update) {

    if (Trigger.isInsert) {
        MarketRateTriggerHandler.determineIfActivatingRate(Trigger.new);
    }
    if (Trigger.isUpdate) {
        MarketRateTriggerHandler.determineIfActivatingRate(Trigger.new, Trigger.oldMap);
    }
}