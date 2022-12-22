//Added for Lead Conversion process - TODO combined all trigers into one!

trigger OpportunityBeforeInsert on Opportunity (before insert) {

  BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
  if(ProfileCustomSettings.Trigger_Objects__c == null){
      ProfileCustomSettings.Trigger_Objects__c = '';
  }
  if(ProfileCustomSettings.Triggers_Disabled__c == null){
      ProfileCustomSettings.Triggers_Disabled__c = false;
  }
  if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('opportunity') && ProfileCustomSettings.Triggers_Disabled__c)){
        if(Trigger.isBefore && Trigger.isInsert){
                OpportunityHelper.onBeforeInsert();
        }
    }
    
}