public with sharing class FC_Refresh_Details_Comments_Ctrl {
    
    public FC_Details__c detail {get;set;}
    public Id objectId {get;set;}
    public String  msg {get;set;}
    
    public PAgeReference back(){
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
   
    public PAgeReference refreshComments(){
      	PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);       
        
        //do refresh
        List<FC_Details__c> details = new List<FC_Details__c>();
        details.add(detail);
        //2019.03.05 J Caughie - Catch error for field updates
        try{ 
            FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);
        } catch (Exception e){
            return null;
        }
        

        return page; 
    }
    
   public FC_Refresh_Details_Comments_Ctrl(ApexPages.StandardController thecontroller) {
        detail = (FC_Details__c)thecontroller.getRecord();
        detail = [Select Id, FC_Form__c, RecordTypeId, Opp_School__c from FC_Details__c where Id=:detail.Id];
        objectId = detail.Id;
        
         if (FCFOrmUtils.UWFcDetailRecType==detail.RecordTypeId) {
    		msg = 'Academic Performance Comments, School Profile Comments, State Specific Comments, Underwriting EWS Comments';
        } else if (FCFOrmUtils.FinanceFcDetailRecType==detail.RecordTypeId) {
        	msg = 'Current Funding Comments, Financial Review Comments, Finance EWS Comments, Current Year Surplus/Deficit, Net Assets, Indebtedness';
        } else if (FCFOrmUtils.ServicingFcDetailRecType==detail.RecordTypeId) {
        	msg = 'Servicing Comments, Funding Exposure Comments';
        } 
        
    	msg = 'WARNING:  The following fields will be updated - ' + msg ;
    	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,msg);
    	ApexPages.addMessage(myMsg );
    	
    	myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'**** Do not click Refresh if you do not want them refreshed');
    	ApexPages.addMessage(myMsg );
    
   }
}