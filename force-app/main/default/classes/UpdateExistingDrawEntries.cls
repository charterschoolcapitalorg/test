/**=====================================================================
 * Appirio, Inc
 * Name: UpdateExistingDrawEntries
 * Description: Update Null values with 0 in existing Draw Entry Records
 * Created Date: [07/18/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
global class UpdateExistingDrawEntries implements Database.Batchable<SObject>{

	/*** BATCHABLE INTERFACE Methods ***/
  	global Database.QueryLocator start(Database.BatchableContext context) {
		String query = 'Select Interest_Fwd__c From Draw_Entry__c';

		return database.getQueryLocator(query);
  	}

  	global void execute(Database.BatchableContext context, List<Draw_Entry__c> listDrawEntries){
  		for(Draw_Entry__c drawEntry : listDrawEntries){
  			if(drawEntry.Interest_Fwd__c == null){
  				drawEntry.Interest_Fwd__c = 0.0;
  			}
  		}

  		update listDrawEntries;
  	}

  	global void finish(Database.BatchableContext context){

  	}
}