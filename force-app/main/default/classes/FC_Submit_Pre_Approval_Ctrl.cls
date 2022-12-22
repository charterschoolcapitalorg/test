public with sharing class FC_Submit_Pre_Approval_Ctrl {
    
    public FC_Form__c form {get;set;}
    public Id objectId {get;set;}
    public String  msg {get;set;}
    public boolean cancreate {get;set;}
    public static boolean isbeingrejected {get;set;}
    public static boolean isbeingapproved {get;set;}
    public boolean confirmation {get;set;}
    
    
    public PAgeReference approve(){
    	System.debug('**** in approve');
        isbeingapproved = true;
        if (confirmation==null) confirmation = false;
        
            if (form.status__c!='Waiting For Pre Approval'  && form.status__c!='Pre Approval Not Approved') {
                msg = 'FC Form status: ' + form.status__c + '.  Pre-FC Approval is no longer Open.  You cannot Approve';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,msg);
                ApexPages.addMessage(myMsg );
                confirmation = false;
                return null;
            }
            
            List<FC_Approval__c> fas = [Select id, status__c from FC_Approval__c 
            	where Approver__c=:UserInfo.getUserId() 
            	and FC_Form__c=:objectId
            	and Type__c='Pre-FC Approval' and Is_Current__c = true];
            
            if (fas.size()==0) {
            	msg = 'No Pending approvals were found.  You cannot approve.  Please contact the System Administator';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,msg);
                ApexPages.addMessage(myMsg );
                return null;
                
            } else {
            	boolean exists = false;
            	for (FC_Approval__c exist : fas) {
            		if (exist.Status__c=='Not Approved') exists = true; 
            	}
            	
            	if (exists&&!confirmation) {
            		confirmation = true;
            		msg = 'You already marked this as Not Approved.  Are you sure you want to Approve?';
	                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,msg);
	                ApexPages.addMessage(myMsg );
	                return null;
            	}
            	
            	/*for (FC_Approval__c fa : fas) {
            		fa.status__c='Approved';
            	}
            	update fas;*/
            }	
        
            
        //PageReference page = new PageReference('/'+objectId);
        PageReference page = new PageReference('/apex/FC_Approval_Update?id='+fas[0].ID+'&retUrl=/'+form.Id);
        page.setRedirect(true);            
        return page;
    }
    
    public PAgeReference reject(){
    	System.debug('**** in reject');
        isbeingrejected = true;
        if (confirmation==null) confirmation = false;
        
        	if (form.status__c!='Waiting For Pre Approval'  && form.status__c!='Pre Approval Not Approved' && form.status__c!='In Progress'   ) {
                msg = 'FC Form status: ' + form.status__c + '.  Pre-FC Approval is no longer Open.  You cannot Reject';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,msg);
                ApexPages.addMessage(myMsg );
                confirmation = false;
                return null;
            }
            
            List<FC_Approval__c> fas = [Select id, status__c from FC_Approval__c 
            	where Approver__c=:UserInfo.getUserId() 
            	and FC_Form__c=:objectId 
            	and Type__c='Pre-FC Approval' and Is_Current__c = true];
            	
            if (fas.size()==0) {
            	msg = 'No Pending approvals were found.  You cannot Reject.  Please contact the System Administator';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,msg);
                ApexPages.addMessage(myMsg );
                return null;
            } else {
            	boolean exists = false;
            	for (FC_Approval__c exist : fas) {
            		if (exist.Status__c=='Approved'  || exist.Status__c=='Approved with Contingencies') exists = true; 
            	}
            	if (exists&&!confirmation) {
            		confirmation = true;
            		msg = 'You already marked this as Approved.  Are you sure you want to Not Approve?';
	                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,msg);
	                ApexPages.addMessage(myMsg );
	                return null;
            	}
            	
            	/*
            	for (FC_Approval__c fa : fas) {
            		fa.status__c='Not Approved';
            	}
            	update fas;
            	*/
            }	
            
            //Notify the opp team, FC Team, Department Heads
        
        //PageReference page = new PageReference('/'+objectId);
        PageReference page = new PageReference('/apex/FC_Approval_Update?id='+fas[0].ID+'&retUrl=/'+form.Id + '&status=Not Approved');
        page.setRedirect(true);            
        return page;
    
    }
    
    
    public PAgeReference create(){
        System.debug('**** in create confirmation: ' + confirmation);
        List<Task> tasks = new List<Task>();

        if (confirmation==null) confirmation = false;

        //validations
        if (!confirmation) {
    		if (form.Approval_Tier__c==null) {
        		msg = 'WARNING:  Approval Tier needs to be filled in before you can Submit For Pre-FC Approval';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,msg);
                ApexPages.addMessage(myMsg );
                cancreate = false;
                confirmation = true;
                return null;
    		}
        		
    		if (form.status__c!='In Progress' && form.status__c!='Pre Approval Not Approved') {
                msg = 'FC Form status is not In Progress or Pre Approval Not Approved.  You cannot submit for Pre FC Approval';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,msg);
                ApexPages.addMessage(myMsg );
                cancreate = false; 
                confirmation = true;   
                return null;
            }
        	
        	//prompts
            List<FC_Approval__c> fas = [Select id, status__c from FC_Approval__c 
                	where Type__c='Pre-FC Approval' 
                	and FC_Form__c=:objectId and status__c='Approved'];
            if (fas.size()>=3) {
            	msg = 'This form has already been Approved for Pre-FC Approval, are you sure you want submit again?';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,msg);
                ApexPages.addMessage(myMsg );
                confirmation = true;
                return null;
            }  

            if (form.Account_Strategy__c==null|| form.Client_Update__c ==null ||form.AM_Additional_Information__c==null ) {
                Set<String> flds = new Set<STring>();
                
                if (form.Account_Strategy__c==null) flds.add('Account Strategy');
                if (form.AM_Additional_Information__c==null) flds.add('AM Additional Information');
                if (form.Client_Update__c==null) flds.add('Client Strategy');
                //if (form.Date_PreparedInitials__c==null) flds.add('Date Prepared/Initials');
                
                msg = 'WARNING:  The following fields are not filled in: ' + flds + '. Are you sure you want to Submit for Pre-FC Approval?';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,msg);
                ApexPages.addMessage(myMsg );
                confirmation = true;
                return null;
            }
        }
        Map<Id,Id> users = new Map<Id,Id>();
        if (form.approval_tier__c=='Working Capital') {
        	users = FCFormUtils.getUsersFromGroup('FC_Approvers_WC');
        }  else if (form.approval_tier__c=='Facilities') {
        	users = FCFormUtils.getUsersFromGroup('FC_Approvers_FAC');
        }
        
        List<FC_Approval__c> fas = new List<FC_Approval__c >();
        for (Id i : users.keyset()) {
            FC_Approval__c f = new FC_Approval__c(Approver__c=i, FC_Form__c=objectId, Status__c='Pending', 
            	Type__c='Pre-FC Approval');
            //f.OwnerId=i;
            fas.add(f);
        } 
        
        
        //deactivate old pre fc approvals if they exist
        List<FC_Approval__c> exist = [Select id, status__c, is_current__c from FC_Approval__c 
            	where FC_Form__c=:objectId and Type__c='Pre-FC Approval' and Is_Current__c = true];
        for (FC_Approval__c f : exist){
            f.is_current__c = false;
        }

        if (exist.size()>0) update exist;    	
        
            	
        //FCFormUtils.sendEmailToGroupUsingTemplate('Test - submitted for Pre-FC approval', 'Submitted for Pre-FC Approval', 'FC Approval Tier '+form.Approval_Tier__c);
        if (FCFormUtils.fcEmailTemplates!=null) {
        	
	        if (form.approval_tier__c=='Working Capital') {
	        	FCFormUtils.sendEmailToGroupUsingTemplate('FC_Approvers_WC', FcFormUTils.fcEmailTemplates.PreFC_Ready_Template__c, form.Id);
	        }  else if (form.approval_tier__c=='Facilities') {
	        	FCFormUtils.sendEmailToGroupUsingTemplate('FC_Approvers_FAC', FcFormUTils.fcEmailTemplates.PreFC_Ready_Template__c, form.Id);
	        }
            tasks.add(new Task(WhatId = form.Id, Subject = 'Email: FC Pre-Approval Requested', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'FC Pre-Approval Requested, email sent.', Type = 'Email'));
        	
        }
        
        insert fas;
        insert tasks;
        
        form.status__c = 'Waiting For Pre Approval';
        update form;
        
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
    
    public PAgeReference back(){
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
   
    public PAgeReference resubmitfinal(){
		SYstem.debug('****in resubmitfinal');
		
        List<Task> tasks = new List<Task>();
       
	   	if (form.status__c!='Final Approval Not Approved') {
	                msg = 'FC Form status must be Final Approval Not Approved in order to resubmit.';
	                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,msg);
	                ApexPages.addMessage(myMsg );
	                return null;
        }
    	
        //deactivate old final fc approvals if they exist
        List<FC_Approval__c> exist = [Select id, status__c, is_current__c from FC_Approval__c 
            	where FC_Form__c=:objectId and Type__c='Final FC Approval' and Is_Current__c = true];
        for (FC_Approval__c f : exist) {
            f.is_current__c = false;
        }
        if (exist.size()>0) update exist;   
        SYstem.debug('****deactivate old final fc approvals: ' + exist);
           
        Map<Id,Id> users = new Map<Id,Id>();
        if (form.approval_tier__c=='Working Capital') {
            users = FCFormUtils.getUsersFromGroup('FC_Approvers_WC');
        } else if (form.approval_tier__c=='Facilities') {
        	users = FCFormUtils.getUsersFromGroup('FC_Approvers_FAC');
        }
           
        SYstem.debug('****users: ' + users);
        
        List<FC_Approval__c> fas = new List<FC_Approval__c >();
		for (Id i : users.keyset()) {
	 		FC_Approval__c f = new FC_Approval__c(Approver__c=i,Is_Current__c = true, FC_Form__c=form.Id, Status__c='Pending', 
		            	Type__c='Final FC Approval');
	        fas.add(f);
		}

		if (fas.size()>0) insert fas; 	
        SYstem.debug('****created final approvals: ' + fas);
        
        if (FCFormUtils.fcEmailTemplates!=null) {
        	if (form.approval_tier__c=='Working Capital') {
	        	FCFormUtils.sendEmailToGroupUsingTemplate('FC_Approvers_WC', FcFormUTils.fcEmailTemplates.Dept_Head_Approved_Template__c, form.Id);
	        } else if (form.approval_tier__c=='Facilities') {
	        	FCFormUtils.sendEmailToGroupUsingTemplate('FC_Approvers_FAC', FcFormUTils.fcEmailTemplates.Dept_Head_Approved_Template__c, form.Id);
	        }
            tasks.add(new Task(WhatId = form.Id, Subject = 'Email: FC Pre-Approval resubmitted', ActivityDate = Date.today(), Status = 'Completed', Priority = 'Normal', Description = 'FC Pre-Approval resubmitted, email sent.', Type = 'Email'));
	
        }
        insert tasks;

        form.status__c = 'Waiting For Final Approval';
        update form;
        
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page;
        
    }
   
    public FC_Submit_Pre_Approval_Ctrl(ApexPages.StandardController thecontroller) {
        form = (FC_Form__c)thecontroller.getRecord();
        form = [Select Id, opportunity__c, Status__c, RecordTypeId, Account_Strategy__c, Client_Update__c, AM_Additional_Information__c, 
        	Total_Fund_Receiv_FV_Amount__c, Approval_Tier__c from FC_Form__c where Id=:form.Id];
        objectId = form.Id;
    	cancreate = true;
    	
    	//if page being loaded for Submitting for PRe FC Approval
    	System.debug('*** isbeingrejected: ' + isbeingrejected);
    	System.debug('*** isbeingapproved: ' + isbeingapproved);
    		
    }
   
}