/**=====================================================================
 * Date Modified                Modified By                  Description of the update
 * [08/02/2016]                [John Caughie]                [Disabled update of Action Items when paralegal is changed]
 * Test Class: AccountTests
  =====================================================================*/

trigger AccountAfterUpdate on Account (after update, before update) {
    
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    if(ProfileCustomSettings.Trigger_Objects__c == null){
        ProfileCustomSettings.Trigger_Objects__c = '';
    }
    if(ProfileCustomSettings.Triggers_Disabled__c == null){
        ProfileCustomSettings.Triggers_Disabled__c = false;
    }
    if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('account') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        Set<Id> updateOppSchoolIds = new Set<Id>();
        Set<Id> updateSchoolIds = new Set<Id>();
        Set<Id> oldParalegalIds = new Set<Id>();

        for(Account acct : trigger.new) {
            
            Account old = trigger.oldMap.get(acct.Id);
            Boolean nameChanged = acct.Name != old.Name;
            Boolean legalNameChanged = acct.Legal_Name__c != old.Legal_Name__c;
            Boolean authorizerChanged = acct.Authorizer_A__c != old.Authorizer_A__c;
            Boolean coeChanged = acct.COE__c != old.COE__c;
            Boolean districtChanged = acct.School_District__c != old.School_District__c;
            Boolean countyChanged = acct.County__c != old.County__c;
            Boolean addressChanged = acct.BillingStreet != old.BillingStreet || acct.BillingCity != old.BillingCity || acct.BillingState != old.BillingState || acct.BillingPostalCode != old.BillingPostalCode || acct.BillingCountry != old.BillingCountry;
            Boolean schoolChanged = RecordTypeUtils.isSchool(acct) && acct.Num_of_Opp_Schools__c > 0 && (legalNameChanged || authorizerChanged || coeChanged || districtChanged || countyChanged || addressChanged);
            Boolean businessChanged = RecordTypeUtils.isBusiness(acct) && (nameChanged);

            if(schoolChanged || businessChanged) {
                updateOppSchoolIds.add(acct.Id);
            }

            if(RecordTypeUtils.isCharterHolder(acct)) {
                Boolean para1Changed = acct.Paralegal_1__c != null && acct.Paralegal_1__c != old.Paralegal_1__c;
                Boolean para2Changed = acct.Paralegal_2__c != null && acct.Paralegal_2__c != old.Paralegal_2__c;
                Boolean financialRevChanged = acct.Financial_Review__c != null && acct.Financial_Review__c != old.Financial_Review__c;
                Boolean acctMgrChanged = acct.Account_Manager__c != null && acct.Account_Manager__c != old.Account_Manager__c;
                Boolean assManChanged = acct.Asset_Manager__c != null && acct.Asset_Manager__c != old.Asset_Manager__c;

                if(acct.OwnerId != old.OwnerId) {
                    updateSchoolIds.add(acct.Id);
                }

                if(para1Changed || para2Changed || financialRevChanged || acctMgrChanged || assManChanged) {
                    updateSchoolIds.add(acct.Id);
                }

                if(para1Changed) {
                    oldParalegalIds.add(old.Paralegal_1__c);
                }
            }
        }

        updateOppSchoolIds.remove(null);

        if(!updateOppSchoolIds.isEmpty()) {
            Set<Id> oppIds = new Set<Id>();
            List<Opp_School__c> oppSchools = [SELECT Id, Opportunity__c FROM Opp_School__c WHERE School__c IN :updateOppSchoolIds OR Authorizer__c IN :updateOppSchoolIds OR COE__c IN :updateOppSchoolIds OR School_District__c IN :updateOppSchoolIds];

            if(!oppSchools.isEmpty()) {
                for(Opp_School__c oppSchool : oppSchools) {
                    oppIds.add(oppSchool.Opportunity__c);
                }

                try {
                    Flags.SyncingOppSchoolData = true;
                    update oppSchools;
                } finally {
                    Flags.SyncingOppSchoolData = false;
                }
            }

            try {
                List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id IN :oppIds AND IsClosed = false];
                Flags.ForceOpportunitySchoolsUpdate = true;
                update opps;
            } finally {
                Flags.ForceOpportunitySchoolsUpdate = false;
            }
        }

        if(!updateSchoolIds.isEmpty()) {
            Map<Id, Account> schoolsMap = new Map<Id, Account>([SELECT Id, Charter_Holder__c, OwnerId, Paralegal_1__c, Paralegal_2__c, Financial_Review__c, Account_Manager__c, Asset_Manager__c FROM Account WHERE Charter_Holder__c IN :updateSchoolIds]);
            Set<String> excludeStatuses = new Set<String> { 'Completed', 'Cancelled', 'N/A' };
            Set<Id> itemAccountIds = new Set<Id>();
            itemAccountIds.addAll(updateSchoolIds);
            itemAccountIds.addAll(schoolsMap.keySet());

            if(!schoolsMap.isEmpty()) {
                for(Account school : schoolsMap.values()) {
                    Account charterHolder = trigger.newMap.get(school.Charter_Holder__c);
                    school.OwnerId = charterHolder.OwnerId;
                    school.Paralegal_1__c = charterHolder.Paralegal_1__c;
                    school.Paralegal_2__c = charterHolder.Paralegal_2__c;
                    school.Financial_Review__c = charterHolder.Financial_Review__c;
                    school.Account_Manager__c = charterHolder.Account_Manager__c;
                    school.Asset_Manager__c = charterHolder.Asset_Manager__c;
                }

                try {
                    Flags.SyncingAccountContacts = true;
                    update schoolsMap.values();
                } finally {
                    Flags.SyncingAccountContacts = false;
                }

                List<Charter_Term__c> charterTerms = [SELECT Id, School__c, Paralegal_1__c, Paralegal_2__c, Financial_Review__c, Account_Manager__c FROM Charter_Term__c WHERE School__c IN :schoolsMap.keySet() AND Status__c = 'Active'];

                if(!charterTerms.isEmpty()) {
                    for(Charter_Term__c charterTerm : charterTerms) {
                        Account school = schoolsMap.get(charterTerm.School__c);
                        Account charterHolder = trigger.newMap.get(school.Charter_Holder__c);
                        charterTerm.Paralegal_1__c = charterHolder.Paralegal_1__c;
                        charterTerm.Paralegal_2__c = charterHolder.Paralegal_2__c;
                        charterTerm.Financial_Review__c = charterHolder.Financial_Review__c;
                        charterTerm.Account_Manager__c = charterHolder.Account_Manager__c;
                    }

                    try {
                        Flags.SyncingAccountContacts = true;
                        update charterTerms;
                    } finally {
                        Flags.SyncingAccountContacts = false;
                    }
                }
            }
        }
    }
}