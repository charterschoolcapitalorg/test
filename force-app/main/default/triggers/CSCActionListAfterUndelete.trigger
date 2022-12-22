trigger CSCActionListAfterUndelete on CSC_Action_List__c (after undelete) {
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance(UserInfo.getUserId());
    // 05/06/2014 : Manisha Gupta : Add null check (T-276525)
    if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('csc_action_list__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        List<CSC_Action_List__c> actionLists = [SELECT Id, Order__c FROM CSC_Action_List__c WHERE Id IN :trigger.newMap.keySet()];

        for(CSC_Action_List__c actionList : actionLists) {
            actionList.Order__c = CSCUtils.ActionListOrderThreshold;
        }

        Flags.SkipActionListOrderResequencing = true;
        update actionLists;
        Flags.SkipActionListOrderResequencing = false;
    }
}