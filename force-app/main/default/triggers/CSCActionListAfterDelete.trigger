trigger CSCActionListAfterDelete on CSC_Action_List__c (after delete) {
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
        Map<Id, List<CSC_Action_List__c>> accountListsMap = new Map<Id, List<CSC_Action_List__c>>();

        for(CSC_Action_List__c actionList : trigger.old) {
            accountListsMap.put(actionList.Account__c, new List<CSC_Action_List__c>());
        }

        List<CSC_Action_List__c> actionLists = [SELECT Id, Account__c, Order__c FROM CSC_Action_List__c WHERE Account__c IN :accountListsMap.keySet() AND Order__c < :CSCUtils.ActionListOrderThreshold ORDER BY Account__c, Order__c];

        for(CSC_Action_List__c actionList : actionLists) {
            List<CSC_Action_List__c> accountLists = accountListsMap.get(actionList.Account__c);
            accountLists.add(actionList);
            actionList.Order__c = accountLists.size();
        }

        if(!actionLists.isEmpty()) {
            Flags.SkipActionListOrderResequencing = true;
            update actionLists;
            Flags.SkipActionListOrderResequencing = false;
        }
    }
}