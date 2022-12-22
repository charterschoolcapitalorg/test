trigger CharterTermAfterInsertAfterUpdateAfterDeleteAfterUndelete on Charter_Term__c (after insert, after update, after delete, after undelete) {
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    // 05/06/2014 : Manisha Gupta : Add null check (T-276525)
    if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('charter_term__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        Set<Id> schoolIds = new Set<Id>();

        if(trigger.isUpdate) {
            for(Charter_Term__c term : trigger.new) {
                Charter_Term__c old = trigger.oldMap.get(term.Id);

                if(term.School__c != old.School__c || term.Charter_Term__c != old.Charter_Term__c) {
                    schoolIds.add(term.School__c);
                    schoolIds.add(old.School__c);
                }
            }
        } else {
            List<Charter_Term__c> terms = trigger.isDelete ? trigger.old : trigger.new;

            for(Charter_Term__c term : terms) {
                schoolIds.add(term.School__c);
            }
        }

        schoolIds.remove(null);

        if(!schoolIds.isEmpty()) {
            Set<Id> oppIds = new Set<Id>();
            List<Opp_School__c> oppSchools = [SELECT Id, Opportunity__c FROM Opp_School__c WHERE School__c = :schoolIds AND Manual_Charter_Terms__c = false AND Opportunity__r.IsClosed = false];

            for(Opp_School__c oppSchool : oppSchools) {
                oppIds.add(oppSchool.Opportunity__c);
            }

            if(!oppSchools.isEmpty()) {
                try {
                    Flags.SyncingOppSchoolData = true;
                    update oppSchools;
                } finally {
                    Flags.SyncingOppSchoolData = false;
                }
            }

            if(!oppIds.isEmpty()) {
                List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id = :oppIds];

                try {
                    Flags.ForceOpportunitySchoolsUpdate = true;
                    update opps;
                } finally {
                    Flags.ForceOpportunitySchoolsUpdate = false;
                }
            }
        }
    }
}