public with sharing class CloneUtility {
	private static Map<String, Schema.sObjectType> objTypeMap;
	
	static {
		objTypeMap = Schema.getGlobalDescribe();
	}
	
	public static String getCSCActionListBaseQuery() {
		return getBaseQuery('CSC_Action_List__c', null);
	}
	
	public static String getCSCActionListBaseQuery(List<String> additionalFields) {
		return getBaseQuery('CSC_Action_List__c', additionalFields);
	}

	public static String getCSCActionItemBaseQuery() {
		return getBaseQuery('CSC_Action_Item__c', null);
	}
	
	private static String getBaseQuery(String obj, List<String> additionalFields) {
		if(additionalFields == null || additionalFields.size() == 0){
			return 'SELECT Id, ' + String.join(getCloneFields(obj), ', ') + ' FROM ' + obj;
		} else {
			return 'SELECT Id, ' + String.join(getCloneFields(obj), ', ') + ', ' + String.join(additionalFields, ', ') + ' FROM ' + obj;
		}
		
	}
	
	private static List<String> getCloneFields(String objName) {
		List<String> fieldNames = new List<String>();
		
		if(objTypeMap.containsKey(objName)) {
			for(Schema.SObjectField sof : objTypeMap.get(objName).getDescribe().fields.getMap().values()) {
				Schema.DescribeFieldResult dfr = sof.getDescribe();
				
				if(dfr.isCalculated() || dfr.isUnique() || !dfr.isCreateable() || dfr.getName().equalsIgnoreCase('Id')) {
					continue;
				}
				
				fieldNames.add(dfr.getName());
			}
		}
		
		return fieldNames;
	}
}