public class EWS_Ctrl {

    @AuraEnabled(cacheable=true)
    public static EWS__c getRecord(String recordId) {
        
        // get original record and clone
        EWS__c originalEWS = new EWS__c();
        originalEWS = [
            SELECT Account__c, Account__r.Charter_Termination__c, Account__r.Date_Opened__c, Fiscal_Year__c, Quarter_Ending_FY__c, FDA_County__c, FDA_District__c, Date_Opened__c, 
            	Num_of_Shortfalls_Current_FY__c, Audit_Information__c, Net_Assets__c, Non_Facilities_Liabilities__c, 
            	Annual_Rent_Expense__c, Prior_Year_Surplus_Deficit__c, Budgeted_Revenue__c, Budgeted_Donations__c, 
            	Budgeted_Surplus_Deficit__c, Budgeted_Attendance__c, Attendance_Current__c, Attendance_Prior__c, Year_1_Latest__c, 
            	Year_2__c, Year_3_Oldest__c, Number_of_Months_Outstanding__c, Cross_Year_Funding_Date__c, Cross_Year_Funding_Amount__c, 
            	Number_of_Fundings_per_Year__c, Avg_percentage_of_Face_Funded__c, Avg_Days_Notice_given__c, Comments__c, 
            	Initial_Funding_Date__c, Charter_Renewal_Date__c, Lease_Status__c, Lease_Expiration_Date__c, Closure_Indication__c, 
            	Google_alerts__c, Management_changes_in_past_year__c, CAP_SIP_SOD_Financial_CAP_in_FL__c, Proof_of_Good_Standing__c, 
            	Audit_Completion__c, Tax_Payment_Status__c, Rent_Payment_Status__c, Current_Academic_Performance__c, Historical_Ratings_Actual__c,
            	Current_Year_1_Academic_Performance__c, Current_Year_2_Academic_Performance__c, RecordTypeId, Type__c, Historical_Ratings_Color__c
            FROM EWS__c WHERE id =:recordId LIMIT 1];
        EWS__c clonedEWS = new EWS__c();
        clonedEWS = originalEWS.clone();
        clonedEWS.Review_Date__c = Date.today();
        clonedEWS.Charter_Renewal_Date__c = originalEWS.Account__r.Charter_Termination__c;
        clonedEWS.Date_Opened__c = originalEWS.Account__r.Date_Opened__c;
        
        //update record type
        if(originalEWS.RecordTypeId == RecordTypeUtils.EWSFinanceActive.Id){
            clonedEWS.RecordTypeId = RecordTypeUtils.EWSFinanceInactive.Id;
        } else if(originalEWS.RecordTypeId == RecordTypeUtils.EWSUnderwritingActive.Id){
            clonedEWS.RecordTypeId = RecordTypeUtils.EWSUnderwritingInactive.Id;
        }
        System.debug('cloned EWS: ' + clonedEWS);
        return clonedEWS;
    }
    
    @AuraEnabled(cacheable=true)
    public static Academic_Rating__c getRatings(String accountId, String fy) {
        //get AR info from SChool Account
        Map<Id, Academic_Rating__c> recentARMap = new Map<Id, Academic_Rating__c>();
        List<Academic_Rating__c> ars = [Select Id, Account__c, Historical_Ratings_Color__c, FY__c, Historical_Ratings__c
                             			from Academic_Rating__c
                             			where Account__c = :accountId ORDER BY FY__c DESC];
        system.debug('Academic_Rating__c with ar for comments refresh == '+ars);
        Integer currentfy = Integer.valueOf(fy.left(2));
        for(Academic_Rating__c ar :ars){
            if(currentfy-1 == Integer.valueOf(ar.FY__c.left(2))){
            	recentARMap.put(ar.Account__c, ar);
            }
            
        }        
        Academic_Rating__c ar = recentARMap.get(accountId);
        
       
        return ar;
            
    }
    
}