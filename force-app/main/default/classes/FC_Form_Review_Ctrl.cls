public class FC_Form_Review_Ctrl {
    
    public FC_Form__c form {get;set;}
    public Id objectId {get;set;}
    public String  msg {get;set;}
    //public Map<Id,Id> uwUsers {get;set;}
    //public Map<Id,Id> finUsers {get;set;}
    public List<User> uwUsers {get;set;}
    public List<User> finUsers {get;set;}
    public List<User> svcUsers {get;set;}
    public List<User> facUsers {get;set;}
    public User deptHead {get;set;}
    public List<SelectOption> users { get; set; }
    public String selectedUser { get; set; }
    public boolean cansubmit {get;set;}
    
    
     public PAgeReference submitForReview(){
        //mark FC Detail as subbmtied for review, but no emails are sent yet
        if (selectedUser=='-- Select --') {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select a Reviewer');
            ApexPages.addMessage(myMsg );
            return null;
        } else {
            form.Submitted_For_Review__c = true;
            form.Reviewer__c = selectedUser;
            update form;
            
            Id summFOrmId;
            FC_Form__c summform;
            
            //get summary form and update prepared by fields
            if (form.recordtypeid==FcFOrmUtils.FacilitiesFcRecType) {
            	summform = [Select Id, Date_Prepared_Fac__c, Prepared_By_FAC__c, Date_Prepared_Fin__c, Date_Prepared_SVC__c, Date_Prepared_UW__c, Prepared_By_FIN__c, Prepared_By_SVC__c, Prepared_By_UW__c from FC_Form__c where Id=:form.Id];
            	summFOrmId=form.Id;
            } else {
            	summform = [Select Id, Date_Prepared_Fac__c, Prepared_By_FAC__c, Date_Prepared_Fin__c, Date_Prepared_SVC__c, Date_Prepared_UW__c, Prepared_By_FIN__c, Prepared_By_SVC__c, Prepared_By_UW__c 
            		from FC_Form__c where Id=:form.Summary_FC_Form__c];
            	summFOrmId=sumMForm.Id;
            }
            
            if (form.recordtypeid==FcFOrmUtils.FacilitiesFcRecType ) {
                summform.Date_Prepared_FAC__c=date.today();
                summFOrm.Prepared_By_FAC__c=UserInfo.getUserId();
            }
            if (form.recordtypeid==FcFOrmUtils.UWFcRecType ) {
                summform.Date_Prepared_UW__c=date.today();
                summFOrm.Prepared_By_UW__c=UserInfo.getUserId();
            }
            if (form.recordtypeid==FcFOrmUtils.FinanceFcRecType) {
                summform.Date_Prepared_FIN__c=date.today();
                summFOrm.Prepared_By_FIN__c=UserInfo.getUserId();
            }
            if (form.recordtypeid==FcFOrmUtils.ServicingFcRecType) {
                summform.Date_Prepared_SVC__c=date.today();
                summFOrm.Prepared_By_SVC__c=UserInfo.getUserId();
            }
            
            update summFOrm;
            
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
   
    public PAgeReference init(){
    	
    	System.debug('****form: ' + form);
        
        if (form.Submitted_For_Review__c) {
        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This form has already been submitted for review');
            ApexPages.addMessage(myMsg );
            cansubmit = false;
            return null;
        }
        
        Map<Id,Id> uu = FcFormUtils.getUsersFromGroup('FC_Pre_Approvers_UW');
        Map<Id,Id> finu = FcFormUtils.getUsersFromGroup('FC_Pre_Approvers_FIN');
        Map<Id,Id> svcu = FcFormUtils.getUsersFromGroup('FC_Pre_Approvers_SVC');
        Map<Id,Id> facu = FcFormUtils.getUsersFromGroup('FC_Pre_Approvers_FAC');
        
        users = new List<SelectOption>();
        users.add(new SelectOption('-- Select --', '-- Select --'));
        
               
        List<User> deptHEads = [Select Id, Finance_Dept_Head__c , Underwriting_Dept_Head__c, Facilities_Dept_Head__c , Servicing_Dept_Head__c from User 
        	where Underwriting_Dept_Head__c = true or Finance_Dept_Head__c = true or Servicing_Dept_Head__c = true
        	or Facilities_Dept_Head__c = true];
        
        for (User dptHEad : deptHEads) {
        	if (form.recordtypeid==FcFOrmUtils.UWFcRecType && dptHEad.Underwriting_Dept_Head__c) {
                deptHEad = dptHEad;
            }
            if (form.recordtypeid==FcFOrmUtils.FinanceFcRecType && dptHEad.Finance_Dept_Head__c) {
                deptHEad = dptHEad;
            }
            if (form.recordtypeid==FcFOrmUtils.ServicingFcRecType && dptHEad.Servicing_Dept_Head__c) {
                deptHEad = dptHEad;
            }
            if (form.recordtypeid==FcFOrmUtils.FacilitiesFcRecType && dptHEad.Facilities_Dept_Head__c) {
                deptHEad = dptHEad;
            }
        }
        
        if (form.recordtypeid==FcFOrmUtils.UWFcRecType) {
        	
	        uwUsers = [Select Id, Servicing_Dept_Head__c, Underwriting_Dept_Head__c, Finance_Dept_Head__c, Name from User where ID IN: uu.keyset() and IsActive = true ];
	        for (User u : uwUSers) {
	            	users.add(new SelectOption(u.Id, u.name));            
	        }
	        System.debug('***uw users: ' + uwUsers.size());
        }
        
        if (form.recordtypeid==FcFOrmUtils.FinanceFcRecType) {
	        finUsers = [Select Id, Servicing_Dept_Head__c, Underwriting_Dept_Head__c, Finance_Dept_Head__c, Name from User where ID IN: finu.keyset() and IsActive = true];
	        for (User u : finUsers) {
	        		System.debug('*** adding finance user: ' + u.Id);
	            	users.add(new SelectOption(u.Id, u.name));
	            
	        }
	        System.debug('***finance users: ' + finUsers.size());
        }
        
        if (form.recordtypeid==FcFOrmUtils.ServicingFcRecType) {
	        //servicing doesnt select reviewer, just marks the froms as Submitted for Review
	        form.Submitted_For_Review__c = true;
            update form;
            
            FC_FOrm__c summFOrm;
            
            //get summary form and update prepared by fields
            summform = [Select Id, Date_Prepared_Fac__c, Prepared_By_FAC__c, Date_Prepared_Fin__c, Date_Prepared_SVC__c, Date_Prepared_UW__c, Prepared_By_FIN__c, Prepared_By_SVC__c, Prepared_By_UW__c 
            		from FC_Form__c where Id=:form.Summary_FC_Form__c];
            
            summform.Date_Prepared_SVC__c=date.today();
            summFOrm.Prepared_By_SVC__c=UserInfo.getUserId();
            update summForm;
            
	        PageReference page = new PageReference('/'+objectId);
	        page.setRedirect(true);            
	        return page; 
        	
        }
        
        if (form.recordtypeid==FcFOrmUtils.FacilitiesFcRecType) {
	        facUsers = [Select Id, Servicing_Dept_Head__c, Underwriting_Dept_Head__c, Finance_Dept_Head__c, Name from User where ID IN: facu.keyset() and IsActive = true];
	        for (User u : facUsers) {
	            users.add(new SelectOption(u.Id, u.name));                        
	        }
	        System.debug('***fac users: ' + facUsers.size());
        }
        
        System.debug('***dept head: ' + deptHead);
        if (deptHEad!=nulL) selectedUser = deptHEad.Id;
        
    	
    	return null;
        
    }
    
   public FC_Form_Review_Ctrl(ApexPages.StandardController thecontroller) {
   		cansubmit = true;
        form = (FC_Form__c)thecontroller.getRecord();
        form = [Select Id, Summary_FC_Form__c, recordtypeid, Submitted_For_Review__c from FC_Form__c where Id=:form.Id];
        System.debug('****form in FC_Form_Review_Ctrl: ' + form);
        objectId = form.Id;
        
        
   }

}