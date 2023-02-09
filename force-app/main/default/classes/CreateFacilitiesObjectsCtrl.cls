/**=====================================================================
 * Charter School Capital
 * Name: CreateFacilitiesObjectsCtrl
 * Test Class: TestFacilitiesObjects
 * Description: plays role in the Property Overview page
 * Created Date: 
 * Created By: 
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 * Oct 28, 2022                 Slava Krel                   Property tax status automation
 =====================================================================*/
public with sharing class CreateFacilitiesObjectsCtrl {
    
    @AuraEnabled
    public static String getAquisitionsChecklist(){
        try {
        Facilities_Checklist__mdt a = [Select Acquisition__c, Asset_Mgmt__c 
                       from Facilities_Checklist__mdt where MasterLabel='Checklists'];
        return a.Acquisition__c;
        } catch (EXception e) {
            return '';
        }
    }
    
    @AuraEnabled
    public static String getAssetMgmtChecklist(){
    	
    	 /*String result = '';
        
        if (FacilitiesChecklists__c.getOrgDefaults() != null) {
            result  = FacilitiesChecklists__c.getOrgDefaults().Asset_Mgmt__c;
        }
    	
    	return result;*/
        try {
        Facilities_Checklist__mdt a = [Select Acquisition__c, Asset_Mgmt__c 
                       from Facilities_Checklist__mdt where MasterLabel='Checklists'];
        return a.Asset_Mgmt__c;
        } catch (EXception e) {
            return '';
        }
    }

    @AuraEnabled
    public static String getFinancialsChecklist(){

        try {
        Facilities_Checklist__mdt a = [Select Acquisition__c, Asset_Mgmt__c, Financials__c
                       from Facilities_Checklist__mdt where MasterLabel='Checklists'];
        return a.Financials__c;
        } catch (Exception e) {
            return '';
        }
    }
    
    @AuraEnabled
    public static Account getProperty(String pId){
    	System.debug('getProperty: ' + pId);
    	Account a = [Select Id, Name, County__c, BillingStreet, BillingCity, BillingState, 
                     BillingPostalCode, Gross_Land_Area__c, Purchase_Price__c, First_Purchase_Date__c, 
                     BillingCountry, BillingAddress,
            Adjusted_Purchased_Price__c, Net_Rentable_Area__c, 
    		Adjusted_Cap_Rate__c, Acquisition_Date__c, Property_Management_Company__r.Name, Nick_Name__c
    		from Account where Id=:pId];
    	return a;
    }
    
    public static List<Account> getProperties(Set<Id> pIds){
    	System.debug('getProperties: ' + pIds);
    	List<Account> a = [Select Id, Property_Status__c, Name, County__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, 
                     BillingCountry, BillingAddress,
            Adjusted_Purchased_Price__c, Net_Rentable_Area__c, 
    		Adjusted_Cap_Rate__c, Acquisition_Date__c, Property_Management_Company__r.Name
    		from Account where Id IN:pIds];
    	return a;
    }
    
    @AuraEnabled
    public static List<Building__c> getBuildings(String pId){
    	System.debug('getBuildings: ' + pId);
    	List<Building__c> bb = [Select Id, Name, Address__c, Square_Feet__c, Date_Last_Expanded__c, Year_of_Construction__c, Building_Capacity__c
    		from Building__c where Property__c=:pId];
    	return bb;
    }
    
    @AuraEnabled
    public static List<Suite__c> getSuites(String pId){
    	System.debug('getSuites: ' + pId);
    	List<Suite__c> ss = [Select Id, Name, Suite_Number__c, Net_Rentable_Area__c, Vacancy__c, Vacancy_Reason__c, Building__r.Name
    		from Suite__c where Property__c=:pId ];
    	return ss;
    }
    
    
    @AuraEnabled
    public static Lease_Compliance_Template__c getLeaseComplianceTemplate(String tType){
    	System.debug('getLeaseComplianceTemplate: ' + tType);
        Lease_Compliance_Template__c t = null;
        try {
    		t= [Select Id, Type__c, Period__c, FAM_Alert_Days__c, Expire_Days__c, Due_Days__c, 
                   Critical__c, Client_Alert_Days__c, Action_Item_Mapping__c
                   from Lease_Compliance_Template__c where Type__c=:tType ];
        } catch (EXception e) {
            return null;
        }
    	return t;
    }
    
    @AuraEnabled
    public static List<Lease_Compliance__c> getLeaseCompliances(String pId){
    	System.debug('getLeaseCompliances: ' + pId);
        Set<Id> leaseIds = new Set<Id>();
        List<Lease__c> leases = getActiveLeases(pId);
        for (Lease__c l : leases) {
            leaseIds.add(l.Id);
        }
    	List<Lease_Compliance__c> ll = [Select Id,Client_Notifications_Sent__c, Lease_Compliance_Name__c, Lease__r.Name, 
                                        Type__c, Due_Date__c, Received_Date__c, Comments__c, Action_Item_Mapping__c, Period__c
                                        from Lease_Compliance__c where Lease__c IN:leaseIds];
    	return ll;
    }
 	
    @AuraEnabled
    public static List<Lease_School__c> getLeaseSchools(String pId){
    	System.debug('getLeaseCompliances: ' + pId);
        Set<Id> leaseIds = new Set<Id>();
        List<Lease__c> leases = getActiveLeases(pId);
        for (Lease__c l : leases) {
            leaseIds.add(l.Id);
        }
    	List<Lease_School__c> ll = [Select Id,Name, Account_School__c, Account_School__r.Name, 
                                    Lease__c, Lease__r.Name, Off_Date__c, On_Date__c
                                        from Lease_School__c where Lease__c IN:leaseIds];
    	return ll;
    }
    
    @AuraEnabled
    public static List<Lease__c> getLeases(String pId){
    	System.debug('getLeases: ' + pId);
    	// List<Lease__c> ss = [Select Id, Name, Lease_Type__c, 
        //     Tenant__r.Name, Tenant__c, Lease_Status__c, Base_Year_Rent__c,  Purchase_Option__c, 
    	// 	Escalation_Date__c, Lease_Expiration_Date__c, RecordType.DeveloperName, Tenant_Name__c
    	// 	from Lease__c where Property__c=:pId ORDER BY Lease_Status__c ASC, CreatedDate ASC];
    	List<Lease__c> ss = [Select Id, Name, Lease_Type__c, 
            Tenant__r.Name, Tenant__c, Lease_Status__c, Base_Year_Rent__c,  Purchase_Option__c, 
    		Escalation_Date__c, Lease_Expiration_Date__c, RecordType.DeveloperName, Tenant_Name__c, Overview_Sequence__c
    		from Lease__c where Property__c=:pId ORDER BY Overview_Sequence__c];
    	return ss;
    }
    
    @AuraEnabled
    public static List<Lease__c> getActiveLeases(String pId){
    	System.debug('getLeases: ' + pId);
    	List<Lease__c> ss = [Select Id, Name, Lease_Type__c, 
            Tenant__r.Name, Tenant__c, Lease_Status__c, Base_Year_Rent__c,  Purchase_Option__c, 
    		Escalation_Date__c, Lease_Expiration_Date__c
    		from Lease__c where Lease_Status__c = 'Active' And Property__c=:pId ORDER BY Lease_Status__c ASC];
    	return ss;
    }
    
    @AuraEnabled
    public static List<Lease_Suite__c> getLeaseSuites(String pId){
    	System.debug('getLeaseSuites: ' + pId);
    	List<Lease_Suite__c> ss = [Select Id,  Name, Lease__r.Name, Suite__r.Name
    		from Lease_Suite__c where Lease__r.Property__c=:pId and Lease__r.Lease_Status__c='Active'];
    	return ss;
    }
    
    @AuraEnabled
    public static List<Parcel__c> getParcels(String pId){
        System.debug('getParcels: ' + pId);
    	List<Parcel__c> ss = [SELECT Id, Name, County__c, 
            Notes__c, Parcel_Number__c, Property__c, Property_Address__c,
            Property_Sold__c, Website__c, 
            //Total_Amount_Due_For_Tax_Year__c, 
            Next_Due_Date_MIN__c, Final_Due_Date_for_Tax_Year__c, Balance_for_tax_year__c
    		FROM Parcel__c WHERE Property__c=:pId];
    	return ss;
    }
    
    @AuraEnabled
    public static List<Property_Tax__c> getPropertyTaxes(String pId){
    	System.debug('get Property_Tax__c: ' + pId);
    	List<Property_Tax__c> ss = [SELECT Id, Name, 
            Payments_Current__c, Status__c, 
            //Payment_Status__c, 
            Tax_Year__c, 
            //Total_Amount_Due_for_Tax_Year__c, 
            Total_Amount_Paid_for_Tax_Year__c, 
            Property_Exemption_Status__c, Unpaid_Tax_Flag__c, Tax_Year_Number__c, Outstanding_Balance__c,
            X1st_Tax_Due_Date__c, Total_Amount_Due__c
    		FROM Property_Tax__c WHERE Property__c=:pId];
    	return ss;
    }
    
    @AuraEnabled
    public static List<Related_Contact__c> getRelatedContacts(String pId){
    	System.debug('getRelatedContacts: ' + pId);
    	Set<Id> tenantIds = new Set<Id>();
        List<Tenant__c> tenants =getTenantsForActiveLeases(pId);
        if (tenants!=null&&tenants.size()>0) {
            for (Tenant__c t : tenants) {
                if (t.Tenant__c!=null) {
                    //add tenant accoutnts
                    tenantIds.add(t.tenant__c);
                }
            }
        }
        //add property account
        tenantIds.add(Id.valueOf(pId));
        
        List<Related_Contact__c> ss = [Select Id, Facilities_Contact__c, Financial_Contact__c, Rent_Invoice__c, 
            Contact__r.FIrstName, Contact__r.LastName, 
            Contact__r.Email, Account__r.Name 
    		from Related_Contact__c where Account__c IN:tenantIds 
            and (Financial_Contact__c = True OR Facilities_Contact__c = True OR Rent_Invoice__c = True)];
        
        System.debug('***getRelatedContacts: ' + ss);
    	return ss;
    }
    
    @AuraEnabled
    public static List<Account> searchProperties(String searchText){
    	System.debug('searchForProperties: ' + searchText);
    	
    	List<List<SObject>> results = [FIND :searchText IN ALL FIELDS  RETURNING Account(Id)];
	    List<String> ids = new List<String>();
	    for (List<SObject> sobjs : results) {
	      for (SObject sobj : sobjs) {
	        ids.add(sobj.Id);
	      }
	    }
	    System.debug('ids: ' + ids);
	    return [Select Id, Name, Property_Type__c, BillingAddress, BillingStreet, BillingCity, 
	    	BillingState from Account where ID IN: ids and RecordTypeId=:RecordTypes.IDPropAccount];
	    
	    
    }
    
    
    @AuraEnabled
    public static List<Tenant__c> getTenants(String pId){
    	System.debug('getTenants: ' + pId);
    	Set<Id> tenantIds = new Set<Id>();
    	
    	//get Leases for this Property
    	List<Lease__c> leases = [Select Id, Name, Tenant__r.Name, Tenant__c, 
            Base_Year_Rent__c,  Purchase_Option__c, 
    		Escalation_Date__c, Lease_Expiration_Date__c
    		from Lease__c where Property__c=:pId];
    	
    	for (Lease__c l : leases) {
    		if (l.tenant__c !=null) tenantIds.add(l.tenant__c);
    	}
    		
    	//Opportunities1
    	if (tenantIds.size()>0) {	
    		List<Tenant__c> ten = [Select Id, Name, Tenant__r.Name, Tenant__c, Management_Fee_as_of_School_Revenue__c, 
            Primary_Tenant__r.Name
    		from Tenant__c where ID IN:tenantIds];
    		return ten;
    	} else {return null;}
    }
    
    @AuraEnabled
    public static List<Tenant__c> getTenantsForActiveLeases(String pId){
    	System.debug('getTenants: ' + pId);
    	Set<Id> tenantIds = new Set<Id>();
    	
    	//get Leases for this Property
    	List<Lease__c> leases = [Select Id, Name, Tenant__r.Name, Tenant__c, 
            Base_Year_Rent__c,  Purchase_Option__c, 
    		Escalation_Date__c, Lease_Expiration_Date__c
    		from Lease__c where Property__c=:pId and Lease_Status__c = 'Active'];
    	
    	for (Lease__c l : leases) {
    		if (l.tenant__c !=null) tenantIds.add(l.tenant__c);
    	}
    		
    	//Opportunities1
    	if (tenantIds.size()>0) {	
    		List<Tenant__c> ten = [Select Id, Name, Tenant__r.Name, Tenant__c, Management_Fee_as_of_School_Revenue__c, 
            Primary_Tenant__r.Name
    		from Tenant__c where ID IN:tenantIds];
    		return ten;
    	} else {return null;}
    }
    
    public static List<Tenant__c> getTenants(Set<Id> pIds){
    	System.debug('getTenants: ' + pIds);
    	Set<Id> tenantIds = new Set<Id>();
    	
    	//get Leases for this Property
    	List<Lease__c> leases = [Select Id, Name, Tenant__r.Name, Tenant__c, 
            Base_Year_Rent__c,  Purchase_Option__c, 
    		Escalation_Date__c, Lease_Expiration_Date__c
    		from Lease__c where Property__c IN:pIds];
    	
    	for (Lease__c l : leases) {
    		if (l.tenant__c !=null) tenantIds.add(l.tenant__c);
    	}
    		
    	//Opportunities1
    	if (tenantIds.size()>0) {	
    		List<Tenant__c> ten = [Select Id, Property_Status__c, Name, Tenant__r.Name, Tenant__c, Management_Fee_as_of_School_Revenue__c, Primary_Tenant__r.Name
    		from Tenant__c where ID IN:tenantIds];
    		return ten;
    	} else {return null;}
    }
    
    
    @AuraEnabled
    public static Opportunity getOpportunity(String oId){
    	System.debug('getOpportunity: ' + oId);
    	Opportunity o = [Select Id, Name, Property__c, Property__r.Name, CloseDate, Total_Price__c from Opportunity where Id=:oId];
    	return o;
    }
    /*
    @AuraEnabled
    public static Account createNewProperty(String o){
    	
    	System.debug('createNewProperty: ' + o);
    	Opportunity opp =  (Opportunity)System.JSON.deserializeStrict(o, Opportunity.Class);
    	System.debug('createNewProperty: ' + opp);
    	 
    	Account a = new Account();
    	a.recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
    	a.Purchase_Price__c = opp.Total_Price__c;
    	a.Acquisition_Date__c = opp.CloseDate;
    	a.Name = 'Property for: ' + opp.Name;
    	insert a;
    	 
    	opp.property__c = a.Id;
    	update opp;
    	 
    	return a;
    }
    */
    @AuraEnabled
    public static void savePropertyToOpp(String o, String p){
    	
    	System.debug('savePropertyToOpp: ' + o);
    	Opportunity opp =  [Select Id, property__c from Opportunity where Id=:o];
    	System.debug('savePropertyToOpp: ' + opp);
    	opp.property__c = p;
    	update opp;
    	
    }
    
     @AuraEnabled
    public static Id getLeaseRecordType(){
    	return Schema.SObjectType.Lease__c.getRecordTypeInfosByName().get('Facilities Asset Leases').getRecordTypeId();	
    }
    
     @AuraEnabled
    public static Id getLeaseComplianceRecordType(){
    	return Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Current').getRecordTypeId();	
    }
    
    ID IDPropAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
}