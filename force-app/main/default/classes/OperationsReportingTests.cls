@isTest
private class OperationsReportingTests {

	//
	@testSetup static void setupTestData(){

        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');
        
		//create accounts
		List<Account> accs = new List<Account>();
		for(Integer i = 0; i < 10; i++){
			accs.add(CSCTestUtil.createAccount('Test ' + i));
		}
		insert accs;
        System.debug('accs: ' + accs);

		//create opportunities
		List<Opportunity> opps = new List<Opportunity>();
		for(Integer i = 0; i < 10; i++){
			opps.add(CSCTestUtil.createOpportunity(accs[i].Id, 'Opp ' + i, 'Stage 3 - Review'));
		}
		insert opps;
        System.debug('opps: ' + opps);

		//create Action Lists
		List<CSC_Action_List__c> lists = new List<CSC_Action_List__c>();
		for(Integer i = 0; i < 10; i++){
			lists.add(CSCTestUtil.createSPActionList(accs[i].Id, opps[i].Id, 'Stage 3 - Review', 'Underwriting', 1, false, true));
		}
		insert lists;
        System.debug('lists: ' + lists);

		//create Action Items
		List<CSC_Action_Item__c> items = new List<CSC_Action_Item__c>();
		for(Integer i = 0; i < 10; i++){
			CSC_Action_Item__c item = CSCTestUtil.createActionItem(lists[i].Id, i);
			switch on i{
				when 0 {
					item.Action_Item_Name__c = 'OIL documents received - UW';
					item.Status__c = 'Completed';
				}
				when 1 {
					item.Action_Item_Name__c = 'Funding Committee form completed - FIN (Financial review completed)';
				}
				when 2 {
					item.Action_Item_Name__c = 'Received electronic signature pages';
				}
				when 3 {
					item.Action_Item_Name__c = '"Ready to Fund" email sent';
				}
				when 4 {
					item.Action_Item_Name__c = 'Funding Committee Form (Financial Review Completed)';
				}
				when 5 {
					item.Action_Item_Name__c = 'Diligence Items Received';
				}
				when 6 {
					item.Action_Item_Name__c = 'Underwriting FC Form Complete';
				}
				when else {
					item.Action_Item_Name__c = 'An item not related to the above';
				}
			}
			
			items.add(item);
		}
		insert items;

	}

	@isTest static void testOperationsReport(){
		System.debug(OperationsReporting.getDailyUpdates());
		System.assertEquals(7, OperationsReporting.getDailyUpdates().size(),'One per item = 7');

	}


}