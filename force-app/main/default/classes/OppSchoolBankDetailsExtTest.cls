@isTest
private class OppSchoolBankDetailsExtTest {

	static testMethod void oppSchoolBankTest() {

		Opportunity opp = new Opportunity();
		opp = [SELECT Id FROM Opportunity LIMIT 1];

		PageReference pref = Page.OppSchoolBankDetails;
		pref.getParameters().put('id', String.valueOf(opp.Id));

		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
		OppSchoolBankDetailsExt extBankDetails = new OppSchoolBankDetailsExt(sc);
		
		Test.setCurrentPage(pref);
		Test.startTest();
			List<Bank_Usage__c> listBanks = extBankDetails.getOppSchoolsBanks();
		Test.stopTest();

		System.debug(extBankDetails.getOppSchoolsBanks());
		System.assertEquals(1, listBanks.size(),'Wrong number of bank accounts pulled');
		System.assertEquals('School Funding Account', listBanks[0].Usage__c,'Primary record not pulled');

	}

	static testMethod void oppSchoolDetailsTest() {

		Opportunity opp = new Opportunity();
		opp = [SELECT Id, AccountId, Account.CMO__c FROM Opportunity LIMIT 1];

		PageReference pref = Page.OppClientDetails;
		pref.getParameters().put('id', String.valueOf(opp.Id));

		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
		OppSchoolBankDetailsExt extBankDetails = new OppSchoolBankDetailsExt(sc);
		
		Test.setCurrentPage(pref);
		Test.startTest();
			List<Client_Alert__c> charterAlerts = extBankDetails.getOppCharterClientAlerts();
			List<Account> listSchools = extBankDetails.getOppSchoolsDetails();
			List<CSC_Action_Item__c> listCharterItems = extBankDetails.getOppCharterActionItems();
			List<CSC_Action_Item__c> listCMOItems = extBankDetails.getOppCharterCMOActionItems();
			List<CSC_Action_List__c> listSchoolLists = extBankDetails.getOppSchoolActionLists();
		Test.stopTest();

		System.debug('cas: ' + charterAlerts);
		System.assertEquals(1, charterAlerts.size(),'Number of Alerts pulled != 1');
		//System.assertEquals('School Funding Account', charterAlerts[0].Usage__c,'Primary record not pulled');
		System.assertEquals(0, listSchoolLists.size(), 'Should be nothing here');
		System.assertEquals(0, listCMOItems.size(), 'Should be nothing here');
	}

	static testMethod void getAttendanceTest() {

		Opportunity opp = new Opportunity();
		opp = [SELECT Id FROM Opportunity LIMIT 1];
		
		List<Id> opps = new List<Id>();
		opps.add(opp.Id);

		List<List<School_Attendance__c>> listAttendances = new List<List<School_Attendance__c>>();
		listAttendances = OppSchoolBankDetailsExt.getActiveAttendances(opps);
		
		System.assertEquals(1, listAttendances.size(),'Incorrect number of attendance records pulled');
	}

	@testSetup static void TestDataHelper(){

		Opportunity opp = new Opportunity();
		Account charterHolder = new Account();
		Account school = new Account();

		charterHolder = new Account(
			Name = 'Charter Holder',
			RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id
		);
		insert charterHolder;
		System.debug('ch: ' + charterHolder.id);

		school = new Account(
			Name = 'School',
			Charter_Holder__c = charterHolder.Id,
			RecordTypeId = RecordTypeUtils.AccountSchool.Id
		);
		insert school;

		Account bank = new Account(
			Name = 'Bank',
			RecordTypeId = RecordTypeUtils.AccountBank.Id
		);
		insert bank;

		List<Client_Alert__c> charterAlerts = new List<Client_Alert__c>();
		Boolean oneAlert = TRUE;
		for(Integer i = 0; i < 10; i++){
			Client_Alert__c ca = new Client_Alert__c(Account__c = charterHolder.Id, Active__c = False, Type__c = 'Finance', Client_Alert_Details__c = 'Test details');
				if(oneAlert){
					ca.Active__c = TRUE;
					oneAlert = FALSE;
				}
			charterAlerts.add(ca);
		}
		insert charterAlerts;

		Bank_Usage__c bankUsage1 = new Bank_Usage__c(Account__c = school.Id, Bank__c = bank.Id, Usage__c = 'School Funding Account', Account_Number__c = '654321', Routing_Number__c = '123-456-789');
		insert bankUsage1;

		Bank_Usage__c bankUsage2 = new Bank_Usage__c(Account__c = school.Id, Bank__c = bank.Id, Usage__c = 'Working Capital Deposit Account', Account_Number__c = '123456', Routing_Number__c = '123-456-789');
		insert bankUsage2;

		opp = new Opportunity(Name = 'Test Opp', AccountId = charterHolder.Id, CloseDate = System.today(), StageName = 'Initial Funding');
		insert opp;

		Opp_School__c oppSchool = new Opp_School__c(Opportunity__c = opp.Id, School__c = school.Id);
		insert oppSchool;

		School_Attendance__c sa = new School_Attendance__c(School__c = school.Id, Total_Attendance_manual__c = 200, Report_Date__c = Date.today(), Active__c = true);
		insert sa;

	}
	
	
}