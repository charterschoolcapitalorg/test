@isTest
private class ReportingWeeklyInitialFundingTest {
	static testMethod void testWeeklyReport() {
		ReportingWeeklyInitialFunding rwif = new ReportingWeeklyInitialFunding();
		Test.startTest();
			rwif.execute(null);
		Test.stopTest();
		List<Snapshot_Report__c> snapshots = [SELECT Id, Opp_Status__c FROM Snapshot_Report__c];
		System.debug(snapshots);
		System.assertEquals(2, snapshots.size(), 'Should be two snapshots');
	}

	static testMethod void testWeeklyReportBlue() {
		ReportingWeeklyInitialFunding rwif = new ReportingWeeklyInitialFunding();
		Opportunity o = [Select Id, Name, CloseDate FROM Opportunity LIMIT 1];
		o.CloseDate = Date.today().addDays(50);
		update o;
		Test.startTest();
			rwif.execute(null);
		Test.stopTest();
		Snapshot_Report__c sr = [SELECT ID, Opp_Status__c FROM Snapshot_Report__c WHERE Record_Name__c = :o.Name];
		System.assertEquals('Blue', sr.Opp_Status__c, 'Incorrect Status');
	}

	static testMethod void testWeeklyReportRed() {
		ReportingWeeklyInitialFunding rwif = new ReportingWeeklyInitialFunding();
		List<CSC_Action_Item__c> items = [SELECT Status__c FROM CSC_Action_Item__c];
		for(CSC_Action_Item__c i : items){
			i.Status__c = 'New';
		}
		update items;
		Test.startTest();
			rwif.execute(null);
		Test.stopTest();
		Snapshot_Report__c sr = [SELECT ID, Opp_Status__c FROM Snapshot_Report__c LIMIT 1];
		//All should be Red as no items are complete
		System.assertEquals('Red', sr.Opp_Status__c, 'Incorrect Status');
	}

	/*static testMethod void testWeeklyReportNoComments() {
		ReportingWeeklyInitialFunding rwif = new ReportingWeeklyInitialFunding();
		List<CSC_Action_Item__c> items = [SELECT Status__c FROM CSC_Action_Item__c];
		for(CSC_Action_Item__c i : items){
			i.Comments__c = null;
		}
		update items;
		Test.startTest();
			rwif.execute(null);
		Test.stopTest();
		Snapshot_Report__c sr = [SELECT ID, Opp_Status__c FROM Snapshot_Report__c LIMIT 1];
		//All should be Red as no comments in opening call
		System.assertEquals('Red', sr.Opp_Status__c, 'Incorrect Status');
	}*/

	static testMethod void testWeeklyReportAccelerated() {
		ReportingWeeklyInitialFunding rwif = new ReportingWeeklyInitialFunding();
		Opportunity o = [Select Id, Name, CloseDate, Accelerated_Sales_Process__c FROM Opportunity LIMIT 1];
		o.Accelerated_Sales_Process__c = true;
		o.CloseDate = Date.today().addDays(20);
		update o;
		Test.startTest();
			rwif.execute(null);
		Test.stopTest();
		Snapshot_Report__c sr = [SELECT ID, Opp_Status__c FROM Snapshot_Report__c WHERE Record_Name__c = :o.Name];
		//Should be green based on the dates used, ie opp closes in 20 days and all items are complete
		System.assertEquals('Green', sr.Opp_Status__c, 'Incorrect Status');
	}

	@testSetup static void setup() {
		

		//bypass action list resequence
		BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Terms_Letter__c',
                                            Triggers_Disabled__c = true,
                                            Validation_Rules_Disabled__c = false,
                                            Workflow_Rules_Disabled__c = false);
    	insert ProfileCustomSettings;

		//create States, Accounts, Initial Fundings, Action Lists, Action Items
		List<State_Province__c> states = new List<State_Province__c>();
		State_Province__c state1 = new State_Province__c();
		state1.Name = 'AZ';
        state1.State_Name__c = 'AZ';
        states.add(state1);
		State_Province__c state2 = new State_Province__c();
		state2.Name = 'CA';
        state2.State_Name__c = 'CA';
        states.add(state2);
        insert states;

		List<Account> accounts = new List<Account>();
		Account acc1 = new Account();
		acc1.Name = 'Account AZ';
        acc1.Operating_State__c = states[0].Id;
        accounts.add(acc1);
		Account acc2 = new Account();
		acc2.Name = 'Account CA';
        acc2.Operating_State__c = states[1].Id;
        accounts.add(acc2);
        insert accounts;

		List<Opportunity> opps = new List<Opportunity>();
		Opportunity opp1 = new Opportunity();
		opp1.AccountId = accounts[0].Id;
		opp1.Name = 'Test Opp AZ';
		opp1.CloseDate = Date.today();
		opp1.Amount = 0;
		opp1.StageName = 'Stage 2 - Preparation';
		opp1.RecordTypeId = RecordTypes.IDFundingOpp;
		opps.add(opp1);
		Opportunity opp2 = new Opportunity();
		opp2.AccountId = accounts[1].Id;
		opp2.Name = 'Test Opp CA';
		opp2.CloseDate = Date.today();
		opp2.Amount = 0;
		opp2.StageName = 'Stage 2 - Preparation';
		opp2.RecordTypeId = RecordTypes.IDFundingOpp;
		opps.add(opp2);
		Opportunity opp3 = new Opportunity();
		opp3.AccountId = accounts[1].Id;
		opp3.Name = 'Test Opp CA';
		opp3.CloseDate = Date.today();
		opp3.Amount = 0;
		opp3.StageName = 'Stage 2 - Preparation';
		opp3.RecordTypeId = RecordTypes.IDFOFOpp;
		opps.add(opp3);
		insert opps;

		List<String> stages = new List<String>{'Stage 1 - Qualification', 'Stage 2 - Preparation'};
		List<CSC_Action_List__c> lists = new List<CSC_Action_List__c>();
		for(Opportunity o : opps){
			for(String s : stages){
				CSC_Action_List__c lst = new CSC_Action_List__c();
				lst.Opportunity__c = o.Id;
				lst.Action_List_Name__c = s;
				lists.add(lst);
			}
		}
		insert lists;

		List<String> itemNames = new List<String>{'Complete Pre-Qualification Form', 'Opening Call Conducted', 'Client Completes MSA (FDA)', 'W-9 Obtained', 'OIL Docs Received (Underwriting)', 'OIL Docs Received (Finance)'};
		System.debug(itemNames);

		List<CSC_Action_Item__c> items = new List<CSC_Action_Item__c>();
		for(CSC_Action_List__c al : lists){
			for(String s : itemNames){
				CSC_Action_Item__c item = new CSC_Action_Item__c();
				item.CSC_Action_List__c = al.id;
				item.Action_Item_Name__c = s;
				item.BD_Green_Level_Accelerated__c = 15;
				item.BD_Green_Level_Standard__c = 30;
				item.BD_Red_Level_Accelerated__c = 14;
				item.BD_Red_Level_Standard__c = 15;
				item.Date_Completed__c = Date.today().addDays(-10);
				item.Assigned_To__c = UserInfo.getUserId();
				item.Comments__c = 'Got me some comments';
				item.Status__c = 'Completed';
				items.add(item);
			}
		}

		insert items;


	}
}