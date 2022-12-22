/**=====================================================================
 * Date Modified            Modified By                 Description of the update
 * [10/17/2014]            [John Caughie]              [Added RPA_Face_Value__c to the VF layout and to the controller query]
  =====================================================================*/

public with sharing class AddOppRelatedRecordsController {
	//public Boolean hasErrors { get { return ApexPages.hasMessages(ApexPages.Severity.ERROR) || ApexPages.hasMessages(ApexPages.Severity.FATAL); } }
	//public List<RPA__c> rpas { get; private set; }
	public List<Terms_Letter__c> tls { get; private set; }
		
	private ApexPages.StandardController stdController;
	
	public AddOppRelatedRecordsController(ApexPages.StandardController stdController) {
		if(!test.isRunningTest()) {
			stdController.addFields(new List<String> { 'AccountId' });
		}
		
		this.stdController = stdController;
	}
	
	public void init() {
		Id acctId = ((Opportunity) stdController.getRecord()).AccountId;
		
		//rpas = [SELECT Id, Name, RPA_Date__c, RPA_Type__c, Status__c FROM RPA__c WHERE Account__c = :acctId AND Status__c = 'Active' ORDER BY RPA_Date__c DESC];
		tls = [SELECT Id, Name, RPA__c, TL_Date__c, Initial_Close_Date__c, Termination_Date__c, TL_Type__c, RPA_Gross_Value__c, RPA_Face_Value__c, Status__c FROM Terms_Letter__c WHERE Account__c = :acctId AND Status__c in ('Active','Draft') ORDER BY TL_Date__c DESC];
	}				//2014.10.17 J Caughie - Added FV to VF & to query
	
	public PageReference save() {
		Opportunity opp = (Opportunity) stdController.getRecord();
		Map<Id, Terms_Letter__c> tlMap = new Map<Id, Terms_Letter__c>(tls);
		
		if(tlMap.containsKey(opp.Terms_Letter__c)) {
			opp.RPA__c = tlMap.get(opp.Terms_Letter__c).RPA__c;
		}
		
		return stdController.save();
	}
	
	/*
	private void addError(String msg) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
	}
	*/
}