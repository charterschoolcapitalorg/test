@isTest

private class FileUploaderCtrlTest {
    
    private static void setup() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        CSC_Action_List__c aList = new CSC_Action_List__c();
        aList.Action_List_Name__c = 'Test Action List';
        aList.Account__c = acc.Id;
        aList.Library_Type__c = 'Underwriting';
        insert aList;

        CSC_Action_Item__c aItem = new CSC_Action_Item__c();
        aItem.Action_Item_Name__c = 'Test Action Item';
        aItem.CSC_Action_List__c = aList.Id;
        insert aItem;

        List<ContentVersion> cVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 10; i++) {
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Sample Document ' + (i + 1),
                PathOnClient = 'document.txt',
                VersionData = Blob.valueOf('Content goes here'),
                IsMajorVersion = true
            );
            cVersions.add(contentVersion);
        }
        insert cVersions;
    }

    @isTest static void testRelatingFile(){
        setup();
        List<ContentDocument> cDocuments = [SELECT Id FROM ContentDocument];
        List<String> fileIds = new List<String>();
        for(ContentDocument cd : cDocuments){
            fileIds.add((String) cd.Id);
        }
        String records = 'CSC_Action_List__c, Account_Id__c';
        String libraryField = 'Library_Type__c';
        CSC_Action_Item__c aItem = [SELECT Id, Library_Type__c FROM CSC_Action_Item__c WHERE Action_Item_Name__c = 'Test Action Item'];

        Test.startTest();
            FileUploaderCtrl.relateFileToObjects(fileIds, records, libraryField, aItem.Id);
        Test.stopTest();

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        List<ContentDocumentLink> cdl = new List<ContentDocumentLink>();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id];
        System.assertEquals(10, cdl.size(), 'Should be one for each for the account!');

        CSC_Action_List__c aList = [SELECT Id FROM CSC_Action_List__c WHERE Action_List_Name__c = 'Test Action List'];
        cdl.clear();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :aList.Id];
        System.assertEquals(10, cdl.size(), 'Should be one for each for the action list!');

        ContentWorkspace cw = [SELECT Id, Name FROM ContentWorkspace WHERE Name = :aItem.Library_Type__c LIMIT 1];
        cdl.clear();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :cw.Id];
        System.assertEquals(10, cdl.size(), 'Should be one for each for the Library!');        
    }

    @isTest static void testRelatingLibraryOnly(){
        setup();
        List<ContentDocument> cDocuments = [SELECT Id FROM ContentDocument];
        List<String> fileIds = new List<String>();
        for(ContentDocument cd : cDocuments){
            fileIds.add((String) cd.Id);
        }

        String records;
        String libraryField = 'Library_Type__c';
        CSC_Action_Item__c aItem = [SELECT Id, Library_Type__c FROM CSC_Action_Item__c WHERE Action_Item_Name__c = 'Test Action Item'];

        Test.startTest();
            FileUploaderCtrl.relateFileToObjects(fileIds, records, libraryField, aItem.Id);
        Test.stopTest();

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        List<ContentDocumentLink> cdl = new List<ContentDocumentLink>();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id];
        System.assertEquals(0, cdl.size(), 'Shouldn\'t be any for the account!');

        CSC_Action_List__c aList = [SELECT Id FROM CSC_Action_List__c WHERE Action_List_Name__c = 'Test Action List'];
        cdl.clear();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :aList.Id];
        System.assertEquals(0, cdl.size(), 'Shouldn\'t be any for the action list!');

        ContentWorkspace cw = [SELECT Id, Name FROM ContentWorkspace WHERE Name = :aItem.Library_Type__c LIMIT 1];
        cdl.clear();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :cw.Id];
        System.assertEquals(10, cdl.size(), 'Should be one for each for the Library!');        
    }

    @isTest static void testRelatingRecordsOnly(){
        setup();
        List<ContentDocument> cDocuments = [SELECT Id FROM ContentDocument];
        List<String> fileIds = new List<String>();
        for(ContentDocument cd : cDocuments){
            fileIds.add((String) cd.Id);
        }
        String records = 'CSC_Action_List__c, Account_Id__c';
        String libraryField;
        CSC_Action_Item__c aItem = [SELECT Id, Library_Type__c FROM CSC_Action_Item__c WHERE Action_Item_Name__c = 'Test Action Item'];

        Test.startTest();
            FileUploaderCtrl.relateFileToObjects(fileIds, records, libraryField, aItem.Id);
        Test.stopTest();

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        List<ContentDocumentLink> cdl = new List<ContentDocumentLink>();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id];
        System.assertEquals(10, cdl.size(), 'Should be one for each for the account!');

        CSC_Action_List__c aList = [SELECT Id FROM CSC_Action_List__c WHERE Action_List_Name__c = 'Test Action List'];
        cdl.clear();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :aList.Id];
        System.assertEquals(10, cdl.size(), 'Should be one for each for the action list!');

        ContentWorkspace cw = [SELECT Id, Name FROM ContentWorkspace WHERE Name = :aItem.Library_Type__c LIMIT 1];
        cdl.clear();
        cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :cw.Id];
        System.assertEquals(0, cdl.size(), 'Shouldn\' be any for the library!');        
    }

}