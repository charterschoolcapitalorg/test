trigger AccountBeforeInsertBeforeUpdate on Account (before insert, before update) {
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
	if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('account') && ProfileCustomSettings.Triggers_Disabled__c)){
	    Set<Id> charterHolderIds = new Set<Id>();
	    List<Account> newSchools = new List<Account>();

	    for(Account acct : trigger.new) {
	    	
	        if(RecordTypeUtils.isSchool(acct)) {
	            acct.ParentId = acct.Charter_Holder__c;

	            if(trigger.isInsert && acct.Charter_Holder__c != null) {
	                charterHolderIds.add(acct.Charter_Holder__c);
	                newSchools.add(acct);
	            }

	            if(trigger.isUpdate && !Flags.SyncingAccountContacts) {
	                Account old = trigger.oldMap.get(acct.Id);
	                acct.OwnerId = old.OwnerId;
	                acct.Paralegal_1__c = old.Paralegal_1__c;
	                acct.Paralegal_2__c = old.Paralegal_2__c;
	                acct.Financial_Review__c = old.Financial_Review__c;
	                acct.Account_Manager__c = old.Account_Manager__c;
	                acct.Asset_Manager__c = old.Asset_Manager__c;
	            }
	        }

	        if(RecordTypeUtils.isCharterHolder(acct)) {
	            acct.ParentId = acct.CMO__c;
	        }
	    }

	    if(!charterHolderIds.isEmpty()) {
	        Map<Id, Account> charterHolderMap = new Map<Id, Account>([SELECT Id, OwnerId, Paralegal_1__c, Paralegal_2__c, Financial_Review__c, Account_Manager__c, Asset_Manager__c FROM Account WHERE Id IN :charterHolderIds]);

	        for(Account acct : newSchools) {
	            Account charterHolder = charterHolderMap.get(acct.Charter_Holder__c);
	            acct.OwnerId = charterHolder.OwnerId;
	            acct.Paralegal_1__c = charterHolder.Paralegal_1__c;
	            acct.Paralegal_2__c = charterHolder.Paralegal_2__c;
	            acct.Financial_Review__c = charterHolder.Financial_Review__c;
	            acct.Account_Manager__c = charterHolder.Account_Manager__c;
	            acct.Asset_Manager__c = charterHolder.Asset_Manager__c;
	        }
	    }
	}
}