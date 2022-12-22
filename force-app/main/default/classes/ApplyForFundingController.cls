public with sharing class ApplyForFundingController {
	public Boolean hasErrors { get { return ApexPages.hasMessages(ApexPages.Severity.ERROR) || ApexPages.hasMessages(ApexPages.Severity.FATAL); } }
	public Applicant__c applicant { get; private set; }
	public Organization__c org { get; private set; }
	
	private static String LandingError = 'Could not locate the requested applicant.';
	
	public ApplyForFundingController() {}
	
	public void init() {
		Map<String, String> paramMap = ApexPages.currentPage().getParameters();
		String idOrToken;
			
		if(paramMap.containsKey('t')) {
			idOrToken = paramMap.get('t');	
		} else if(paramMap.containsKey('id')) {
			idOrToken = paramMap.get('id');
		}
		
		if(String.isNotBlank(idOrToken)) {
			try {
				reloadApplicant(idOrToken);
				List<Organization__c> orgs = [SELECT Id, Applicant__c, DC_First_Name__c, DC_Last_Name__c, Email__c, Phone__c, School_Name__c, Street__c, City__c, State__c, Zip_Code__c, Main_Phone__c, Current_Enrollment__c FROM Organization__c WHERE Applicant__c = :applicant.Id];
			
				if(!orgs.isEmpty()) {
					org = orgs.get(0);
				} else {
					createOrg();
				}
			} catch(Exception e) {
				addError(LandingError);
			}
		} else {
			applicant = new Applicant__c(
				Step__c = 1
			);
		}
	}
	
	public void saveApplicant() {
		upsert applicant;
		
		reloadApplicant(applicant.Id);
		createOrg();
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Applicant saved.'));
	}
	
	public PageReference save() {
		applicant.Step__c = 3;
		update applicant;
		upsert org;
		
		PageReference pr = Page.ApplyForFundingConfirm;
		pr.getParameters().put('t', applicant.Token__c);
		pr.setRedirect(true);
		return pr;
	}
	
	private void reloadApplicant(String idOrToken) {
		try {
			applicant = [SELECT Id, Application_Status__c, Token__c, Lead__c, First_Name__c, Last_Name__c, Company__c, Title__c, Email__c, Phone__c, Role__c FROM Applicant__c WHERE Id = :idOrToken OR Token__c = :idOrToken];
		} catch(QueryException e) {
			addError(LandingError);
			return;
		}
	}
	
	private void createOrg() {
		org = new Organization__c(
			Applicant__c = applicant.Id,
			Lead__c = applicant.Lead__c
		);
		
		if(String.isNotBlank(applicant.Role__c) && applicant.Role__c.equalsIgnoreCase('Individual School')) {
			org.DC_First_Name__c = applicant.First_Name__c;
			org.DC_Last_Name__c = applicant.Last_Name__c;
			org.Email__c = applicant.Email__c;
			org.Phone__c = applicant.Phone__c;
			org.School_Name__c = applicant.Company__c;
		}
	}
	
	private void addError(String msg) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
	}
}