trigger RPAAfterInsertAfterUpdate on RPA__c (after insert, after update) {
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
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('rpa__c') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        if(Flags.UpdatingRPAHistoricValues) {
            return;
        }

        Map<Id, RPA__c> sourceToRpaMap = new Map<Id, RPA__c>();
        Set<Id> terminatedIds = new Set<Id>();

        for(RPA__c rpa : trigger.new) {
            String prevStatus = '';

            if(trigger.isUpdate) {
                RPA__c old = trigger.oldMap.get(rpa.Id);
                prevStatus = old.Status__c;
            }

            if(String.isNotBlank(rpa.Status__c) && rpa.Status__c != prevStatus) {
                if(String.isNotBlank(rpa.Source__c) && rpa.Status__c.equalsIgnoreCase('Active')) {
                    sourceToRpaMap.put(rpa.Source__c, rpa);
                } else if(rpa.Status__c.equalsIgnoreCase('Terminated')) {
                    terminatedIds.add(rpa.Id);
                }
            }
        }

        List<Terms_Letter__c> tls = new List<Terms_Letter__c>();
        Set<Id> tlRpaIds = new Set<Id>();
        tlRpaIds.addAll(sourceToRpaMap.keySet());
        tlRpaIds.addAll(terminatedIds);

        if(!sourceToRpaMap.isEmpty()) {
            List<RPA__c> sourceRPAs = [SELECT Id, RPA_Gross_Value__c, RPA_Face_Value__c, RPA_GRV_Historic__c, RPA_FV_Historic__c FROM RPA__c WHERE Id IN :sourceToRpaMap.keySet()];

            for(RPA__c source : sourceRPAs) {
                source.RPA_GRV_Historic__c = source.RPA_Gross_Value__c;
                source.RPA_FV_Historic__c = source.RPA_Face_Value__c;
            }

            try {
                Flags.UpdatingRPAHistoricValues = true;
                update sourceRPAs;
            } finally {
                Flags.UpdatingRPAHistoricValues = false;
            }
        }

        if(!tlRpaIds.isEmpty()) {
            tls = [SELECT Id, RPA__c FROM Terms_Letter__c WHERE RPA__c IN :tlRpaIds AND Status__c = 'Active'];

            if(!tls.isEmpty()) {
                for(Terms_Letter__c tl : tls) {
                    if(sourceToRpaMap.containsKey(tl.RPA__c)) {
                        RPA__c newActive = sourceToRpaMap.get(tl.RPA__c);
                        tl.RPA__c = newActive.Id;
                    }

                    if(terminatedIds.contains(tl.RPA__c)) {
                        tl.Status__c = 'Terminated';
                    }
                }

                update tls;
            }
        }

        //Assign existing oppty records to new RPA
        if(!sourceToRpaMap.isEmpty()) {
            List<Opportunity> opps = [SELECT Id, RPA__c FROM Opportunity WHERE RPA__c IN :sourceToRpaMap.keySet()];

            if(!opps.isEmpty()) {
                for(Opportunity opp : opps) {
                    RPA__c newActive = sourceToRpaMap.get(opp.RPA__c);
                    opp.RPA__c = newActive.Id;
                }

                update opps;
            }
        }

        //Assign existing funded receivable records to new RPA
        if(!sourceToRpaMap.isEmpty()) {
            List<Funded_Receivable__c> recs = [SELECT Id, RPA__c FROM Funded_Receivable__c WHERE RPA__c IN :sourceToRpaMap.keySet()];

            if(!recs.isEmpty()) {
                for(Funded_Receivable__c rec : recs) {
                    RPA__c newActive = sourceToRpaMap.get(rec.RPA__c);
                    rec.RPA__c = newActive.Id;
                }

                update recs;
            }
        }

        //Assign existing program fee allocation records to new RPA
        if(!sourceToRpaMap.isEmpty()) {
            List<RPA_Redemption__c> progfees = [SELECT Id, RPA__c FROM RPA_Redemption__c WHERE RPA__c IN :sourceToRpaMap.keySet()];

            if(!progfees.isEmpty()) {
                for(RPA_Redemption__c progfee : progfees) {
                    RPA__c newActive = sourceToRpaMap.get(progfee.RPA__c);
                    progfee.RPA__c = newActive.Id;
                }

                update progfees;
            }
        }
    }
}