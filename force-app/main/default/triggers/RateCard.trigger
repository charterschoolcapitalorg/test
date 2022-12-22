/**=====================================================================
 * Appirio, Inc
 * Name: RateCard Trigger
 * Description: T-283215 : Invoke same logic from T-273952 when a rate card is inserted with active__c flag set to true (trigger)
 * Created Date: [06/02/2014]
 * Created By: [Manisha] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
trigger RateCard on Rate_Card__c (after insert) {

	BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
	if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.contains('Rate_Card__c') && ProfileCustomSettings.Triggers_Disabled__c)){
	    if(trigger.isAfter && trigger.isInsert){
			RateCardManager.rateCardAfterInsert(trigger.new);
		}
	}

}