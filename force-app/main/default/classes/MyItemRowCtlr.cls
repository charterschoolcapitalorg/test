public class MyItemRowCtlr {
    @AuraEnabled
    public static String getItemDetail(Id itemId) {
        Intake_Item__c item = [
            SELECT
                Status__c,
                Opportunity__r.Client_Facing_Opportunity_Name__c,
                Opportunity__r.Name,
                Account_Name__r.Name
            FROM Intake_Item__c
            WHERE Id = :itemId
        ];

        String project = '';
        for (String it: new List<String> {
            item.Opportunity__r.Client_Facing_Opportunity_Name__c,
            item.Opportunity__r.Name,
            item.Account_Name__r.Name
        }) {
            if (String.isNotBlank(it)) {
                project = it;
                break;
            }
        }

        String status = DiligenceUtils.getClientFriendlyStatuses.get(item.Status__c);

        return JSON.serialize(new Map<String,String> {
            'status' => status,
            'project' => project
        });
    }
    
    @AuraEnabled
    public static Intake_Item__c getIntakeItem(String iId){
        Id itemId = Id.valueOf(iId);
        
        Intake_Item__c intakeItem = [SELECT id,Client_Facing_Item_Name__c,Comment_Required__c, Action_URL__c, name,Client_Comments__c,Client_Due__c, Status__c, Status_Reason__c, Opportunity__r.Client_Facing_Opportunity_Name__c, Red_Flag_Instructions_For_Client__c, COmments__c, Due_Date__c, 
        	Intake_Item__c.Assigned_To__c, Is_Pre_Qual__c,Opportunity__r.Account.Name, Due__c, Parent_Intake_Item__c, 
        	Opportunity__r.Name, Opportunity__r.Funded_Date__c, Opportunity__c,Is_Visible_To_Community__c,Is_Document__c, RecordTypeId,
            Opportunity__r.recordtypeid, Opportunity__r.recordtype.name
                                   FROM Intake_Item__c WHERE Id = :itemId];
        
        return intakeItem;
    }
    
    @AuraEnabled
    public static List<ContentDocument> getFiles(string theid) {
        List<ContentDocumentLink > files = [Select ContentDocument.Title, ContentDocumentId from ContentDocumentLink where LinkedEntityId=:theid];
        System.debug('****files: ' + files);
        Set<Id> ids = new Set<Id>();
        for (ContentDocumentLink c : files) {
            ids.add(c.ContentDocumentId);
            System.debug('****file: ' + c.ContentDocument.Title);
        }
        List<ContentDocument> docs = [Select Id, CreatedDate, TItle, CreatedBy.Name, CreatedById from ContentDocument where Id IN:ids];
        System.debug('****docs: ' + docs);
        return docs;
    }
    
    @AuraEnabled
    public static List<ContentDocument> getOppFiles(string theid) {
        List<ContentDocumentLink > files = [Select ContentDocument.Title, ContentDocumentId from ContentDocumentLink where 
        	LinkedEntityId=:theid and ContentDocument.Title like 'Closing_Statement%'];
        System.debug('****files: ' + files);
        Set<Id> ids = new Set<Id>();
        for (ContentDocumentLink c : files) {
            ids.add(c.ContentDocumentId);
            System.debug('****file: ' + c.ContentDocument.Title);
        }
        List<ContentDocument> docs = [Select Id, CreatedDate, TItle, CreatedBy.Name, CreatedById from ContentDocument where Id IN:ids];
        System.debug('****docs: ' + docs);
        return docs;
    }
    
    @AuraEnabled
    public static IntakeItemWrapper getIntakeItemWrapper(String iId){
        Id itemId = Id.valueOf(iId);
        String role = getUserRole(UserInfo.getUserId());
        
        Intake_Item__c intakeItem = [SELECT id,Client_Facing_Item_Name__c,Comment_Required__c, Action_URL__c, name,Client_Comments__c,Client_Due__c, 
        	Status__c, Status_Reason__c, Opportunity__r.Client_Facing_Opportunity_Name__c, Red_Flag_Instructions_For_Client__c, 
        	COmments__c, Due_Date__c, Due__c, Parent_Intake_Item__c, 
        	Intake_Item__c.Assigned_To__c, Is_Pre_Qual__c,Opportunity__r.Account.Name, 
        	Opportunity__r.Name, Opportunity__r.Funded_Date__c, Opportunity__c,Is_Visible_To_Community__c,Is_Document__c, RecordTypeId,
            Opportunity__r.recordtypeid, Opportunity__r.recordtype.name, 
            	(Select Id,Submitted_Date__c, Approved_Date__c, Comment_Required__c, Client_Due__c,Client_Facing_Item_Name__c,RecordTypeId,Opportunity__r.Account.Name, Opportunity__r.AccountId, Visible_To__c, Is_Document__c, 
               Comments__c, Parent_Intake_Item__c, Client_Comments__c, Name,Status__c,Opportunity__r.Name,Due_Date__c,Action_URL__c,
               Document_Name__c,Assigned_To__c,Due__c,Status_Reason__c, Is_Pre_Qual__c from Intake_Items__r
               WHERE ( Assigned_To__c includes (:role) or Visible_To__c includes (:role)) AND Is_Visible_To_Community__c = true ORDER BY Processing_Order__c ASC) 
               
               FROM Intake_Item__c WHERE Id = :itemId];
       
        
        IntakeItemWrapper w = new IntakeItemWrapper(intakeItem, role);
        return w;
    }
    
    @AuraEnabled
    public static String getIntakeItemClientComments(String iId){
        Id itemId = Id.valueOf(iId);
        
        Intake_Item__c intakeItem = [SELECT id,Comment_Required__c, Action_URL__c, name,Client_Comments__c,Client_Due__c, Status__c, Status_Reason__c, Opportunity__r.Client_Facing_Opportunity_Name__c, Red_Flag_Instructions_For_Client__c, COmments__c, Due_Date__c, 
        	Intake_Item__c.Assigned_To__c, 
        	Opportunity__r.Name, Opportunity__r.Funded_Date__c, Opportunity__c,Is_Visible_To_Community__c,Is_Document__c, 
            Opportunity__r.recordtypeid, Opportunity__r.recordtype.name
                                   FROM Intake_Item__c WHERE Id = :itemId];
        
        if (intakeItem.Client_Comments__c!=null) {
        	String ret = intakeItem.Client_Comments__c.replaceAll('<[^>]+>',' ');
        	//ret = ret.replace('&#39;', '\'');	
        	return ret;
        } else return '';
        
        
    }
    
    
    
    @AuraEnabled
    public static List<IntakeItemWrapper> getIntakeItems(String opportunityId, String intakeParentId){
        return MyItemCtlr.getIntakeItems(opportunityId, intakeParentId);
        /*
        System.debug('***** in getIntakeItems: ' + opportunityId + ' - ' + intakePArentId);
        String role = getUserRole(UserInfo.getUserId());
        List<Intake_Item__c> intakeItems = [SELECT Id, Client_Facing_Item_Name__c,Client_Comments__c, Name, Status__c,
        Intake_Item__c.Assigned_To__c,  
         Opportunity__r.Name, Opportunity__r.Funded_Date__c, Due_Date__c, Parent_Intake_Item__c, Comments__c, Is_Document__c,
         Opportunity__r.Targeted_Funding_Date__c, Opportunity__c, Intake_Item__c.Opportunity__r.Account.Name, Due__c, 
         Action_URL__c, Is_Pre_Qual__c, RecordTypeId 
         FROM Intake_Item__c 
         
        WHERE ( Assigned_To__c includes (:role) or Visible_To__c includes (:role)) AND
                   Opportunity__r.Id = :opportunityId AND Is_Visible_To_Community__c = true AND
                   Parent_Intake_Item__c = :intakeParentId ORDER BY Processing_Order__c ASC];
        
        Set<Id> parentIds = new Set<Id>();
        for(Intake_Item__c ii : intakeItems){
	    	parentIds.add(ii.Id);
        } 
        system.debug('Parent Ids: ' + parentIds);
        List<Intake_Item__c> children = [SELECT Parent_Intake_Item__c FROM Intake_Item__c WHERE Parent_Intake_Item__c IN :parentIds];
        Set<Id> childIds = new Set<Id>();
        for(Intake_Item__c ci : children){
            childIds.add(ci.Parent_Intake_Item__c);
        }
        system.debug('Child Ids: ' + childIds);
        List<IntakeItemWrapper> wraps = new List<IntakeItemWrapper>();
        for(Intake_Item__c ii : intakeItems){
            IntakeItemWrapper w = new IntakeItemWrapper(ii, role);
            if(childIds.contains(ii.Id)){
                w.hasChildren = true;
            }
            wraps.add(w);
        }
		System.debug('***** returning: ' + wraps);        
        return wraps;
        */
    }
    
    /*
    @AuraEnabled
    public static IntakeItemWrapper getIntakeItem(String intakeItemId){
        Intake_Item__c intakeItem = [SELECT Id, Name, Status__c,
        Intake_Item__c.Assigned_To__c,  
        	Opportunity__r.Name, Opportunity__r.Funded_Date__c, Due_Date__c, Parent_Intake_Item__c, Comments__c, Is_Document__c,
         	Opportunity__r.Targeted_Funding_Date__c, Opportunity__c, Intake_Item__c.Opportunity__r.Account.Name, Due__c, 
         	Action_URL__c, Is_Pre_Qual__c, RecordTypeId FROM Intake_Item__c WHERE Id = :intakeItemId];
        String role = getUserRole(UserInfo.getUserId());
        IntakeItemWrapper wrapper = new IntakeItemWrapper(intakeItem, role);
        return wrapper;
    }
	*/
	
    public static String getUserRole(String userId){
    	if (test.isrunningtest()) {
        	return 'School';
        } else {
	        User u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :userId];       
        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
        return drm.role__c;
        }
        
    }
    
    
	@AuraEnabled
    public static Id getIDFOFOpp(){
    	//return Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
        return RecordTypes.IDFOFOpp;   	
	}
	
	@AuraEnabled
    public static Id getIDIFOpp(){
    	//return Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
        return RecordTypes.IDFundingOpp;   	
	}
	
	@AuraEnabled
    public static Id getIDFacOpp(){
    	//return Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
        return RecordTypes.IDFacilitiesOpp;   	
	}
	
	@AuraEnabled
    public static Id getIDInitialFundingIntake(){
    	//return Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
        return RecordTypes.IDInitialFundingIntakeItem;   	
	}

	@AuraEnabled
    public static Id getID5DFIntake(){
    	//return Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
        return RecordTypes.ID5DFIntakeItem;   	
	}    
    
	@AuraEnabled
    public static Id getIDFacilitiesIntakeItem(){
        //return Schema.SObjectType.Intake_Item__c.getRecordTypeInfosByName().get('Facilities').getRecordTypeId();
        return RecordTypes.IDFacilitiesIntakeItem;
    }
    
	@AuraEnabled
    public static Opportunity getOpportunity(String theId){
    	system.debug('**theId: ' + theId);	
     	Opportunity opp = [Select Id, CloseDate, Face_Value__c, Purchase_Price__c, IsClosed, IsWon, Target_Wire_Date__c, Funded_Date__c,NET_Amount_Requested__c,
	        Reporting_Value__c, Name, Client_Facing_Opportunity_Name__c, RecordTypeId from Opportunity where Id =:theId];
	        system.debug('**Opp: ' + opp);
        
        return opp;
    }
    
    
    
    
    @AuraEnabled
    public static IntakeItemWrapper acceptedStatus(String iiId){
        Intake_Item__c ii = [SELECT Id, Opportunity__c, Parent_Intake_Item__c, status__c from Intake_Item__c where Id=:iiId];
        ii.status__c = DiligenceVars.IntakeApprovedStatus;
        update ii;
        List<IntakeItemWrapper> wraps = MyItemCtlr.getIntakeItems(ii.Opportunity__c, ii.Parent_Intake_Item__c);
        
        System.debug('Wrap Size: ' + wraps.size());
        for(IntakeItemWrapper w : wraps){
            if(w.item.Id == ii.Id){
                return w;
            }
        }
        return new IntakeItemWrapper();
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
    public static String getNextDocId(string iId, String thisId) {
        List<ContentDocumentLink > files = [Select ContentDocument.Title, ContentDocumentId from ContentDocumentLink where LinkedEntityId=:iId ];
        String sfiles = '';// new List<String>();
        System.debug('****files: ' + files);
        Set<Id> ids = new Set<Id>();
        boolean getNext = false;
        for (ContentDocumentLink c : files) {
            ids.add(c.ContentDocumentId);
            ContentVersion cv = [Select Id,Title from ContentVersion Where ContentDocumentId=:c.ContentDocumentId];//'0690S0000006pqeQAA'
            if (getnext) {
            	return cv.Id+'';
            }
            if (thisId+''==cv.Id+'') {
            	//get next
            	getnext = true;
            }
        }
        return '';
        
    }
    @AuraEnabled
    public static String getPrevDocId(string iId, String thisId) {
        List<ContentDocumentLink > files = [Select ContentDocument.Title, ContentDocumentId from ContentDocumentLink where LinkedEntityId=:iId ];
        String sfiles = '';// new List<String>();
        System.debug('****files: ' + files);
        Set<Id> ids = new Set<Id>();
        boolean getNext = false;
        String lastId = '';
        for (ContentDocumentLink c : files) {
            ids.add(c.ContentDocumentId);
            ContentVersion cv = [Select Id,Title from ContentVersion Where ContentDocumentId=:c.ContentDocumentId];//'0690S0000006pqeQAA'
            if (thisId+''==cv.Id+'') {
            	return lastId;
            }
            lastId = cv.Id+'';
        }
        return '';
        
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
    public static void addComment(string iId, String comment) {
    	System.debug('saving comment: ' + comment);
        Id itemId = Id.valueOf(iId);
        Intake_Item__c ii = [Select Status__c, Client_Comments__c from Intake_Item__c where Id=:itemId];
        ii.Client_Comments__c = comment;
        ii.status__c = DiligenceVars.IntakeSubmittedStatus;
        update ii;
        
    }
    @AuraEnabled
    public static void noChanges(string iId) {
        Id itemId = Id.valueOf(iId);
        Intake_Item__c ii = [Select Client_Comments__c from Intake_Item__c where Id=:itemId];
        if (ii.Client_Comments__c==null) {
        	ii.Client_Comments__c = 'No Changes as of ' + Date.today().month() + '/' 
        	+ Date.today().day() + '/'
        	+ Date.today().year() ;
        } else {
        	ii.Client_Comments__c += '<br/> No Changes as of ' + Date.today().month() + '/' 
        	+ Date.today().day() + '/'
        	+ Date.today().year() ;
        }
        ii.status__c = DiligenceVars.IntakeSubmittedStatus;
        update ii;
        
    }
     
}