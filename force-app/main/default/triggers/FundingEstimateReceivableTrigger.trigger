/**=====================================================================
* Charter School CaPital
* Trigger Name: FundingEstimateReceivableTrigger
* Description: Case :00001565 - Identify receivables being purchased on a weekend or holiday
* Created Date: [09/09/2019]
* Created By: Johners
* Date Modified                Modified By                  Description of the update
* 
*======================================================================*/
trigger FundingEstimateReceivableTrigger on Funding_Estimate_Receivable__c (before insert, before update) {
	
	BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
	if(ProfileCustomSettings.Trigger_Objects__c == null){
		ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
		ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('funding_estimate_receivable__c') && ProfileCustomSettings.Triggers_Disabled__c)){
		if(Trigger.isBefore){
            if(Trigger.isInsert || Trigger.isUpdate){
            	FundingEstimateReceivableTriggerManager.determineBusinessDay(Trigger.new);
            }
        }
	}
}