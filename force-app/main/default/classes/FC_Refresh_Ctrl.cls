public with sharing class FC_Refresh_Ctrl {
   
    public FC_Form__c form {get;set;}
    public Id objectId {get;set;}
    public String  msg {get;set;}
    
    public PAgeReference back(){
      PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
   
    public PAgeReference refresh(){
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);       
        
        //do refresh
        List<FC_FOrm__c> forms = new List<FC_FOrm__c>();
        forms.add(form);
        //2019.03.05 J Caughie - Catch error for field updates
        try{ 
            FCFOrmUtils.populateHeaderFieldsFromSFData(forms);
        } catch (Exception e){
            return null;
        }        
             
        return page; 
    }
    
    
    
    
   public FC_Refresh_Ctrl(ApexPages.StandardController thecontroller) {
        form = (FC_Form__c)thecontroller.getRecord();
        form = [Select Id, opportunity__c, RecordTypeId, Total_Fund_Receiv_FV_Amount__c from FC_Form__c where Id=:form.Id];
        objectId = form.Id;
        
        if (FCFOrmUtils.UWFcRecType==form.RecordTypeId) {
            msg = 'Charter Holder, State, Management Company, SOS Good Standing, Enrollment Cap By Site, Certified Articles Of Incorporation, UCC Search Results, County Level Lien Search Results';
                
        } else if (FCFOrmUtils.FinanceFcRecType==form.RecordTypeId) {
            msg = 'Current Year Surplus/Deficit, Net Assets, Indebtedness, Audit Findings, Transaction Fee, Current Funding Face Value, Maximum Deferred Purchase Price, Deferred Purchase Amount, Current Attendance, Attendance Trends, Annual Estimated Budget, GRV Left On Board, FV Left On Board, RPA Initial, RPA Remaining, RPA Expiration Date, Program Fee, Fee Collected (this transaction),  Initial Draw, Total Maximum Loan Amount, Interest Rate, Commitment Fee, Last Draw Date, Maturity Date';
        } else if (FCFOrmUtils.SummaryFcRecType==form.RecordTypeId) {
            msg = 'Funding Date,Account Manager, Date CS Last Visited School, Account Strategy, Client Update';
        } else if (FCFOrmUtils.ServicingFcRecType==form.RecordTypeId) {
           msg = 'Total Exposure, Number of Receivables Outstanding, Number Payments Outstanding Post Funding, Past Due Amounts';   
        } 
        msg = 'WARNING:  The following fields will be updated - ' + msg ;
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,msg);
        ApexPages.addMessage(myMsg );
        
        myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'**** Do not click Refresh if you do not want them refreshed');
        ApexPages.addMessage(myMsg );
        
   }
   
}