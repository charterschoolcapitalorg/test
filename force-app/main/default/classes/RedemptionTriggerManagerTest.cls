@isTest
private class RedemptionTriggerManagerTest {

	@isTest static void testRedemption(){
		Redemption__c red = new Redemption__c();
		red.Date_Cleared__c = Date.newInstance(2018, 12, 24);
		red.Date_Paid__c = Date.newInstance(2018, 12, 24);
		insert red;

		red.Distribution_Email_Sent_Date__c = Date.newInstance(2018, 12, 26);
		Test.startTest();
			update red;
		Test.stopTest();

		Redemption__c r = [SELECT Id, Date_Paid__c, Distribution_Email_Sent_Date__c, Distribution_Email_Sent_Days__c FROM Redemption__c WHERE id = :red.Id];
		System.assertEquals(1, r.Distribution_Email_Sent_Days__c, 'One business day betweeen');
	}

	@isTest static void testRedemptionWorkflow(){
		Redemption__c red = new Redemption__c();
		red.Date_Cleared__c = Date.newInstance(2009, 12, 31);
		red.Date_Paid__c = Date.newInstance(2010, 1, 1);
		insert red;

		red.Distribution_Email_Sent__c = true;
		Test.startTest();
			update red;
		Test.stopTest();

		List<Redemption__c> reds = [SELECT Id, Date_Paid__c, Distribution_Email_Sent_Date__c, Distribution_Email_Sent_Days__c FROM Redemption__c WHERE Distribution_Email_Sent_Days__c > 0];
		System.assertEquals(1, reds.size(), 'Should have updated the days sent');
	}


	@isTest static void testRedemptionBulk(){
		List<Redemption__c> reds = new List<Redemption__c>();
		for(Integer i = 0; i < 200; i++){
			Redemption__c red = new Redemption__c();
			red.Date_Cleared__c = Date.newInstance(2018, 12, 21);
			red.Date_Paid__c = Date.newInstance(2018, 12, 24);
			reds.add(red);
		}
		insert reds;
		
		for(Redemption__c r : reds){
			r.Distribution_Email_Sent_Date__c = Date.newInstance(2018, 12, 26);
		}
		
		Test.startTest();
			update reds;
		Test.stopTest();

		Redemption__c r = [SELECT Id, Date_Paid__c, Distribution_Email_Sent_Date__c, Distribution_Email_Sent_Days__c FROM Redemption__c LIMIT 1];
		System.assertEquals(1, r.Distribution_Email_Sent_Days__c, 'One business day betweeen');
	}


}