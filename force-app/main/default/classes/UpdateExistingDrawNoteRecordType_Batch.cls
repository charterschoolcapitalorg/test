/**=====================================================================
 * Appirio, Inc
 * Name: UpdateExistingDrawNoteRecordType_Batch
 * Description: T-289598 - Create Draw Note Lock layouts : Batch Class to update record types/layouts of all non-Draft Draw Notes
 * Created Date: [06/30/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update

  =====================================================================*/
global class UpdateExistingDrawNoteRecordType_Batch implements Database.Batchable<SObject>, Schedulable{

	/*** BATCHABLE INTERFACE Methods ***/
  	global Database.QueryLocator start(Database.BatchableContext context) {
		String query = 'Select Id, RecordTypeId From Draw_Note__c where Status__c != \'Draft\' AND Status__c != \'New\'';

		return database.getQueryLocator(query);
  	}

  	global void execute(Database.BatchableContext context, List<Draw_Note__c> listDrawNote){
		List<RecordType> recordTypeList = [Select Id,Name,DeveloperName
                                           From RecordType
                                           Where sObjectType = 'Draw_Note__c'
                                           and DeveloperName = 'After_Activation'];
        system.debug('record type is '+recordTypeList[0]);
		List<Draw_Note__c> listDrawToUpdate = new list<Draw_Note__c>();
		if(!recordTypeList.isEmpty()){
			for(Draw_Note__c draw : listDrawNote){
				if(draw.RecordTypeId != recordTypeList[0].Id){
					draw.RecordTypeId = recordTypeList[0].Id;
					listDrawToUpdate.add(draw);
				}
			}
		}

		if(!listDrawToUpdate.isEmpty()){
			update listDrawToUpdate;
		}
  	}

  	global void finish(Database.BatchableContext context){

  	}

	/*** SCHEDULEABLE INTERFACE Methods ***/
  	global void execute(SchedulableContext sc) {
	    id batchId = Database.executeBatch(new UpdateExistingDrawNoteRecordType_Batch(), 200);
	    System.debug('\n\n==> batchId = ' + batchId);
  	}
}