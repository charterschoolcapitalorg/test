public with sharing class ContentDocumentHelper {
    
    @AuraEnabled(cacheable=true)
    public static ContentVersion getLatestVersionId(String accountId){
        Id contentId = [SELECT Id, Account_Image_Id__c FROM Account WHERE ID = :accountId WITH SECURITY_ENFORCED].Account_Image_Id__c;
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE ContentDocumentId =:contentId AND IsLatest = true WITH SECURITY_ENFORCED];

        if (contentVersions.size() != 1) {
            throw new AuraHandledException('Could not find image');
        }

        return contentVersions[0];

    }
}