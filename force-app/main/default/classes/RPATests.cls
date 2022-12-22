@isTest
private class RPATests {
	private static Account acct;
	private static RPA__c rpa1, rpa2;
	private static Terms_Letter__c tl1, tl2;
	private static Opportunity opp;

	private static void setup() {
		acct = new Account(
			Name = 'Unit Test Charter Holder',
			RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id
		);
		insert acct;

		rpa1 = new RPA__c(
			Account__c = acct.Id,
			RPA_Date__c = System.today().toStartOfMonth(),
			RPA_Type__c = 'Original',
			Status__c = 'Active'
		);
		rpa2 = new RPA__c(
			Account__c = acct.Id,
			RPA_Date__c = System.today().toStartOfMonth(),
			RPA_Type__c = 'First Amended and Restated',
			Status__c = 'Draft'
		);
		insert new List<RPA__c> { rpa1, rpa2 };

		tl1 = new Terms_Letter__c(
			RPA__c = rpa1.Id,
			Account__c = acct.Id,
			TL_Type__c = 'Original',
			TL_Date__c = System.today(),
			Initial_Close_Date__c = System.today().toStartOfMonth().addMonths(1).addDays(-1),
			RPA_Face_Value__c = 100,
			RPA_Gross_Value__c = 100,
			Status__c = 'Active',
			Termination_Date__c = System.today().toStartOfMonth().addMonths(2)
		);
		tl2 = new Terms_Letter__c(
			RPA__c = rpa1.Id,
			Account__c = acct.Id,
			TL_Type__c = 'First Amended and Restated',
			TL_Date__c = System.today(),
			Initial_Close_Date__c = System.today().toStartOfMonth().addMonths(1).addDays(-1),
			RPA_Face_Value__c = 200,
			RPA_Gross_Value__c = 200,
			Status__c = 'Draft',
			Termination_Date__c = System.today().toStartOfMonth().addMonths(2)
		);
		insert new List<Terms_Letter__c> { tl1, tl2 };

		opp = new Opportunity(
			Name = 'Unit Test Opp',
			CloseDate = System.today(),
			StageName = 'Initial Funding',
			AccountId = acct.Id,
			Amount = 100,
			RPA__c = rpa1.Id,
			Terms_Letter__c = tl1.Id
		);
		insert opp;
	}

	private static Opportunity loadOpportunity(Id oppId) {
		return [SELECT Id, RPA__c, Terms_Letter__c FROM Opportunity WHERE Id = :oppId];
	}

	private static List<Opportunity> loadAcctOpps(Id acctId) {
		return [SELECT Id, RPA__c, Terms_Letter__c FROM Opportunity WHERE AccountId = :acctId];
	}

	static testMethod void testRpaActivation() {
		setup();

		for(Terms_Letter__c tl : [SELECT Id, RPA__c FROM Terms_Letter__c WHERE Account__c = :acct.Id]) {
			System.assertEquals(rpa1.Id, tl.RPA__c);
		}

		for(Opportunity acctOpp : loadAcctOpps(acct.Id)) {
			System.assertEquals(rpa1.Id, acctOpp.RPA__c);
		}

		rpa1.Status__c = 'Amended';
		rpa2.Source__c = rpa1.Id;
		rpa2.Status__c = 'Active';
		update new List<RPA__c> { rpa1, rpa2 };

		tl1 = [SELECT Id, RPA__c FROM Terms_Letter__c WHERE Id = :tl1.Id];
		System.assertEquals(rpa2.Id, tl1.RPA__c);

		opp = loadOpportunity(opp.Id);
		System.assertEquals(rpa2.Id, opp.RPA__c);
	}

	static testMethod void testTermsLetterActivation() {
		setup();

		for(Opportunity acctOpp : loadAcctOpps(acct.Id)) {
			System.assertEquals(tl1.Id, acctOpp.Terms_Letter__c);
		}

		tl1.Status__c = 'Amended';
		tl2.Source__c = tl1.Id;
		tl2.Status__c = 'Active';
		update new List<Terms_Letter__c> { tl1, tl2 };

		opp = loadOpportunity(opp.Id);
		System.assertEquals(tl2.Id, opp.Terms_Letter__c);
	}

	static testMethod void testTerminationPropagation() {
		setup();

		//RA - [07/01/2014] - T-289109 - This custom setting is used to conditionally control which users are allowed to 
		//terminate an RPA record.
        AuthorizedUsersforRPATermination__c authUsers = new AuthorizedUsersforRPATermination__c();
        authUsers.Username_of_Authorized_Users__c = UserInfo.getUserName();
        insert authUsers;
        //RA - [07/01/2014] - T-289109 - This custom setting is used to conditionally control which users are allowed to 
		//terminate an RPA record.
		rpa1.Status__c = 'Terminated';
		update rpa1;

		tl1 = [SELECT Id, Status__c FROM Terms_Letter__c WHERE Id = :tl1.Id];
		System.assertEquals('Terminated', tl1.Status__c);
	}

	static testMethod void testAddOppRelatedRecordsController() {
		setup();
		opp.RPA__c = null;
		opp.Terms_Letter__c = null;
		update opp;

		PageReference testPr = Page.AddOppRelatedRecords;
		testPr.getParameters().put('id', opp.Id);
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		AddOppRelatedRecordsController controller = new AddOppRelatedRecordsController(stdController);
		controller.init();
		//System.assertEquals(1, controller.rpas.size());
		System.assertEquals(2, controller.tls.size());
		opp.Terms_Letter__c = controller.tls.get(0).Id;
		controller.save();

		opp = loadOpportunity(opp.Id);
		System.assertEquals(tl1.Id, opp.Terms_Letter__c);
		System.assertEquals(rpa1.Id, opp.RPA__c);
	}
}