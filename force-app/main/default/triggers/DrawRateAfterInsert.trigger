/**=====================================================================
 * Appirio, Inc
 * Trigger Name: DrawRateAfterInsert
 * Description: T-275242 : Trigger to fill the note rate field on the Draw Note record with the lastest Draw Rate entry
 * Created Date: [05/02/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 *
 =====================================================================*/
trigger DrawRateAfterInsert on Draw_Rate__c (after insert) {

    DrawRateManager.DrawRateAfterInsert(Trigger.new);
}