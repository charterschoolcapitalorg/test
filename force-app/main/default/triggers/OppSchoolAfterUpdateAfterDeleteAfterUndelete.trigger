trigger OppSchoolAfterUpdateAfterDeleteAfterUndelete on Opp_School__c (after update, after delete, after undelete) {
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
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('opp_school__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        if(Flags.SyncingOppSchoolData) {
            return;
        }

        // The Insert case is handled by after insert workflow causing an update when it sets the unique key
        Set<Id> oppIds = new Set<Id>();

        if(trigger.isUpdate) {
            for(Opp_School__c oppSchool : trigger.new) {
                Opp_School__c old = trigger.oldMap.get(oppSchool.Id);
                Boolean authChanged = oppSchool.Authorizer__c != old.Authorizer__c;
                Boolean coeChanged = oppSchool.COE__c != old.COE__c;
                Boolean districtChanged = oppSchool.School_District__c != old.School_District__c;
                Boolean charterTermsChanged = oppSchool.Charter_Terms__c != old.Charter_Terms__c || (!oppSchool.Manual_Charter_Terms__c && old.Manual_Charter_Terms__c);

                if(authChanged || coeChanged || districtChanged || charterTermsChanged) {
                    oppIds.add(oppSchool.Opportunity__c);
                }
            }
        } else {
            for(Opp_School__c oppSchool : (trigger.isDelete ? trigger.old : trigger.new)) {
                oppIds.add(oppSchool.Opportunity__c);
            }
        }

        if(!oppIds.isEmpty()) {
            try {
                List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id IN :oppIds];
                Flags.ForceOpportunitySchoolsUpdate = true;
                update opps;
            } finally {
                Flags.ForceOpportunitySchoolsUpdate = true;
            }
        }
    }
}