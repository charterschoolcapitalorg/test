/**=====================================================================
 * Appirio, Inc
 * Trigger Name: ProgramFeeTrigger
 * Description: T-278354 : Trigger for task 'Create RPA monthly report Fields'
 * Created Date: [05/23/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
trigger ProgramFeeTrigger on Program_Fee__c (after insert) {
	/*BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    if(ProfileCustomSettings <> null
      && ProfileCustomSettings.Trigger_Objects__c <> null &&
      !(ProfileCustomSettings.Trigger_Objects__c.contains('Program_Fee__c') && ProfileCustomSettings.Triggers_Disabled__c)){*/
      	if(Trigger.isAfter){
            if(Trigger.isInsert){
               ProgramFeeTriggerManager.RecentProgramFeeRPAUpdate(Trigger.New);
            }
      	}
     //}
}