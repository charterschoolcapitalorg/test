public class IntakeItemWrapper implements Comparable {
    	@AuraEnabled
		public Intake_Item__c item {get;set;}
		@AuraEnabled
		public boolean hasChildren {get;set;}
		@AuraEnabled
		public boolean hasParent {get;set;}
		@AuraEnabled
		public boolean isReadOnly {get;set;}
		@AuraEnabled
		public boolean isPQSubmitted {get;set;}

		@AuraEnabled
		public Integer numUnsubmittedDocs {get;set;}
		
    	@AuraEnabled
		public Integer numChildrenAccepted {get;set;}
    	
    	@AuraEnabled
		public Integer numChildren {get;set;}
    	
    	@AuraEnabled
		public boolean allChildrenAccepted {get;set;}
    
		@AuraEnabled
		public String assignedToName {get;set;}

		@AuraEnabled
		public String oppName {get;set;}

		@AuraEnabled
		public boolean assignedToCSC {get;set;}

		@AuraEnabled
		public boolean isOverdue {get;set;}

		@AuraEnabled
		public boolean hasOverdueChildren {get;set;}

		@AuraEnabled
		public List<IntakeItemWrapper> children {get;set;}

		@AuraEnabled
		public boolean isPQ {get;set;}
		@AuraEnabled
		public boolean isInfoSheet {get;set;}
		@AuraEnabled
		public boolean isActionDetail {get;set;}
		@AuraEnabled
		public boolean isActionEditDetail {get;set;}

		@AuraEnabled
		public String clientFriendlyStatus {get;set;}
		
		public IntakeItemWrapper() {

		}
		public IntakeItemWrapper(Intake_Item__c i, String role) {
			//STring communityUrl = Network.getLoginUrl(DiligenceVars.community.Id) ;
			//communityUrl = communityUrl.removeEnd('login');
			//System.debug('communityURL: ' + communityUrl);
			isPq = false;
			isInfoSheet = false;
			isActionDetail = false;
			isActionEditDetail = false;
			isPQSubmitted = false;
			assignedToCSC = false;
			isOverdue = false;
			hasOverdueChildren = false;
			oppName = i.Opportunity__r.Name;
			clientFriendlyStatus = DiligenceUtils.getClientFriendlyStatuses.get(i.Status__c);

			if (!(i.status__c==DiligenceVars.IntakePendingStatus || i.status__c==DiligenceVars.IntakeInputNeededStatus)) {
				isPQSubmitted = true;
			}
			System.debug('&&&&& intake item: '+i + ' for role: ' + role);
			System.debug('&&&&& intake items: '+i.Intake_Items__r);
			//System.debug('&&&&& assigned to: ' + i.assigned_to__c);
            
			if (
			DiligenceUtils.multiSelectFIeldContains(i.assigned_to__c,role )
			
			) {
                //System.debug('**assigned to: ' + i.Opportunity__r.Account.Name);
                assignedToName = i.Opportunity__r.Account.Name;	
			} else {
				assignedToName = i.assigned_to__c;
				assignedToCSC = true;
			}
			
			if (i.due__c&&!assignedToCSC&&(i.status__c==DiligenceVars.IntakePendingStatus || 
                          i.status__c==DiligenceVars.IntakeInputNeededStatus)) {
				isOverdue = true;
			}
			if (i.action_url__c==Diligencevars.IIActionDetails) {
				isActionDetail = true;
				//molinger 0417 change
				//i.action_url__c =  '';//communityUrl+'detail/'+i.Id;
			} else if (i.action_url__c==Diligencevars.IIActionEdit) {
				isActionEditDetail = true;
				//molinger 0417 change
				//i.action_url__c =  '';//communityUrl+'detail/'+i.Id;
			} else if (i.action_url__c==Diligencevars.IIActionForm) {
				if (i.Is_Pre_Qual__c) {
					isPQ = true;
				}
				if (i.name=='Information Sheet' || i.name=='Director & Officer Roster') {
					isInfoSheet = true;
				}
				//item.action_url__c =  '';
			} else if (i.action_url__c==Diligencevars.IIActionDocument) {
				//item.action_url__c =  '';
			}
			
			if (i.Parent_Intake_Item__c!=null) {
				System.debug('****intake item has parent'); 
				hasParent = true;
			} else hasparent = false;
			
			Integer numDOcs = 0;
            Integer numChildAccepted = 0;
			Integer numChild = 0;
			if (i.Intake_Items__r!=null&&i.Intake_Items__r.size()>0) {
				haschildren = true;
				
				List<IntakeItemWrapper> iws = new List<IntakeItemWrapper>();
				
				boolean overduechild = false;
				
				//handle child objects
				for (Intake_Item__c ic :  i.Intake_Items__r) {
                    numChild+=1;
					IntakeItemWrapper iw = new IntakeItemWrapper();	
                    if (
                    !DiligenceUtils.multiSelectFIeldContains(ic.Assigned_To__c,role )
                    ) {
                        System.debug('****child intake item is read only');
                        iw.isReadOnly = true;
                    } else {
                        System.debug('****child intake item is NOT read only');
                        iw.isReadOnly = false;
                    }
                    
					iw.item = ic;
					iw.assignedToCSC = false;
					iw.isActionEditDetail = false;
					iw.isPQSubmitted = false;
					iw.clientFriendlyStatus = DiligenceUtils.getClientFriendlyStatuses.get(ic.Status__c);
                    if (!(ic.status__c==DiligenceVars.IntakePendingStatus || 
                          ic.status__c==DiligenceVars.IntakeInputNeededStatus)) {
                            iw.isPQSubmitted = true;
                    }
                    if (
                    DiligenceUtils.multiSelectFIeldContains(ic.assigned_to__c,role ) 
                    ) {
                        iw.assignedToName = i.Opportunity__r.Account.Name;
                        
                    } else {
                        iw.assignedToName = ic.assigned_to__c;
                        iw.assignedToCSC = true;
                    }
                    
					if (ic.due__c&&!iw.assignedToCSC&&(ic.status__c==DiligenceVars.IntakePendingStatus || 
                          ic.status__c==DiligenceVars.IntakeInputNeededStatus)) {
						iw.isOverdue = true;
						overduechild = true;
					}
                    //System.debug('***Child for parent is due: ' + ic.due__c);
                    //System.debug('***iw.assignedToCSC: ' + iw.assignedToCSC);
					//System.debug('***Child is due: ' + iw.isOverdue);
                    
                    if (ic.status__c==Diligencevars.IntakeApprovedStatus ) {
                        numChildAccepted+=1;
                    }
					if (ic.status__c==Diligencevars.IntakePendingStatus || ic.status__c==Diligencevars.IntakeInputNeededStatus ) {
						numDOcs+=1;
					}
					
					if (ic.action_url__c==Diligencevars.IIActionDetails) {
						System.debug('***Child is action detail');
						iw.isActionDetail = true;
						iw.item.action_url__c =  '';//communityUrl+'detail/'+ic.Id;
					} else if (ic.action_url__c==Diligencevars.IIActionEdit) {
						System.debug('***Child is action edit detail');
						iw.isActionEditDetail = true;
						iw.item.action_url__c =  '';//communityUrl+'detail/'+ic.Id;
					} else if (ic.action_url__c==Diligencevars.IIActionForm) {
						System.debug('***Child is action form');
						if (ic.Is_Pre_Qual__c) {
							System.debug('***Child is PQ');
							iw.isPQ = true;
						}
						if (ic.name=='Information Sheet' || ic.name=='Director & Officer Roster') {
							System.debug('***Child is Info Sheet');
							iw.isInfoSheet = true;
						}
						//item.action_url__c =  '';
					} else if (i.action_url__c==Diligencevars.IIActionDocument) {
						//item.action_url__c =  '';
					}
					//System.debug('***child wrapper: ' + iw);
					iws.add(iw);
				}
				
				if (overduechild) {
					hasOverdueChildren = true;
					isoverdue = true;
				}
					
				children = iws;
				System.debug('****children: ' + children);
			}else haschildren = false;
			
			
			if (
			!DiligenceUtils.multiSelectFIeldContains(i.Assigned_To__c,role )
			) {
				System.debug('****intake item is read only');
				isReadOnly = true;
			} else {
				isReadOnly = false;
			}
			
			item = i;
            System.debug('****id: ' + i.id);
			numUnsubmittedDocs = numDOcs;
            System.debug('****numChildrenAccepted: ' +numChildAccepted);
            numChildrenAccepted = numChildAccepted;
            System.debug('****numChildren: ' +numChild);
            numChildren = numChild;
            if (numChildren==numChildrenAccepted) { allChildrenAccepted = true; } else allChildrenAccepted = false;
            System.debug('****allChildrenAccepted: ' +allChildrenAccepted);
		}
	
	public Integer compareTo(Object o) {
		IntakeItemWrapper that = (IntakeItemWrapper)o;

		if (this.item.Due_Date__c != null && that.item.Due_Date__c != null) {
			// sort by comparing date
			return
				this.item.Due_Date__c < that.item.Due_Date__c ? -1 :
				this.item.Due_Date__c > that.item.Due_Date__c ? 1 :
				0;
		}

		// sort null vs. non-null
		return
			this.item.Due_Date__c != null && that.item.Due_Date__c == null ? -1 :
			this.item.Due_Date__c == null && that.item.Due_Date__c != null ? 1 :
			0;
	}
}