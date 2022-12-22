/**=====================================================================
 * Appirio, Inc
 * Trigger Name: DrawNoteTrigger
 * Description: T-275864 : Create means to calculate new / existing client
 * Created Date: [05/13/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 11/02/2015					John Caughie				Call residual estimation calculation when activated
 =====================================================================*/
trigger DrawNoteTrigger on Draw_Note__c (after update) {

	if(trigger.isAfter && trigger.isUpdate){
		DrawNoteTriggerManager.calculateInterest(trigger.New, trigger.oldMap);
		DrawNoteTriggerManager.calculateResidual(trigger.New, trigger.oldMap);
	}
}