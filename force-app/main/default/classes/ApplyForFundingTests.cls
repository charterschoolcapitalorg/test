@isTest
private class ApplyForFundingTests {
	private static Applicant__c applicant;
	
	private static void setup() {
		applicant = new Applicant__c(
			Step__c = 1,
			First_Name__c = 'Granny',
			Last_Name__c = 'Goodness',
			Company__c = 'St. Louise\'s Orphanage',
			Title__c = 'Head Administrator / Minion of Darkseid',
			Phone__c = '1-888-375-7343', // 1-888-DRK-SEID
			Email__c = 'grannygoodness@stlouisesorphanage.org',
			Role__c = 'Individual School'
		);
		insert applicant;
	}
	
	private static Applicant__c loadApplicant(Id applicantId) {
		return [SELECT Id, Lead__c, Token__c, First_Name__c, Last_Name__c, Title__c, Email__c, Phone__c, Company__c, Role__c FROM Applicant__c WHERE Id = :applicantId];
	}
	
	private static Lead loadLead(Id leadId) {
		return [SELECT Id, FirstName, LastName, Company, Title, Email, Phone, Role__c FROM Lead WHERE Id = :leadId];
	}
	
	static testMethod void testApplicantLeadCreation() {
		setup();
		applicant = loadApplicant(applicant.Id);
		System.assertNotEquals(null, applicant.Lead__c);
		
		Lead l = loadLead(applicant.Lead__c);
		System.assertEquals(applicant.First_Name__c, l.FirstName);
		System.assertEquals(applicant.Last_Name__c, l.LastName);
		System.assertEquals(applicant.Company__c, l.Company);
		System.assertEquals(applicant.Title__c, l.Title);
		System.assertEquals(applicant.Phone__c, l.Phone);
		System.assertEquals(applicant.Email__c, l.Email);
		System.assertEquals(applicant.Role__c, l.Role__c);
	}
	
	static testMethod void testApplicantLeadSync() {
		setup();
		applicant = loadApplicant(applicant.Id);
		
		applicant.First_Name__c = 'Grandma';
		update applicant;
		
		Lead l = loadLead(applicant.Lead__c);
		System.assertEquals(applicant.First_Name__c, l.FirstName);
	}
	
	static testMethod void testLeadApplicantSync() {
		setup();
		applicant = loadApplicant(applicant.Id);
		Lead l = loadLead(applicant.Lead__c);
		l.FirstName = 'Grandma';
		update l;
		
		applicant = loadApplicant(applicant.Id);
		System.assertEquals(l.FirstName, applicant.First_Name__c);
	}
	
	static testMethod void testControllerLanding() {
		setup();
		applicant = loadApplicant(applicant.Id);
		
		PageReference testPr = Page.ApplyForFunding;
		testPr.getParameters().put('t', applicant.Token__c);
		Test.setCurrentPage(testPr);
		ApplyForFundingController controller = new ApplyForFundingController();
		controller.init();
		System.assertNotEquals(null, controller.applicant);
		System.assertNotEquals(null, controller.applicant.Id);
	}
	
	static testMethod void testControllerGoodData() {
		PageReference testPr = Page.ApplyForFunding;
		Test.setCurrentPage(testPr);
		ApplyForFundingController controller = new ApplyForFundingController();
		controller.init();
		System.assertNotEquals(null, controller.applicant);
		System.assertEquals(null, controller.applicant.Id);
		System.assertEquals(null, controller.applicant.Lead__c);
		
		applicant = controller.applicant;
		applicant.First_Name__c = 'Granny';
		applicant.Last_Name__c = 'Goodness';
		applicant.Company__c = 'St. Louise\'s Orphanage';
		applicant.Title__c = 'Head Administrator / Minion of Darkseid';
		applicant.Phone__c = '1-888-375-7343';
		applicant.Email__c = 'grannygoodness@stlouisesorphanage.org';
		applicant.Role__c = 'Individual School';
		
		controller.saveApplicant();
		applicant = loadApplicant(applicant.Id);
		System.assertNotEquals(null, applicant.Lead__c);
		
		System.assertNotEquals(null, controller.org);
		Organization__c org = controller.org;
		org.School_Name__c = 'St. Louise\'s Orphanage';
		org.DC_First_Name__c = 'Granny';
		org.DC_Last_Name__c = 'Goodness';
		org.Street__c = '666 Darkseid Rd.';
		org.City__c = 'Metropolis';
		org.State__c = 'KS';
		org.Zip_Code__c = '66100';
		org.Phone__c = '1-888-375-7343';
		
		PageReference pr = controller.save();
		System.assertNotEquals(null, pr);
		System.assertNotEquals(null, controller.org.Id);
	}
	
	static testMethod void testApplicantRedirect() {
		setup();
		applicant = loadApplicant(applicant.Id);
		
		PageReference testPr = Page.ApplicantRedirect;
		Test.setCurrentPage(testPr);
		ApexPages.StandardController stdController = new ApexPages.StandardController(new Applicant__c());
		ApplicantRedirectController controller = new ApplicantRedirectController(stdController);
		PageReference pr = controller.init();
		System.assertNotEquals(null, pr);
		System.assertEquals(false, controller.hasErrors);
	}
}