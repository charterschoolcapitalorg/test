public class OppMakeAllIntakeItemsVisibleController {
    
    public Opportunity opp {get;set;}
    public Id objectId {get;set;}
        
    public PAgeReference back(){
      PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
    
   public OppMakeAllIntakeItemsVisibleController (ApexPages.StandardController thecontroller) {
        opp = (Opportunity)thecontroller.getRecord();
        opp = [Select Id From Opportunity Where Id=:opp.Id];
        objectId = opp.Id;
   }
   
    
    public PageReference execute() {
        try {
            List<INtake_Item__c> ii = [Select Id, Is_Visible_To_Community__c from Intake_Item__c where Opportunity__c=:opp.Id and Is_Visible_To_Community__c = false];
            for (INtake_Item__c i : ii) {
                i.Is_Visible_To_Community__c  = true;
            }
            update ii;
        } catch (EXception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Could not update: ' +e.getmessage() + e.getstacktracestring());
            ApexPages.addMessage(myMsg);
            return null;    
        }
        
                
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page;
        
        
    }
    
}