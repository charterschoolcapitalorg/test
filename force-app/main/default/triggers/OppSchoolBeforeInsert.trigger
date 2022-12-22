trigger OppSchoolBeforeInsert on Opp_School__c (before insert) {
	Set<Id> acctIds = new Set<Id>();
	
	for(Opp_School__c oppSchool : trigger.new) {
		acctIds.add(oppSchool.School__c);
	}
	
	Map<Id, Id> legalNoticeContMap = new Map<Id, Id>();

	for(Related_Contact__c rc : [SELECT Id, Account__c, Contact__c FROM Related_Contact__c WHERE Account__c IN :acctIds AND Legal_Notice__c = true]) {
		legalNoticeContMap.put(rc.Account__c, rc.Contact__c);
	}
	
	for(Opp_School__c oppSchool : trigger.new) {
		oppSchool.Legal_Notice_Contact__c = legalNoticeContMap.get(oppSchool.School__c);
	}
}