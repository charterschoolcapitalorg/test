public class ItemDocUploadWrapper {
	@AuraEnabled
	public Intake_Item__c item {get;set;}
    
	@AuraEnabled
	public Integer numPending {get;set;}
    
    public ItemDocUploadWrapper(Intake_Item__c i) {
    	item = i;
    }
}