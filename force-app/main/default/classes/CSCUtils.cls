public with sharing class CSCUtils {
	public static Integer ActionListOrderThreshold { get {
			if(ActionListOrderThreshold == null) {
				Action_List_Settings__c actionListSettings = Action_List_Settings__c.getOrgDefaults();
				ActionListOrderThreshold = actionListSettings != null && actionListSettings.Order_Threshold__c != null ? actionListSettings.Order_Threshold__c.intValue() : 50;
			}
			
			return ActionListOrderThreshold;
		}
		private set;
	}
	
	@future
	public static void deleteAttachments(Set<Id> attachmentIds) {
		Database.delete(new List<Id>(attachmentIds));
	}
}