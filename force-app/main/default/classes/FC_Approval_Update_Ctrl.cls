public class FC_Approval_Update_Ctrl {
    
    public FC_Approval__c approval {get;set;}
    public Id objectId {get;set;}
    public List<SelectOption> statusOptions { get; set; }
    public String selectedStatus { get; set; }
    
    public void getStatusOptions() {
            
            Set<String> typesSet = new Set<String>();
            
            typesSet.add('Approved');                
            typesSet.add('Approved with Contingencies'); 
                typesSet.add('Not Approved'); 
        
            List<String> types = new List<String>(typesSet); 
            statusOptions = new List<SelectOption>();
            types.sort();                       
            
            for (String t : types)
                statusOptions.add(new SelectOption(t, t));
            
            statusOptions.add(0, new SelectOption('-- Select --', '-- Select --'));

    }

    
    public PAgeReference back(){
                String retUrl;
                PageReference page;
                try {
                   retUrl = ApexPages.currentPage().getParameters().get('retURL');
                } catch (EXception e) {}
                if (retUrl!=null) {
                        page = new PageReference(retUrl);
                } else {
                        page = new PageReference('/'+objectId);
                }
            page.setRedirect(true);            
            return page; 
    }
   
    public PAgeReference submit(){
        if (selectedStatus=='-- Select --') {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select a Status');
            ApexPages.addMessage(myMsg );
            
            return null;
        } else if(selectedstatus=='Approved with Contingencies'&& approval.Contingencies__c==null) {
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please add the Contingencies');
                ApexPages.addMessage(myMsg );
                return null;
        } else if(selectedstatus=='Not Approved'&& approval.comments__c==null) {
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You must provide an explanation for the Not Approved decision in the Comments field');
                ApexPages.addMessage(myMsg );
                return null;
        } else {
            approval.status__c = selectedStatus;
                update approval;
                
                String retURL;
                PageReference page;
                try {
                        retUrl = ApexPages.currentPage().getParameters().get('retURL');
                } catch (EXception e) {}
                if (retUrl!=null) {
                        page = new PageReference(retUrl);
                } else {
                        page = new PageReference('/'+objectId);
                }
            page.setRedirect(true);            
            return page; 
        }
        
    }
    
   public FC_Approval_Update_Ctrl(ApexPages.StandardController thecontroller) {
        approval = (FC_Approval__c)thecontroller.getRecord();
        approval = [Select Id, Comments__c, Contingencies__c, Status__c, Contingency_Fulfillment_Timeline__c from FC_Approval__c where Id=:approval.Id];
        getStatusOptions();
        objectId = approval.Id; 
        try {
                        String defaultStatus = ApexPages.currentPage().getParameters().get('status');
                        selectedStatus = defaultStatus;
        } catch (EXception e) {}
   }
   
}