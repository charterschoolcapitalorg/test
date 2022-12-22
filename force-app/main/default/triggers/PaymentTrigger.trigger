/**=====================================================================
 * Appirio, Inc
 * Trigger Name: PaymentTrigger
 * Description: T-275864 : To calculate interests on Draw Notes when payments are made using Payment Sub
 * Created Date: [05/15/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 05/20/2014                   Manisha Gupta                   Writing the logic for the task T-275864
 *
 =====================================================================*/
trigger PaymentTrigger on Payment__c (after insert) {
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    if(ProfileCustomSettings.Trigger_Objects__c == null){
        ProfileCustomSettings.Trigger_Objects__c = '';
    }
    if(ProfileCustomSettings.Triggers_Disabled__c == null){
        ProfileCustomSettings.Triggers_Disabled__c = false;
    }
    if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('payment__c') && ProfileCustomSettings.Triggers_Disabled__c)){
        if(trigger.isAfter && trigger.isInsert){
            // calculate interest and create draw entry every time payment is made against any draw note
            PaymentTriggerManager.calculateDrawInterestTrigger(trigger.new);							//2015.08.07 J Caughie - Updated to point to new method
        }
    }
}