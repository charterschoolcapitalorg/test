public class PortalBankCtrl {
    @AuraEnabled
    public static Opportunity getBankDetails(string oppId) {
		return [SELECT id, Bank_Account_Name__c, Bank_Name__c, Bank_Account_Num__c, Bank_Routing_Num__c, Bank_Address__c, 
		 Bank_Contact__c, Bank_Contact_Phone__c FROM Opportunity WHERE id =: oppId];
    }

    @AuraEnabled
    public static void updateOpportunityBank(Opportunity opp){
    	update opp;
    }
}