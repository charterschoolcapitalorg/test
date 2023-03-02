/**=====================================================================
 * Charter School Capital
 * Name: MarketRateEvents
 * Test Class: MarketRateTriggerHandlerTest
 * Description: 
 * Created Date: 2023, Feb 05
 * Created By: Slava Krel
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/

trigger MarketRateEvents on Market_Rate__c (before update) {
    if (trigger.isBefore) { 
        if (trigger.isUpdate) {
            MarketRateTriggerHandler handler = new MarketRateTriggerHandler(trigger.oldMap, trigger.newMap, trigger.old, trigger.new);
            handler.beforeUpdate();
        }
    }
}