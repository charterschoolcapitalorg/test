trigger IntakeItemAfterUpdate on Intake_Item__c (after update) {
 	
 	if (trigger.isupdate && trigger.isafter) {
	 	//when an Intake Item changes to Additional Input Needed
	 	//  , send emails to the Community USers that the task is assigned to
	 	List<Intake_Item__c> forEmail = new List<Intake_Item__c>();
	 	
	 	for (Intake_Item__c i : trigger.new) {
		 	if (i.status__c==DiligenceVars.IntakeInputNeededStatus 
		 		&& trigger.oldmap.get(i.id).status__c!=i.status__c) {
		 		forEmail.add(i);
		 	}
	 	}
	 	if (forEmail.size()>0) {
	    	DiligenceUtils.sendCommunityEmails(forEmail, true);
	 	}	
	 	
	 	Set<Id> items = new Set<Id>();
	 	Set<Id> parentItems = new Set<Id>();
	 	
	 	//when an Item changes to Accepted, see if all of the other child tiems are Accepted, and mark the parent as Accepted
	 	for (Intake_Item__c i : trigger.new) {
	 		if (i.Parent_Intake_Item__c!=null&&i.status__c==DiligenceVars.IntakeApprovedStatus && trigger.oldmap.get(i.Id).status__c!=DiligenceVars.IntakeApprovedStatus) {
	 			items.add(i.Id);
	 			parentItems.add(i.Parent_Intake_Item__c);
	 		}
	 	}
	 	
	 	List<Intake_Item__c> childItems = [Select Id, Status__c, Parent_Intake_Item__c from Intake_Item__c where 
	 		status__c !=: DiligenceVars.IntakeApprovedStatus AND Is_Visible_To_Community__c=True AND Parent_Intake_Item__c IN:parentItems];
	 		
	 	if (childitems.size()==0) {
	 		//need to update all parents
	 		
	 	} else {
			for (Intake_Item__c i : childItems) {
				try { parentitems.remove(i.Parent_Intake_Item__c); } catch (Exception e) {}
			}	 		
			
	 	}
	 	if (parentItems.size()>0) {
	 		List<Intake_Item__c> iiForUpdate = [Select Id, Status__c from Intake_Item__c where ID IN:parentItems];
	 		for (Intake_Item__c itemForUpdate : iiForUPdate) {
	 			itemForUpdate.status__c = 'Accepted';
	 		}
	 		update iiForUpdate;
	 	}	 	
	 	
	 	
 	}
    
 	if (trigger.isupdate && trigger.isafter) {
 		Map<Id, Id> oppIdsForApplyDR = new Map<Id, Id>();
 		Map<Intake_Item__c, Id> facOppIdsForINtakeCreation = new Map<Intake_Item__c, Id>();
 		Map<Id, Intake_Item__c> fundingOpeningCallOppIds = new Map<Id, Intake_Item__c>();
 		Map<Id,Intake_Item__c> iiApproved = new Map<Id,Intake_Item__c>();
 		Map<Id,Intake_Item__c> iiSubmitted = new Map<Id, Intake_Item__c>();
 		
 		for (Intake_Item__c i : trigger.new) {
 				//for Initial FUnding, whem PQ Items are approved, trigger the Opportunity Diligence Rules process builder
	 			//also create the rest of the Intake Items
	 			if (i.recordtypeid==RecordTypes.IDInitialFundingIntakeItem&&i.name==DiligenceVars.PQName ) {
	 				if (i.status__c==DiligenceVars.IntakeApprovedStatus && trigger.oldmap.get(i.id).status__c!=i.status__c) {
	 					System.debug('*** Applying opp diligence rules for: ' +i.opportunity__c );
	 					oppIdsForApplyDR.put(i.opportunity__c, i.opportunity__c);
	 				}
	 			}
	 			
	 			//for Facilities, whem Stop 1 Item is approved, trigger the Opportunity Diligence Rules process builder
	 			if (i.recordtypeid==RecordTypes.IDFacilitiesIntakeItem&&i.status__c==DiligenceVars.IntakeApprovedStatus 
 					&& trigger.oldmap.get(i.id).status__c!=i.status__c
 					&&i.stop_number__c==1) {
	 					System.debug('*** Applying opp diligence rules for: ' +i.opportunity__c );
	 					oppIdsForApplyDR.put(i.opportunity__c, i.opportunity__c);
	 			}
	 			
 				//for Facilities, create new INtake Items when a Stop has been Accepted
 				if (i.recordtypeid==RecordTypes.IDFacilitiesIntakeItem&&i.status__c==DiligenceVars.IntakeApprovedStatus 
 					&& trigger.oldmap.get(i.id).status__c!=i.status__c
 					&&i.stop_number__c!=null) {
 					facOppIdsForINtakeCreation.put(i, i.opportunity__c);
 				}
 				
	 			
	 			//When CSC Approves the Opening Call Intake Item,  recalculate Due Dates
	 			if (i.recordtypeid==RecordTypes.IDInitialFundingIntakeItem&&i.name==DiligenceVars.OpeningCallName) {
	 				if (i.status__c==DiligenceVars.IntakeApprovedStatus && trigger.oldmap.get(i.id).status__c!=i.status__c) {
	 					fundingOpeningCallOppIds.put(i.opportunity__c, i);
	 				}
	 			}
 			
 			
 		}
 		
 		if (!facOppIdsForINtakeCreation.isempty() ) {
 			for (Intake_Item__c i : facOppIdsForINtakeCreation.keyset()) {
 				DiligenceUtils.createIntakeItems(facOppIdsForINtakeCreation.get(i),Integer.valueOf(i.stop_number__c+1), i);				
 			}
 			
 		}
 		
 		if (!fundingOpeningCallOppIds.isempty()) {
 			List<Opportunity> oo = [Select Id, RecordTypeId, diligence_path__c, target_wire_date__c from Opportunity where Id IN:fundingOpeningCallOppIds.keyset()];
 			for (Opportunity o : oo) {
 				if (o.recordtypeid==recordtypes.IDFundingOpp ) {
	 				if (o.target_wire_date__c==null ||o.diligence_path__c==null  ) {
	 					fundingOpeningCallOppIds.get(o.Id).addError('Target WIre Date and Diligence Path must be filled in on this Opportunity in order to Approve this Item');
	 					break;
	 				} else {
	 					DiligenceUtils.updateIntakeItemsDueDates(o.Id);
	 				}
 				}
 			}	
 		}
 		if (!oppIdsForApplyDR.isempty()) {
 			
	    	
 			List<Opportunity> oo = [Select Id, (Select Id, Apply_Diligence_Rules__c, Charter_Opened_Date__c from PQ_Forms__r), RecordTypeId, Apply_Diligence_Rules__c from Opportunity where Id IN:oppIdsForApplyDR.keyset()];
 			for (Opportunity o : oo) {
 				//create Intake Items for Initial Funding
	 			if (o.recordtypeid==RecordTypes.IDFundingOpp) {
			    	DiligenceUtils.createIntakeItems(o.Id, 1, null);
			    }
	 			
	 				
 				if (o.recordtypeid==recordtypes.IDFundingOpp || o.recordtypeid==recordtypes.IDFacilitiesOpp ) {
					//if all of the PQ fields are filled in,   trigger the Opportunity Diligence Rules process builder
					if (o.PQ_Forms__r==null||o.PQ_Forms__r.size()==0) {
 						throw new DiligenceUtils.DiligenceException('There is no PQ Form for this Opportunity');
 					} else {
 						//if (o.PQ_Forms__r[0].Charter_Opened_Date__c==null) {
 						//	throw new DiligenceUtils.DiligenceException('Charter Open Date cannot be null in the PQ Form');
 						//}
 					}
					
					System.debug('*** Triggering process builder for: ' +o );
					//we need to change the flag to trigger the Process Builder
					if (o.PQ_Forms__r[0].Apply_Diligence_Rules__c ==true) {
					  	o.PQ_Forms__r[0].Apply_Diligence_Rules__c = false;	
						update o.PQ_Forms__r[0];
					} 
				 	   		
				   o.PQ_Forms__r[0].Apply_Diligence_Rules__c = true;
				   update o.PQ_Forms__r[0];
					 
				}
 				
 				
 			}
 			//update oo;	
 			
 		}

		List<Intake_Item__c> changed = new List<Intake_Item__c>();

		for (Intake_Item__c oldItem: Trigger.old) {
			Intake_Item__c newItem = Trigger.newMap.get(oldItem.Id);

			if (
				oldItem.Opportunity__c != newItem.Opportunity__c ||
				oldItem.Account_Name__c != newItem.Account_Name__c ||
				oldItem.Is_Visible_To_Community__c != newItem.Is_Visible_To_Community__c
			) {
				changed.add(newItem);
			}
		}

		DiligenceUtils.shareIntakeItems(changed);
 	}
}