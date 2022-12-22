/**=====================================================================
 * Appirio, Inc
 * Name: UpdateExistingRPA_Batch
 * Description: T-284603: Need a batch job to update the existing RPA records
 * Created Date: [06/03/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
global class UpdateExistingRPA_Batch implements Database.Batchable<SObject>, Schedulable{

	/*** BATCHABLE INTERFACE Methods ***/
  	global Database.QueryLocator start(Database.BatchableContext context) {
		String query = 'Select Id From RPA__c';

		return database.getQueryLocator(query);
  	}

  	global void execute(Database.BatchableContext context, List<RPA__c> listRPA){

		set<Id> setProcessedRPA = new set<Id>();
		List<RPA__c> listRPAToUpdate = new list<RPA__c>();
		for(Program_Fee__c fee : [Select Program_Fee__c, Start_Date__c, End_Date__c, Terms_Letter__r.RPA__c
									from Program_Fee__c
									where End_Date__c >= TODAY
									and Start_Date__c <= TODAY
									and Terms_Letter__r.RPA__c in : listRPA
									and Terms_Letter__r.Status__c = 'Active'
									order by End_Date__c desc]){
			if(!setProcessedRPA.contains(fee.Terms_Letter__r.RPA__c)){
				listRPAToUpdate.add(new RPA__c(
												Id = fee.Terms_Letter__r.RPA__c,
												Current_Program_Fee_Value__c = fee.Program_Fee__c,
												Current_Program_Fee_Months__c = fee.Start_Date__c.monthsBetween(fee.End_Date__c)));
				setProcessedRPA.add(fee.Terms_Letter__r.RPA__c);
			}
		}

		/*for(RAP__c rpa : listRPA){
			if(!setProcessedRPA.contains(rpa.Id)){
				listRPAToUpdate.add(new RPA__c(
												Id = fee.Terms_Letter__r.RPA__c,
												Current_Program_Fee_Value__c = null,
												Current_Program_Fee_Months__c = null));
			}
		}*/

		if(!listRPAToUpdate.isEmpty()){
			update listRPAToUpdate;
		}
  	}



  	global void finish(Database.BatchableContext context){

  	}

	/*** SCHEDULEABLE INTERFACE Methods ***/
  	global void execute(SchedulableContext sc) {
	    id batchId = Database.executeBatch(new UpdateExistingRPA_Batch(), 200);
	    System.debug('\n\n==> batchId = ' + batchId);
  	}


}