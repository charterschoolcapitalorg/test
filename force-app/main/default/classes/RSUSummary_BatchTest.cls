/**=====================================================================
 * Appirio, Inc
 * Name: RSUSummary_BatchTest
 * Description: Test class for RSUSummary_Batch
 * Created Date: [07/25/2014]
 * Created By: [Manisha] (Appirio)
 * Date Modified                Modified By                  Description of the update
 *
 =====================================================================*/
@isTest
private class RSUSummary_BatchTest {

	static testmethod void RSUSummaryBatchtest(){
		Test.StartTest();
		list<Account> listAcc = new list<Account>();
		for(Integer i = 0 ; i < 15 ; i++){
			listAcc.add(new Account(Name = 'Test Account ' + i));
		}

		insert listAcc;
		set<Id> setAccId = new set<Id>();
		for(Account acc : listAcc){
			setAccId.add(acc.Id);
		}

		RSUSummary_Batch controller = new RSUSummary_Batch(setAccId,
															String.valueOf(date.today().addDays(-10)),
															String.valueOf(date.today().addDays(10)), userInfo.getSessionId(), userInfo.getOrganizationId());
		controller.start(null);
		controller.execute(null, listAcc);
		controller.finish(null);
		Test.StopTest();
	}
}