public class UploadTableCtlr {
    
    @AuraEnabled
    
    
    public static List<Intake_Item__c> getIntakeItems(String intakeName, String dateRange, String recType, String statusFilter, List<String> acctIds){
        
        System.debug('getIntakeItems in UpdateTabelCtrl statusFilter: ' + statusFilter);
        System.debug('getIntakeItems: recType: ' + recType);
        System.debug('getIntakeItems: acctIds: ' + acctIds);
        
        String acctFilter = '';
    	for (String s : acctIds) {
    		acctFilter+=s+',';
    	}
    	acctFilter = acctFilter.removeEnd(',');
    	System.debug('**** acctFilter: ' + acctFilter);
    	
    	
        //User will use picklist to select 30,60,90 use this to filter the opps.
        date filterDate;
        if (dateRange!=null&&dateRange!='') {
        	filterDate = system.today() + integer.ValueOf(dateRange);    
        } else {
            filterDate = null;
        }
                                  
        list<intake_item__c> iis = IntakeCommunityItemsCtrl.getFilteredUploadIntakeItems(filterDate, intakeName, recType, statusFilter, acctFilter);
        
        for (intake_item__c i : iis) {
            System.debug('***** upload doc item found: ' + i.Name + ' ' + i.Opportunity__c);
        }
        
        return iis;
    }
    
    
    @AuraEnabled
    public static void insertUpload(String recordIds, String documentIds){
        List<String> recIds = recordIds.split(',');
        Portal_Multi_Doc_Upload__c pmdu = new Portal_Multi_Doc_Upload__c();
        pmdu.Root_Object_Id__c = recIds[0];
        pmdu.Target_Object_Ids__c = recordIds;
        pmdu.Content_Ids__c = documentIds;
        insert pmdu;
    }
    
    @AuraEnabled
    public static IntakeItemWrapper acceptedSelected(String iiIds){
        System.debug('**** in acceptedSelected: ' + iiIds);
        List<STring> strs = iiIds.split(',');
        for (STring s : strs) {
        	MyItemRowCtlr.acceptedStatus(s);
        }
        return null;
   }
	
	@AuraEnabled
    public static String getDownloadFileURL(string iId) {
        List<ContentDocumentLink > files = [Select ContentDocument.Title, ContentDocumentId from ContentDocumentLink where LinkedEntityId=:iId];
        String sfiles = '';// new List<String>();
        System.debug('****files: ' + files);
        Set<Id> ids = new Set<Id>();
        for (ContentDocumentLink c : files) {
            ids.add(c.ContentDocumentId);
            System.debug('****file: ' + c.ContentDocument.Title);
            //return c.ContentDocumentId+'';
            ContentVersion cv = [Select Id,Title from ContentVersion Where ContentDocumentId=:c.ContentDocumentId];//'0690S0000006pqeQAA'
            sfiles+=cv.Id+',';
            //return cv.Id+'';
        }
        sFiles.removeEnd(',');
        return sfiles;
        
    }
    @AuraEnabled
    public static Integer getNumDocs(string iId) {
        List<ContentDocumentLink > files = [Select ContentDocument.Title, ContentDocumentId from ContentDocumentLink where LinkedEntityId=:iId];
        Integer num = 0;// new List<String>();
        System.debug('****files: ' + files);
        Set<Id> ids = new Set<Id>();
        for (ContentDocumentLink c : files) {
            num+=1;
        }
        return num;
        
    }
    
    @AuraEnabled
    public static Id getIDInitialFundingIntake(){
    	//return Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
        return MyItemRowCtlr.getIDInitialFundingIntake();  	
	}
	
	@AuraEnabled
    public static Id getIDFacilitiesIntakeItem(){
        //return Schema.SObjectType.Intake_Item__c.getRecordTypeInfosByName().get('Facilities').getRecordTypeId();
        return MyItemRowCtlr.getIDFacilitiesIntakeItem();
    }
    
    
}