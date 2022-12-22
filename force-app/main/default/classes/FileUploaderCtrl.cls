public with sharing class FileUploaderCtrl {
    @AuraEnabled
    public static void relateFileToObjects(List<String> fileIds, String records, String library, String sourceObjectId){

        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        List<ContentWorkspaceDoc> cwds = new List<ContentWorkspaceDoc>();

        System.debug('fileIds ' + fileIds);
        System.debug('records ' + records);
        System.debug('library ' + library);

        List<String> recordFieldNameList = new List<String>();
        if(records <> null){
            recordFieldNameList = getRecordIdList(records);
        }        

        String query = '';
        query += 'SELECT Id ';
        if(records <> null){
            query += ', ' + String.join(recordFieldNameList, ', ');
        }
        if(library <> null){
            query += ', ' + library;
        }
        query += ' FROM ' + getSObjectFromId(sourceObjectId);
        query += ' WHERE id = \'' + sourceObjectId + '\'';
        sObject s = Database.query(query);

        ContentWorkspace cw = new ContentWorkspace();
        if(library != null){
            String libName = (String)s.get(library);
            cw = [SELECT Id, Name FROM ContentWorkspace WHERE Name = :libName LIMIT 1];
        }

        for(String file : fileIds){
            if(records <> null){
                //link to related records
                for(String record : recordFieldNameList){
                    ContentDocumentLink cdlRecord = new ContentDocumentLink();
                    Id recordId = (Id)s.get(record);
                    cdlRecord.ContentDocumentId = file;
                    cdlRecord.LinkedEntityId = recordId;
                    cdlRecord.Visibility = 'InternalUsers';
                    cdls.add(cdlRecord);          
                }
            }
            //link to library
            if(library <> null){
                ContentWorkspaceDoc cwdRecord = new ContentWorkspaceDoc();
                cwdRecord.ContentDocumentId = file;
                cwdRecord.ContentWorkspaceId = cw.Id;
                cwds.add(cwdRecord);
            }
        }

        insert cdls;
        insert cwds;

    }

    private static List<String> getRecordIdList(String records){
        List<String> recordNameList = new List<String>();
        recordNameList = records.split(',');
        List<String> newRecordFieldNameList = new List<String>();
        for(String s : recordNameList){
            newRecordFieldNameList.add(s.trim());
        }
        return newRecordFieldNameList;
    }

    private static String getSObjectFromId(String recordId){
        Id myId = (String)recordId;
        Schema.SObjectType sObjectType = myId.getSobjectType();
        return String.valueOf(sObjectType);
    }

}