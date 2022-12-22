public with sharing class FinancialUIVFCtrl {
	public Id accountId { get; set; }
    
    public FinancialUIVFCtrl(ApexPages.StandardController controller) {

        Financial__c f = (Financial__c) controller.getRecord();
        f = [Select Id, Account__c From Financial__c Where Id = :f.Id];
        accountId = f.Account__c;
    }

}