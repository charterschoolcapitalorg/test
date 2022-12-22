/**=====================================================================
 * Appirio, Inc
 * Trigger Name: TermsLetter
 * Description: I-116731(T-278354) : Trigger on terms letter for task 'Create RPA monthly report Fields'
 * Created Date: [05/23/2014]
 * Created By: Manisha Gupta (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 03/05/2015					John Caughie				Added Appirio Bypass Rules and Triggers functionality
 =====================================================================*/
trigger TermsLetter on Terms_Letter__c (after update) {

	BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
	if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('terms_letter__c') && ProfileCustomSettings.Triggers_Disabled__c)){
		if(trigger.isUpdate){
				TermsLetterManager.termsLetterAfterUpdate(trigger.New, trigger.oldMap);
			}
	}
}