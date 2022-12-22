global without sharing class IntakeItemPQCommunityCtrl {
	@AuraEnabled
    public String fundRecType {get; set;}
     
    @AuraEnabled
    public String facRecType {get; set;}
    
    @AuraEnabled
    public String thisRecType {get; set;}
    
    @AuraEnabled
    public static IntakeItemPQCommunityCtrl getRecTypes() {
     	IntakeItemPQCommunityCtrl i = new IntakeItemPQCommunityCtrl();
        
        i.fundRecType = RecordTypes.IDInitialFundingPQ;
        i.facRecType = RecordTypes.IDFacilitiesPQ;
        return i;
    }
        
	@AuraEnabled
    public static List<String> getStates() {
		List<String> result = new List<String>();
		     
	   Schema.DescribeFieldResult fieldResult = PQ_Form__c.Mailing_State_Province__c.getDescribe();
	   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	        
	   for( Schema.PicklistEntry f : ple)
	   {
	      result.add(f.getLabel());
	   }       
	   
        return result;
    }
    
    @AuraEnabled
    public static List<String> getCountries() {
		List<String> result = new List<String>();
		     
	   Schema.DescribeFieldResult fieldResult = PQ_Form__c.Mailing_Country__c.getDescribe();
	   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	        
	   for( Schema.PicklistEntry f : ple)
	   {
           if (f.getlabel().equalsignorecase('United States Of America (USA)')) {
	      		result.add(f.getLabel());
           }
	   }       
	   
        return result;
    }
    
	private static PQ_Form__c pq {get;set;}
	
	/*
    @AuraEnabled
    public static Intake_Item__c getItem() {
        objectId = 'a281k0000009RG7';
        System.debug('****opp id: ' + objectId);
        Intake_Item__c i =  [Select Id, Status_Reason__c, status__c from INtake_item__c where Name=:DiligenceVars.PQName and Opportunity__c=:objectId LIMIT 1];
        System.debug('****intake id: ' + i.Id);
        return i;
    }*/
    
    
    @AuraEnabled
    public static void submitPQ(String upsertData){
		try {	    	
			 System.debug('****upserting: ' +upsertData);
        	PQ_Form__c toUpsertData = (PQ_Form__c)System.JSON.deserializeStrict(upsertData, PQ_Form__c.Class);
	        System.debug('****upserting pq - ' + toupsertdata.Id);
	        System.debug('****for opp: - ' + toUpsertData.Opportunity__c);
	        
	        upsert toUpsertData;
        	
        	
	        	PQ_Form__c p = [Select Id, Intake_item__c from PQ_Form__c where Id=:toUpsertData.Id];
	        	System.debug('****updating intake item id: - ' + p.Intake_Item__c);
	        	if (p.Intake_item__c!=null) {
	        		Intake_Item__c i =  [Select Id, Status_Reason__c, status__c from INtake_item__c 
	        		where Id=:p.Intake_item__c and Opportunity__c=:toUpsertData.Opportunity__c LIMIT 1];
	        		
	        		i.status__c = DiligenceVars.IntakeSubmittedStatus;
	    			update i;	
	    			
	        	} else {
                    AuraHandledException e2 = new AuraHandledException('Unable to find PQ form in Salesforce.  Please contact CSC for resolution and provide this error message.');
			        e2.setMessage('Unable to find PQ form in Salesforce.  Please contact CSC for resolution and provide this error message.');
	        		
                    throw e2;
	        	}
	        	
	        	
        	} catch (EXception e) {
                System.debug('*****returning error: ' + e.getmessage()+ ' - ' + e.getstacktracestring() );
        		throw new AuraHandledException( e.getMessage());
        	}
        	
    }
    	
    	/*
    @AuraEnabled
    public static void submit(String oppId, String charterDate, Boolean bond,
    		Boolean lien,Boolean litigation,Boolean standing,Boolean academics
    	){
    	
    	//System.debug('*** in submit: item: ' + ii);
    	System.debug('*** in submit: charterDate: ' + charterDate);
    	System.debug('*** in submit: oppId: ' + oppId);
    	System.debug('*** in submit: bond: ' + bond);
    	
    	Date dt;
    	if (charterDate!=null&&charterDate!='') {
    	List<string> dates = charterdate.split('-');
    	dt = Date.parse(dates[1]+'/'+dates[2]+'/'+dates[0]);
    	}
    		
    	Opportunity opp = [Select Id, charter_opened_date__c, Has_Bond__c, Has_Good_Academics__c,Has_Lien__c,Has_Litigation__c,Good_Standing__c from Opportunity where Id=:oppId ];
    	if (dt!=null) opp.charter_opened_date__c = dt;
    	if (bond!=null) opp.Has_Bond__c =bond;
    	if (academics!=null) opp.Has_Good_Academics__c= academics;
    	if (lien!=null) opp.Has_Lien__c= lien;
    	if (litigation!=null) opp.Has_Litigation__c= litigation;
    	if (standing!=null) opp.Good_Standing__c = standing;
    	
    	
    	System.debug('*** in submit: opp: ' + opp);
    	Intake_Item__c ii = [Select Id, status__c from Intake_Item__c where Opportunity__c=:oppId and Name=:DIligenceVars.PQName LIMIT 1];
    	System.debug('*** in submit: ii: ' + ii);	
    	ii.status__c=DiligenceVars.IntakeSubmittedStatus;
    	update ii;
    	System.debug('*** updating opp: ' + opp);
    	upsert opp;
    	
    	
    }
    */
    /*
    @AuraEnabled
    
    public static Opportunity getOpp(String oppId) {
        
        System.debug('****param id: ' + oppId);
        opp = [Select Id,Name, has_bond__c, has_lien__c, has_litigation__c, Good_Standing__c, Has_Good_Academics__c, charter_opened_date__c From Opportunity Where Id=:oppId];
        objectId = opp.Id;
        
        ii =  [Select Id, Status_Reason__c, status__c from INtake_item__c where Name=:DiligenceVars.PQName and Opportunity__c=:objectId LIMIT 1];
        System.debug('****intake id: ' + ii);
        return opp;
        
    }
    */
    @AuraEnabled
    public static PQ_Form__c getPQ(String oppId) {
        
        System.debug('****param id: ' + oppId);
        Intake_Item__c ii = [Select Id, Opportunity__c from Intake_Item__c where Id=:oppId];
        
        pq = [Select Id,RecordTypeId, Current_Student_Count__c, Opening_Date_of_Your_School__c, Desired_Funding_Date__c, Name,Intake_item__c, Approved_for_other_financing__c,Other_financing_details__c,
        CA_Directly_Funded__c,Affiliated_with_other_businesses__c,
        EMO_CMO_Company_Name__c,BOP_Phone__c,BOP_Email__c,BOP_Contact_Last_Name__c,
        BOP_Contact_First_Name__c,BOP_Name__c, Part_of_EMO_CMO__c,
        first_name__c, last_name__c, email__c, phone__c, title__c, of_sites_under_charter__c, Account_Charter_Holder__c, 
        Applicant_Organization_Account__c, Authorizer_or_Sponsor_Name__c, BOP__c, 
        CAP_SIP__c, Changing_authorizer_sponso__c, Charter_Expiration_Date__c, 
        Charter_Holder_Name__c, Charter_Opened_Date__c, currently_under_review_or_audit__c, 
        Current_number_of_enrolled_students__c, expectation_of_review_or_audit__c, 
        Good_Standing__c, Has_Bond__c, Has_Lien__c, Has_Litigation__c, 
        Mailing_City__c, Mailing_Country__c, Mailing_State_Province__c, Mailing_Street__c, 
        Mailing_ZIP_Post_Code__c, Opportunity__c, Previously_applied_to_CSC__c, School_Name__c, 
        School_open_and_active__c, School_Phone__c, State_Organized__c, Unknown_prior_review_or_audit__c 
        From PQ_Form__c Where Opportunity__c=:ii.Opportunity__c];
        
        System.debug('****pq id: ' + pq.Id);
        System.debug('****pq fn: ' + pq.First_name__c);
        
        
        return pq;
        
    }
    
	public IntakeItemPQCommunityCtrl() {
		//iiId = ApexPages.currentPage().getParameters().get('id');
        //System.debug('****id: ' + iiid);
    }
    
}