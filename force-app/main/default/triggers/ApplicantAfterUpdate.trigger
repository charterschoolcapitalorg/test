trigger ApplicantAfterUpdate on Applicant__c (after update) {
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
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('applicant__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        if(Flags.SyncingApplicantWithLead) {
            return;
        }

        Set<Id> leadIds = new Set<Id>();

        for(Applicant__c applicant : trigger.new) {
            if(applicant.Application_Status__c < 2) {
                leadIds.add(applicant.Lead__c);
            }
        }

        leadIds.remove(null);

        if(!leadIds.isEmpty()) {
            Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, FirstName, LastName, Company, Title, Phone, Email, Role__c, Applicant_Step__c, Num_Organizations__c, Token__c FROM Lead WHERE Id IN :leadIds]);

            for(Applicant__c applicant : trigger.new) {
                if(applicant.Application_Status__c < 2 && leadMap.containsKey(applicant.Lead__c)) {
                    Lead l = leadMap.get(applicant.Lead__c);
                    l.FirstName = applicant.First_Name__c;
                    l.LastName = applicant.Last_Name__c;
                    l.Company = applicant.Company__c;
                    l.Title = applicant.Title__c;
                    l.Email = applicant.Email__c;
                    l.Phone = applicant.Phone__c;
                    l.Role__c = applicant.Role__c;
                    l.Applicant_Step__c = applicant.Step__c;
                    l.Num_Organizations__c = applicant.Num_Organizations__c;
                    l.Token__c = applicant.Token__c;
                }
            }

            try {
                Flags.SyncingLeadWithApplicant = true;
                update leadMap.values();
            } finally {
                Flags.SyncingLeadWithApplicant = false;
            }
        }
    }
}