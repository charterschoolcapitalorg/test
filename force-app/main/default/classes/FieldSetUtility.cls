public inherited sharing class FieldSetUtility {
    
    private static Map<String, String> objToIconMap = new Map<String, String> {
		'account' => 'standard:account',
		'contact' => 'standard:contact',
		'event' => 'standard:event',
		'campaign' => 'standard:campaign',
		'campaignmember' => 'standard:campaign_members',
		'case' => 'standard:case',
		'contract' => 'standard:contract',
		'document' => 'standard:document',
		'entitlement' => 'standard:entitlement',
		'lead' => 'standard:lead',
		'opportunity' => 'standard:opportunity',
		'user' => 'standard:people',
		'product' => 'standard:product',
		'task' => 'standard:task'
	};

    public static List<FieldDescription> getFieldSetFields(String fsName, String objName) {
		List<FieldDescription> fields = new List<FieldDescription>();

		Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objName);
		Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

		Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fsName);
 
 		for (FieldSetMember member : fieldSetObj.getFields()) {
 			try {
 				fields.add( new FieldDescription(member, objName) );
			} catch (Exception e) {
				System.debug('Failed to add field description to list for field: '+member.getFieldPath()+' on object: '+objName);
				System.debug('Error: '+e.getMessage());
				System.debug('Stack Trace: '+e.getStackTraceString());
			}
 		}
		return fields; 
	}

    public class FieldDescription {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String fieldPath { get; set; }
		@AuraEnabled
		public String objType { get; set; }
		@AuraEnabled
		public String referencedObject { get; set; }
		@AuraEnabled
		public String type { get; set; }
		@AuraEnabled
		public Boolean required { get; set; }
		@AuraEnabled
		public String iconName { get; set; }
		@AuraEnabled
		public Boolean editable { get; set; }

		public FieldDescription(FieldSetMember member, String objType) {
			this.label = member.getLabel();
			this.fieldPath = member.getFieldPath();
			this.objType = objType;
			this.type = String.valueOf(member.getType()).toLowerCase();
			this.required = (member.getDBRequired() || member.getRequired());
			this.iconName = 'custom:custom9';
			this.editable = true;

			if (this.type.equalsIgnoreCase('reference') || this.fieldPath.contains('.')) {
				if ( this.fieldPath.contains('.') ) {
					String lookupField = this.fieldPath.split('\\.')[0];
					lookupField = lookupField.replace('__r', '__c');
					Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objType).getDescribe().fields.getMap().get(lookupField).getDescribe();
					this.referencedObject = fieldResult.getReferenceTo()[0].getDescribe().getName();
					lookupField = this.fieldPath.split('\\.')[1];
					lookupField = lookupField.replace('__r', '__c');
					fieldResult = Schema.getGlobalDescribe().get(this.referencedObject).getDescribe().fields.getMap().get(lookupField).getDescribe();

					this.editable = fieldResult.isUpdateable();
				} else {
					Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objType).getDescribe().fields.getMap().get(this.fieldPath).getDescribe();
					this.editable = fieldResult.isUpdateable();
					this.referencedObject = fieldResult.getReferenceTo()[0].getDescribe().getName();
				}
			} else {
				Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objType).getDescribe().fields.getMap().get(this.fieldPath).getDescribe();
				this.editable = fieldResult.isUpdateable();
				this.referencedObject = this.objType;
			}

			if ( objToIconMap.containsKey(this.referencedObject.toLowerCase()) ) this.iconName = objToIconMap.get(this.referencedObject.toLowerCase());
		}
	}
}