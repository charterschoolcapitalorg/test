public with sharing class AddOppSchoolsController {
	public Boolean hasErrors { get { return ApexPages.hasMessages(ApexPages.Severity.ERROR) || ApexPages.hasMessages(ApexPages.Severity.FATAL); } }
	public Opportunity opp { get; private set; }
	public List<OppSchoolHelper> oppSchoolHelpers { get; private set; }
	public List<OppSchoolHelper> invalidOppSchoolHelpers { get; private set; }
	
	private ApexPages.StandardController stdController;
	
	public AddOppSchoolsController(ApexPages.StandardController stdController) {
		this.stdController = stdController;
		oppSchoolHelpers = new List<OppSchoolHelper>();
		invalidOppSchoolHelpers = new List<OppSchoolHelper>();
	}
	
	public PageReference init() {
		Map<Id, Id> existingSchoolIdMap = new Map<Id, Id>();
		try {
			opp = [SELECT Id, Name, AccountId FROM Opportunity WHERE Id = :stdController.getId()];
		} catch(QueryException e) {
			addError('Could not load the opportunity.');
			return null;
		}
		
		for(Opp_School__c oppSchool : [SELECT Id, Opportunity__c, School__c FROM Opp_School__c WHERE Opportunity__c = :opp.Id]) {
			existingSchoolIdMap.put(oppSchool.School__c, oppSchool.Id);
		}
		
		for(Account acct : [SELECT Id, Name, Legal_Name__c, Operating_State__c FROM Account WHERE Charter_Holder__c = :opp.AccountId AND RecordTypeId = :RecordTypeUtils.AccountSchool.Id ORDER BY Name, Operating_State__r.Name]) {
			Opp_School__c oppSchool = new Opp_School__c(
				Id = existingSchoolIdMap.containsKey(acct.Id) ? existingSchoolIdMap.get(acct.Id) : null,
				Opportunity__c = opp.Id,
				School__c = acct.Id,
				School__r = acct
			);
			
			OppSchoolHelper osh = new OppSchoolHelper(oppSchool);
			
			//if(osh.hasLegalName) {													//2015.05.20 J Caughie - removed as we are not filtering out Schools with no legal_name__c
				oppSchoolHelpers.add(osh);
			//} else {
			//	invalidOppSchoolHelpers.add(osh);										//2015.05.20 J Caughie - removed as we are not filtering out Schools with no legal_name__c
			//}																			//2015.05.20 J Caughie - removed as we are not filtering out Schools with no legal_name__c
		}
		
		if(oppSchoolHelpers.size() == 1 && invalidOppSchoolHelpers.isEmpty()) {
			return save();
		}
		
		return null;
	}
	
	public PageReference save() {
		List<Opp_School__c> oppSchools = new List<Opp_School__c>();
		
		for(OppSchoolHelper helper : oppSchoolHelpers) {
			if(helper.selected) {
				oppSchools.add(helper.oppSchool);
			}
		}
		
		if(!oppSchools.isEmpty()) {
			upsert oppSchools;
		}
		
		return new PageReference('/' + opp.Id);
	}
	
	private void addError(String msg) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
	}
	
	public class OppSchoolHelper {
		public Boolean selected { get; set; }
		//public Boolean hasLegalName { get { return oppSchool != null && oppSchool.School__r != null && String.isNotBlank(oppSchool.School__r.Legal_Name__c); } }			//2015.05.20 J Caughie - removed as we are not filtering out Schools with no legal_name__c
		public Opp_School__c oppSchool { get; set; }
		
		public OppSchoolHelper(Opp_School__c oppSchool) {
			selected = true;
			this.oppSchool = oppSchool;
		}
	}
}