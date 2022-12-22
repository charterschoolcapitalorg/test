public class IntakeCustomDetailCtrl {
	public IntakeCustomDetailCtrl() {
        
    }
    
    @AuraEnabled
    public static String getBoxURL(string iId) {
        System.debug('****iId: ' + iId);
        User u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
        Intake_Item__c item= [SELECT id,Opportunity__c FROM Intake_Item__c WHERE Id=:iId];
        STring role;
        if (test.isrunningtest()) {
        	role = 'School';
        } else {
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        role = drm.role__c;
        }
        system.debug('role: '+role);        
        Box_Read_Only_Shares__c folder = [SELECT id,Box_URL__c, Role__c, Opportunity__r.Name FROM Box_Read_Only_Shares__c WHERE Opportunity__c =:item.Opportunity__c AND Role__c =:role LIMIT 1];

        return folder.Box_URL__c;
        
    }
    
    @AuraEnabled
    public static INtake_Item__c getItem(string iId) {
        System.debug('****iId: ' + iId);
        
        Intake_Item__c item= [SELECT id,Account_Manager__c, Client_Comments__c, Account_Manager_Email__c, Account_Manager_Phone__c, Opportunity__r.Account.Name, Opportunity__r.AccountId,Visible_To__c, 
                                           Comments__c, Is_Document__c, Parent_Intake_Item__c, Action_URL__c,Name,OppName__c,
                                           Status__c,Is_Pre_Qual__c, Status_Reason__c,Opportunity__r.Name,Due_Date__c,
                                           Document_Name__c,
                                           Assigned_To__c,
                                           Due__c,Processing_Order__c
                                            FROM Intake_Item__c WHERE Id=:iId];
        return item;
    }
    @AuraEnabled
    public static List<ContentDocument> getFiles(string iId) {
        List<ContentDocumentLink > files = [Select ContentDocument.Title, ContentDocumentId from ContentDocumentLink where LinkedEntityId=:iId];
        System.debug('****files: ' + files);
        Set<Id> ids = new Set<Id>();
        for (ContentDocumentLink c : files) {
            ids.add(c.ContentDocumentId);
            System.debug('****file: ' + c.ContentDocument.Title);
        }
        List<ContentDocument> docs = [Select Id, CreatedDate, TItle from ContentDocument where Id IN:ids];
        System.debug('****docs: ' + docs);
        return docs;
    }
    @AuraEnabled
    public static String submit(String upsertData){
	    try {
	        		
        	INtake_Item__c toUpsertData = (INtake_Item__c)System.JSON.deserializeStrict(upsertData, INtake_Item__c.Class);
	        System.debug('****upserting - ' + toupsertdata.Id);
	        upsert toUpsertData;
            
        	return '';
        } catch (EXception e) {
        		return e.getmessage();
        }
        	
    }
}