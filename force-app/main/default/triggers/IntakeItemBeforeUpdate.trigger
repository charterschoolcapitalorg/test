trigger IntakeItemBeforeUpdate on Intake_Item__c (before update) {
	
	//molinger - Phase 3 - When Intake STatus is changed away from Accepted, need to set this field back to false
	// to enforce the vlaidation rule on the Status field not being updated manually from the SF page
 	if (trigger.isupdate && trigger.isBefore) {
		for (Intake_Item__c i : trigger.new) {
			System.debug('new status: ' + i.status__c + ' - old status: ' + trigger.oldMap.get(i.Id).Status__c);
			System.debug('Status_Changed_from_UI__c: ' + i.Status_Changed_from_UI__c);
			if (i.Status_Changed_from_UI__c == true 
				&& i.Status__c!='Accepted' 
				&& trigger.oldMap.get(i.Id).Status__c=='Accepted') 
				{
					System.debug('setting Status_Changed_from_UI__c to false');
					i.Status_Changed_from_UI__c = false; 
				}
		}
 	}
 	
    if (trigger.isupdate && trigger.isbefore) {
 		for (Intake_Item__c i : trigger.new) {
	 			
	 			//if status = Accepted, update the Approved By and Approved Date fields
	 			if (i.status__c==DiligenceVars.IntakeApprovedStatus
	 				&&trigger.oldmap.get(i.Id).status__c!=DiligenceVars.IntakeApprovedStatus) {
	 				//iiApproved.put(i.LastModifiedByid, i);
	 				i.Approved_By__c = UserInfo.getUserId();
		 		 	i.Approved_Date__c = date.today();
		 		 	if(i.Submitted_By__c == null){
		 		 		i.Submitted_By__c = UserInfo.getUserId();
	 					i.Submitted_Date__c = date.today();
		 		 	}
	 			}
	 			//if status = SUbmitted, update the Submitted By and Submitted Date fields
	 			if (i.status__c==DiligenceVars.IntakeSubmittedStatus
	 				&&trigger.oldmap.get(i.Id).status__c!=DiligenceVars.IntakeSubmittedStatus) {
	 				//System.debug('*** submitted - LastModifiedBy.id: '+ i.LastModifiedByid);
	 				//iiSubmitted.put(i.LastModifiedByid, i);
	 				System.debug('****updating submitted by');
	 				i.Submitted_By__c = UserInfo.getUserId();
	 				i.Submitted_Date__c = date.today();
	 			}
 			
 		}
   }
}