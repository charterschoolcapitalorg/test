/**=====================================================================
 * Appirio, Inc
 * Trigger Name: AllocationTrigger
 * Description: T-279945 : Trigger to calculate the rolled up payment on the receivable
 * Created Date: [05/20/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 
 * 06/10/2014					Rajeev Arya 				 T-286219 Revise trigger code
 * 03/20/2017                   John Caughie                 Added Appirio Custom Setting for conditional control
 =====================================================================*/
trigger AllocationTrigger on Allocation__c (after delete, after insert, after update) {

  BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
  if(ProfileCustomSettings.Trigger_Objects__c == null){
      ProfileCustomSettings.Trigger_Objects__c = '';
  }
  if(ProfileCustomSettings.Triggers_Disabled__c == null){
      ProfileCustomSettings.Triggers_Disabled__c = false;
  }
  if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('allocation__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    	if(Trigger.isAfter){
            if(Trigger.isInsert || Trigger.isUpdate){
                AllocationTriggerManager.AddAllocationToFundedReceivable(Trigger.New);
            }
        	if(Trigger.isDelete){
        		AllocationTriggerManager.AddAllocationToFundedReceivable(Trigger.Old);
        	}
        }  
    
    }
}