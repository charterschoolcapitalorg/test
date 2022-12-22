trigger AccountAfterInsert on Account (after insert) {
    
    //molinger - 7/31/19 - for Facilities project, need to update the Opportunity lookup to Property when  Property object is created
	//    from the Lightning UI
	if (trigger.isinsert && trigger.isafter) {
		Set<Id> oppIds = new Set<Id>();
		Map<Id,Id> propOppMap = new Map<Id,Id>();
		
		for(Account acct : trigger.new) {
			
			System.debug('Opportunity_That_Created_the_Property__c: ' + acct.Opportunity_That_Created_the_Property__c);
			System.debug('Prop Id: ' + acct.Id);
			if (acct.Opportunity_That_Created_the_Property__c !=null) {
				oppids.add(Id.valueOf(acct.Opportunity_That_Created_the_Property__c));
				propOppMap.put(acct.Opportunity_That_Created_the_Property__c,acct.Id);
			}
		}
		List<Opportunity> oppsForUpdate = [Select Id, Property__c from Opportunity where ID IN:oppIds and Property__c=null];
		for (Opportunity o : oppsForUpdate) {
			if (propOppMap.get(o.Id)!=null) o.Property__c=propOppMap.get(o.Id);
		}	
		update oppsForUpdate;
	}
}