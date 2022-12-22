@isTest
private class DocumentAutomationTest {

	private static Opportunity opp{get;}

	@isTest static void testBuildURL() {
		// Implement test code
		createData();
		Test.startTest();
		opp.StageName = 'Stage 3 - Review';
		update opp;
		String s = DocumentAutomation.oppFundingDocsURL(opp.Id, 'WC - OH', true);
		Test.stopTest();

		System.assert(s.contains('pv0=' + opp.id));
	}	

	static void createData(){
		
		Map<String, Id> recordTypes = new Map<String, Id>();
		recordTypes = RecordTypeUtils.getsObjectRecordMap('Account');
		System.debug('Types: ' + recordTypes);

		Map<String, Id> oppRecordTypes = new Map<String, Id>();
		oppRecordTypes = RecordTypeUtils.getsObjectRecordMap('Opportunity');
		System.debug('Types: ' + oppRecordTypes);

		State_Province__c state = TestHelper.createStateProvince('CA', true);

		List<Account> accs = new List<Account>();
		accs.add(new Account(name = 'Test Charter', RecordTypeId = recordTypes.get('Charter_Holder'), Operating_State__c = state.Id));
		accs.add(new Account(name = 'Test Bank', RecordTypeId = recordTypes.get('Bank'), Operating_State__c = state.Id));
		insert accs;
		System.debug('Bank: ' + accs[1]);
		Account school = new Account(name = 'Test School', Charter_Holder__c = accs[0].Id, RecordTypeId = recordTypes.get('School'));
		insert school;
		Bank_Usage__c bu = new Bank_Usage__c(Bank__c = accs[1].Id, Account__c = school.Id, Usage__c  = 'Working Capital Deposit Account', Account_Number__c = '12345678', Routing_Number__c = '123-456-789');
		insert bu;
		System.debug('bu: ' + bu);

		//insert contacts
		List<Contact> cons = new List<Contact>();

		for(Integer i = 0; i < 10; i++){
			cons.add(new Contact(LastName = 'Contact ' + i, Account = accs[0]));
		}
		insert cons;

		//insert related contacts, every other is an FD
		List<Related_Contact__c> rcs = new List<Related_Contact__c>();
		for (Contact c : cons){
			Related_Contact__c rc = new Related_Contact__c(Account__c = accs[0].Id, Contact__c = c.Id);
			rc.Funding_Docs__c = true;
			rcs.add(rc);
		}
		System.debug('rcs: ' + rcs);
		insert rcs;

		//insert Opportunity and Opp School
		opp = new Opportunity(name = 'Test Opportunity', AccountId = accs[0].Id, StageName = 'Stage 1 - Qualification', CloseDate = Date.today(), RecordTypeId = oppRecordTypes.get('FOF'));
		opp.Signer_1__c = cons[0].Id;
		opp.Signer_2__c = cons[1].Id;
		opp.Signer_Manager_1__c = cons[2].Id;
		opp.Signer_Manager_2__c = cons[3].Id;
		insert opp;
		Opp_School__c oppSch = new Opp_School__c(Opportunity__c = opp.Id , School__c = school.Id);
		insert oppSch;
		System.debug('Opp school: ' + oppSch);


	}

	/*
	need
	Charter
	Opp School
	Contacts
	Related Contacts
	Opportunity
	Opp Schools
	Custom Settings
	*/


}