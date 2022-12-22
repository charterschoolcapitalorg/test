/**=====================================================================
 * Appirio, Inc
 * Name: UpdateExistingReceivables_Batch
 * Description: I-122095 - Issue related to Clear Date in Redemption and AllocationTrigger
 * Created Date: [07/18/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
global class UpdateExistingReceivables_Batch implements Database.Batchable<SObject>, Schedulable{
	/*** BATCHABLE INTERFACE Methods ***/
  	global Database.QueryLocator start(Database.BatchableContext context) {
		//String query = 'select id,Face_Amount_Applied__c,Funded_Receivable__c, Redemption_Date_Cleared__c, Funded_Receivable__r.Final_Payment_Date__c from allocation__c where Funded_Receivable__r.FV_Amount_Due__c = 0.00 order by Redemption_Date_Cleared__c desc';

		String query = 'SELECT Id, Name, (SELECT Id, Redemption_Date_Cleared__c FROM allocations__r WHERE Redemption_Date_Cleared__c != NULL ORDER BY Redemption_Date_Cleared__c DESC LIMIT 1) FROM Funded_Receivable__c WHERE FV_Amount_Due__c = 0.00';

		return database.getQueryLocator(query);
  	}

  	global void execute(Database.BatchableContext context, List<Funded_Receivable__c> listFunRec){

		List<Funded_Receivable__c> listReceivableToUpdate = new list<Funded_Receivable__c>();
		
		for(Funded_Receivable__c funRec : listFunRec){
			if(funRec.Allocations__r.size() > 0){
				listReceivableToUpdate.add(new Funded_Receivable__c(
											Id = funRec.Id,
											Final_Payment_Date__c = funRec.Allocations__r[0].Redemption_Date_Cleared__c
											));
			}
		}

		if(!listReceivableToUpdate.isEmpty()){
			update listReceivableToUpdate;
		}
  	}

  	global void finish(Database.BatchableContext context){

  	}

	/*** SCHEDULEABLE INTERFACE Methods ***/
  	global void execute(SchedulableContext sc) {
	    id batchId = Database.executeBatch(new UpdateExistingReceivables_Batch(), 200);
	    System.debug('\n\n==> batchId = ' + batchId);
  	}


}