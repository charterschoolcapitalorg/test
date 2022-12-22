trigger CSCActionItemBeforeInsert on CSC_Action_Item__c (before insert) {
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
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('csc_action_item__c') && ProfileCustomSettings.Triggers_Disabled__c) && !FeatureManagement.checkPermission('Bulk_Data_Load')){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        if(Flags.SkipActionItemOrderResequencing) {
            return;
        }

        List<CSC_Action_Item__c> reorderActionItems = new List<CSC_Action_Item__c>();

        for(CSC_Action_Item__c actionItem : trigger.new) {
            if(actionItem.Order__c == null || actionItem.Order__c < CSCUtils.ActionListOrderThreshold) {
                reorderActionItems.add(actionItem);
            }
        }

        if(reorderActionItems.size() > 1) {
            for(CSC_Action_Item__c actionItem : reorderActionItems) {
                actionItem.addError('Multiple action items cannot be resequenced at the same time.');
            }

            return;
        }

        if(reorderActionItems.size() == 1) {
            CSC_Action_Item__c newActionItem = reorderActionItems.get(0);
            List<CSC_Action_Item__c> actionItems = [SELECT Id, Order__c FROM CSC_Action_Item__c WHERE CSC_Action_List__c = :newActionItem.CSC_Action_List__c AND Order__c < :CSCUtils.ActionListOrderThreshold ORDER BY Order__c];

            if(newActionItem.Order__c == null || newActionItem.Order__c <= 0 || newActionItem.Order__c >= actionItems.size()) {
                newActionItem.Order__c = actionItems.size() + 1;
            } else {
                List<CSC_Action_Item__c> updateActionItems = new List<CSC_Action_Item__c>();
                Integer i = 1;

                for(CSC_Action_Item__c actionItem : actionItems) {
                    if(i == newActionItem.Order__c.intValue()) {
                        i++;
                    }

                    actionItem.Order__c = i++;
                    updateActionItems.add(actionItem);
                }

                if(!updateActionItems.isEmpty()) {
                    Flags.SkipActionItemOrderResequencing = true;

                    try {
                        update updateActionItems;
                    } finally {
                        Flags.SkipActionItemOrderResequencing = false;
                    }
                }
            }
        }
    }
}