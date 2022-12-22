trigger CSCActionListBeforeInsert on CSC_Action_List__c (before insert) {
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
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('csc_action_list__c') && ProfileCustomSettings.Triggers_Disabled__c) && !FeatureManagement.checkPermission('Bulk_Data_Load')){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        if(Flags.SkipActionListOrderResequencing) {
            return;
        }

        List<CSC_Action_List__c> reorderActionLists = new List<CSC_Action_List__c>();

        for(CSC_Action_List__c actionList : trigger.new) {
            if(actionList.Order__c == null || actionList.Order__c < CSCUtils.ActionListOrderThreshold) {
                reorderActionLists.add(actionList);
            }
        }

        if(reorderActionLists.size() > 1) {
            for(CSC_Action_List__c actionList : reorderActionLists) {
                actionList.addError('Multiple action lists cannot be resequenced at the same time.');
            }

            return;
        }

        if(reorderActionLists.size() == 1) {
            CSC_Action_List__c newActionList = reorderActionLists.get(0);
            List<CSC_Action_List__c> actionLists = [SELECT Id, Order__c FROM CSC_Action_List__c WHERE Account__c = :newActionList.Account__c AND Order__c < :CSCUtils.ActionListOrderThreshold ORDER BY Order__c];

            if(newActionList.Order__c == null || newActionList.Order__c <= 0 || newActionList.Order__c >= actionLists.size()) {
                newActionList.Order__c = actionLists.size() + 1;
            } else {
                List<CSC_Action_List__c> updateActionLists = new List<CSC_Action_List__c>();
                Integer i = 1;

                for(CSC_Action_List__c actionList : actionLists) {
                    if(i == newActionList.Order__c.intValue()) {
                        i++;
                    }

                    actionList.Order__c = i++;
                    updateActionLists.add(actionList);
                }

                if(!updateActionLists.isEmpty()) {
                    Flags.SkipActionListOrderResequencing = true;

                    try {
                        update updateActionLists;
                    } finally {
                        Flags.SkipActionListOrderResequencing = false;
                    }
                }
            }
        }
    }
}