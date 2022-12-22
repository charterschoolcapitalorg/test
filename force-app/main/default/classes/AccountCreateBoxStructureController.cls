public class AccountCreateBoxStructureController {
    
    
    public Account acct {get;set;}
    public Id objectId {get;set;}
	    
    public PAgeReference back(){
      PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
    
   public AccountCreateBoxStructureController(ApexPages.StandardController thecontroller) {
   		acct = (Account)thecontroller.getRecord();
        acct = [Select Id From Account Where Id=:acct.Id];
        objectId = acct.Id;
   }
   
    
    public PageReference execute() {
    	try {
    		BoxAPIUtils.createAcctFolders(acct.Id);
    	} catch (EXception e) {
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Could not create Folders: ' +e.getmessage() + e.getstacktracestring());
			ApexPages.addMessage(myMsg);
			return null;	
    	}
    	
    	 		
     	PageReference page = new PageReference('/'+objectId);
	    page.setRedirect(true);            
	    return page;
     	
     	
    }
    
}