public with sharing class RecordTypeUtils {
	public static RecordType AccountBusiness { get { return getRecordType('Account', '', 'Business'); } }
	public static RecordType AccountCharterHolder { get { return getRecordType('Account', '', 'Charter_Holder'); } }
	public static RecordType AccountSchool { get { return getRecordType('Account', '', 'School'); } }
	public static RecordType LeadApplicant { get { return getRecordType('Lead', '', 'Applicant'); } }
	public static RecordType OpportunityFOF { get { return getRecordType('Opportunity', '', 'FOF'); } }
	public static RecordType OpportunityFacilities { get { return getRecordType('Opportunity', '', 'Facilities'); } }
	public static RecordType OpportunityWorkingCapital { get { return getRecordType('Opportunity', '', 'Initial_Funding'); } } //2018.5.8 - MOLINGER changed the Dveeloper name of Opp record type to Initial_Funding
	public static RecordType CSCActionItemSalesProcess { get { return getRecordType('CSC_Action_Item__c', '', 'Sales_Process'); } }			//2015.06.24 J Caughie - CSCActionItem Test Class
	public static RecordType AccountBank { get { return getRecordType('Account', '', 'Bank'); } }											//2016.01.12 J Caughie - OppSchoolBankDetail Test
	public static RecordType EWSFinanceActive { get { return getRecordType('EWS__c', '', 'Financial_Activated'); } }						//2017.02.17 J Caughie - EWS_Ext Test
	public static RecordType EWSFinanceInactive { get { return getRecordType('EWS__c', '', 'Financial'); } }								//2017.02.17 J Caughie - EWS_Ext Test
	public static RecordType EWSUnderwritingActive { get { return getRecordType('EWS__c', '', 'Underwriting_Activated'); } }						//2017.02.17 J Caughie - EWS_Ext Test
	public static RecordType EWSUnderwritingInactive { get { return getRecordType('EWS__c', '', 'Underwriting'); } }								//2017.02.17 J Caughie - EWS_Ext Test
	public static RecordType DrawCreditLine { get { return getRecordType('Draw_Note__c', '', 'Credit_Line'); } }

	private static Map<Id, RecordType> rtMap;
	private static Map<String, RecordType> rtNameMap;

	static {
		Set<String> objs = new Set<String> { 'Account', 'Lead', 'Opportunity', 'CSC_Action_Item__c', 'EWS__c', 'Draw_Note__c' };
		rtMap = new Map<Id, RecordType>();
		rtNameMap = new Map<String, RecordType>();

		for(RecordType rt : [SELECT Id, sObjectType, Name, DeveloperName, NamespacePrefix FROM RecordType WHERE sObjectType IN :objs]) {
			String key = rt.sObjectType + '.' + (rt.NamespacePrefix != null ? rt.NamespacePrefix : '') + '.' + rt.DeveloperName;
			rtMap.put(rt.Id, rt);
			rtNameMap.put(key.toLowerCase(), rt);
		}
	}

	public static Boolean isBusiness(Account acct) {
		return acct.RecordTypeId == AccountBusiness.Id;
	}

	public static Boolean isCharterHolder(Account acct) {
		return acct.RecordTypeId == AccountCharterHolder.Id;
	}

	public static Boolean isSchool(Account acct) {
		return acct.RecordTypeId == AccountSchool.Id;
	}

	public static Boolean isApplicant(Lead l) {
		return l.RecordTypeId == LeadApplicant.Id;
	}

	public static RecordType getRecordType(Id rtId) {
		return rtMap.get(rtId);
	}

	//2015.10.19 J Caughie - method to return map of Developer Name to Id
	public static Map<String, Id> getsObjectRecordMap(String type) {
		List<RecordType> rts = new List<RecordType>();
		rts = Database.query('SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = :type');
		Map<String, Id> typeToIdMap = new Map<String, Id>();
		for (RecordType r : rts){
		    typeToIdMap.put(r.DeveloperName, r.Id);
			}
		return typeToIdMap;
	}
	//2015.10.19 J Caughie - method to return map of Developer Name to Id
	
	private static RecordType getRecordType(String obj, String nsPrefix, String devName) {
		String key = obj + '.' + (nsPrefix != null ? nsPrefix : '') + '.' + devName;
		return rtNameMap.get(key.toLowerCase());
	}
}