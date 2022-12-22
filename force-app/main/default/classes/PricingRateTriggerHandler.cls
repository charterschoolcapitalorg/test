public with sharing class PricingRateTriggerHandler {
    
    public static Boolean runRateCalc = false;

    public static void calculateFinalRate(List<Pricing_Rate__c> triggerRates) {

        if (!runRateCalc) return; 

        for (Pricing_Rate__c pr : triggerRates) {
            pr.Final_Effective_Rate__c = 
                pr.Floor_Effective_Rate__c 
                + pr.Enrollment_Rate_Adjustment__c 
                + pr.Charter_Renewal_Rate_Adjustment__c 
                + pr.Enrollment_Trend_Rate_Adjustment__c 
                + pr.Intercept_Rate_Adjustment__c 
                + pr.Year_0_PENSEC_Rate_Adjustment__c 
                + pr.Year_0_Pre_PENSEC_Rate_Adjustment__c; 
        }
    }
}