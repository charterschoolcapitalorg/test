public class IntakeItem {
	@AuraEnabled
    public string name {get;set;}
    @AuraEnabled
    public boolean hasChildren {get;set;}
    @AuraEnabled
	public Integer numPending {get;set;}
	@AuraEnabled
	public String action {get;set;}
	@AuraEnabled
	public boolean isDocument {get;set;}
    @AuraEnabled
	public Integer numItems {get;set;}
	@AuraEnabled
	public String status {get;set;}
}