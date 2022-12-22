/**=====================================================================
 * Appirio, Inc
 * Name: DrawEntryTriggerManager
 * Description: I-119205 : Trigger on Draw Entry to hold Interest forward in DrawNote.Interest_Due__c field from most recent Draw Entry
 * Created Date: [06/27/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
trigger DrawEntryTrigger on Draw_Entry__c (after insert) {
	DrawEntryTriggerManager.DrawEntryAfterInsert(Trigger.new);
}