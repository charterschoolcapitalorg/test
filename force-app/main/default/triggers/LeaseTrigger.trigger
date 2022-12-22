trigger LeaseTrigger on Lease__c (after insert, after update) {
    
    
    if (trigger.isafter && (trigger.isupdate ||trigger.isinsert)) {
    	
    	//create lease school object when Lease is linked to a School Account
    	Set<Id> leaseIds = new Set<Id>();
    	Set<Id> acctIds = new Set<Id>();
    	Map<Id,Id> leaseAcctMap = new Map<Id,Id>();
    	List<Lease_School__c> forInsert = new List<Lease_School__c>();
    	for (Lease__c l : trigger.new) {
    		leaseids.add(l.Id);
    	}
    	Map<Id, Lease__c> leasesExpanded = new Map<Id,Lease__c>([Select Id, Tenant__r.Tenant__c from Lease__c where ID IN: leaseIds]);
    	System.debug('****leasesExpanded: ' + leasesExpanded);
    	
    	for (Lease__c l : trigger.new) {
    		//System.debug('trigger.oldMap: ' + trigger.oldMap);
    		//System.debug('trigger.oldMap.get(l.Id): ' + trigger.oldMap.get(l.Id));
    		if ((trigger.isinsert && l.Tenant__c!=null && leasesExpanded.get(l.Id).Tenant__r.Tenant__c!=null) || 
    			(trigger.isupdate && l.Tenant__c!=null && leasesExpanded.get(l.Id).Tenant__r.Tenant__c!=null 
    				&& trigger.oldMap.get(l.Id).Tenant__c ==null )) {
    			
    			acctIds.add(leasesExpanded.get(l.Id).Tenant__r.Tenant__c);
    			leaseAcctMap.put(leasesExpanded.get(l.Id).Tenant__r.Tenant__c, l.Id);
    		}
    	}
    	System.debug('****acctIDs: ' + acctIDs);
    	
    	List<Account> accts = [Select Id, Name, recordtypeid, (Select Id from Accounts4__r) from Account where Id IN:acctIDs];
    	for (account a : accts) {
    		System.debug('****acct: ' + a + ' Accounts4__r: ' + a.Accounts4__r);
    		//create if Account is a Charter Holder acct with only 1 School account
    		if (a.Accounts4__r!=null&&a.Accounts4__r.size()==1) {
	    		if (a.recordtypeid==RecordTypes.IDCharterAccount) {
	    			forinsert.add(new Lease_School__c(Account_School__c=a.Accounts4__r[0].Id, lease__c=leaseAcctMap.get(a.Id)));
	    		}
    		}
    	}
    	
    	if (forinsert.size()>0) insert forinsert;
    }
    
    if (trigger.isafter && trigger.isupdate) {
    	//if Lease_Facilities_Contact__c or Lease_Financial_Contact__c change, update the Pending or Current Lease Compliance objects
    	Set<Id> idsForUpdate = new Set<Id>();
    	Map<Id,String> facConMap = new Map<Id,String>();
    	Map<Id,String> finConMap = new Map<Id,String>();
    	Set<Id> lIds = new Set<Id>();
    	for (Lease__c l : trigger.new) {
    		lids.add(l.Id);
    	}
    	Map<Id,Lease__c> expanded = new Map<Id,Lease__c>([Select Id, Lease_Facilities_Contact__c, Lease_Financial_Contact__c, 
    		Lease_Facilities_Contact__r.Email, Lease_Financial_Contact__r.Email from LEase__c where ID IN: lIds]);
    		
    	for (Lease__c l : trigger.new) {
    		if ( l.Lease_Facilities_Contact__c!= trigger.oldMap.get(l.Id).Lease_Facilities_Contact__c || 
    			l.Lease_Financial_Contact__c!= trigger.oldMap.get(l.Id).Lease_Financial_Contact__c ) {
    			idsForUpdate.add(l.Id);
    			facConMap.put(l.Id,expanded.get(l.Id).Lease_Facilities_Contact__r.Email);
    			finConMap.put(l.Id,expanded.get(l.Id).Lease_Financial_Contact__r.Email);
    		}
    		
    	}
    	System.debug('****lease ids for udpate: ' + idsForUpdate);
    	if (idsForUpdate.size()>0) {
    		//List<Lease_Compliance__c> forUpdate = new List<Lease_Compliance__c>();
    		List<Lease_Compliance__c> exist = [Select Id, Lease__c, Facilities_Contact_Email__c, Finance_Contact_Email__c from 
    			Lease_Compliance__c
    			where Lease__c IN:idsForUpdate
    			and (recordtypeid =:CreateLeaseComplianceBatchable.pending or recordtypeid =:CreateLeaseComplianceBatchable.current )
    			];
    			
    		for (Lease_Compliance__c l : exist) {
    			l.Facilities_Contact_Email__c = facConMap.get(l.lease__c);
    			l.Finance_Contact_Email__c = finConMap.get(l.lease__c);
    		}	
    		if (exist.size()>0) update exist;
    	}
    } 
}