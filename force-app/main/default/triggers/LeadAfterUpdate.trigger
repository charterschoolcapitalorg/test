trigger LeadAfterUpdate on Lead (after update) {
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
	if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('lead') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        if(Flags.SyncingLeadWithApplicant) {
            return;
        }

        Map<Id, Lead> appLeadMap = new Map<Id, Lead>();

        for(Lead l : trigger.new) {
            if(RecordTypeUtils.isApplicant(l)) {
                appLeadMap.put(l.Id, l);
            }
        }

        if(!appLeadMap.isEmpty()) {
            List<Applicant__c> applicants = [SELECT Id, Lead__c FROM Applicant__c WHERE Lead__c IN :appLeadMap.keySet()];

            if(!applicants.isEmpty()) {
                for(Applicant__c applicant : applicants) {
                    Lead l = trigger.newMap.get(applicant.Lead__c);
                    applicant.First_Name__c = l.FirstName;
                    applicant.Last_Name__c = l.LastName;
                    applicant.Company__c = l.Company;
                    applicant.Title__c = l.Title;
                    applicant.Email__c = l.Email;
                    applicant.Phone__c = l.Phone;
                    applicant.Role__c = l.Role__c;
                }

                try {
                    Flags.SyncingApplicantWithLead = true;
                    update applicants;
                } finally {
                    Flags.SyncingApplicantWithLead = false;
                }
            }
        }
    }
}