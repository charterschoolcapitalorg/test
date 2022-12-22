@isTest
public class PortalBankCtrlTests {
	@testSetup static void methodName(){
		Account acc = new Account(name = 'Test Account');
		insert acc;

		Opportunity opp = new Opportunity(name = 'Test Opp', AccountId = acc.Id, StageName = 'Stage 1', CloseDate = Date.today(), Bank_Account_Name__c = 'Charter Bank Account',
			Bank_Name__c = 'US Bank', Bank_Account_Num__c = '123456789', Bank_Routing_Num__c = '123-123-123', Bank_Address__c = 'Main Street, Portland, OR, 97201',
			Bank_Contact__c = 'John Smith', Bank_Contact_Phone__c = '5555555555');
		insert opp;
	}

	@isTest static void testGetBank(){
		String oppId = [SELECT id FROM Opportunity LIMIT 1].Id;
		Opportunity o = PortalBankCtrl.getBankDetails(oppId);
		System.assertEquals('Charter Bank Account', o.Bank_Account_Name__c, 'Incorrect bank account');
	}

	@isTest static void testUpdateBank(){
		Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
		opp.Bank_Account_Name__c = 'Strange bank name';
		PortalBankCtrl.updateOpportunityBank(opp);
		Opportunity updatedOpp = [SELECT id, Bank_Account_Name__c, Bank_Name__c, Bank_Account_Num__c, Bank_Routing_Num__c, Bank_Address__c, 
		 Bank_Contact__c, Bank_Contact_Phone__c FROM Opportunity WHERE id =: opp.Id];
		System.assertEquals('Strange bank name', updatedOpp.Bank_Account_Name__c, 'Incorrect bank account');
	}
}