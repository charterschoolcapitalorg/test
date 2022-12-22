/**=====================================================================
 * Appirio, Inc
 * Name: RSUSummaryControllerTest
 * Description: Test class for RSUSummaryController
 * Created Date: [07/25/2014]
 * Created By: [Manisha] (Appirio)
 * Date Modified                Modified By                  Description of the update
 *
 =====================================================================*/
@isTest
private class RSUSummaryControllerTest {
	
	static testmethod void updateBalanceTest(){
		Test.StartTest();

		list<APXTConga4__Conga_Merge_Query__c> listCongaQuery = new list<APXTConga4__Conga_Merge_Query__c>();
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU Dates'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU Outstanding'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU SoldSummary'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU CollectedSummary'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU Sold'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU Collected'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU PAA'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU Penalty'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'RSU Bank'));

		insert listCongaQuery;

		APXTConga4__Conga_Template__c template = new APXTConga4__Conga_Template__c(APXTConga4__Name__c = 'RSU Summary');
		insert template;

		list<Account> listAcc = new list<Account>();
		for(Integer i = 0 ; i < 15 ; i++){
			listAcc.add(new Account(Name = 'Test Account ' + i));
		}

		insert listAcc;

		RPA__c rpa = new RPA__c(Account__c = listAcc[0].Id);
		insert rpa;
		String accountIds = '';
		list<String> accIds = new list<Id>();
		list<Funded_Receivable__c> listFundedRec = new list<Funded_Receivable__c>();
		list<Attachment> attachList = new list<Attachment>();
		for(Account acc : listAcc){
			accountIds += ','+acc.Id;
			accIds.add(acc.Id);
			attachList.add(new Attachment(Name = 'RSU_Summary_' + acc.name, Body = blob.valueOf('Test'), parentId = acc.Id));
			for(Integer i = 0; i < 10; i++){

				listFundedRec.add(new Funded_Receivable__c(Charter_Holder__c = acc.Id,
															School__c = acc.Id,
															RPA__c = rpa.Id,
														   FV_Amount__c = 1000,
														   Final_Payment_Date__c = date.today().addDays(10),
														   Purchase_Date__c = date.today().addDays(-10) ));
			}
		}

		insert listFundedRec;
		insert attachList;

		list<Allocation__c> listAllocation = new list<Allocation__c>();
		Redemption__c red = TestHelper.createRedemption(listAcc[0].Id);
		red.Amount_received__c = 75000;
		insert red;


		for(Funded_Receivable__c fundedRec : listFundedRec){
			listAllocation.add(new Allocation__c(Funded_Receivable__c = fundedRec.Id,
												Face_Amount_Applied__c = 500,
												Redemption__c = red.Id));
												//Redemption_Date_Cleared__c = date.today().addDays(-10)));
		}

		insert listAllocation;



		Test.setCurrentPage(Page.RSU_Summary);
		ApexPages.CurrentPage().getParameters().put('accountIds',accountIds.replaceFirst(',', ''));
		RSUSummaryController controller = new RSUSummaryController();
		controller.rsuDateSetting.Start_Date__c = date.today().addDays(-10);
		controller.rsuDateSetting.End_Date__c = date.today();
		controller.updateBalance();
		controller.createRSUSummary();

		RSUSummaryController.downloadRSU(accIds);
		Test.StopTest();
	}
	

	@testSetup
	public static void setup(){
			List<Account> testAccounts = new List<Account>();

			Account a = new Account();
			a.Name = 'ABC Company, Inc.';
			testAccounts.add(a);

			Account acct = new Account();
			acct.Name = 'XYZ Company, Inc.';
			testAccounts.add(acct);

			insert testAccounts;
	}	

	@IsTest
	public static void testRsuGeneration() {
		List<sObject> accts = (List<Account>)[Select Id From Account];
		System.debug(accts);
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(accts);
		ssc.setSelected(accts);
		RSUSummaryController cn = new RSUSummaryController(ssc);

		cn.rsuDateSetting = new RSU_Dates__c();
		cn.rsuDateSetting.Start_Date__c = Date.today();
		cn.rsuDateSetting.End_Date__c = Date.today();

		Test.startTest();
		PageReference pr = cn.rsuGeneration();
		String fieldName = pr.getParameters().get('UrlFieldName');
		System.assertEquals('Conga_Conductor_RSU_flexible_dates__c',fieldName, 'The UrlFieldName parameter is not set' );
		Test.stopTest();
}  


}