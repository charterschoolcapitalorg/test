trigger ApplicantBeforeInsert on Applicant__c (before insert) {
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('applicant__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to condtiionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        List<Applicant__c> applicants = trigger.new;
        List<Lead> leads = new List<Lead>();

        for(Integer i = 0; i < applicants.size(); i++) {
            Applicant__c applicant = applicants.get(i);
            leads.add(new Lead(
                RecordTypeId = RecordTypeUtils.LeadApplicant.Id,
                LeadSource = 'Web',
                FirstName = applicant.First_Name__c,
                LastName = applicant.Last_Name__c,
                Title = applicant.Title__c,
                Company = applicant.Company__c,
                Email = applicant.Email__c,
                Phone = applicant.Phone__c,
                Role__c = applicant.Role__c,
                Num_Organizations__c = 0,
                Applicant_Step__c = applicant.Step__c
            ));
        }

        insert leads;

        for(Integer i = 0; i < applicants.size(); i++) {
            Applicant__c applicant = applicants.get(i);
            Lead l = leads.get(i);
            applicant.Lead__c = l.Id;
            applicant.Token__c = EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(l.Id)));
            l.Token__c = applicant.Token__c;
        }

        update leads;
    }
}