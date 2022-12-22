/*
Because these tests are testing generated strings rely on formulas in the interface 
exact value testing isn't ideal so these tests aren't as robust as normal. Interface 
testing for exact value comparison is recommended.
*/ 
@isTest
private class OppSchoolTests {
	private static Account charterHolder1;
	private static Account authorizer1;
	private static Account coe1;
	private static Account district1, district2;
	private static Account school1, school2, school3;
	private static Contact cont1, cont2, cont3;
	private static Related_Contact__c rc1, rc2, rc3;
	private static Charter_Term__c term1, term2, term3, term4;
	private static Opportunity opp1;
	private static Opp_School__c oppSchool1, oppSchool2, oppSchool3;
	
	private static void setup() {
		charterHolder1 = new Account(
			Name = 'Unit Test Charter Holder',
			RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id
		);
		authorizer1 = createBusiness('Authorizer 1');
		coe1 = createBusiness('County Office of Education 1');
		district1 = createBusiness('School District 1');
		district2 = createBusiness('School District 2');
		insert new List<Account> { charterHolder1, authorizer1, coe1, district1, district2 };
		
		school1 = createSchool(charterHolder1, authorizer1, coe1, district1, 'Orange', 1);
		school2 = createSchool(charterHolder1, authorizer1, coe1, district1, 'Orange', 2);
		school3 = createSchool(charterHolder1, authorizer1, coe1, district2, 'Los Angeles', 3);
		insert new List<Account> { school1, school2, school3 };
		
		opp1 = new Opportunity(
			Name = 'Unit Test Opp',
			AccountId = charterHolder1.Id,
			CloseDate = System.today(),
			StageName = 'Initial Funding',
			Amount = 100
		);
		insert opp1;
		
		oppSchool1 = createOppSchool(opp1, school1);
		oppSchool2 = createOppSchool(opp1, school2);
		oppSchool3 = createOppSchool(opp1, school3);
		insert oppSchool1;	// purposely not inserting oppSchool2 or oppSchool3, the tests that use it will insert it
		
		term1 = createCharterTerm(school1, System.today(), 'Initial');
		term2 = createCharterTerm(school1, System.today().addYears(1), 'Renewal');
		term3 = createCharterTerm(school2, System.today(), 'Initial');
		term4 = createCharterTerm(school3, System.today(), 'Initial');
	}
	
	private static void setupUnderwritingContactTests() {
		setup();
		
		cont1 = createContact(school1, 1);
		cont2 = createContact(school1, 2);
		cont3 = createContact(charterHolder1, 3);
		insert new List<Contact> { cont1, cont2, cont3 };
		
		rc1 = createUnderwritingContact(cont1, true, false);
		rc2 = createUnderwritingContact(cont2, false, false);
		rc3 = createUnderwritingContact(cont3, false, true);
		insert new List<Related_Contact__c> { rc1, rc2, rc3 };
	}
	
	private static Account createBusiness(String name) {
		return new Account(
			Name = name,
			RecordTypeId = RecordTypeUtils.AccountBusiness.Id
		);
	}
	
	private static Account createSchool(Account charterHolder, Account authorizer, Account coe, Account district, String county, Integer ord) {
		return new Account(
			Name = 'Unit Test School ' + ord,
			Legal_Name__c = 'Unit Test School ' + ord,
			RecordTypeId = RecordTypeUtils.AccountSchool.Id,
			Charter_Holder__c = charterHolder.Id,
			Authorizer_A__c = authorizer.Id,
			COE__c = coe.Id,
			School_District__c = district.Id,
			County__c = county
		);
	}
	
	private static Opp_School__c createOppSchool(Opportunity opp, Account school) {
		return new Opp_School__c(
			Opportunity__c = opp1.Id,
			School__c = school.Id
		);
	}
	
	private static Contact createContact(Account acct, Integer ord) {
		return new Contact(
			FirstName = 'Unit' + ord,
			LastName = 'Test',
			AccountId = acct.Id,
			Phone = '949-555-1212',
			Fax = '949-555-1213',
			Email = 'unit' + ord + 'test@test.com'
		);
	}
	
	private static Related_Contact__c createUnderwritingContact(Contact cont, Boolean legalNotice, Boolean fundingDocs) {
		return new Related_Contact__c(
			Account__c = cont.AccountId,
			Contact__c = cont.Id,
			Legal_Notice__c = legalNotice,
			Funding_Docs__c = fundingDocs
		);
	}
	
	private static Charter_Term__c createCharterTerm(Account school, Date startDate, String termType) {
		return new Charter_Term__c(
			School__c = school.Id,
			Start_Date__c = startDate,
			End_Date__c = startDate.addYears(1),
			Term__c = 'One',
			Frequency__c = 'Year',
			Type__c = termType,
			No_Cap_Limit__c = true
		);
	}
	
	private static Opportunity loadOpportunity(Id oppId) {
		return [SELECT Id, Num_of_Opp_Schools__c, Schools__c, TL_Auth_Entity__c, TL_Attesting_Party__c, TL_Obligor__c, PAA_County__c, TL_School_Address__c, TL_Charter_Terms__c, Additional_To_FD__c FROM Opportunity WHERE Id = :oppId];
	}
	
	private static Opp_School__c loadOppSchool(Id oppSchoolId) {
		return [SELECT Id, Authorizer__c, Authorizer_Id__c, COE__c, COE_Id__c, School_District__c, School_District_Id__c, Legal_Notice_Contact__c, PAA_Attesting_Party__c FROM Opp_School__c WHERE Id = :oppSchoolId];
	}
	
	static testMethod void testSetupAssumptions() {
		setup();
		
		opp1 = loadOpportunity(opp1.Id);
		System.assertEquals(1, opp1.Num_of_Opp_Schools__c);
		System.assertNotEquals(null, opp1.Schools__c);
		System.assertNotEquals('', opp1.Schools__c);
		System.assertNotEquals(null, opp1.TL_Auth_Entity__c);
		System.assertNotEquals('', opp1.TL_Auth_Entity__c);
		System.assertNotEquals(null, opp1.TL_Attesting_Party__c);
		System.assertNotEquals('', opp1.TL_Attesting_Party__c);
		System.assertNotEquals(null, opp1.TL_Obligor__c);
		System.assertNotEquals('', opp1.TL_Obligor__c);
		System.assertNotEquals(null, opp1.PAA_County__c);
		System.assertNotEquals('', opp1.PAA_County__c);
		System.assertNotEquals(null, opp1.TL_School_Address__c);
		System.assertNotEquals('', opp1.TL_School_Address__c);
		
		oppSchool1 = loadOppSchool(oppSchool1.Id);
		// make sure the ids are set to the expected values before testing the lookup values
		System.assertNotEquals(null, oppSchool1.Authorizer_Id__c);
		System.assertNotEquals(null, oppSchool1.COE_Id__c);
		System.assertNotEquals(null, oppSchool1.School_District_Id__c);
		System.assertEquals(authorizer1.Id, oppSchool1.Authorizer_Id__c);
		System.assertEquals(coe1.Id, oppSchool1.COE_Id__c);
		System.assertEquals(district1.Id, oppSchool1.School_District_Id__c);
		
		// the assumption is that on insert a workflow rule causes an update, if not these values will be null
		System.assertNotEquals(null, oppSchool1.Authorizer__c);
		System.assertNotEquals(null, oppSchool1.COE__c);
		System.assertNotEquals(null, oppSchool1.School_District__c);
		
		System.assertEquals(authorizer1.Id, oppSchool1.Authorizer__c);
		System.assertEquals(coe1.Id, oppSchool1.COE__c);
		System.assertEquals(district1.Id, oppSchool1.School_District__c);
		
		System.assertEquals(null, oppSchool1.Legal_Notice_Contact__c);
	}
	
	static testMethod void testLegalDocsStampingOppSchoolCreateSecond() {
		setup();
		
		opp1 = loadOpportunity(opp1.Id);
		String oldVal = opp1.Schools__c;
		
		insert oppSchool2;
		
		opp1 = loadOpportunity(opp1.Id);
		System.assertEquals(2, opp1.Num_of_Opp_Schools__c);
		System.assertNotEquals(null, opp1.Schools__c);
		System.assertNotEquals('', opp1.Schools__c);
		System.assertNotEquals(oldVal, opp1.Schools__c);
	}
	
	static testMethod void testLegalDocsStampingOppSchoolCreateThird() {
		setup();
		
		opp1 = loadOpportunity(opp1.Id);
		String oldVal = opp1.Schools__c;
		
		insert new List<Opp_School__c> { oppSchool2, oppSchool3 };
		
		opp1 = loadOpportunity(opp1.Id);
		System.assertEquals(3, opp1.Num_of_Opp_Schools__c);
		System.assertNotEquals(null, opp1.Schools__c);
		System.assertNotEquals('', opp1.Schools__c);
		System.assertNotEquals(oldVal, opp1.Schools__c);
	}
	
	static testMethod void testLegalDocsStampingOppSchoolDelete() {
		setup();
		
		delete oppSchool1;
		opp1 = loadOpportunity(opp1.Id);
		System.assertEquals(0, opp1.Num_of_Opp_Schools__c);
		System.assertEquals(null, opp1.Schools__c);
	}
	
	static testMethod void testLegalDocsStampingOppSchoolUndelete() {
		setup();
		
		delete oppSchool1;
		undelete oppSchool1;
		opp1 = loadOpportunity(opp1.Id);
		System.assertEquals(1, opp1.Num_of_Opp_Schools__c);
		System.assertNotEquals(null, opp1.Schools__c);
		System.assertNotEquals('', opp1.Schools__c);
	}
	
	static testMethod void testLegalDocsStampingSchoolLegalNameChanged() {
		setup();
		
		opp1 = loadOpportunity(opp1.Id);
		String oldVal = opp1.Schools__c;
		
		school1.Legal_Name__c += ', Inc.';
		update school1;
		
		opp1 = loadOpportunity(opp1.Id);
		System.assertEquals(1, opp1.Num_of_Opp_Schools__c);
		System.assertNotEquals(null, opp1.Schools__c);
		System.assertNotEquals('', opp1.Schools__c);
		System.assertNotEquals(oldVal, opp1.Schools__c);
	}
	
	static testMethod void testCharterTermsSingleSchoolInsert() {
		setup();
		insert term1;
		
		opp1 = loadOpportunity(opp1.Id);
		System.assertNotEquals(null, opp1.TL_Charter_Terms__c);
		System.assertNotEquals('', opp1.TL_Charter_Terms__c);
	}
	
	static testMethod void testCharterTermsMultipleSchoolInsert() {
		setup();
		insert term1;
		term2.Prior_Term__c = term1.Id;
		insert oppSchool2;
		insert new List<Charter_Term__c> { term2, term3 };
		
		opp1 = loadOpportunity(opp1.Id);
		System.assertNotEquals(null, opp1.TL_Charter_Terms__c);
		System.assertNotEquals('', opp1.TL_Charter_Terms__c);
	}
	
	static testMethod void testCharterTermsUpdate() {
		setup();
		insert term1;
		
		term1.Start_Date__c = System.today().addDays(1);
		term1.End_Date__c = term1.Start_Date__c.addYears(1);
		update term1;
		
		opp1 = loadOpportunity(opp1.Id);
		System.assertNotEquals(null, opp1.TL_Charter_Terms__c);
		System.assertNotEquals('', opp1.TL_Charter_Terms__c);
	}
	
	static testMethod void testUnderwritingContactInsert() {
		setupUnderwritingContactTests();
		
		oppSchool1 = loadOppSchool(oppSchool1.Id);
		System.assertEquals(cont1.Id, oppSchool1.Legal_Notice_Contact__c);
	}
	
	static testMethod void testUnderwritingContactDataUpdate() {
		setupUnderwritingContactTests();
		
		oppSchool1 = loadOppSchool(oppSchool1.Id);
		String priorVal = oppSchool1.PAA_Attesting_Party__c;
		
		cont1.Email = 'anothertest@test.com';
		update cont1;
		//oppSchool1 = loadOppSchool(oppSchool1.Id);
		//System.assertNotEquals(priorVal, oppSchool1.PAA_Attesting_Party__c);
		System.assert(true, 'Enable this once the PAA Attesting Party workflow has been implemented.');
	}
	
	static testMethod void testOppSchoolInsertExistingUnderwritingContact() {
		setup();
		
		cont1 = createContact(school2, 1);
		insert cont1;
		
		rc1 = createUnderwritingContact(cont1, true, false);
		insert rc1;
		insert oppSchool2;
		
		oppSchool2 = loadOppSchool(oppSchool2.Id);
		System.assertEquals(cont1.Id, oppSchool2.Legal_Notice_Contact__c);
	}
	
	static testMethod void testUnderwritingContactChanged() {
		setupUnderwritingContactTests();
		
		rc1.Legal_Notice__c = false;
		update rc1;
		
		oppSchool1 = loadOppSchool(oppSchool1.Id);
		System.assertEquals(null, oppSchool1.Legal_Notice_Contact__c);
		
		rc2.Legal_Notice__c = true;
		update rc2;
		
		oppSchool1 = loadOppSchool(oppSchool1.Id);
		System.assertEquals(cont2.Id, oppSchool1.Legal_Notice_Contact__c);
	}
	
	static testMethod void testUnderwritingContactFundingDataChanged() {
		setupUnderwritingContactTests();
		
		opp1 = loadOpportunity(opp1.Id);
		String prevVal = opp1.Additional_To_FD__c;
		
		cont3.Email = 'newemail@test.com';
		update cont3;
		
		opp1 = loadOpportunity(opp1.Id);
		System.assertNotEquals(prevVal, opp1.Additional_To_FD__c);
	}
	
	static testMethod void testUnderwritingContactDeleteProtection() {
		setupUnderwritingContactTests();
		
		try {
			delete rc1;
			System.assert(false, 'This should have failed due to the delete protection trigger.');
		} catch(DMLException e) {} // this is expected
		
		rc1.Legal_Notice__c = false;
		update rc1;
		delete rc1;
		System.assert(true, 'If we got this far it passed');
	}
}