public class FC_Details_Ctrl {
	
    public FC_Details__c details {get;set;}
    public Id objectId {get;set;}
    public String  msg {get;set;}
    //public Map<Id,Id> uwUsers {get;set;}
    //public Map<Id,Id> finUsers {get;set;}
    public List<User> uwUsers {get;set;}
    public List<User> finUsers {get;set;}
    public List<User> svcUsers {get;set;}
    public User deptHead {get;set;}
    public List<SelectOption> users { get; set; }
    public String selectedUser { get; set; }
    
    
     public PAgeReference submitForReview(){
        //mark FC Detail as subbmtied for review, but no emails are sent yet
        if (selectedUser=='-- Select --') {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select a Reviewer');
            ApexPages.addMessage(myMsg );
            return null;
        } else {
	        details.Submitted_For_Review__c = true;
	        details.Reviewer__c = selectedUser;
	        update details;
	        
	        PageReference page = new PageReference('/'+objectId);
	        page.setRedirect(true);            
	        return page;
        } 
    }
    
    public PAgeReference back(){
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
   
    
   public FC_Details_Ctrl(ApexPages.StandardController thecontroller) {
        details = (FC_Details__c)thecontroller.getRecord();
        details = [Select Id from FC_Details__c where Id=:details.Id];
        objectId = details.Id;
        
        
        Map<Id,Id> uu = FcFormUtils.getUsersFromGroup('FC_Pre_Approvers_UW');
        Map<Id,Id> finu = FcFormUtils.getUsersFromGroup('FC_Pre_Approvers_FIN');
        Map<Id,Id> svcu = FcFormUtils.getUsersFromGroup('FC_Pre_Approvers_SVC');
        users = new List<SelectOption>();
        users.add(new SelectOption('-- Select --', '-- Select --'));
        
        uwUsers = [Select Id, Servicing_Dept_Head__c, Underwriting_Dept_Head__c, Finance_Dept_Head__c, Name from User where ID IN: uu.keyset() ];
        for (User u : uwUSers) {
        	if (details.recordtypeid==FcFOrmUtils.UWFcDetailRecType && u.Underwriting_Dept_Head__c) {
        		deptHEad = u;
        	}
        	users.add(new SelectOption(u.Id, u.name));
            
        }
        finUsers = [Select Id, Servicing_Dept_Head__c, Underwriting_Dept_Head__c, Finance_Dept_Head__c, Name from User where ID IN: finu.keyset() ];
        for (User u : finUsers) {
        	if (details.recordtypeid==FcFOrmUtils.FinanceFcDetailRecType && u.Finance_Dept_Head__c) {
        		deptHEad = u;
        	}
        	users.add(new SelectOption(u.Id, u.name));
        }
        svcUsers = [Select Id, Servicing_Dept_Head__c, Underwriting_Dept_Head__c, Finance_Dept_Head__c, Name from User where ID IN: svcu.keyset() ];
        for (User u : svcUsers) {
        	if (details.recordtypeid==FcFOrmUtils.ServicingFcDetailRecType && u.Servicing_Dept_Head__c) {
        		deptHEad = u;
        	}
        	users.add(new SelectOption(u.Id, u.name));
        }
        if (deptHEad!=nulL) selectedUser = deptHEad.Name;
        
   }
}