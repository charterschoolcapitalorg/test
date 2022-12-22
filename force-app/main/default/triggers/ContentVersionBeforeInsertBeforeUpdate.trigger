trigger ContentVersionBeforeInsertBeforeUpdate on ContentVersion (before insert, before update) {
	/*[02/10/20] - J Caughie - This custom setting is used to conditionally control for which users/profile or the entire org
	the triggers, validation rules and workflow rules fire*/
	BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
	if(ProfileCustomSettings.Trigger_Objects__c == null){
			ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
			ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.containsIgnoreCase('ContentVersion') && ProfileCustomSettings.Triggers_Disabled__c)){ 	
		Set<Id> aiIds = new Set<Id>();
		for(ContentVersion ver : trigger.new) {
			ContentVersion old = trigger.isUpdate ? trigger.oldMap.get(ver.Id) : new ContentVersion();
			
			if(String.isNotBlank(ver.Related_Action_Item__c) && (ver.Related_Action_Item__c != old.Related_Action_Item__c || String.isBlank(ver.Related_Action_List__c))) {
				aiIds.add(ver.Related_Action_Item__c);
			}
		}
		
		aiIds.remove(null);
		
		if(!aiIds.isEmpty()) {
			Map<Id, CSC_Action_Item__c> aiMap = new Map<Id, CSC_Action_Item__c>([SELECT Id, CSC_Action_List__c FROM CSC_Action_Item__c WHERE Id IN :aiIds]);
			
			for(ContentVersion cv : trigger.new) {
				if(aiMap.containsKey(cv.Related_Action_Item__c)) {
					cv.Related_Action_List__c = aiMap.get(cv.Related_Action_Item__c).CSC_Action_List__c;
				}
			}
		}
	}
}