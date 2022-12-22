trigger Redemption on Redemption__c (before update) {

  BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
  if(ProfileCustomSettings.Trigger_Objects__c == null){
      ProfileCustomSettings.Trigger_Objects__c = '';
  }
  if(ProfileCustomSettings.Triggers_Disabled__c == null){
      ProfileCustomSettings.Triggers_Disabled__c = false;
  }
  if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('redemption__c') && ProfileCustomSettings.Triggers_Disabled__c)){
		  RedemptionTriggerManager.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}