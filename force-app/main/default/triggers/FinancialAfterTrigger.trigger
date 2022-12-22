trigger FinancialAfterTrigger on Financial__c (before insert, before update) {
    if (trigger.isbefore) {
        FinancialUtils.afterTrigger(trigger.new, (trigger.isupdate ? trigger.oldMap : null));
    }
}