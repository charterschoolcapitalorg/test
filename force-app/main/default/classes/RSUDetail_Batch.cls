/**=====================================================================
 * Appirio, Inc
 * Name: Batch Class to Generate RSU Summary for Selected Accounts if number of selected accounts is greater than 10
 * Description:
 * Created Date: [07/21/2014]
 * Created By: [Manisha Gupta] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 08/07/2014 					Manisha Gupta					Updated to resolve session id null issue in production
 * 08/07/2014					John Caughie					Copied from RSUSummaryBatch 
 =====================================================================*/
global with sharing class RSUDetail_Batch implements database.Batchable<sObject>, Database.AllowsCallouts{
	set<Id> accountIds;
	String startDate;
	String endDate;
	String sessionId;
	String orgId;

	public RSUDetail_Batch(set<Id> accountIds, String startDate, String endDate, String sessionId, String orgId){
		this.accountIds = accountIds;
		this.startDate = startDate;
		this.endDate = endDate;
		this.sessionId = sessionId;
		this.orgId = orgId;
	}

	global Database.QueryLocator start(Database.BatchableContext context) {
		String query = 'Select Id, Name From Account where Id in :accountIds';

		return database.getQueryLocator(query);
  	}

  	global void execute(Database.BatchableContext context, List<Account> listAccount){

  		for(Account account : listAccount){
  			RSUSummaryController.generateRSUDetailForAccount(account.Id, startDate, endDate, account.Name, sessionId, orgId);
  		}

  	}

  	global void finish(Database.BatchableContext context){

  	}
}