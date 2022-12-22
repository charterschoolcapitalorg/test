public with sharing class DiligenceVars {
	private static string iiName;
	private static string ocName;
	private static List<STring> facNames = new List<STring>();
	private static Network activeComm;
	// public static LIst<GroupMember> boxUsers = new LIst<GroupMember>();
	public static List<User> boxUsers = new LIst<User>();
	
	public static void refreshPQ() {
		try {
			Intake_Item_Template__c ii = [Select Id, Name from Intake_Item_Template__c where is_pre_qual__c = true and RecordTypeId=:RecordTypes.IDInitialFundingIntake limit 1];
			PQName = ii.Name;//'Pre Qualification';
		} catch (EXception e) {
			SYstem.debug('***No Pre QUal Intake Item Template found for INitial Funding');
		}
	}
	
	public static void refreshOpeningCall() {
		try {
			Intake_Item_Template__c ii = [Select Id, Name from Intake_Item_Template__c where is_opening_call__c = true and RecordTypeId=:RecordTypes.IDInitialFundingIntake limit 1];
			OpeningCallName = ii.Name;//'Pre Qualification';
		} catch (EXception e) {
			SYstem.debug('***No Opening Call Item Template found for INitial Funding');
		}
	}
	
	static {
		try {
			Intake_Item_Template__c ii = [Select Id, Name from Intake_Item_Template__c where is_pre_qual__c = true and RecordTypeId=:RecordTypes.IDInitialFundingIntake limit 1];
			iiName = ii.Name;//'Pre Qualification';
			System.debug('***pq name: ' + iiName);
			
		} catch (EXception e) {
			SYstem.debug('***No Pre QUal Intake Item Template found for INitial Funding');
		}
		
		try {
			Intake_Item_Template__c iOC = [Select Id, Name from Intake_Item_Template__c where is_opening_call__c = true and RecordTypeId=:RecordTypes.IDInitialFundingIntake limit 1];
			ocName = iOC.Name;//'Pre Qualification';
			System.debug('***opening call name: ' + ocName);
			
		} catch (EXception e) {
			SYstem.debug('***No Opening Call Item Template found for INitial Funding');
		}
		
		for (Intake_Item_Template__c i :[Select Id, Name from Intake_Item_Template__c where is_pre_qual__c = true and RecordTypeId=:RecordTypes.IDFacilitiesIntake]) {
			facNames.add(i.Name);
		}
		//iiName = ii.Name;//'Pre Qualification';
		String grpName = 'Box Users';
		List<Id> userIds = new List<Id>();
		if (BoxCredentials__c.getOrgDefaults() != null && BoxCredentials__c.getOrgDefaults().SF_Box_Group_Name__c!=null) {
            grpName = BoxCredentials__c.getOrgDefaults().SF_Box_Group_Name__c;
        }
		Group g = [Select Id from group where Name=:grpName];
		// boxUsers = [SELECT Id, UserOrGroupId FROM GroupMember WHERE GroupId =:g.Id];
		for (GroupMember gm : [SELECT Id, UserOrGroupId FROM GroupMember WHERE GroupId =:g.Id]) {
			userIds.add(gm.UserOrGroupId);
		}
		boxUsers = [SELECT Id, Box_User_Id__c FROM User WHERE id IN :userIds];
		System.debug('Box Users: ' + boxUsers);
		
		activeComm = null;
		try {
			activeComm = [SELECT id, Name,Status, UrlPathPrefix FROM Network where Status='Live' LIMIT 1];
		} catch (EXception e) {
			SYstem.debug('***No Active community');
		}
	}
    
    public static Network community =activeComm;
    public static string PQName = iiName;
    public static string OpeningCallName = ocName;//'Opening Call with CSC';
    public static List<string> PQFacilitiesNames = facNames;
    
    public static string IIActionDetails = 'See Instructions';
    public static string IIActionEdit = 'Edit Item Details';
    public static string IIActionForm = 'Custom Form';
    public static string IIActionDocument = 'Document Upload';
    
    public static STring facStageToTriggerIntakeItemCreation = 'Stage 2 - Qualification';
    public static STring fofStageToTriggerIntakeItemCreation = 'Stage 3 - Review';
    
    public static string CSCRole = 'CSC';
    public static string SchoolTenantRole = 'School';
    public static string IntakeSubmittedStatus = 'Submitted';
    public static string IntakeApprovedStatus = 'Accepted';
    public static string IntakePendingStatus = 'Pending';
    public static string IntakeInputNeededStatus = 'Additional Input Needed';
    
    
}