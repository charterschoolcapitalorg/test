public with sharing class ManualFundingEstimateEditorCtrl {
    @AuraEnabled(cacheable=true)
    public static List<Funding_Estimate_Receivable__c> getFundingEstimateReceivables(String feId) {
        return [
            SELECT Id, Name, GRV_Amount__c, Expected_Pay_Date__c, School__c, Statutory_Expected_Pay_Date__c
            FROM Funding_Estimate_Receivable__c
            WHERE Funding_Estimate__c = :feId
            AND Source_State_Rate_Card__c = null
            WITH SECURITY_ENFORCED
        ];
    }

    @AuraEnabled
    public static string updateReceivables(Object data) {
        List<Funding_Estimate_Receivable__c> recsForUpdate = (List<Funding_Estimate_Receivable__c>) JSON.deserialize(
            JSON.serialize(data),
            List<Funding_Estimate_Receivable__c>.class
        );
        try {
            update recsForUpdate;
            return 'Success: FERs updated successfully';
        }
        catch (Exception e) {
            return 'The following exception has occurred: ' + e.getMessage();
    }}
}