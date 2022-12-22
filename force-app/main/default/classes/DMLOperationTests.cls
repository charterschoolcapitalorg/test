@isTest
private class DMLOperationTests {
	
	private static final Integer BATCH_SIZE = 200;
	private static final String CLASS_NAME = 'DMLOperationTests';

	private static Lead createTestLead() {
		return new Lead(
			LastName = 'Name',
			FirstName = 'Test',
			Email = 'fakeemail@fakefake.com',
			Company = 'Test Company'
		);
	}

	@isTest 
	static void testInsert() {
		List<Lead> leads = new List<Lead>();

		for (Integer i = 0; i < BATCH_SIZE; i++) {
			if (math.mod(i, 2) == 0) {
				leads.add(new Lead());
			}
			else {
				leads.add(
					createTestLead()
				);
			}
		}

		DMLOperation.Options optns = DMLOperation.getDefaultOptions();
		optns.className = CLASS_NAME;
		optns.methodName = 'testInsert';

		System.assertEquals(0, [SELECT count() FROM Log__c]);
		Test.startTest();
		DMLOperation dmlOperation = new DMLOperation( leads, DMLOperation.OperationType.INS, optns );
		Test.stopTest();
		//System.assertEquals(100, [SELECT count() FROM Log__c]);
	}
	
	@isTest 
	static void testUpdate() {
		List<Lead> leads = new List<Lead>();

		for (Integer i = 0; i < BATCH_SIZE; i++) {
			leads.add(
				createTestLead()
			);
		}

		DMLOperation.Options optns = DMLOperation.getDefaultOptions();
		optns.className = CLASS_NAME; 
		optns.methodName = 'testUpdate';

		System.assertEquals(0, [SELECT count() FROM Log__c]);
		DMLOperation dmlOperation = new DMLOperation( leads, DMLOperation.OperationType.INS );
		System.assertEquals(true, dmlOperation.getResult().wasSuccess);
		System.assertEquals(0, [SELECT count() FROM Log__c]);

		leads = [SELECT Id FROM Lead];
		Integer i = 0;
		for (Lead l : leads) {
			if (math.mod(i, 2) == 0) {
				l.LastName = null;
			}
			i++;
		}

		Test.startTest();
		//dmlOperation = new DMLOperation( leads, DMLOperation.OperationType.UPD, optns );
		Test.stopTest();
		System.assertEquals(100, [SELECT count() FROM Log__c]);
	}
	
	@isTest 
	static void testDelete() {
		List<Lead> leads = new List<Lead>();

		for (Integer i = 0; i < BATCH_SIZE; i++) {
			leads.add(
				createTestLead()
			);
		}

		DMLOperation.Options optns = DMLOperation.getDefaultOptions();
		optns.className = CLASS_NAME; 
		optns.methodName = 'testDelete';

		System.assertEquals(0, [SELECT count() FROM Log__c]);
		DMLOperation dmlOperation = new DMLOperation( leads, DMLOperation.OperationType.INS, optns );
		System.assertEquals(0, [SELECT count() FROM Log__c]);

		leads = [SELECT Id FROM Lead];
		Test.startTest();
		//dmlOperation = new DMLOperation( leads, DMLOperation.OperationType.DEL, optns ); 
		Test.stopTest();
		System.assertEquals(0, [SELECT count() FROM Log__c]);
	}
}