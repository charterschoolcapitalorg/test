public with sharing class ApplicantRedirectController {
	public Boolean hasErrors { get { return ApexPages.hasMessages(ApexPages.Severity.ERROR) || ApexPages.hasMessages(ApexPages.Severity.FATAL); } }
	
	private ApexPages.StandardController stdController;
	
	public ApplicantRedirectController(ApexPages.StandardController stdController) {
		if(!Test.isRunningTest()) {
			stdController.addFields(new List<String> { 'Lead__c' });
		}
		
		this.stdController = stdController;
	}
	
	public PageReference init() {
		Applicant__c applicant = (Applicant__c) stdController.getRecord();
		PageReference pr = new PageReference('/' + applicant.Lead__c);
		pr.setRedirect(true);
		return pr;
	}
	
	private void addError(String msg) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
	}
}