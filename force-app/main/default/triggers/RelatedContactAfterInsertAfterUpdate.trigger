trigger RelatedContactAfterInsertAfterUpdate on Related_Contact__c (after insert, after update) {
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
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('related_contact__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        Set<Id> acctIds = new Set<Id>();
        Map<Id, Id> legalNoticeIdMap = new Map<Id, Id>();

        for(Related_Contact__c rc : trigger.new) {
            Related_Contact__c old = trigger.isUpdate ? trigger.oldMap.get(rc.Id) : rc;

            if((trigger.isInsert && (rc.Legal_Notice__c || rc.Funding_Docs__c)) || rc.Legal_Notice__c != old.Legal_Notice__c || rc.Funding_Docs__c != old.Funding_Docs__c || rc.Account__c != old.Account__c) {
                acctIds.add(rc.Account__c);
                acctIds.add(old.Account__c);

                if(rc.Legal_Notice__c) {
                    legalNoticeIdMap.put(rc.Account__c, rc.Contact__c);
                }
            }
        }

        if(!acctIds.isEmpty()) {
            List<Opp_School__c> oppSchools = [SELECT Id, School__c, Legal_Notice_Contact__c FROM Opp_School__c WHERE School__c IN :acctIds];
            List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId IN :acctIds AND IsClosed = false];

            if(!oppSchools.isEmpty()) {
                for(Opp_School__c oppSchool : oppSchools) {
                    oppSchool.Legal_Notice_Contact__c = legalNoticeIdMap.get(oppSchool.School__c);
                }

                try {
                    Flags.SyncingOppSchoolData = true;
                    Flags.AllowLegalNoticeContactChange = true;
                    update oppSchools;
                } finally {
                    Flags.SyncingOppSchoolData = false;
                    Flags.AllowLegalNoticeContactChange = false;
                }
            }

            if(!opps.isEmpty()) {
                update opps;
            }
        }
    }
}