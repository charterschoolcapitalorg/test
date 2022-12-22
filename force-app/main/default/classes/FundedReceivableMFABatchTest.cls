@isTest
private class FundedReceivableMFABatchTest {
	
	public static String CRON_EXP = '0 0 0 15 3 ? 2030';

	static testmethod void testSendEmail() {
		createTestData();
	}
	
	private static void createTestData(){

		Account charter = new Account(Name = 'Charter Account');
		insert charter;

		Account school = new Account(Name = 'School Account', Charter_Holder__c = charter.Id);
		insert school;

		Contact con = new Contact(LastName = 'McTest', Account = charter, email = 'jcaughie@charterschoolcapital.com');
		insert con;

		RPA__c rpa = TestDataUtility.createRPA(charter.Id);

		EmailTemplate validEmailTemplate = [Select id from EmailTemplate Limit 1];

		MFA_Loan_Notification__c mfa = new MFA_Loan_Notification__c();
		mfa.Contact__c = con.Id;
		mfa.Template__c = validEmailTemplate.id;
		insert mfa;

		RecordType r = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Funded_Receivable__c' and Name = 'Loan'];

		Funded_Receivable__c loan = new Funded_Receivable__c(Charter_Holder__c = charter.Id, Principal__c = 1000.00, RecordTypeId = r.Id, RPA__c = rpa.Id, School__c = school.Id, Purchase_Date__c = Date.today());
		insert loan;

		Test.startTest();
			//Schedule job
			String jobID = system.schedule('MFA Alert' + Datetime.now(), CRON_EXP, new FundedReceivableMFABatch());

			// Get the information from the CronTrigger API object
			CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
			
			// Verify the expressions are the same
			System.assertEquals(CRON_EXP, ct.CronExpression);

			// Verify the job has not run
			System.assertEquals(0, ct.TimesTriggered);

			// Verify the next time the job will run
			System.assertEquals('2030-03-15 00:00:00',String.valueOf(ct.NextFireTime));
		Test.stopTest();


	}

}