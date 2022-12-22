public with sharing class OpportunityPushFilesToBoxController {
    
    public Opportunity opp {get;set;}
    public Id objectId {get;set;}
    public List<FileWrapper> files {get;set;}
    private Map<Id,Id> docIdMap = new Map<Id,Id>();
    private Map<Id,Intake_Item__c> itemMap = new Map<Id,Intake_Item__c>();
    private List<DiligenceRoleMap__mdt> drm;
    private boolean init;
    
   public OpportunityPushFilesToBoxController(ApexPages.StandardController thecontroller) {
   		opp = (Opportunity)thecontroller.getRecord();
        opp = [Select Id, Client_External_Box_Folder_Id__c, Account.ParentId  From Opportunity Where Id=:opp.Id];
        objectId = opp.Id;
    	
    	drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt];  
	    
   }
   
   public PageReference execute() {
   	init = true;
   	//files = new List<ContentVersion>();
   	refresh();
   	init = false;
   	return null;
   }
   
   public PageReference pushToBox() {
   	
   	if (opp.Client_External_Box_Folder_Id__c==null) {
   		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Opportunity field Client External Box FOlder Id is not populated.  Please populate and try again');
		ApexPages.addMessage(myMsg);
   		return null;
   	}
   	
   	List<ContentVersion> forUpdate = new List<ContentVersion>();
   	//init process to Processing
   	for (FileWrapper fw : files) {
   		ContentVersion c = fw.cv;
   		if (c.Pushed_To_Box_Error__c!='Success' && !c.pushed_to_box__c) {
   			c.Pushed_To_Box_Error__c = 'Processing ....';
   			forUpdate.add(c);
   			fw.cv = fw.cv;
   		}
   		if (forupdate.size()>0) update forUpdate;
   	}
   	
   	for (FileWrapper fw : files) {
   		if (!fw.cv.pushed_to_box__c) {
   			if (fw.cv.Title!=null) {
    			//upload doc to Box
	        	System.debug('***Limits.getHeapSize(): ' + Limits.getHeapSize());
	        	System.debug('***Limits.getLimitHeapSize(): ' + Limits.getLimitHeapSize());
	        	System.debug('***pushing file: ' + fw.cv.Title);
   				BoxAPIUtils.uploadDocument(docIdMap.get(fw.cv.ContentDOcumentId),opp.Client_External_Box_Folder_Id__c, fw.cv.Title+'.'+fw.cv.FileExtension,fw.cv.Id);
   			}
   		}	
   	}
   	
   	return null;
   }
   
   public PageReference back() {
   		PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page;
   }
   
   public PageReference refresh() {
   	
   	Set<Id> iiIds = new Set<Id>();
   	files = new List<FileWrapper>();
   	
   	List<Intake_Item__c> ii = [Select Id, Name from Intake_item__c where Opportunity__c=:objectId];
   	for (Intake_Item__c i : ii) {
   		iiIds.add(i.Id);
   		itemMap.put(i.Id, i);
   	}
   	
   	List<ContentDocumentLink> cd = [Select Id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId IN:iiIds];
   	for (ContentDocumentLink c : cd) {
   		docIdMap.put(c.ContentDocumentId, c.LinkedEntityId);
   	}
   	
   	if (cd.size()==0) {
   		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'No Files found to upload to Box');
		ApexPages.addMessage(myMsg);
		return null;
   	} else {
   		Set<Id> userIds = new Set<Id>();
   		Map<Id,String> profileMap = new Map<Id,String>();
   		
   		List<ContentVersion> cvs = [select Id, Title, CreatedById, ContentDocumentId, FileExtension, CreatedDate,
   		 Pushed_To_Box_Error__c,  pushed_to_box__c from ContentVersion where ContentDocumentId IN:docIdMap.keyset()];
   		for (ContentVersion cv : cvs) {
   			userIds.add(cv.CreatedById);
   		}
   		
   		for (User u: [Select Id, Name, Profile.Name from USer where Id IN:userids]) {
	   		for (DiligenceRoleMap__mdt d : drm) {
	   			System.debug('****profile: ' +u.Profile.Name  + ' - ' + d.profile_name__c);
		   		if (u.Profile.Name.equalsignorecase(d.profile_name__c)) {
		   			profileMap.put(u.Id,d.profile_name__c);
		   			System.debug('****user : ' +u.Name  + ' - is a community profile');
		   			break;
		   		}
		    }
   		}
	    
   		for (ContentVersion cv : cvs) {
   			//only show docs uploaded by a Community User
   			if (profileMap.get(cv.createdbyid)!=null) {
	   			Id itemId = docIdMap.get(cv.ContentDocumentId);
	   			System.debug('***: itemId ' + itemId);
	   			System.debug('***: itemMap.get(itemId).Name ' + itemMap.get(itemId).Name);
	   			FileWrapper fw = new FileWrapper(cv,itemMap.get(itemId));
	   			files.add(fw);
   			}
   		}
   	} 
   	
   	return null;
   }
   
   public class FileWrapper {
   		public ContentVersion cv {get;set;}
   		public String itemName {get;set;}
   		public String itemId {get;set;}
   		
   		public FileWrapper(ContentVersion conver, Intake_Item__c item) {
   			System.debug('***new filewrapper: ' +conver);
   			cv = conver;
   			itemName = item.Name;
   			itemId = item.Id;
   			System.debug('***end of filewrapper: ');
   		}
   }
}