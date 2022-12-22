trigger FCApprovalAfterUpdate on FC_Approval__c (after update) {
 
 Set<Id> formIds = new Set<Id>();
 Set<Id> summaryFormIds = new Set<Id>();
 Set<Id> opPIds = new Set<Id>();
 List<Task> tasks = new List<Task>();
 
 for(FC_Approval__c fa : trigger.new) {
 	if (fa.fc_form__c!=null) formIds.add(fa.fc_form__c);
 	if (fa.fc_form_2__c!=null) formIds.add(fa.fc_form_2__c);
 	
 }
 
 Map<Id, FC_Form__c> forms = new Map<Id, FC_Form__c>([Select Id, RecordTypeId, Opportunity__c, Opportunity__r.OwnerId, Opportunity__r.RecordTypeId, Opportunity__r.IsClosed, Opportunity__r.CloseDate, Status__c, Approval_Tier__c, Email_Final_Approval__c, (Select Id, Status__c, Is_Current__c, TYpe__c from FC_Approvals__r)
 	 from FC_FOrm__c where id IN: formIds]);
 
 for (FC_Form__c fo : forms.values()) {
 	if (fo.Opportunity__c!=null) oppIds.add(fo.Opportunity__c);
 }
 
 //get CSC ACtion ITems for update
 List<CSC_Action_Item__c> aItems = [Select Id, Department__c, Action_Item_Name__c, Date_Completed__c, Assigned_To__c, 
 	Status__c, CSC_Action_List__r.Opportunity__c, 
 	CSC_Action_List__r.Opportunity__r.Legal_Assistant__c, 
 	CSC_Action_List__r.Opportunity__r.User__c,
 	CSC_Action_List__r.Opportunity__r.Financial_Review__c,
 	CSC_Action_List__r.Opportunity__r.Paralegal__c
 	from CSC_Action_Item__c where CSC_Action_List__r.Opportunity__c IN:oppIds];
 	
 List<CSC_Action_Item__c> aItemsForUpdate = new List<CSC_Action_Item__c>();
 
 for(FC_Approval__c fa : trigger.new) {
 		
 		FC_Form__c fo = forms.get(fa.fc_form__c);
 		FC_Form__c deptForm = forms.get(fa.fc_form_2__c);
 		
 		//Final Approval cannot happen ater the Close Date, and Opp must still be Open in order to Vote
 		if (fo.Opportunity__r.CloseDate < Date.today() || fo.Opportunity__r.IsClosed) {
 			SObject sobj = (SObject)fa;
			sobj.adderror('Final Approval cannot be submitted as Opportunity is either Closed or Close Date is in the past');
 			//throw new FCFOrmUTils.FCEXception('Final Approval cannot be submitted as Opportunity is either CLosed or Close Date is in the past');
 		}
 		
 		//Approvals cannot be udpated if FC Summary Form is Rejected
 		if (fo!=null&&fo.status__c=='Rejected') {
 			SObject sobj = (SObject)fa;
			sobj.adderror('You cannot edit this record.  FC Summary Form is in status of Rejected');
 			//throw new FCFOrmUTils.FCEXception('Approvals cannot be edited when FC Summary Form is in status of Rejected');
 		}
 		
 		//Final FC Approval, see if this is the 3rd approval with no rejections
    	if (fa.type__c=='Final FC Approval' &&
    		((trigger.oldMap.get(fa.Id).status__c!='Approved' && fa.status__c=='Approved')
    		 || 
    		(trigger.oldMap.get(fa.Id).status__c!='Approved with Contingencies' && fa.status__c=='Approved with Contingencies'))) {
    			
            integer rejectcount = 0;
            integer approvecount = 0;
            integer approvewithcontingenciescount = 0;
            
            for (FC_Approval__c f : fo.FC_Approvals__r) {
            		if ((f.status__c=='Approved' ) && f.Type__c=='Final FC Approval' && f.Is_Current__c == true) approvecount+=1;
            		if ((f.status__c=='Approved with Contingencies') && f.Type__c=='Final FC Approval' && f.Is_Current__c == true) approvewithcontingenciescount+=1;
            		if (f.status__c=='Not Approved' && f.Type__c=='Final FC Approval' && f.Is_Current__c == true) rejectcount+=1;
            }
		    
		    //if we get subsequent contingencies, send out a different email prior to changing form status to Approved With Contingencies (so we dont send dupliocate emials)
		    if (fo.status__c=='Approved With Contingencies'
		 		&& fo.recordtypeid==FcFormUtils.SummaryFcRecType
		 		&& (fa.Status__c=='Approved With Contingencies' && trigger.oldmap.get(fa.Id).Status__c!='Approved With Contingencies')
		 		) 
		 	{
			 		if (FCFormUtils.fcEmailTemplates!=null) {
			        	if (fo.Approval_Tier__c=='Working Capital') {
			        		FCFormUtils.sendEmailToGroupAndDeptHeadAndLAUsingTemplate('FC_Approvers_WC', FcFormUTils.fcEmailTemplates.Subsequent_Approval_With_Contingencies__c, fo.Id, fo.Opportunity__c);	
			        	} else if (fo.Approval_Tier__c=='Facilities') {
			        		FCFormUtils.sendEmailToGroupAndDeptHeadAndLAUsingTemplate('FC_Approvers_FAC', FcFormUTils.fcEmailTemplates.Subsequent_Approval_With_Contingencies__c, fo.Id, fo.Opportunity__c);
			        	}
			    	}
		 	}  
		 	
		    if ((approvecount+approvewithcontingenciescount)>=3 && rejectcount==0) {
		        //This has been approved, update form status and send notifications
		        if (approvewithcontingenciescount>0) {
		        	fo.status__c='Approved With Contingencies';
		        } else {
		        	fo.status__c='Approved';
		        }
		        fo.FC_Decision_Date__c = Date.today();
		        update fo;
		        
		        //update CSC ACtion Item
		        if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFundingOpp || fo.Opportunity__r.RecordTypeId==RecordTypes.ID5DFOpp) {
		            for( CSC_Action_Item__c ai : aItems) {
		            	if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee Approval') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            	}
		            }
		            	
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDLoanOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		            	if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee approvals') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            	}
		            }
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFOFOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		            	if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee Approval received') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            	}
		            }
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFacilitiesOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		            	if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee (FC) Final Approval') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            	}
		            }
		        } 
		     	tasks.add(new Task(WhatId = fa.FC_Form__c, Subject = 'Email: FC Approved', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'FC Form Approved, email sent.', Type = 'Email'));   
		        
		    }
		 	
    	}
    	
    	//for Final FC not approvals send out email and change status of Form
    	if (fa.type__c=='Final FC Approval' &&(trigger.oldMap.get(fa.Id).status__c!='Not Approved' &&fa.status__c=='Not Approved') && fa.Is_Current__c == true) {
    		fo.status__c='Final Approval Not Approved';
    		fo.FC_Decision_Date__c = Date.today();
    		update fo;
    		
    		//null out CSC ACtion Items if thwy were already completed
		        if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFundingOpp || fo.Opportunity__r.RecordTypeId==RecordTypes.ID5DFOpp) {
		            for( CSC_Action_Item__c ai : aItems) {
		            	
		            	if (ai.status__c=='Completed'&& ai.Action_Item_Name__c.equalsignorecase('Funding Committee Approval') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.nullCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            	}
		            	
		            }
		            	
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDLoanOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		            	if (ai.status__c=='Completed'&& ai.Action_Item_Name__c.equalsignorecase('Funding Committee approvals') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.nullCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            	}
		            }
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFOFOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		            	if (ai.status__c=='Completed'&& ai.Action_Item_Name__c.equalsignorecase('Funding Committee Approval received') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.nullCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            	}
		            }
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFacilitiesOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		            	if (ai.status__c=='Completed'&& ai.Action_Item_Name__c.equalsignorecase('Funding Committee (FC) Final Approval') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.nullCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            	}
		            }
		        }
    		if (FCFormUtils.fcEmailTemplates!=null) {
    			if (fo.Approval_Tier__c=='Working Capital') {
		        	FCFormUtils.sendEmailToGroupAndDeptHeadAndLAUsingTemplate('FC_Approvers_WC', FcFormUTils.fcEmailTemplates.Final_Approval_Not_Approved_Template__c, fo.Id, fo.opportunity__c);	
    			} else if (fo.Approval_Tier__c=='Facilities') {
		        	FCFormUtils.sendEmailToGroupAndDeptHeadAndLAUsingTemplate('FC_Approvers_FAC', FcFormUTils.fcEmailTemplates.Final_Approval_Not_Approved_Template__c, fo.Id, fo.opportunity__c);
		        }
		        tasks.add(new Task(WhatId = fa.FC_Form__c, Subject = 'Email: FC Not Approved', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'FC Form Not Approved, email sent.', Type = 'Email'));
    			
    		//FCFormUtils.sendEmailToGroupUsingTemplate('FC Approval Tier '+fo.Approval_Tier__c, 'Test Final Approval Not Approved', fo.Id);
    		//FCFormUtils.notifyOppTeamAndDeptHeads('Test Final Approval Not Approved',fo.Id, fo.Opportunity__c);
    		}
    	}
    	
    	
 		//Pre FC Approval, see if this is the 3rd approval with no rejections
    	if (fa.type__c=='Pre-FC Approval' &&
    		((trigger.oldMap.get(fa.Id).status__c!='Approved' && fa.status__c=='Approved')
    		 || 
    		(trigger.oldMap.get(fa.Id).status__c!='Approved with Contingencies' && fa.status__c=='Approved with Contingencies'))) {
    			
            integer rejectcount = 0;
            integer approvecount = 0;
            
            
            for (FC_Approval__c f : fo.FC_Approvals__r) {
            		if ((f.status__c=='Approved'  || f.status__c=='Approved with Contingencies') && f.Type__c=='Pre-FC Approval' && f.Is_Current__c == true) approvecount+=1;
            		if (f.status__c=='Not Approved' && f.Type__c=='Pre-FC Approval' && f.Is_Current__c == true) rejectcount+=1;
            }
		    
		    if (approvecount>=3 && rejectcount==0) {
		        //This has been approved, update form status and send notifications
		        fo.status__c='In Progress';
		        update fo;
		        
		        
		        //update CSC ACtion Item
		        if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFundingOpp) {
		            for( CSC_Action_Item__c ai : aItems) {
		            	System.debug('***** checking ai: ' + ai);
		            	if (ai.Action_Item_Name__c.equalsignorecase('Preliminary Approval from FC (Optional)') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            		System.debug('***** completing ai: ' + ai);
		            	}
		            }
		            	
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDLoanOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		        		System.debug('***** checking ai: ' + ai);
		            	if (ai.Action_Item_Name__c.equalsignorecase('Preliminary Approval from FC (Optional)') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            		System.debug('***** completing ai: ' + ai);
		            	}
		            }
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFacilitiesOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		        		System.debug('***** checking ai: ' + ai);
		            	if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee (FC) Pre-Approval') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            		System.debug('***** completing ai: ' + ai);
		            	}
		            }
		        } 
		        
		        //only send approval email if this is the 3rd one
		        if (approvecount==3) {
		        	if (FCFormUtils.fcEmailTemplates!=null) {
			        	if (fo.Approval_Tier__c=='Working Capital') {
			        		FCFormUtils.sendEmailToGroupAndDeptHeadUsingTemplate('FC_Pre_FC_Notifications_WC', FcFormUTils.fcEmailTemplates.PreFC_Approved_Template__c, fo.Id, fo.opportunity__c);
			        	} else if (fo.Approval_Tier__c=='Facilities') {
			        		FCFormUtils.sendEmailToGroupAndDeptHeadUsingTemplate('FC_Pre_FC_Notifications_FAC', FcFormUTils.fcEmailTemplates.PreFC_Approved_Template__c, fo.Id, fo.opportunity__c);
			        	}
		        	}
		        	tasks.add(new Task(WhatId = fa.FC_Form__c, Subject = 'Email: Pre-FC Approval Granted', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'Pre-FC Approved continuation of this request, email sent.', Type = 'Email'));
		        }
		    }
    	}
    	
    	//for rejections send out email and change status of Form
    	System.debug('**** trigger.oldMap.get(fa.Id).status__c: '+trigger.oldMap.get(fa.Id).status__c);
    	System.debug('**** fa.status__c: '+fa.status__c);
    	
    	if (fa.type__c=='Pre-FC Approval' &&(trigger.oldMap.get(fa.Id).status__c!='Not Approved' &&fa.status__c=='Not Approved') && fa.Is_Current__c == true) {
    		fo.status__c='Pre Approval Not Approved';
    		update fo;
    		
    		//null out CSC ACtion Items if thwy were already completed
		        if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFundingOpp) {
		            for( CSC_Action_Item__c ai : aItems) {
		            	System.debug('***** checking ai: ' + ai);
		            	if (ai.status__c=='Completed'&&ai.Action_Item_Name__c.equalsignorecase('Preliminary Approval from FC (Optional)') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.nullCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            		System.debug('***** completing ai: ' + ai);
		            	}
		            }
		            	
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDLoanOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		        		System.debug('***** checking ai: ' + ai);
		            	if (ai.status__c=='Completed'&&ai.Action_Item_Name__c.equalsignorecase('Preliminary Approval from FC (Optional)') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.nullCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            		System.debug('***** completing ai: ' + ai);
		            	}
		            }
		        } else if (fo.Opportunity__r.RecordTypeId==RecordTypes.IDFacilitiesOpp) {
		        	for( CSC_Action_Item__c ai : aItems) {
		        		System.debug('***** checking ai: ' + ai);
		            	if (ai.status__c=='Completed'&&ai.Action_Item_Name__c.equalsignorecase('Funding Committee (FC) Pre-Approval') && ai.CSC_Action_List__r.Opportunity__c==fo.Opportunity__c) {
		            		aItemsForUpdate.add(FCFOrmUtils.nullCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
		            		System.debug('***** completing ai: ' + ai);
		            	}
		            }
		        }
		    
		    if (FCFormUtils.fcEmailTemplates!=null) {
		    	if (fo.Approval_Tier__c=='Working Capital') {
		        		FCFormUtils.sendEmailToGroupAndDeptHeadUsingTemplate('FC_Pre_FC_Notifications_WC', FcFormUTils.fcEmailTemplates.PreFC_Rejected_Template__c, fo.Id, fo.opportunity__c);
		        } else if (fo.Approval_Tier__c=='Facilities') {
		        		FCFormUtils.sendEmailToGroupAndDeptHeadUsingTemplate('FC_Pre_FC_Notifications_FAC', FcFormUTils.fcEmailTemplates.PreFC_Rejected_Template__c, fo.Id, fo.opportunity__c);
		        }
		    
		    }
		    //FCFormUtils.sendEmailToGroupUsingTemplate('PreFC Notifications '+fo.Approval_Tier__c, 'Test PreFC Rejected', fo.Id);
    		//FCFormUtils.notifyOppTeamAndDeptHeads('Test PreFC Rejected',fo.Id, fo.Opportunity__c);
    		
    	}
    	
    	//Dept Head Approval - once all groups have approved, send email if needed and update Form status to Waiting for Final Approval
    	//generate approval records
    	
    	if (fa.type__c=='Dept Head Review' &&
    		((trigger.oldMap.get(fa.Id).status__c!='Approved' && fa.status__c=='Approved')
    		 || 
    		(trigger.oldMap.get(fa.Id).status__c!='Approved with Contingencies' && fa.status__c=='Approved with Contingencies'))) {
    		
    			//update CSC ACtion Item
    			if (deptForm!=null) {
    				//only for non-Facilities
			        if (deptForm.Opportunity__r.RecordTypeId==RecordTypes.IDFundingOpp || deptForm.Opportunity__r.RecordTypeId==RecordTypes.ID5DFOpp) {
			            for( CSC_Action_Item__c ai : aItems) {
			            	if (deptForm.RecordTypeId==FcFormUtils.UWFcRecType) {
				            	if (ai.Action_Item_Name__c.equalsignorecase('Pre-approval Provided - Underwriting') && ai.CSC_Action_List__r.Opportunity__c==deptForm.Opportunity__c) {
				            		//aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
				            		aItemsForUpdate.add(FCFOrmUtils.updateActionItem(ai, fa.Approver__c));
				            	}
			            	} else if (deptForm.RecordTypeId==FcFormUtils.FinanceFcRecType) {
			            		if (ai.Action_Item_Name__c.equalsignorecase('Pre-approval Provided - Finance') && ai.CSC_Action_List__r.Opportunity__c==deptForm.Opportunity__c) {
				            		//aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
				            		aItemsForUpdate.add(FCFOrmUtils.updateActionItem(ai, fa.Approver__c));
				            	}
			            	}
			            }
			            	
			        } else if (deptForm.Opportunity__r.RecordTypeId==RecordTypes.IDLoanOpp) {
			        	for( CSC_Action_Item__c ai : aItems) {
			            	if (deptForm.RecordTypeId==FcFormUtils.UWFcRecType) {
				            	if (ai.Action_Item_Name__c.equalsignorecase('Pre-approval- Underwriting') && ai.CSC_Action_List__r.Opportunity__c==deptForm.Opportunity__c) {
				            		//aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
				            		aItemsForUpdate.add(FCFOrmUtils.updateActionItem(ai, fa.Approver__c));
				            	}
			            	} else if (deptForm.RecordTypeId==FcFormUtils.FinanceFcRecType) {
			            		if (ai.Action_Item_Name__c.equalsignorecase('Pre-approval- Finance') && ai.CSC_Action_List__r.Opportunity__c==deptForm.Opportunity__c) {
				            		//aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
				            		aItemsForUpdate.add(FCFOrmUtils.updateActionItem(ai, fa.Approver__c));
				            	}
			            	}
			            }
			        } else if (deptForm.Opportunity__r.RecordTypeId==RecordTypes.IDFOFOpp) {
			        	for( CSC_Action_Item__c ai : aItems) {
			            	if (deptForm.RecordTypeId==FcFormUtils.UWFcRecType) {
				            	if (ai.Action_Item_Name__c.equalsignorecase('Pre-approval provided - UW') && ai.CSC_Action_List__r.Opportunity__c==deptForm.Opportunity__c) {
				            		//aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
				            		aItemsForUpdate.add(FCFOrmUtils.updateActionItem(ai, fa.Approver__c));
				            	}
			            	} else if (deptForm.RecordTypeId==FcFormUtils.FinanceFcRecType) {
			            		if (ai.Action_Item_Name__c.equalsignorecase('Pre-Approval Provided - FIN') && ai.CSC_Action_List__r.Opportunity__c==deptForm.Opportunity__c) {
				            		//aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, fo.Opportunity__r.OwnerId));
				            		aItemsForUpdate.add(FCFOrmUtils.updateActionItem(ai, fa.Approver__c));
				            	}
			            	}
			            }
			        } 	
    			}
    		integer rejectcount = 0;
            integer approvecount = 0;
            
            System.debug('***** approvals: ' + fo.FC_Approvals__r);
            
            for (FC_Approval__c f : fo.FC_Approvals__r) {
            		if ((f.status__c=='Approved'  || f.status__c=='Approved with Contingencies') && f.Type__c=='Dept Head Review' && f.Is_Current__c == true) approvecount+=1;
            		if (f.status__c=='Not Approved' && f.Type__c=='Dept Head Review' && f.Is_Current__c == true) rejectcount+=1;
            }
		    
		    
		    	//Non Facilities needs 2 approvals
		    	//Facilities needs one	
			    if ((approvecount>=2 && rejectcount==0 && fo.recordtypeid!=FCFOrmUtils.FacilitiesFcRecType) ||
			    	(approvecount>=1 && rejectcount==0 && fo.recordtypeid==FCFOrmUtils.FacilitiesFcRecType)
			    	) {
			    	
			        //This has been approved, update form status and send notifications
			        fo.status__c='Waiting for Final Approval';
			        update fo;
			    	
			    	//deactivate old final fc approvals if they exist
			        List<FC_Approval__c> exist = [Select id, status__c, is_current__c from FC_Approval__c 
			            	where FC_Form__c=:fo.Id and Type__c='Final FC Approval' and Is_Current__c = true];
			        for (FC_Approval__c f : exist) {
			            		f.is_current__c = false;
			        }
			        if (exist.size()>0) update exist;   
			        
				    //create final approval object	
				    Map<Id,Id> users = new Map<Id,Id>();
				    if (fo.Approval_Tier__c=='Working Capital') {
			        	users = FCFormUtils.getUsersFromGroup('FC_Approvers_WC');	
	    			} else if (fo.Approval_Tier__c=='Facilities') {
			        	users = FCFormUtils.getUsersFromGroup('FC_Approvers_FAC');
			        }
			        
				    
			        List<FC_Approval__c> fas = new List<FC_Approval__c >();
			        for (Id i : users.keyset()) {
				 		FC_Approval__c f = new FC_Approval__c(Approver__c=i, Is_Current__c = true, FC_Form__c=fo.Id, Status__c='Pending', 
				            	Type__c='Final FC Approval');
				        fas.add(f);
			        }
			        if (fas.size()>0) insert fas;
			        
			    	//if (fo.Email_Final_Approval__c) {
			    		//send out email
			    		if (FCFormUtils.fcEmailTemplates!=null) {
			    			if (fo.Approval_Tier__c=='Working Capital') {
				        		FCFormUtils.sendEmailToGroupUsingTemplate('FC_Approvers_WC', FcFormUTils.fcEmailTemplates.Dept_Head_Approved_Template__c, fo.Id);	
				        	} else if (fo.Approval_Tier__c=='Facilities') {
				        		FCFormUtils.sendEmailToGroupUsingTemplate('FC_Approvers_FAC', FcFormUTils.fcEmailTemplates.Dept_Head_Approved_Template__c, fo.Id);
				        	}
			    			
			    		}
			    	tasks.add(new Task(WhatId = fa.FC_Form__c, Subject = 'Email: Dept Head Review Complete', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'FC Form decision made by Dept Heads, email sent.', Type = 'Email'));
		    	}
		    
    	}
    	
    	
 }  
 
 if (aItemsForUpdate.size()>0) update aItemsForUpdate;
 System.debug('Tasks: ' + tasks);
 if (tasks.size()>0) insert tasks;
  
}