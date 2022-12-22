/**=====================================================================
 * Appirio, Inc
 * Name: CommissionFromRPARedemption trigger
 * Description: T-280412 : Trigger to create Commissin records for the RPA Redemption records
 * Created Date: [05/26/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                Description of the update
 * 06/02/2014					Rahul Agrawal			   Update Redemption records for populating Face_Amount_Applied_Fee__c
 * 06/13/2014					Rajeev Arya				   T-286219 - Revise trigger code
 =====================================================================*/
trigger CommissionFromRPARedemption on RPA_Redemption__c (after insert, after update, after delete) {
	
	/*BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    if(ProfileCustomSettings <> null
      && ProfileCustomSettings.Trigger_Objects__c <> null &&
      !(ProfileCustomSettings.Trigger_Objects__c.contains('RPA_Redemption__c') && ProfileCustomSettings.Triggers_Disabled__c)){*/
        if(Trigger.isAfter){
            if(Trigger.isInsert){
               	RPARedemptionManager.CreateCommissions(Trigger.new);
			}
            if(!Trigger.isDelete){
            	RPARedemptionManager.calculateRedemptionFaceAmount(Trigger.new);	
            }
            if(Trigger.isDelete){
            	RPARedemptionManager.calculateRedemptionFaceAmount(Trigger.old);	
            }
        }
    //}
}