public with sharing class FC_Refresh_Comments_Ctrl {
    
    public FC_Form__c form {get;set;}
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
        List<FC_FOrm__c> forms = new List<FC_FOrm__c>();
        forms.add(form);
        //2019.03.05 J Caughie - Catch error for field updates
        try{ 
            FCFOrmUtils.populateHeaderCommentFieldsFromSFData(forms);
        } catch (Exception e){
            return null;
        }           
             
        return page; 
    }
    
   public FC_Refresh_Comments_Ctrl(ApexPages.StandardController thecontroller) {
        form = (FC_Form__c)thecontroller.getRecord();
        form = [Select Id, opportunity__c, RecordTypeId, Total_Fund_Receiv_FV_Amount__c from FC_Form__c where Id=:form.Id];
        objectId = form.Id;
        
        if (FCFOrmUtils.UWFcRecType==form.RecordTypeId) {
    		msg = 'Oustanding Info Needed For Funding - UW, Underwriting Risks and Mitigants, Underwriting Review Comments, Underwriting Recomendation';
        } else if (FCFOrmUtils.FinanceFcRecType==form.RecordTypeId) {
        	msg = 'Oustanding Info Needed For Funding - FIN, Current Funding Comments, Financial Review Comments, State Specific Finance Comments, Current Year Surplus/Deficit, Net Assets, Indebtedness, Funding Plan, Audit Findings';
        } else if (FCFOrmUtils.SummaryFcRecType==form.RecordTypeId) {
        	msg = '';
        } else if (FCFOrmUtils.ServicingFcRecType==form.RecordTypeId) {
           msg = 'Oustanding Info Needed For Funding - SVC, Funding Exposure Comments';	
        } 
        msg = 'WARNING:  The following fields will be updated - ' + msg ;
    	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,msg);
    	ApexPages.addMessage(myMsg );
    	
    	myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'**** Do not click Refresh if you do not want them refreshed');
    	ApexPages.addMessage(myMsg );
    	
   }
 
}