public class PortalMultiDocUploadTriggerHandler {


    public static void CopyDocToSelectedRecords(List<Portal_Multi_Doc_Upload__c> uploads){
        List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
        for(Portal_Multi_Doc_Upload__c u : uploads){
            List<String> recIds = u.Target_Object_Ids__c.split(',');
            List<String> docIds = u.Content_Ids__c.split(',');
            for(String r : recIds){
                if(r == u.Root_Object_Id__c) continue;
                for(String d : docIds){
                    ContentDocumentLink cdl = New ContentDocumentLink();
                    cdl.LinkedEntityId = Id.valueOf(r);
                    cdl.ContentDocumentId = id.valueOf(d);
                    cdl.shareType = 'V'; 
                    linksToCreate.add(cdl);                   
                }            
            }
        }
        insert linksToCreate;    
    }

}