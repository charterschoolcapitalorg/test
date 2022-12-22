trigger CharterTermBeforeUpdate on Charter_Term__c (before update) {
	if(!Flags.SyncingAccountContacts) {
		for(Charter_Term__c charterTerm : trigger.new) {
			Charter_Term__c old = trigger.oldMap.get(charterTerm.Id);
			charterTerm.Paralegal_1__c = old.Paralegal_1__c;
			charterTerm.Paralegal_2__c = old.Paralegal_2__c;
			charterTerm.Financial_Review__c = old.Financial_Review__c;
			charterTerm.Calculator__c = old.Calculator__c;
			charterTerm.Account_Manager__c = old.Account_Manager__c;
		}
	}
}