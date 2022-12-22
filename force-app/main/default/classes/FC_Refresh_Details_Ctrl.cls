public with sharing class FC_Refresh_Details_Ctrl {
     
    public FC_Details__c detail {get;set;}
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
        List<FC_Details__c> details = new List<FC_Details__c>();
        details.add(detail);
        //2019.03.05 J Caughie - Catch error for field updates
        try{ 
            FCFOrmUtils.populateDetailFieldsFromSFData(details);
        } catch (Exception e){
            return null;
        }
                     
        return page; 
    }
    
    
   public FC_Refresh_Details_Ctrl(ApexPages.StandardController thecontroller) {
        detail = (FC_Details__c)thecontroller.getRecord();
        detail = [Select Id, FC_Form__c, RecordTypeId, Opp_School__c from FC_Details__c where Id=:detail.Id];
        objectId = detail.Id;
        
         if (FCFOrmUtils.UWFcDetailRecType==detail.RecordTypeId) {
            msg = 'School Name, Charter Term, School Open Date, Enrollment Cap By Site, First Day of School this Academic Year, Grades Served, Lease Term, Authorizer, Academic Performance, Charter Good Standing, EWS Level, Concerning Google Alert, Indication of Closure, Management Changes in the Last Year';
        } else if (FCFOrmUtils.FinanceFcDetailRecType==detail.RecordTypeId) {
            msg = 'Current Year Surplus/Deficit, Net Assets, Indebtedness, EWS Level, Pricing, Transaction Fee, Current Funding Face Value, Maximum Deferred Purchase Price, Deferred Purchase Amount, Current Attendance, Attendance Trends, Annual Estimated Budget, Receivables Description, Concerning Google Alert, Indication of Closure, Management Changes in the Last Year ';
        } else if (FCFOrmUtils.ServicingFcDetailRecType==detail.RecordTypeId) {
            msg = 'Intercept Type, FDA Status, Total Exposure, Number of Receivables Outstanding, Number Payments Outstanding Post Funding, Past Due Amounts';
        } 
        
        msg = 'WARNING:  The following fields will be updated - ' + msg ;
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,msg);
        ApexPages.addMessage(myMsg );
        
        myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'**** Do not click Refresh if you do not want them refreshed');
        ApexPages.addMessage(myMsg );
    
   }
}