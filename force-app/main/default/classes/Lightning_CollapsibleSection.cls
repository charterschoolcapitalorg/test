public class Lightning_CollapsibleSection {
    
    public static List<intake_item__c> getItems(string recordtypename){
        list<intake_item__c> items = [SELECT id,name,Opportunity__c,Is_Visible_To_Community__c,Is_Document__c, 
                                      Opportunity__r.recordtypeid, Opportunity__r.recordtype.name
                                   FROM Intake_Item__c WHERE Is_Visible_To_Community__c = TRUE AND Is_Document__c = TRUE 
                                      AND Opportunity__r.recordtypeid =: recordtypename];
        
        return items;
        
    }

}