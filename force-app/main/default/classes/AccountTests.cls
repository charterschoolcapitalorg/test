@isTest
private class AccountTests {
	private static User u1, u2;
	private static Account cmo, charterHolder, school1;
	private static Charter_Term__c charterTerm1;

	private static void setup() {
		Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

		u1 = createUser('Unit1', 'Test1', 'unittest1@unittest.com', 'UT1', prof.Id);
		u2 = createUser('Unit2', 'Test2', 'unittest2@unittest.com', 'UT2', prof.Id);
		insert new List<User> { u1, u2 };

		cmo = new Account(
			Name = 'CMO',
			OwnerId = u1.Id,
			RecordTypeId = RecordTypeUtils.AccountBusiness.Id
		);
		insert cmo;

		charterHolder = new Account(
			Name = 'Charter Holder',
			OwnerId = u1.Id,
			CMO__c = cmo.Id,
			RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id,
			Paralegal_1__c = u2.Id
		);
		insert charterHolder;

		school1 = new Account(
			Name = 'School',
			Charter_Holder__c = charterHolder.Id,
			RecordTypeId = RecordTypeUtils.AccountSchool.Id
		);
		insert school1;
	}

	private static void setupCharterTerms() {
		charterTerm1 = new Charter_Term__c(
			School__c = school1.Id,
			Start_Date__c = System.today(),
			End_Date__c = System.today().addYears(5),
			Term__c = 'five',
			Frequency__c = 'year',
			Type__c = 'Initial',
			Paralegal_1__c = u2.Id,
			No_Cap_Limit__c = true
		);
		insert charterTerm1;
	}

	private static User createUser(String firstName, String lastName, String email, String alias, Id profileId) {
		return new User(
			FirstName = firstName,
			LastName = lastName,
			Alias = alias,
			CommunityNickname = alias,
			Email = email,
			Username = email,
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			LanguageLocaleKey = 'en_US',
			EmailEncodingKey = 'ISO-8859-1',
			ProfileId = profileId,
			Paralegal__c = true
		);
	}

	private static Account loadAccount(Id acctId) {
		return [SELECT Id, OwnerId, RecordTypeId, ParentId, Charter_Holder__c, CMO__c, Paralegal_1__c FROM Account WHERE Id = :acctId];
	}

	private static Charter_Term__c loadCharterTerm(Id termId) {
		return [SELECT Id, Paralegal_1__c FROM Charter_Term__c WHERE Id = :termId];
	}

	static testMethod void testParentLinkage() {
		setup();

		charterHolder = loadAccount(charterHolder.Id);
		System.assertEquals(cmo.Id, charterHolder.ParentId);

		school1 = loadAccount(school1.Id);
		System.assertEquals(charterHolder.Id, school1.ParentId);
	}

	static testMethod void testKeyResourcesInsertStamping() {
		setup();
		setupCharterTerms();

		school1 = loadAccount(school1.Id);
		System.assertEquals(u1.Id, school1.OwnerId);
		System.assertEquals(u2.Id, school1.Paralegal_1__c);

		charterTerm1 = loadCharterTerm(charterTerm1.Id);
		System.assertEquals(u2.Id, charterTerm1.Paralegal_1__c);
	}

	static testMethod void testKeyResourcesChanged() {
		setup();
		setupCharterTerms();

		CSC_Action_List__c actionList = new CSC_Action_List__c(
			Account__c = school1.Id,
			Library_Type__c = 'Underwriting'
		);
		insert actionList;

		CSC_Action_Item__c actionItem1 = new CSC_Action_Item__c(
			Action_Item_Name__c = 'Test Item 1',
			CSC_Action_List__c = actionList.Id,
			Assigned_To__c = u2.Id
		);
		insert actionItem1;

		charterHolder.OwnerId = u2.Id;
		charterHolder.Paralegal_1__c = u1.Id;
		update charterHolder;

		school1 = loadAccount(school1.Id);
		System.assertEquals(u2.Id, school1.OwnerId);
		System.assertEquals(u1.Id, school1.Paralegal_1__c);

		charterTerm1 = loadCharterTerm(charterTerm1.Id);
		System.assertEquals(u1.Id, charterTerm1.Paralegal_1__c);

		actionItem1 = [SELECT Id, Assigned_To__c FROM CSC_Action_Item__c WHERE Id = :actionItem1.Id];
		System.assertEquals(u2.Id, actionItem1.Assigned_To__c);															//2016.08.02 J Caughie - Updated to reflect disablement of trigger AccountAfterUpdate.trigger
	}
}