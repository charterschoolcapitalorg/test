/**=====================================================================
* Appirio, Inc
* Trigger Name: FundedReceivable
* Description: T-278335 : Create means to calculate new / existing client,
                          Create commission records and calculate commissions for the user on the updated receivables
* Created Date: [05/13/2014]
* Created By: [Rajeev Arya] (Appirio)
* Date Modified                Modified By                  Description of the update
* 06/27/2014					Rajeev Arya 			    I-119257 Update PurchaseUID field when is blank for new Funded Receivable
* 05/06/2015                    John Caughie                Added Appirio Custom Setting for conditional control
*======================================================================*/
trigger FundedReceivable on Funded_Receivable__c (before insert, after insert, after update) {

  BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
  if(ProfileCustomSettings.Trigger_Objects__c == null){
      ProfileCustomSettings.Trigger_Objects__c = '';
  }
  if(ProfileCustomSettings.Triggers_Disabled__c == null){
      ProfileCustomSettings.Triggers_Disabled__c = false;
  }
  if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('funded_receivable__c') && ProfileCustomSettings.Triggers_Disabled__c)){
        if(Trigger.isAfter){
            if(Trigger.isInsert || Trigger.isUpdate){
                FundedReceivableManager.AccountUpdateAfter(Trigger.new);
                FundedReceivableManager.CommissionCaculation(Trigger.New, Trigger.oldMap, trigger.isInsert);
            }
        }
        if(Trigger.isBefore){
            if(Trigger.isInsert){
                FundedReceivableManager.UpdateFundedReceivablePurchaseUID(Trigger.New);
            }
        }

    }
}