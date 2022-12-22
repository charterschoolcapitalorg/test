public with sharing class AddContentController {
	public Boolean hasErrors { get { return ApexPages.hasMessages(ApexPages.Severity.ERROR) || ApexPages.hasMessages(ApexPages.Severity.FATAL); } }

	private ApexPages.StandardController stdController;
	private Map<String, String> paramMap;
	private String contentQuery = '';

	public AddContentController(ApexPages.StandardController stdController) {
		this.stdController = stdController;
	}

	public void init() {
		ContentVersion ver = (ContentVersion) stdController.getRecord();
		paramMap = ApexPages.currentPage().getParameters();
		ver.Account__c = getIdParam('aid');
		ver.CSC_Action_Item__c = getIdParam('aiid');
		ver.CSC_Action_List__c = getIdParam('alid');
		ver.Legal_Doc__c = getIdParam('ldid');
		ver.Resolution__c = getIdParam('rid');
		ver.Opportunity__c = getIdParam('oid');
		ver.RPA__c = getIdParam('rpaid');
		ver.Terms_Letter__c = getIdParam('tlid');
		String lt = getStringParam('lt');

		if(String.isNotBlank(lt)) {
			try {
				ContentWorkspace workspace = [SELECT Id, Name FROM ContentWorkspace WHERE Name = :lt];
				ver.FirstPublishLocationId = workspace.Id;
			} catch(QueryException e) {
				addError('Could not find the requested content library.');
			}
		}

		if (ver.CSC_Action_Item__c != null){
			contentQuery += 'CSC_Action_Item__c = \'' + ver.CSC_Action_Item__c + '\'';
			} else if (ver.Legal_Doc__c != null){
				contentQuery += 'Legal_Doc__c = \'' + ver.Legal_Doc__c + '\'';
			} else if (ver.Resolution__c != null){
				contentQuery += 'Resolution__c = \'' + ver.Resolution__c + '\'';
			} else if (ver.Opportunity__c != null && ver.CSC_Action_Item__c == null) {
				contentQuery += 'Opportunity__c = \'' + ver.Opportunity__c + '\'';
			} else if (ver.RPA__c != null && ver.Terms_Letter__c == null) {
				contentQuery += 'RPA__c = \'' + ver.RPA__c + '\'';
			} else if (ver.Terms_Letter__c != null) {
				contentQuery += 'Terms_Letter__c = \'' + ver.Terms_Letter__c + '\'';
			}


	}

	private String getStringParam(String param) {
		return paramMap.containsKey(param) && String.isNotBlank(paramMap.get(param)) ? paramMap.get(param) : null;
	}

	private Id getIdParam(String param) {
		Id objId = null;
		String val = getStringParam(param);

		try {
			objId = val;
		} catch(StringException e) {}

		return objId;
	}

	public PageReference save() {
		ContentVersion ver = (ContentVersion) stdController.getRecord();
		ver.Title = ver.PathOnClient;
		stdController.save();
		String saveURL = getStringParam('saveURL');

		PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
		pageRef.setRedirect(true);
		return pageRef;
		//return new PageReference(String.isNotBlank(saveURL) ? saveURL : '/' + ver.Id);
	}

	private void addError(String msg) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
	}

	//2016.07.26 J Caughie - Query Item content for dipsplay on upload page
	public List<ContentVersion> getListContent(){
		
		List<ContentVersion> content = new List<ContentVersion>();
		Id itemId = getIdParam('aiid');
		System.debug('SELECT Id, Title, CreatedBy.Name, CreatedDate FROM ContentVersion WHERE ' + contentQuery);
		if(contentQuery != null){
			content = Database.query('SELECT Id, Title, CreatedBy.Name, CreatedDate FROM ContentVersion WHERE ' + contentQuery + ' ORDER BY CreatedDate DESC'); 
		}

		return content;
	}
}