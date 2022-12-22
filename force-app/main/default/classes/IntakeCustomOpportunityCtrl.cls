public class IntakeCustomOpportunityCtrl {
    public IntakeCustomOpportunityCtrl() {
        
    }
    
    @AuraEnabled
    public static Opportunity getOpp(string oppId) {
        System.debug('****oppId: ' + oppId);
        Opportunity opp = [SELECT Id, Name,Target_Wire_Date__c, Funded_Date__c,NET_Amount_Requested__c, Reporting_Value__c, Owner_Name__c,
                           Owner_Email__c, OWner_Phone__c, 
                           Client_Comments__c FROM Opportunity WHERE Id =: oppId];
        System.debug('****opp: ' + opp );
        return opp;
    }
     @AuraEnabled
    public static User getOwner(string oppId) {
        System.debug('****oppId: ' + oppId);
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Id =: oppId];
        System.debug('****owner Id: ' + opp.OwnerId);
        try {
            User u = [SELECT Id, LastName, Name, FirstName, Email, Phone FROM User WHERE Id =: opp.OwnerId];
            System.debug('****user: ' + u + ' email: ' + u.Email + ' phone: ' + u.Phone);
            return u;
        } catch (EXception e) {
            System.debug('****exception getting user: ' + e.getstacktracestring() + ' - ' + e.getmessage());
            return null;
        }
    }
    @AuraEnabled
    public static List<ContentDocument> getFiles(string oppId) {
        List<ContentDocumentLink > files = [Select ContentDocument.Title, ContentDocumentId from ContentDocumentLink where LinkedEntityId=:oppId];
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
                    
            Opportunity toUpsertData = (Opportunity)System.JSON.deserializeStrict(upsertData, Opportunity.Class);
            System.debug('****upserting - ' + toupsertdata.Id);
            upsert toUpsertData;
            
            return '';
        } catch (EXception e) {
                return e.getmessage();
        }
            
    }
}