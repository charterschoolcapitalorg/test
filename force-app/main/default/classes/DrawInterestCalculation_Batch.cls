/**=====================================================================
 * Appirio, Inc
 * Name: DrawInterestCalculation_Batch
 * Description: T-275864: Create Investor - Interest calcs
 * Created Date: [04/08/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [07/02/2014]                 [Rajeev Arya]              [T-291633 - Modify Draw Entry Interest calc for rate change]
 * [07/03/2014]                 [Rajeev Arya]              [T-288639 - Create custom VF Page for interest calc]

 =====================================================================*/
global class DrawInterestCalculation_Batch implements Database.Batchable<SObject>, Schedulable{

	global Date userDate;
	global DrawInterestCalculation_Batch(Date selectedDate){
		userDate = selectedDate;
	}

	/*** BATCHABLE INTERFACE Methods ***/
  	global Database.QueryLocator start(Database.BatchableContext context) {
		String query = 'Select d.Total_Amount_Borrowed__c, d.Status__c, d.Prior_Activity_Date__c, '+
						' d.Principal_Paid__c, d.OwnerId, d.Operating_State__c, d.Note_Rate__c, d.Note_Description__c, d.Name, d.LegacyParentID__c, '+
						' d.LegacyID__c, d.Last_Pay_Date__c, d.LastActivityDate, d.Investor__c, Total_Amount_Borrowed_formula__c, '+
						' d.Interest_Paid__c, d.Id, d.Edit_Draw_Receivables__c, d.DrawHeaderID__c, d.Borrow_Date__c '+
						'From Draw_Note__c d where Principal_Due__c > 0 AND Status__c = \'Active\'';
		//Principal_Due__c > 0 AND Status__c = \'Active\''
		//id = \'a0jS0000001GT2C\''
		return database.getQueryLocator(query);
  	}

  	global void execute(Database.BatchableContext context, List<Draw_Note__c> listDrawNotes){

		map<Id,Draw_Entry__c> mapDrawNoteIdDrawEntry = new map<Id, Draw_Entry__c>();
		for(Draw_Entry__c drawEntry : [Select d.SystemModstamp, d.Principal__c, d.Principal_Paid__c, d.Payment_Amount__c, d.Name,
											d.Interest_Paid__c, d.Interest_Fwd__c, d.Id, d.Ending_Principal__c, d.Draw_Rate__c, d.Draw_Note__c,
											d.Activity_Type__c, d.Activity_Date__c, d.Accrued_Interest__c
										From Draw_Entry__c d where Draw_Note__c in : listDrawNotes order by Activity_Date__c desc, Id desc]){
			if(!mapDrawNoteIdDrawEntry.containsKey(drawEntry.Draw_Note__c)){
				mapDrawNoteIdDrawEntry.put(drawEntry.Draw_Note__c, drawEntry);
			}
		}

		List<Draw_Entry__c> listDrawEntryToInsert = new list<Draw_Entry__c>();
		Draw_Entry__c drawEntry;
		for(Draw_Note__c drawNote : listDrawNotes){
			if(drawNote.Note_Rate__c <> null){
				drawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, mapDrawNoteIdDrawEntry.get(drawNote.Id), null, userDate);
				if(drawEntry <> null){
					drawEntry.Activity_Type__c = 'Monthly Interest';
					listDrawEntryToInsert.add(drawEntry);
				}
			}
		}

		if(!listDrawEntryToInsert.isEmpty()){
			try{
				insert listDrawEntryToInsert;
			}catch(exception ex){
				system.debug('Error while inserting draw entries ' + ex.getMessage());
			}
		}
  	}



  	global void finish(Database.BatchableContext context){

  	}

	/*** SCHEDULEABLE INTERFACE Methods ***/
  	global void execute(SchedulableContext sc) {
	    id batchId = Database.executeBatch(new DrawInterestCalculation_Batch(userDate), 200);
	    System.debug('\n\n==> batchId = ' + batchId);
  	}


}