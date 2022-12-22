public class ItemsByOppRecType {

    @AuraEnabled
    public string recordtypename {get;set;}
    
    @AuraEnabled
    public string status {get;set;}
    
    @AuraEnabled
    public Map<Id,String> cmos {get;set;}
    
    
    @AuraEnabled
	public List<IntakeItem> itemList {get;  set;}
    
    
}