@isTest
private class AddOppSchoolsControllerTests {
	private static Account charterHolder, school1, school2;
	private static Opportunity opp;
	
	private static void setup() {
		State_Province__c ks = new State_Province__c(
			Name = 'KS',
			State_Name__c = 'Kansas',
			Active__c = true
		);
		insert ks;
		
		charterHolder = new Account(
			Name = 'Isis Foundation',
			Legal_Name__c = 'Isis Foundation',
			RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id,
			Operating_State__c = ks.Id
		);
		insert charterHolder;
		
		opp = new Opportunity(
			Name = 'Queen Industries Donation',
			StageName = 'Initial Funding',
			CloseDate = System.today(),
			AccountId = charterHolder.Id
		);
		insert opp;
		
		school1 = new Account(
			Name = 'Smallville High',
			Legal_Name__c = 'Smallville High School',
			RecordTypeId = RecordTypeUtils.AccountSchool.Id,
			Operating_State__c = ks.Id,
			Charter_Holder__c = charterHolder.Id
		);
		school2 = new Account(
			Name = 'Granville High',
			Legal_Name__c = 'Granville High School',
			RecordTypeId = RecordTypeUtils.AccountSchool.Id,
			Operating_State__c = ks.Id,
			Charter_Holder__c = charterHolder.Id
		);
	}
	
	public static List<Opp_School__c> loadOppSchools(Id oppId) {
		return [SELECT Id, Opportunity__c, School__c FROM Opp_School__c WHERE Opportunity__c = :oppId];
	}
	
	static testMethod void testNoOppId() {
		PageReference testPr = Page.AddOppSchools;
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(new Opportunity());
		AddOppSchoolsController controller = new AddOppSchoolsController(stdController);
		System.assertEquals(false, controller.hasErrors);
		PageReference pr = controller.init();
		System.assertEquals(true, controller.hasErrors);
	}
	
	static testMethod void testNoSchools() {
		setup();
		
		PageReference testPr = Page.AddOppSchools;
		testPr.getParameters().put('id', opp.Id);
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		AddOppSchoolsController controller = new AddOppSchoolsController(stdController);
		System.assertEquals(false, controller.hasErrors);
		PageReference pr = controller.init();
		System.assertEquals(false, controller.hasErrors);
		System.assertEquals(null, pr);
		System.assertNotEquals(null, controller.oppSchoolHelpers);
		System.assertEquals(0, controller.oppSchoolHelpers.size());
		System.assertEquals(0, controller.invalidOppSchoolHelpers.size());
	}
	
	static testMethod void testOneSchool() {
		setup();
		insert school1;
		
		PageReference testPr = Page.AddOppSchools;
		testPr.getParameters().put('id', opp.Id);
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		AddOppSchoolsController controller = new AddOppSchoolsController(stdController);
		System.assertEquals(false, controller.hasErrors);
		PageReference pr = controller.init();
		System.assertEquals(false, controller.hasErrors);
		System.assertNotEquals(null, pr);
		System.assertNotEquals(null, controller.oppSchoolHelpers);
		System.assertEquals(1, controller.oppSchoolHelpers.size());
		System.assertEquals(0, controller.invalidOppSchoolHelpers.size());
		
		List<Opp_School__c> oppSchools = loadOppSchools(opp.Id);
		System.assertEquals(1, oppSchools.size());
	}
	
	static testMethod void testMultipleSchools() {
		setup();
		insert new List<Account> { school1, school2 };
		
		PageReference testPr = Page.AddOppSchools;
		testPr.getParameters().put('id', opp.Id);
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		AddOppSchoolsController controller = new AddOppSchoolsController(stdController);
		System.assertEquals(false, controller.hasErrors);
		PageReference pr = controller.init();
		System.assertEquals(false, controller.hasErrors);
		System.assertEquals(null, pr);
		System.assertNotEquals(null, controller.oppSchoolHelpers);
		System.assertEquals(2, controller.oppSchoolHelpers.size());
		System.assertEquals(0, controller.invalidOppSchoolHelpers.size());
		
		controller.save();
		System.assertEquals(false, controller.hasErrors);
		List<Opp_School__c> oppSchools = loadOppSchools(opp.Id);
		System.assertEquals(2, oppSchools.size());
	}
	
	static testMethod void testMultipleSchoolsOneSelected() {
		setup();
		insert new List<Account> { school1, school2 };
		
		PageReference testPr = Page.AddOppSchools;
		testPr.getParameters().put('id', opp.Id);
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		AddOppSchoolsController controller = new AddOppSchoolsController(stdController);
		System.assertEquals(false, controller.hasErrors);
		PageReference pr = controller.init();
		System.assertEquals(false, controller.hasErrors);
		System.assertEquals(null, pr);
		System.assertNotEquals(null, controller.oppSchoolHelpers);
		System.assertEquals(2, controller.oppSchoolHelpers.size());
		System.assertEquals(0, controller.invalidOppSchoolHelpers.size());
		
		controller.oppSchoolHelpers.get(0).selected = false;
		controller.save();
		System.assertEquals(false, controller.hasErrors);
		List<Opp_School__c> oppSchools = loadOppSchools(opp.Id);
		System.assertEquals(1, oppSchools.size());
	}
	
	static testMethod void testMultipleSchoolsOneExisting() {
		setup();
		insert new List<Account> { school1, school2 };
		
		Opp_School__c os1 = new Opp_School__c(
			Opportunity__c = opp.Id,
			School__c = school1.Id
		);
		insert os1;
		
		PageReference testPr = Page.AddOppSchools;
		testPr.getParameters().put('id', opp.Id);
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		AddOppSchoolsController controller = new AddOppSchoolsController(stdController);
		System.assertEquals(false, controller.hasErrors);
		PageReference pr = controller.init();
		System.assertEquals(false, controller.hasErrors);
		System.assertEquals(null, pr);
		System.assertNotEquals(null, controller.oppSchoolHelpers);
		System.assertEquals(2, controller.oppSchoolHelpers.size());
		System.assertEquals(0, controller.invalidOppSchoolHelpers.size());
		
		controller.save();
		System.assertEquals(false, controller.hasErrors);
		List<Opp_School__c> oppSchools = loadOppSchools(opp.Id);
		System.assertEquals(2, oppSchools.size());
	}
	
	static testMethod void testMultipleSchoolsOneMissingLegalName() {
		setup();
		school2.Legal_Name__c = null;
		insert new List<Account> { school1, school2 };
		
		PageReference testPr = Page.AddOppSchools;
		testPr.getParameters().put('id', opp.Id);
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
		AddOppSchoolsController controller = new AddOppSchoolsController(stdController);
		System.assertEquals(false, controller.hasErrors);
		PageReference pr = controller.init();
		System.assertEquals(false, controller.hasErrors);
		System.assertEquals(null, pr);
		System.assertNotEquals(null, controller.oppSchoolHelpers);
		//System.assertEquals(1, controller.oppSchoolHelpers.size());										//2015.05.20 J Caughie - removed as we are not filtering out Schools with no legal_name__c
		System.assertEquals(2, controller.oppSchoolHelpers.size());
		//System.assertEquals(1, controller.invalidOppSchoolHelpers.size());								//2015.05.20 J Caughie - removed as we are not filtering out Schools with no legal_name__c
	}
}