trigger OppSchoolBeforeUpdate on Opp_School__c (before update) {
	Set<Id> schoolIds = new Set<Id>();
	List<Opp_School__c> updateCharterTerms = new List<Opp_School__c>();
	
	for(Opp_School__c oppSchool : trigger.new) {
		Opp_School__c old = trigger.oldMap.get(oppSchool.Id);
		oppSchool.Authorizer__c = oppSchool.Authorizer_Id__c;
		oppSchool.COE__c = oppSchool.COE_Id__c;
		oppSchool.School_District__c = oppSchool.School_District_Id__c;
		
		if(!Flags.AllowLegalNoticeContactChange) {
			oppSchool.Legal_Notice_Contact__c = old.Legal_Notice_Contact__c;
		}
		
		if(!oppSchool.Manual_Charter_Terms__c) {
			updateCharterTerms.add(oppSchool);
			schoolIds.add(oppSchool.School__c);
		}
	}
	
	if(!schoolIds.isEmpty()) {
		Map<Id, Account> schoolMap = new Map<Id, Account>([SELECT Id, (SELECT Charter_Term__c FROM Terms__r ORDER BY Start_Date__c) FROM Account WHERE Id IN :schoolIds]);
		
		for(Opp_School__c oppSchool : updateCharterTerms) {
			Account school = schoolMap.get(oppSchool.School__c);
			List<String> terms = new List<String>();
			
			if(school.Terms__r != null && !school.Terms__r.isEmpty()) {
				for(Charter_Term__c term : school.Terms__r) {
					terms.add(term.Charter_Term__c);
				}
			}
			
			if(!oppSchool.Manual_Charter_Terms__c) {
				oppSchool.Charter_Terms__c = String.join(terms, ' and ');
			}
		}
	}
}