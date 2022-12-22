trigger IntakeItemAfterInsert on Intake_Item__c (after insert) {
    //when an Intake Item is created, send emails to the Community USers that the task is assigned to
    if (trigger.isinsert && trigger.isafter) {
    	//DiligenceUtils.sendCommunityEmails(trigger.new, false);	
    	
    	//If this a PQ Item, set the link from the PQ Form to this item
    	for (Intake_Item__c i : trigger.new) {
    		if (i.Is_Pre_Qual__c) {
    			try {
					System.debug('***setting pq intake item to : ' + i.Id);
					PQ_Form__c pq = [Select Id, Intake_Item__c from PQ_Form__c where Opportunity__c=:i.Opportunity__c LIMIT 1];
					pq.Intake_Item__c = i.Id;
					update pq;
				} catch (Exception e) {
					System.debug('***exception:  ' + e.getstacktracestring() + ' - ' + e.getmessage());
				}
						
    		}
    	}
    	
    	DiligenceUtils.shareIntakeItems(Trigger.new);
    }
    
}