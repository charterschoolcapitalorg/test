/**=====================================================================
 * Trigger Name: DocuSignStatusTrigger
 * Description: Trigger for updates on docuSign status records
 * Created Date: [02/16/2018]
 * Created By: John Caughie
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
trigger DocuSignStatusTrigger on dsfs__DocuSign_Status__c (after update) {
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    if(ProfileCustomSettings.Trigger_Objects__c == null){
        ProfileCustomSettings.Trigger_Objects__c = '';
    }
    if(ProfileCustomSettings.Triggers_Disabled__c == null){
        ProfileCustomSettings.Triggers_Disabled__c = false;
    }
    if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('dsfs__docusign_status__c') && ProfileCustomSettings.Triggers_Disabled__c)){
        if(trigger.isAfter && trigger.isUpdate){
            DocuSignStatusTriggerManager.OnAfterInsertUpdate(trigger.newMap, trigger.oldMap);
        }
    }
}