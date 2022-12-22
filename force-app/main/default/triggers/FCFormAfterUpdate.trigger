trigger FCFormAfterUpdate on FC_Form__c (before update, after update) {
 
 Set<Id> formIds = new Set<Id>();
 Set<Id> summaryFormIds = new Set<Id>();
 Set<Id> oppIds = new Set<Id>();
 List<Task> tasks = new List<Task>();
  
 //update Annual Estimated Budget field
 if (trigger.isbefore &&trigger.isbefore) {
	 for(FC_Form__c f : trigger.new) {
	 	if (f.EWS_Budgeted_Surplus_Deficit__c!=trigger.oldMap.get(f.Id).EWS_Budgeted_Surplus_Deficit__c
	 		|| f.EWS_Fiscal_YEar__c!=trigger.oldMap.get(f.Id).EWS_Fiscal_YEar__c
	 		|| f.EWS_Budgeted_Revenue__c!=trigger.oldMap.get(f.Id).EWS_Budgeted_Revenue__c
	 		) {
	 			String bsd = String.format(f.EWS_Budgeted_Surplus_Deficit__c.format(), new String[]{'0','number','###,###,##0.00'});
				String bud = String.format(f.EWS_Budgeted_Revenue__c.format(), new String[]{'0','number','###,###,##0.00'});
				Decimal exp = f.EWS_Budgeted_Revenue__c - f.EWS_Budgeted_Surplus_Deficit__c; 
				String expStr = String.format(exp.format(), new String[]{'0','number','###,###,##0.00'});
										
				// String annEstBud = 'Projected ' + f.EWS_Fiscal_Year__c + ' - ' + '\n' +
				// 	'$' + bud + ' Anticipated Revenue\n' +
				// 	'$'	+ expStr + ' Projected Expenses\n'+
				// 	'$' + bsd + ' Expected Net Surplus';
				
				String annEstBud;
				if (f.EWS_Fiscal_Quarter__c == 'Q3' || f.EWS_Fiscal_Quarter__c == 'Q4') {
						annEstBud = 'Projected ' + (f.EWS_Fiscal_Year__c + 1) + ' - ' + '\n' +
						'$' + bud + ' Anticipated Revenue\n' +
						'$' + expStr + ' Projected Expenses\n' +
						'$' + bsd + ' Expected Net Surplus';
				} else {
						annEstBud = 'Projected ' + f.EWS_Fiscal_Year__c + ' - ' + '\n' +
						'$' + bud + ' Anticipated Revenue\n' +
						'$' + expStr + ' Projected Expenses\n' +
						'$' + bsd + ' Expected Net Surplus';
				}
										
				f.Annual_Estimated_Budget__c = annEstBud;
										 
	 	}
	 }
 }
 
 for(FC_Form__c f : trigger.new) {
 	formIds.add(f.Id);
 	oppIds.add(f.opportunity__c);	
 }

 Map<Id, FC_Form__c> oldForms = trigger.oldMap;
 
 Map<Id, FC_Form__c> forms = new Map<Id, FC_Form__c>([Select Id, Opportunity__r.OwnerId, RecordTypeId, Status__c,Summary_FC_Form__c,
 	(Select Id, Status__c, TYpe__c from FC_Approvals__r)
 	 from FC_FOrm__c where id IN: formIds]);
 	 
for (FC_FOrm__c fo : forms.values()) {
	if (fo.Summary_FC_Form__c!=null) summaryFormIds.add(fo.Summary_FC_Form__c);
	if (fo.recordtypeid==FCFOrmUtils.SummaryFcRecType) summaryFormIds.add(fo.Id);
}

//get CSC ACtion ITems for update
List<CSC_Action_Item__c> aItems = [Select Id, Department__c, Action_Item_Name__c, Date_Completed__c, Assigned_To__c, Status__c, 
	CSC_Action_List__r.Opportunity__c, 
	CSC_Action_List__r.Opportunity__r.Legal_Assistant__c, 
	CSC_Action_List__r.Opportunity__r.User__c,
	CSC_Action_List__r.Opportunity__r.Financial_Review__c,
	CSC_Action_List__r.Opportunity__r.Paralegal__c
	 from CSC_Action_Item__c where CSC_Action_List__r.Opportunity__c IN:oppIds];
List<CSC_Action_Item__c> aItemsForUpdate = new List<CSC_Action_Item__c>();
 
if (summaryFormIds.size()>0) {
 	Map<Id, FC_Form__c> summaryforms = new Map<Id, FC_Form__c>([Select Id, Status__c,Summary_FC_Form__c, Opportunity__r.IsWon,
 	(Select Id, Status__c, TYpe__c from FC_Approvals__r)
 	 from FC_FOrm__c where id IN: summaryFormIds]);
 	 
 	 for(FC_Form__c form : trigger.new) {
 	 	FC_Form__c summform;
 	 	if (form.recordtypeid==FCFOrmUtils.SummaryFcRecType) {
 	 		summform = summaryforms.get(form.Id);
 	 	} else {
 	 	    summform = summaryforms.get(form.Summary_FC_Form__c);
 	 	}
 	 			 		
		/*if (summform!=null && summform.status__c=='Rejected') {
			SObject sobj = (SObject)form;
			sobj.adderror('FC Forms are locked when rejected and cannot be altered.');
			//throw new FCFOrmUTils.FCEXception('You cannot edit this record.  FC Summary Form is in status of Rejected');
		}*/
		//2019.03.05 J Caughie - added filter for won opps and conditional error message
		if (summform!=null && summform.Opportunity__r.IsWon) {
			SObject sobj = (SObject)form;
			sobj.adderror('FC Forms are locked to everyone when an Opportunity is Closed (Won or Lost) and cannot be altered.');
			//throw new FCFOrmUTils.FCEXception('You cannot edit this record.  FC Summary Form is in status of Rejected');
		}
 	 }
}
 
 
 //get all other forms
 Map<Id, FC_FOrm__c> allforms = new Map<Id, FC_FOrm__c>([Select Id, RecordTypeId, Opportunity__r.OwnerId, Opportunity__r.RecordTYpeId, Opportunity__c , Submitted_For_Review__c,Reviewer__c
 	 from FC_FOrm__c where opportunity__c IN: oppIds]);
 	 
 
 
 //here we handle forms being submitted for review
 List<FC_FOrm__c> forUpdate = new List<FC_FOrm__c>();
 List<FC_Approval__c> fas = new List<FC_Approval__c >();

 
for(FC_FOrm__c fa : trigger.new) {
	
 	if (FCFOrmUtils.formsSubmittedForDeptHEadReview.size()==0) {
 		//static check so we dont execute twice
 		if (!FCFOrmUtils.formsSubmittedForDeptHEadReview.contains(fa.Id)) {
 	
 	
		 	Set<Id> userIDs = new set<Id>();
		 	if (fa.Reviewer__c!=null) userIDs.add(fa.Reviewer__c);
		 	FC_FOrm__c summaryForm;
		 	
		 	//For Final Approval or Approved With Contingencies, send out email
		 	if (fa.recordtypeid==FcFormUtils.SummaryFcRecType
		 	&& ((fa.Status__c=='Approved With Contingencies' && trigger.oldmap.get(fa.Id).Status__c!='Approved With Contingencies') ||
		 		(fa.Status__c=='Approved' && trigger.oldmap.get(fa.Id).Status__c!='Approved'))) 
		 	{
			 	if (FCFormUtils.fcEmailTemplates!=null && !FcFormUtils.sentFinalApproval) {
			        	if (fa.Approval_Tier__c=='Working Capital') {
			        		FCFormUtils.sendEmailToGroupAndDeptHeadAndLAUsingTemplate('FC_Approvers_WC', FcFormUTils.fcEmailTemplates.Final_Approval_Template__c, fa.Id, fa.Opportunity__c);	
			        	} else if (fa.Approval_Tier__c=='Facilities') {
			        		FCFormUtils.sendEmailToGroupAndDeptHeadAndLAUsingTemplate('FC_Approvers_FAC', FcFormUTils.fcEmailTemplates.Final_Approval_Template__c, fa.Id, fa.Opportunity__c);
			        	}
			        	FcFormUtils.sentFinalApproval = true;
			    }
			    tasks.add(new Task(WhatId = fa.Summary_FC_Form__c, Subject = 'Email: FC Approved', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'FC Form Approved, email sent.', Type = 'Email'));
			    System.debug('Tasks approvals: ' + tasks);
		 	}  
		 	  
		 	//for Final FC Rejections send out email, lock records for editing
		    if (fa.recordtypeid==FcFormUtils.SummaryFcRecType && fa.Status__c=='Rejected' && trigger.oldmap.get(fa.Id).Status__c!='Rejected') {
	    		if (FCFormUtils.fcEmailTemplates!=null  && !FcFormUtils.sentFinalRejection) {
	    			if (fa.Approval_Tier__c=='Working Capital') {
	    				FCFormUtils.sendEmailToGroupAndDeptHeadAndLAUsingTemplate('FC_Approvers_WC', FcFormUTils.fcEmailTemplates.Final_Approval_Rejected_Template__c, fa.Id, fa.opportunity__c);	
	    			} else if (fa.Approval_Tier__c=='Facilities') {
	    				FCFormUtils.sendEmailToGroupAndDeptHeadAndLAUsingTemplate('FC_Approvers_FAC', FcFormUTils.fcEmailTemplates.Final_Approval_Rejected_Template__c, fa.Id, fa.opportunity__c);
	    			}
	    			FcFormUtils.sentFinalRejection = true;
	    			tasks.add(new Task(WhatId = fa.Id, Subject = 'Email: Rejection received', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'Rejection received, email sent.', Type = 'Email'));
	    			System.debug('Tasks rejections: ' + tasks);
	    		}
	    		//FCFormUtils.sendEmailToGroupUsingTemplate('FC Approval Tier '+fa.Approval_Tier__c, 'Test Final Approval Rejected', fa.Id);
	    		//FCFormUtils.notifyOppTeamAndDeptHeads('Test Final Approval Rejected',fa.Id, fa.Opportunity__c);
		    }
		    	
		    	
		 	if (fa.recordtypeid!=FcFormUtils.SummaryFcRecType && fa.Submitted_For_Review__c 
		 		&& !trigger.oldmap.get(fa.Id).Submitted_For_Review__c) {
		 			
		 		Id formIdForApproval;
		 		if (fa.recordtypeid==FcFormUtils.FacilitiesFcRecType) {
		 			formIdForApproval = fa.Id;
		 		} else {
		 			formIdForApproval = fa.Summary_FC_Form__c;
		 		}
		 		
				//deactivate old dept head approvals if they exist
		        /*List<FC_Approval__c> exist = [Select id, status__c, is_current__c from FC_Approval__c 
		            	where FC_Form__c=:formIdForApproval and Type__c='Dept Head Review' and Is_Current__c = true];
		        for (FC_Approval__c f : exist) {
		            		f.is_current__c = false;
		        }
		        if (exist.size()>0) update exist;   
		        */
		                
		 		//create approval object
		 		FC_Approval__c f;
		 		if (fa.recordtypeid==FcFormUtils.FacilitiesFcRecType) {
		 			f = new FC_Approval__c(Approver__c=fa.Reviewer__c,FC_Form__c=formIdForApproval,  
		 			Status__c='Pending', 
		            	Type__c='Dept Head Review');
		            fas.add(f);	
		            FCFOrmUtils.formsSubmittedForDeptHEadReview.add(fa.Id);
		 		} else if (fa.recordtypeid==FcFormUtils.ServicingFcRecType) {
		 			//Servicing doesnt have a Dept Head Approval
		 			FCFOrmUtils.formsSubmittedForDeptHEadReview.add(fa.Id);	
		 		} else {
		 			f = new FC_Approval__c(Approver__c=fa.Reviewer__c,FC_Form__c=formIdForApproval,  
		 			FC_Form_2__c=fa.Id, Status__c='Pending', 
		            	Type__c='Dept Head Review');
		            fas.add(f);
		            FCFOrmUtils.formsSubmittedForDeptHEadReview.add(fa.Id);
		 		}
		 		
		        
		            
		 		List<FC_FOrm__c> otherforms = new List<FC_FOrm__c>();
		 		for (FC_FOrm__c d : allforms.values()) {
		 			if (d.opportunity__c==fa.opportunity__c) {
		 				otherforms.add(d);
		 			}
		 		}
		 		boolean allSubmitForReview = true;
		 		
		 		for (FC_FOrm__c d2 : otherforms) {
		 			if (d2.reviewer__c!=null) userIDs.add(d2.reviewer__c);
		 			if (!d2.Submitted_For_Review__c && d2.Id!=fa.Id  && d2.recordtypeid!=FcFormUtils.SummaryFcRecType) {
		 				allSubmitForReview = false;
		 			}
		 			if (d2.recordtypeid==FcFormUtils.SummaryFcRecType || d2.recordtypeid==FcFormUtils.FacilitiesFcRecType) summaryForm=d2;
		 		}
		 		
		 		FC_FOrm__c thisFOrm = allforms.get(fa.Id);
		 		
		 		//update CSC ACtion Item
		 		if (thisFOrm!=null) {	
				        if (thisFOrm.Opportunity__r.RecordTypeId==RecordTypes.IDFundingOpp) {
				            for( CSC_Action_Item__c ai : aItems) {
				            	if (fa.RecordTypeId==FcFormUtils.UWFcRecType) {
					            	if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee Form (Underwriting Review Completed)') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, thisForm.Opportunity__r.OwnerId));
					            	}
				            	} else if (fa.RecordTypeId==FcFormUtils.FinanceFcRecType) {
				            		if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee Form (Financial Review Completed)') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, thisForm.Opportunity__r.OwnerId));
					            	}
				            	} else if (fa.RecordTypeId==FcFormUtils.ServicingFcRecType) {
				            		if (ai.Action_Item_Name__c.equalsignorecase('Servicing FC Form Submitted for Review') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, UserInfo.getUserId()));
					            	}
				            	}
				            }
				            	
				        } else if (thisFOrm.Opportunity__r.RecordTypeId==RecordTypes.IDLoanOpp) {
				        	for( CSC_Action_Item__c ai : aItems) {
				            	if (fa.RecordTypeId==FcFormUtils.UWFcRecType) {
					            	if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee Form (Underwriting Review Completed)') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, thisForm.Opportunity__r.OwnerId));
					            	}
				            	} else if (fa.RecordTypeId==FcFormUtils.FinanceFcRecType) {
				            		if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee Form (Financial Review Completed)') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, thisForm.Opportunity__r.OwnerId));
					            	}
				            	}
				            }
				        } else if (thisFOrm.Opportunity__r.RecordTypeId==RecordTypes.IDFOFOpp) {
				        	for( CSC_Action_Item__c ai : aItems) {
				            	if (fa.RecordTypeId==FcFormUtils.UWFcRecType) {
					            	if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee form completed -UW (Due diligence completed)') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, thisForm.Opportunity__r.OwnerId));
					            	}
				            	} else if (fa.RecordTypeId==FcFormUtils.FinanceFcRecType) {
				            		if (ai.Action_Item_Name__c.equalsignorecase('Funding Committee form completed - FIN (Financial review completed)') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, thisForm.Opportunity__r.OwnerId));
					            	}
				            	} else if (fa.RecordTypeId==FcFormUtils.ServicingFcRecType) {
				            		if (ai.Action_Item_Name__c.equalsignorecase('Servicing FC Form Submitted for Review') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, UserInfo.getUserId()));
					            	}
				            	}
				            }
				        } else if (thisFOrm.Opportunity__r.RecordTypeId==RecordTypes.ID5DFOpp) {
				        	for( CSC_Action_Item__c ai : aItems) {
				            	if (fa.RecordTypeId==FcFormUtils.UWFcRecType) {
					            	if (ai.Action_Item_Name__c.equalsignorecase('Underwriting FC Form Complete') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, thisForm.Opportunity__r.OwnerId));
					            	}
				            	} else if (fa.RecordTypeId==FcFormUtils.FinanceFcRecType) {
				            		if (ai.Action_Item_Name__c.equalsignorecase('Finance FC Form Complete') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, thisForm.Opportunity__r.OwnerId));
					            	}
				            	} else if (fa.RecordTypeId==FcFormUtils.ServicingFcRecType) {
				            		if (ai.Action_Item_Name__c.equalsignorecase('Servicing FC Form Complete') && ai.CSC_Action_List__r.Opportunity__c==fa.Opportunity__c) {
					            		aItemsForUpdate.add(FCFOrmUtils.updateCSCActioNItem(ai, UserInfo.getUserId()));
					            	}
				            	}
				            }
				        }
		 		}
		 		 
		 		//when last form is marked as for review, send out the email to the reviewers
		 		if (allSubmitForReview) {
		 			//send emails
		 			List<Id> lUserIds = new List<Id>();
		 			lUserIds.addall(userIDs);
		 			 
		 			 //FCFormUtils.sendEmailToUsers('submitted for dept head review', 'submitted for dept head review', lUserIds);
		 			 if (FCFormUtils.fcEmailTemplates!=null) {
		 			 	FCFormUtils.sendEmailToUsersUsingTemplate(lUserIds, FcFormUTils.fcEmailTemplates.Dept_Head_Ready_For_Review_Template__c, summaryForm.Id);
		 			 }
		 			 
		 			 //update Summary Form status to Waiting for Department Head Review
		 			 if (summaryForm!=null) {
		 			 	//update Facilities Form directly
		 			 	if(Trigger.isBefore && fa.RecordTypeId == FCFormUtils.FacilitiesFcRecType){
		 			 		fa.Status__c = 'Waiting for Department Head Approval';
		 			 	} else {
		 			 		summaryForm.status__c = 'Waiting for Department Head Approval';
		 			 		forUpdate.add(summaryForm);
		 			 	}
		 			 	//summaryForm.status__c = 'Waiting for Department Head Approval';
		 			 	//forUpdate.add(summaryForm);
		 			 }
 		 			tasks.add(new Task(WhatId = fa.Summary_FC_Form__c, Subject = 'Email: Submitted for Dept Head Review', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'FC Form submitted to Dept Head Review, email sent.', Type = 'Email'));
		 		}
		 	
	 		  }
 		}
	}
 } //end loop through each form
 
 if (aItemsForUpdate.size()>0) update aItemsForUpdate;
 if (forUpdate.size()>0)  update forUpdate;    
 if (fas.size()>0) insert fas;
 if (tasks.size()>0) insert tasks;
 	    
}