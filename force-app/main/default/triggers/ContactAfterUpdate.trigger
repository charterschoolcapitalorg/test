trigger ContactAfterUpdate on Contact (after update) {
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
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('contact') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
            Set<Id> contIds = new Set<Id>();

            for(Contact cont : trigger.new) {
                Contact old = trigger.oldMap.get(cont.Id);

                if(cont.Name != old.Name || cont.Formal_Name__c != old.Formal_Name__c || cont.Phone != old.Phone || cont.Fax != old.Fax || cont.Email != old.Email) {
                    contIds.add(cont.Id);
                }
            }

            if(!contIds.isEmpty()) {
                List<Opp_School__c> oppSchools = [SELECT Id FROM Opp_School__c WHERE Legal_Notice_Contact__c IN :contIds];
                List<Related_Contact__c> rcs = [SELECT Id, Account__c, Contact__c FROM Related_Contact__c WHERE Contact__c IN :contIds AND Funding_Docs__c = true];

                if(!oppSchools.isEmpty()) {
                    try {
                        Flags.SyncingOppSchoolData = true;
                        update oppSchools;
                    } finally {
                        Flags.SyncingOppSchoolData = false;
                    }
                }

                if(!rcs.IsEmpty()) {
                    Set<Id> acctIds = new Set<Id>();

                    for(Related_Contact__c rc : rcs) {
                        acctIds.add(trigger.newMap.get(rc.Contact__c).AccountId);
                    }

                    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId IN :acctIds];

                    if(!opps.isEmpty()) {
                        update opps;
                    }
                }
            }
    }
}