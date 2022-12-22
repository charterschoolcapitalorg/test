trigger LeaseComplianceTrigger on Lease_Compliance__c (before insert) {
	//set email fields upon creation based on Lease Contact lookup fields
	if (trigger.isbefore && trigger.isinsert) {
		Set<Id> lIds = new Set<Id>();
		
		for (Lease_Compliance__c l : trigger.new) {
    		lids.add(l.lease__c);
    	}
    	
    	Map<Id,Lease__c> expanded = new Map<Id,Lease__c>([Select Id, Lease_Facilities_Contact__r.Email, 
    		Lease_Financial_Contact__r.Email from Lease__c where ID IN: lIds]);
    		
    	for (Lease_Compliance__c l : trigger.new) {
    		l.Facilities_Contact_Email__c = expanded.get(l.lease__c).Lease_Facilities_Contact__r.Email;
    		l.Finance_Contact_Email__c = expanded.get(l.lease__c).Lease_Financial_Contact__r.Email;
    	}
    	
	}    
}