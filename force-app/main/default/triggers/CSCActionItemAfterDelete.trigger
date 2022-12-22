trigger CSCActionItemAfterDelete on CSC_Action_Item__c (after delete) {
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    // 05/06/2014 : Manisha Gupta : Add null check (T-276525)
    if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('csc_action_item__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        Map<Id, List<CSC_Action_Item__c>> listItemsMap = new Map<Id, List<CSC_Action_Item__c>>();

        for(CSC_Action_Item__c actionItem : trigger.old) {
            listItemsMap.put(actionItem.CSC_Action_List__c, new List<CSC_Action_Item__c>());
        }

        List<CSC_Action_Item__c> actionItems = [SELECT Id, CSC_Action_List__c, Order__c FROM CSC_Action_Item__c WHERE CSC_Action_List__c IN :listItemsMap.keySet() AND Order__c < :CSCUtils.ActionListOrderThreshold ORDER BY CSC_Action_List__c, Order__c];

        for(CSC_Action_Item__c actionItem : actionItems) {
            List<CSC_Action_Item__c> listItems = listItemsMap.get(actionItem.CSC_Action_List__c);
            listItems.add(actionItem);
            actionItem.Order__c = listItems.size();
        }

        if(!actionItems.isEmpty()) {
            Flags.SkipActionItemOrderResequencing = true;
            update actionItems;
            Flags.SkipActionItemOrderResequencing = false;
        }
    }
}