trigger CharterTermBeforeInsert on Charter_Term__c (before insert) {
	Set<Id> schoolIds = new Set<Id>();

	for(Charter_Term__c charterTerm : trigger.new) {
		schoolIds.add(charterTerm.School__c);
	}

	schoolIds.remove(null);

	if(!schoolIds.isEmpty()) {
		Map<Id, Account> schoolMap = new Map<Id, Account>([SELECT Id, OwnerId, Paralegal_1__c, Paralegal_2__c, Financial_Review__c, Account_Manager__c FROM Account WHERE Id IN :schoolIds]);

		for(Charter_Term__c charterTerm : trigger.new) {
			Account school = schoolMap.get(charterTerm.School__c);
			charterTerm.Paralegal_1__c = school.Paralegal_1__c;
			charterTerm.Paralegal_2__c = school.Paralegal_2__c;
			charterTerm.Financial_Review__c = school.Financial_Review__c;
			charterTerm.Account_Manager__c = school.Account_Manager__c;
		}
	}
}