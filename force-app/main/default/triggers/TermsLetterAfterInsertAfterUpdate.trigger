trigger TermsLetterAfterInsertAfterUpdate on Terms_Letter__c (after insert, after update) {
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance(UserInfo.getUserId());
    // 05/06/2014 : Manisha Gupta : Add null check (T-276525)
    if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('terms_letter__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        Map<Id, Terms_Letter__c> sourceToTlMap = new Map<Id, Terms_Letter__c>();

        for(Terms_Letter__c tl : trigger.new) {
            String prevStatus = '';

            if(trigger.isUpdate) {
                Terms_Letter__c old = trigger.oldMap.get(tl.Id);
                prevStatus = old.Status__c;
            }

            if(tl.Status__c != null && tl.Source__c != null && tl.Status__c.equalsIgnoreCase('Active') && tl.Status__c != prevStatus) {
                sourceToTlMap.put(tl.Source__c, tl);
            }
        }

        if(!sourceToTlMap.isEmpty()) {
            List<Opportunity> opps = [SELECT Id, Terms_Letter__c FROM Opportunity WHERE Terms_Letter__c IN :sourceToTlMap.keySet()];

            if(!opps.isEmpty()) {
                for(Opportunity opp : opps) {
                    Terms_Letter__c newActive = sourceToTlMap.get(opp.Terms_Letter__c);
                    opp.Terms_Letter__c = newActive.Id;
                }

                update opps;
            }
        }

        //2015.06.17 J Caughie - Process to update Program Fee dates with relevant Terms Letter Dates
        if(Trigger.isAfter && Trigger.isUpdate){
                TermsLetterAfterInsertAfterUpdateManager.updateChildProgramFeeDates(trigger.newMap, trigger.oldMap);         
        }
    }
}