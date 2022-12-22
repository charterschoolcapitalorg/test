public with sharing class TestOppEditCtrl {
    public Opportunity opp {get;set;}
    public List<Contact> cons {get;set;}
    public Id objectId {get;set;}
    public boolean disabled {get;set;}
    
   public TestOppEditCtrl(ApexPages.StandardController thecontroller) {
        opp = (Opportunity)thecontroller.getRecord();
        objectId = opp.Id;
        disabled = true;
        
        opp = [Select Id, AccountId, Name, StageName, Account.ParentId  From Opportunity Where Id=:opp.Id ];
   		
   }
   
   public PageReference back() {
   		/*
   		Approval.unlock(opp.Id);
   		*/
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page;
        
    }
    
    
    public PageReference getLock() {
    	/*
    	if (Approval.isLocked(opp.id)) {
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Record is already being edited ');
	        ApexPages.addMessage(myMsg);
    	} else {
	   		Approval.LockResult lrList = Approval.lock(opp, false);
	   		
	   		//for(Approval.LockResult lr : lrList) {
			    if (lrList.isSuccess()) {
			        // Operation was successful, so get the ID of the record that was processed
			        System.debug('Successfully locked account with ID: ' + lrList.getId());
			        disabled = false;
			    }
			    else {
			        // Operation failed, so get all errors                
			        for(Database.Error err : lrList.getErrors()) {
			        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Error getting lock: ' + err.getStatusCode() + ': ' + err.getMessage());
	                    ApexPages.addMessage(myMsg);
	                    
			            System.debug('The following error has occurred.');                    
			            System.debug(err.getStatusCode() + ': ' + err.getMessage());
			            System.debug('Account fields that affected this error: ' + err.getFields());
			        }
			    }
			//}
    	}
    	*/
		return null;
    }
    
    public PageReference save() {
    	/*disabled = true;
    	
    	Approval.unlock(opp.Id);
    	
    	update opp;
    	*/
    	return null;
    }
}