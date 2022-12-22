public with sharing class CreateFundedReceivablesCtrl {
	@auraEnabled
	public static void createReceivables(String feId){
		if (Schema.sObjectType.Funded_Receivable__c.fields.Name.isCreateable()) {
			System.debug('feid passed create: ' + feId);
			CreateFundedReceivables.wsCreateFundedReceivables(feId);
		} else {
			throw new AuraHandledException('Access denied.');
		}
	}

	@auraEnabled
	public static Funding_Estimates__c getEstimate(String feId){
		System.debug('feid passed: ' + feId);
		Funding_Estimates__c fe = [SELECT id, Name, Opportunity__r.Name, Converted_to_FR__c FROM Funding_Estimates__c WHERE id =: feId];
		return fe;
	}
}