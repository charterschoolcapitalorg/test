@isTest
private class OpportunityCloseExtTest {
	
	@isTest static void testOppCloseExt() {
		Account acc = new Account(name = 'Test Account');
		insert acc;

		Opportunity opp = new Opportunity();
		opp.StageName = 'Stage 1';
		opp.CloseDate = Date.today();
		opp.Amount = 300;
		opp.Name = 'Spartans!';
		opp.AccountId = acc.Id;
		opp.Reason__c = '';
		insert opp;

		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		Test.startTest();
		OpportunityCloseExt oppClose = new OpportunityCloseExt(stdController);
		opp.Reason__c = 'Went elsewhere';
		PageReference pref = oppClose.save();
		System.debug(oppClose);
		Test.stopTest();

		Opportunity afterOpp = [Select StageName, Reason__c from Opportunity where id = :opp.Id];
		System.assertEquals('Went elsewhere', afterOpp.Reason__c);
		System.assertEquals('Closed Lost', afterOpp.StageName);
	}

	@isTest static void testOppCloseErrorExt() {
		Account acc = new Account(name = 'Test Account');
		insert acc;

		Opportunity opp = new Opportunity();
		opp.StageName = 'Stage 1';
		opp.CloseDate = Date.today();
		opp.Amount = 300;
		opp.Name = 'Spartans!';
		opp.AccountId = acc.Id;
		opp.Reason__c = '';
		insert opp;

		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		Test.startTest();
		OpportunityCloseExt oppClose = new OpportunityCloseExt(stdController);
		opp.Reason__c = 'Went elsewhere';
		opp.StageName = '';
		PageReference pref = oppClose.save();
		System.debug(oppClose);
		Test.stopTest();

		Opportunity afterOpp = [Select StageName, Reason__c from Opportunity where id = :opp.Id];
		System.assertNotEquals('Went elsewhere', afterOpp.Reason__c);
		System.assertNotEquals('Closed Lost', afterOpp.StageName);
	}
	
}