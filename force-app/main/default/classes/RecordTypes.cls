public class RecordTypes {
    public static ID IDFacilitiesLead = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Facilities').getRecordTypeId();
    public static ID IDGeneralLead = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('General').getRecordTypeId();
    public static ID IDCharterAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Charter Holder').getRecordTypeId();
    public static ID IDSChoolAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
    public static ID IDBusAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business').getRecordTypeId();
    public static ID IDPropAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
    
    public static ID IDFacilitiesOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Facilities').getRecordTypeId();
    public static ID IDFOFOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('FOF').getRecordTypeId();
    public static ID IDFundingOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
    public static ID IDLoanOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan').getRecordTypeId();
    public static ID ID5DFOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('5DF').getRecordTypeId();
    public static ID IDEMOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Enrollment_Marketing').getRecordTypeId();
    public static ID IDBrokerNetworkOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Broker_Network').getRecordTypeId();
    
    public static ID IDFacilitiesIntake = Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('Facilities').getRecordTypeId();
	public static ID IDInitialFundingIntake = Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
	public static ID ID5DFIntake = Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('5DF').getRecordTypeId();
	public static ID IDFOFIntake = Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByName().get('FOF').getRecordTypeId();
	public static ID IDOngoingIntake = Schema.SObjectType.Intake_Item_Template__c.getRecordTypeInfosByDeveloperName().get('Ongoing_Diligence').getRecordTypeId();
	
	public static ID IDFacilitiesIntakeItem = Schema.SObjectType.Intake_Item__c.getRecordTypeInfosByName().get('Facilities').getRecordTypeId();
	public static ID IDInitialFundingIntakeItem = Schema.SObjectType.Intake_Item__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
	public static ID ID5DFIntakeItem = Schema.SObjectType.Intake_Item__c.getRecordTypeInfosByName().get('5DF').getRecordTypeId();
	public static ID IDFOFIntakeItem = Schema.SObjectType.Intake_Item__c.getRecordTypeInfosByName().get('FOF').getRecordTypeId();
	public static ID IDOngoingIntakeItem = Schema.SObjectType.Intake_Item__c.getRecordTypeInfosByDeveloperName().get('Ongoing_Diligence').getRecordTypeId();
	
	public static ID IDInitialFundingPQ = Schema.SObjectType.PQ_Form__c.getRecordTypeInfosByName().get('Initial Funding').getRecordTypeId();
	public static ID ID5DFPQ = Schema.SObjectType.PQ_Form__c.getRecordTypeInfosByName().get('5DF').getRecordTypeId();
	public static ID IDFacilitiesPQ = Schema.SObjectType.PQ_Form__c.getRecordTypeInfosByName().get('Facilities').getRecordTypeId();
	

}