public class OppCreateBoxStructureController {
    
    public Opportunity opp {get;set;}
    public Id objectId {get;set;}
        
    public PAgeReference back(){
      PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
    
   public OppCreateBoxStructureController(ApexPages.StandardController thecontroller) {
        opp = (Opportunity)thecontroller.getRecord();
        opp = [Select Id From Opportunity Where Id=:opp.Id];
        objectId = opp.Id;
   }
   
    
    public PageReference execute() {
        try {
            BoxAPIUtils.createOppFoldersNotFuture(opp.Id);
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