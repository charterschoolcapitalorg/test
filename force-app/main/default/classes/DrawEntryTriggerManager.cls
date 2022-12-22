/**=====================================================================
 * Appirio, Inc
 * Name: DrawEntryTriggerManager
 * Description: I-119205 : Trigger Manager Class to hold Interest forward in Interest_Due__c field from most recent Draw Entry
 * Created Date: [06/27/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 * [06/07/2014]					John Caughie				 Changed the drn draw entries to sort by date, entry # desc rather than by id
 * [02/12/2018]					John Caughie				 Exclude Credit Line from draw entry interest due update 
 =====================================================================*/
public class DrawEntryTriggerManager {

	public static void DrawEntryAfterInsert(List<Draw_Entry__c> lstDR){
		set<ID> drawNoteIDs = new set<ID>();
		list<Draw_Note__c> lstDrawNote = new list<Draw_Note__c>();
		
		for(Draw_Entry__c drwEntry : lstDR){
			drawNoteIDs.add(drwEntry.Draw_Note__c);
		}
		
		for(Draw_Note__c drn : [select id, (select id, Interest_Fwd__c from draw_entries__r order by Activity_Date__c desc, Name desc limit 1) 
								from draw_note__c where id in:drawNoteIDs]){// AND RecordType.DeveloperName <> 'Credit_Line']){
			drn.Interest_Due__c = drn.draw_entries__r[0].Interest_Fwd__c;
            lstDrawNote.add(drn);
		}
		update lstDrawNote;
	}
}