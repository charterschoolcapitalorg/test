/**
* Created by Ivan Garcia on 3/26/2018.
*/

global class IntakeCommunityItemsCtrl {
    
    // these static variables hold values so we dont run too many queries from main lightning component
    public static Map<String,List<Intake_Item__c>> cachedItems = new Map<String,List<Intake_Item__c>>();
    public static User cachedUser;
    public static Set<Id> cachedValidOpps = new Set<Id>();
    public static String cachedRole = '';
    public static String ONGOING_DILIGENCE_RECTYPE = 'Ongoing Diligence';
    
        
    public IntakeCommunityItemsCtrl() {
        
    }
    //for testing because permissions dont work from test class
    global Id runningUserId;
    
    
    @AuraEnabled
    public String fundRecType {get; set;}
    
    @AuraEnabled
    public String fofRecType {get; set;}
     
    @AuraEnabled
    public String facRecType {get; set;}
    
    @AuraEnabled
    public String thisRecType {get; set;}
    
    @AuraEnabled
    public static IntakeCommunityItemsCtrl getRecTypes() {
     	IntakeCommunityItemsCtrl i = new IntakeCommunityItemsCtrl();
        
        i.fundRecType = RecordTypes.IDInitialFundingIntakeItem;
        i.facRecType = RecordTypes.IDFacilitiesIntakeItem;
        i.fofRecType = RecordTypes.IDFOFIntakeItem;
        
        return i;
    }
    
    
    @AuraEnabled
    public static List<Box_Read_Only_Shares__c> getFolders(){
        system.debug('enter - getFolders');
        User u;
        //if (!test.isrunningtest()) {
        	u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
        //} else {
        	//u  = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :runningUserId];
        //}
        
        system.debug('user '+u);
        system.debug('profile '+u.Profile.Name);
        system.debug('Contact_Id__c '+u.ContactId);
        
         
        STring role;
        
        if (test.isrunningtest()) {
        	role = 'School';
        } else {
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        role = drm.role__c;
        }
        system.debug('role: '+role);
        
        List<String> opps = getOppsForContactRole(u.ContactId, role);
        
        
        List<Box_Read_Only_Shares__c> folders = [SELECT id,Box_URL__c, Role__c, Opportunity__r.Name FROM Box_Read_Only_Shares__c WHERE Opportunity__c IN :opps AND Role__c =:role];
        
        system.debug('folders: '+folders);
        return folders;
    }

    
    @AuraEnabled
    public static List<String> getOppsForContactRole(String contactId, String role){
        system.debug('enter');
        
        
        List<String> opps = new List<String>();
        For(Community_Contact_Role__c item:[SELECT id,Opportunity__c,ROle__c FROM Community_Contact_Role__c WHERE Contact__c = :contactId and Role__c =:role]){
            opps.add(item.Opportunity__c);
        }
        system.debug('opps '+opps);
        return opps;
    }

    
    @AuraEnabled
    public static Opportunity getOppName(string oppId) {
        Opportunity opp = [SELECT Id, Name,Target_Wire_Date__c, Funded_Date__c,NET_Amount_Requested__c, Reporting_Value__c, Client_Facing_Opportunity_Name__c FROM Opportunity WHERE Id =: oppId];
        return opp;
    }
    
    @AuraEnabled
    public static List<IntakeItemWrapper> submitStatus(String iiId){
        Intake_Item__c ii = [SELECT id,status__c from Intake_Item__c where Id=:iiId];
        ii.status__c = DiligenceVars.IntakeSubmittedStatus;
        update ii;
        return getIntakes();
    }

    @AuraEnabled
    public static List<IntakeItemWrapper> acceptedStatus(String iiId){
        Intake_Item__c ii = [SELECT id,status__c from Intake_Item__c where Id=:iiId];
        ii.status__c = DiligenceVars.IntakeApprovedStatus;
        update ii;
        return getIntakes();
    }
    
    
    @AuraEnabled
    public static List<IntakeItemWrapper> getIntakes(){
		User u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
        
        system.debug('user '+u);
		
        STring role;
        
        if (test.isrunningtest()) {
        	role = 'School';
        } else {
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        role = drm.role__c;
        }
        system.debug('role: '+role);
        
        
        List<String> opps = getContactRole(u.ContactId, role);
        List<Intake_Item__c> loadIntake = [SELECT id, Comment_Required__c, 
        RecordTypeId,Opportunity__r.Target_Wire_Date__c, Opportunity__r.Account.Name, 
        Opportunity__r.AccountId,Visible_To__c, Comments__c, Is_Document__c, 
        Parent_Intake_Item__c, Action_URL__c,Name,OppName__c,Status__c,Is_Pre_Qual__c, 
        Status_Reason__c,Opportunity__r.Name,Due_Date__c,Document_Name__c,
        Assigned_To__c,Due__c,
        Processing_Order__c
                                           , (Select Id,Client_Facing_Item_Name__c,RecordTypeId,Opportunity__r.Account.Name, Opportunity__r.AccountId, Visible_To__c, Is_Document__c, Comments__c, Parent_Intake_Item__c, Name,Status__c,Opportunity__r.Name,Due_Date__c,Action_URL__c,Document_Name__c,
                                           Assigned_To__c,
                                           Due__c,Status_Reason__c, Is_Pre_Qual__c from Intake_Items__r WHERE (
                                           Assigned_To__c includes (:role) or 
                                           Visible_To__c includes (:role)) AND Is_Visible_To_Community__c = true) FROM Intake_Item__c WHERE (
                                           Assigned_To__c includes (:role) or 
                                           Visible_To__c includes (:role)) AND Opportunity__c IN:opps AND Is_Visible_To_Community__c = true ORDER BY Processing_Order__c];
        
        List<IntakeItemWrapper> wraps = new List<IntakeItemWrapper>();
        for (Intake_Item__c i : loadIntake) {
            wraps.add(new IntakeItemWrapper(i,role));
        }
        
        for (IntakeItemWrapper w : wraps) {
            System.debug('****wrapper object: ' + w);
            if (w.item.name=='Pre Qualification') {
            }
        }
        return wraps;
    }
    
    
    @AuraEnabled
    public static List<String> getContactRole(String contactId, String role){
        
        //Community_Contact_Role__c loadCCC = [SELECT id,Opportunity__c,ROle__c FROM Community_Contact_Role__c WHERE Contact__c = :u.contactid];
        List<String> opps = new List<String>();
        For(Community_Contact_Role__c item:[SELECT id,Opportunity__c,ROle__c FROM Community_Contact_Role__c WHERE Contact__c = :contactId AND ROle__c=:role]){
            opps.add(item.Opportunity__c);
        }
        return opps;
    }
    
    @AuraEnabled
    
    public static List<Opportunity> getClosedOpportunities(String JsonString){
    	List<String> result = new List<STring>();
        User u;
        u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
        
        system.debug('user '+u);
		 
        STring role;
        
        if (test.isrunningtest()) {
        	role = 'School';
        } else {
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        role = drm.role__c;
        }
        system.debug('role: '+role);
        
        List<String> oppids = getOppsForContactRole(u.ContactId, role);
        List<Opportunity> opps = [Select Id, CloseDate, Face_Value__c, Purchase_Price__c, IsClosed, IsWon, Target_Wire_Date__c, Funded_Date__c,NET_Amount_Requested__c,
	        Reporting_Value__c, Name, Client_Facing_Opportunity_Name__c, RecordTypeId, Account.Parent.Id, 
	        Account.Parent.Name from Opportunity where Id IN:oppids and IsWon=true ORDER BY Funded_Date__c DESC];
        system.debug('**Opps: ' + opps);
        return opps;
        
    }
    
	
     @AuraEnabled
    public static List<Opportunity> getOpportunities(String JsonString){
    	List<String> result = new List<STring>();
        User u;
        u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
        
        system.debug('user '+u);
		 
        STring role;
        
        if (test.isrunningtest()) {
        	role = 'School';
        } else {
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        role = drm.role__c;
        }
        system.debug('role: '+role);
        
        List<String> oppids = getOppsForContactRole(u.ContactId, role);
        List<Opportunity> opps = [Select Id, CloseDate, Face_Value__c, Purchase_Price__c, IsClosed, IsWon, Target_Wire_Date__c, Funded_Date__c,NET_Amount_Requested__c,
        Reporting_Value__c, Name, Client_Facing_Opportunity_Name__c, RecordTypeId, Account.Parent.Id, 
        Account.Parent.Name from Opportunity where Id IN:oppids ];
        system.debug('**Opps: ' + opps);
        return opps;
        
    }
    
    
    @AuraEnabled
    public static Map<String,List<IntakeItemWrapper>> getMapOpportunity(String JsonString){
        system.debug('GET THE JSON:' + JsonString);
        List<Object> intakeData = (List<Object>) JSON.deserializeUntyped(Jsonstring);
        Map<String,List<IntakeItemWrapper>> returnData = new Map<String, List<IntakeItemWrapper>>();
        List<IntakeItemWrapper> castList = new List<IntakeItemWrapper>();
        List<IntakeItemWrapper> tempList;
        //castList = (List<IntakeItemWrapper>)intakeData;
        Map<String, Object> data = new Map<String, Object>();
        
        For(Object item : intakeData){
            System.debug('***item in getmapopportunity: ' +item);
            data = (Map<String, Object>) item;
            IntakeItemWrapper wrap = new IntakeItemWrapper();
            Map<String, Object> intakeItem = (Map<String, Object>) data.get('item');
            
            // Build Intake Item
            Intake_Item__c newItem = new Intake_Item__c();
            newItem.Name = (string) intakeItem.get('Name');
            newItem.Id = (string) intakeItem.get('Id');
            newItem.Is_Pre_Qual__c = (boolean) intakeItem.get('Is_Pre_Qual__c');
            newItem.Action_URL__c = (string) intakeItem.get('Action_URL__c');
            newItem.Status__c = (string) intakeItem.get('Status__c');
            newItem.Status_Reason__c = (string) intakeItem.get('Status_Reason__c');
            newItem.RecordTypeId = (string) intakeItem.get('RecordTypeId');
            
            // Date mydate = date.valueOf(intakeItem.get('Due_Date__c'));
            string rawDueDate = (string)intakeItem.get('Due_Date__c');
            date dueDate;
            if(rawDueDate != null) {
                newItem.Due_Date__c = date.valueOf(rawDueDate);
                //dueDate = date.valueOf(rawDueDate);
            }
            //newItem.Due_Date__c = date.valueOf(rawDueDate);
            
            newItem.Comments__c = (string) intakeItem.get('Comments__c');
            //newItem.Opportunity__c = (string) intakeItem.get('Opportunity__c'); ** throwing error
            newItem.CSC_Action_Item__c = (string) intakeItem.get('CSC_Action_Item__c');
            newItem.Submitted_Date__c = (date) intakeItem.get('Submitted_Date__c');
            newItem.Approved_Date__c = (date) intakeItem.get('Approved_Date__c');
            newItem.Approved_By__c = (string) intakeItem.get('Approved_By__c');
            newItem.Submitted_By__c = (string) intakeItem.get('Submitted_By__c');
            newItem.Stop_Number__c = (double) intakeItem.get('Stop_Number__c');
            newItem.Parent_Intake_Item__c = (string) intakeItem.get('Parent_Intake_Item__c');
            newItem.Assigned_To__c = (string) intakeItem.get('Assigned_To__c');
            newItem.Visible_To__c = (string) intakeItem.get('Visible_To__c');
            newItem.Is_Document__c = (boolean) intakeItem.get('Is_Document__c');
            newItem.Document_Name__c = (string) intakeItem.get('Document_Name__c');
            newItem.Processing_Order__c = (double) intakeItem.get('Processing_Order__c');
            newItem.Box_Folder_Id__c = (string) intakeItem.get('Box_Folder_Id__c');
            newItem.Facilities_Client_Type__c = (string) intakeItem.get('Facilities_Client_Type__c');
            
            
            Map<String, Object> oppItem = (Map<String, Object>) intakeItem.get('Opportunity__r');
            wrap.OppName = oppItem == null ? null : (string) oppItem.get('Name');

            // Add item to the wrappers item
            newItem.OppName__c = oppItem == null ? null : (string) oppItem.get('Name');
            wrap.item = newItem;
            
            Map<String, Object> children = (Map<String, Object>) intakeItem.get('children');
            List<IntakeItemWrapper> childrenWrap = new List<IntakeItemWrapper>();
            // Build Wrapper
            // 
            System.debug('***children map: ' + data.get('children'));
            
            if(data.get('children') != null) {
                List<object> test = (List<object>) data.get('children');
                if(test.size() != 0 || !test.isEmpty()) {
                    Map<String, Object> data2 = new Map<String, Object>();
                    for(object itemObject : test){
                        data2 = (Map<String, Object>) itemObject;
                        IntakeItemWrapper wrap2 = new IntakeItemWrapper();
                        Map<String, Object> intakeItem2 = (Map<String, Object>) data2.get('item');
                        
                        // Build Intake Item
                        Intake_Item__c newItem2 = new Intake_Item__c();
                        newItem2.Name = (string) intakeItem2.get('Name');
                        System.debug('***child object name: ' + newitem2.Name);
                        newItem2.Id = (string) intakeItem2.get('Id');
                        newItem2.Is_Pre_Qual__c = (boolean) intakeItem2.get('Is_Pre_Qual__c');
                        newItem2.Action_URL__c = (string) intakeItem2.get('Action_URL__c');
                        newItem2.Status__c = (string) intakeItem2.get('Status__c');
                        newItem2.Status_Reason__c = (string) intakeItem2.get('Status_Reason__c');
                        System.debug('***child rec type id: ' + (string) intakeItem2.get('RecordTypeId'));
                        newItem2.RecordTypeId = (string) intakeItem2.get('RecordTypeId');
                        //newItem2.Due__c = (string) intakeItem2.get('Due__c');
                        
                        // Date mydate = date.valueOf(intakeItem.get('Due_Date__c'));
                        string rawDueDate2 = (string)intakeItem2.get('Due_Date__c');
                        date dueDate2;
                        if(rawDueDate2 != null) {
                            newItem2.Due_Date__c = date.valueOf(rawDueDate2);
                            //dueDate = date.valueOf(rawDueDate);
                        }
                        //newItem.Due_Date__c = date.valueOf(rawDueDate);
                        
                        newItem2.Comments__c = (string) intakeItem2.get('Comments__c');
                        newItem2.Opportunity__c = (string) intakeItem2.get('Opportunity__c');
                        newItem2.CSC_Action_Item__c = (string) intakeItem2.get('CSC_Action_Item__c');
                        newItem2.Submitted_Date__c = (date) intakeItem2.get('Submitted_Date__c');
                        newItem2.Approved_Date__c = (date) intakeItem2.get('Approved_Date__c');
                        newItem2.Approved_By__c = (string) intakeItem2.get('Approved_By__c');
                        newItem2.Submitted_By__c = (string) intakeItem2.get('Submitted_By__c');
                        newItem2.Stop_Number__c = (double) intakeItem2.get('Stop_Number__c');
                        newItem2.Parent_Intake_Item__c = (string) intakeItem2.get('Parent_Intake_Item__c');
                        newItem2.Assigned_To__c = (string) intakeItem2.get('Assigned_To__c');
                        newItem2.Visible_To__c = (string) intakeItem2.get('Visible_To__c');
                        newItem2.Is_Document__c = (boolean) intakeItem2.get('Is_Document__c');
                        newItem2.Document_Name__c = (string) intakeItem2.get('Document_Name__c');
                        newItem2.Processing_Order__c = (double) intakeItem2.get('Processing_Order__c');
                        newItem2.Box_Folder_Id__c = (string) intakeItem2.get('Box_Folder_Id__c');
                        newItem2.Facilities_Client_Type__c = (string) intakeItem2.get('Facilities_Client_Type__c');
                        wrap2.item = newItem2;
                        wrap2.hasChildren = (boolean) data2.get('hasChildren');
                        
                        wrap2.hasParent = (boolean) data2.get('hasParent');
                        wrap2.isReadOnly = (boolean) data2.get('isReadOnly');
                        wrap2.isPQSubmitted = (boolean) data2.get('isPQSubmitted');
                        wrap2.numUnsubmittedDocs = (integer) data2.get('numUnsubmittedDocs');
                        wrap2.assignedToName = (string) data2.get('assignedToName');
                        wrap2.assignedToCSC = (boolean) data2.get('assignedToCSC');
                        System.debug('****isOverdue: ' + (boolean) data2.get('isOverdue'));
                        wrap2.isOverdue = (boolean) data2.get('isOverdue');
                        wrap2.hasOverdueChildren = (boolean) data2.get('hasOverdueChildren');
                        wrap2.isPQ = (boolean) data2.get('isPQ');
                        wrap2.isInfoSheet = (boolean) data2.get('isInfoSheet');
                        wrap2.isActionDetail = (boolean) data2.get('isActionDetail');
                        wrap2.isActionEditDetail = (boolean) data2.get('isActionEditDetail');
                        childrenWrap.add(wrap2);
                    }
                }
            }            
            
            wrap.hasChildren = (boolean) data.get('hasChildren');
            wrap.children = childrenWrap;
            wrap.hasParent = (boolean) data.get('hasParent');
            wrap.isReadOnly = (boolean) data.get('isReadOnly');
            wrap.isPQSubmitted = (boolean) data.get('isPQSubmitted');
            wrap.numUnsubmittedDocs = (integer) data.get('numUnsubmittedDocs');
            wrap.assignedToName = (string) data.get('assignedToName');
            wrap.assignedToCSC = (boolean) data.get('assignedToCSC');
            wrap.isOverdue = (boolean) data.get('isOverdue');
            wrap.hasOverdueChildren = (boolean) data.get('hasOverdueChildren');
            wrap.isPQ = (boolean) data.get('isPQ');
            wrap.isInfoSheet = (boolean) data.get('isInfoSheet');
            wrap.isActionDetail = (boolean) data.get('isActionDetail');
            wrap.isActionEditDetail = (boolean) data.get('isActionEditDetail');
            castList.add(wrap);
        }
        for(IntakeItemWrapper item : castList) {
            templist = new List<IntakeItemWrapper>();
            if(returnData.containsKey(item.item.Opportunity__c)){
                tempList = returnData.get(item.item.Opportunity__c);
                tempList.add(item);
                returnData.put(item.item.Opportunity__c,tempList);
            }else{
                tempList.add(item);
                returnData.put(item.item.Opportunity__c,tempList);
            }
        }
        
        return returnData;
    }
    
    
    @AuraEnabled
    public static List<CMOAccounts> getCMOs(List<ItemsByOppRecType> items, List<String> checkedIds) {
    	System.debug('***checkedIds: ' + checkedIds);
    	Set<ID> foundParentIDs = new Set<Id>();
    	List<CMOAccounts> returnAccts = new List<CMOAccounts>();
    	
    	List<Opportunity> opps = getOpportunities('');
    	
    	for (Opportunity o : opps) {
    		System.debug('****opp: ' + o.Id);
    		System.debug('****opp parent id: ' + o.Account.Parent.Id);
    		System.debug('****opp parent name: ' + o.Account.Parent.Name);
    		if (!foundParentIDs.contains(o.Account.Parent.Id) && o.Account.Parent.Id!=null) {
	    			   		System.debug('Parent CMO found: ' + o.Account.Parent.Id);
	    			   		CMOAccounts cmo = new CMOAccounts();
		    				cmo.Name = o.Account.Parent.Name.replaceAll(',', '');
		    				cmo.Id = o.Account.Parent.Id;
		    				foundParentIDs.add(o.Account.Parent.Id);
		    				
		    				
		    				//check which have already been checked so we can default the value to checked
		    				if (checkedIds==null || checkedIds.size()==0) {
		    					cmo.Checked = false;
		    				} else {
		    					//List<String> ids = checkedIds.split(',');
		    					cmo.Checked = false;
		    					for (String s : checkedIds) {
		    						//if (s==o.Account.Parent.Name.replaceAll(',', '')) {
		    						if (s==o.Account.Parent.Id+'') {
		    							cmo.Checked = true;
		    						}
		    					}
		    					
		    				}
		    				
		    				returnAccts.add(cmo); 
    		}
    	}
    	
    	System.debug('returnign CMOS: ' + returnAccts);
    	return returnAccts;
    	
    	
    }
    
    @AuraEnabled
    public static List<STring> getCMOStrings(List<ItemsByOppRecType> items) {
    	System.debug('***getCMOStrings for ' + items);
    	Set<ID> foundParentIDs = new Set<Id>();
    	List<STring> returnAccts = new List<String>();
    	
    	List<Opportunity> opps = getOpportunities('');
    	
    	for (Opportunity o : opps) {
    		System.debug('****opp: ' + o.Id);
    		System.debug('****opp parent id: ' + o.Account.Parent.Id);
    		System.debug('****opp parent name: ' + o.Account.Parent.Name);
    		if (!foundParentIDs.contains(o.Account.Parent.Id) && o.Account.Parent.Id!=null) {	    			   		
		    				returnAccts.add(o.Account.Parent.Name.replaceAll(',', '')); 
		    				foundParentIDs.add(o.Account.Parent.Id);
    		}
    	}
    	
    	System.debug('returnign CMOS: ' + returnAccts);
    	return returnAccts;
    	
    }
    
    public static List<Intake_Item__c> getFilteredUploadIntakeItems(Date filterDate, String itemName, String recType, String statusFilter, String acctFilter) {
     	System.debug('**** in getFilteredUploadIntakeItems for filter: ' + statusFilter + ' and rectype: ' + recType);
     	Set<Id> acctIds = new Set<Id>();
     	if (acctFilter!=null&& acctFilter!='') {
     		for (String s : acctFilter.split(',')) {
     			acctIds.add(Id.valueOf(s));
     		}
     	}
     	system.debug('***** acctIds: '+acctIds);
    	if (cachedUser==null) {
        	cachedUser =  [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
    	}
    	
    	if (cachedValidOpps.size()==0) {
	        for (Opportunity o : getOpportunities('')) {
	            if (!o.IsClosed) {
	            	cachedValidOpps.add(o.Id);
	            }
	        }
    	}
    	
        if (test.isrunningtest()) {
        	cachedRole = 'School';
        } else {
        	if (cachedRole=='') {
		        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt 
	                      where Profile_name__c=:cachedUser.Profile.Name LIMIT 1];	        
		        cachedRole = drm.role__c;
        	}
        }
        system.debug('***** role: '+cachedRole);
        
        for (Id i : cachedValidOpps) {
        	System.debug('***** cachedValidOpps: ' + i);
    	}
        
        list<intake_item__c> items;
        Id filteredRecType;
        if (recType!=null && recType != '' && recType!= ONGOING_DILIGENCE_RECTYPE) {
        	filteredRecType = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        }
        Set<Id> recTypes = new Set<ID>();
        if (filteredRecType!=null) {
        	recTypes.add(filteredRecType);
        } else {
        	recTypes.add(RecordTypes.IDFundingOpp);
        	recTypes.add(RecordTypes.IDFacilitiesOpp);
            recTypes.add(RecordTypes.IDFOFOpp);
            recTypes.add(RecordTypes.ID5DFOpp);
        }
        if (cachedItems.get(recType)==null) {system.debug('**** no cached items');}
        else {System.debug('****** cachedItems size: ' + cachedItems.get(recType).size());}
        
        
        //setup status filters
        Set<STring> statusFilters = new Set<String>();
        
        if (statusFilter=='' ||statusFilter==null || statusFilter=='All Items') {
        	//add all status'
        	statusFilters.add(DiligenceVars.IntakePendingStatus);
        	statusFilters.add('Submitted');
        	statusFilters.add('Accepted');
        	statusFilters.add('Additional Input Needed');
        } else if (statusFilter==DiligenceVars.IntakePendingStatus) {
        	statusFilters.add('Additional Input Needed');
        	statusFilters.add(DiligenceVars.IntakePendingStatus);
        } else if (statusFilter=='Submitted') {
        	statusFilters.add('Submitted');
        } else if (statusFilter=='Completed Items') {
            statusFilters.add('Accepted');
        } 
        System.debug('***** statusFilters: ' + statusFilters);
        
        if (cachedItems.get(recType)==null || cachedItems.get(recType).size()==0) {
	        System.debug('****first time query');
	        
	        //first time get ALL items irregardless of name
	        if (acctIds.size()>0) {
	        	
	            items = [SELECT id,Is_Ongoing__c, Submitted_Date__c, Approved_Date__c, Client_Facing_Item_Name__c, Client_Comments__c,Comment_Required__c, name,Action_URL__c,Client_Due__c, Status__c, Status_Reason__c, 
	            Opportunity__r.Client_Facing_Opportunity_Name__c, Red_Flag_Instructions_For_Client__c, COmments__c, Due_Date__c, Intake_Item__c.Assigned_To__c, 
	            Opportunity__r.Name, Opportunity__r.Funded_Date__c, Opportunity__c,Is_Visible_To_Community__c,Is_Document__c, 
	            Opportunity__r.recordtypeid, Opportunity__r.recordtype.name, Is_Pre_Qual__c,RecordTypeId,
	            Opportunity__r.Account.Name, 
	            Opportunity__r.Account.Id,
	            Opportunity__r.Account.Parent.Id,
	            Opportunity__r.Account.Parent.Name,
                Account_Name__r.Name,
	            (Select Id from Intake_Items__r)
	                                   FROM Intake_Item__c WHERE 
	                                   
	                                   (Assigned_To__c includes (:cachedRole) OR Visible_To__c includes (:cachedRole))
	                                    AND Is_Visible_To_Community__c = TRUE 
	                                    AND status__c IN:statusFilters
	                                    AND ((Opportunity__r.ID IN:cachedValidOpps 
	                                           AND Opportunity__r.recordtypeid IN:recTypes AND Is_Ongoing__c = false) OR Is_Ongoing__c = true)
	                                    
	                                   ORDER BY Due_Date__c ASC];
	        } else {
	        	
	        	items = [SELECT id,Is_Ongoing__c, Submitted_Date__c, Approved_Date__c, Client_Facing_Item_Name__c, Client_Comments__c,Comment_Required__c, name,Action_URL__c,Client_Due__c, Status__c, Status_Reason__c, 
	            Opportunity__r.Client_Facing_Opportunity_Name__c, Red_Flag_Instructions_For_Client__c, COmments__c, Due_Date__c, Intake_Item__c.Assigned_To__c, 
	            Opportunity__r.Name, Opportunity__r.Funded_Date__c, Opportunity__c,Is_Visible_To_Community__c,Is_Document__c, 
	            Opportunity__r.recordtypeid, Opportunity__r.recordtype.name, Is_Pre_Qual__c,RecordTypeId,
	            Opportunity__r.Account.Name, 
	            Opportunity__r.Account.Id,
	            Opportunity__r.Account.Parent.Id,
	            Opportunity__r.Account.Parent.Name,
                Account_Name__r.Name,
	            (Select Id from Intake_Items__r)
	                                   FROM Intake_Item__c WHERE 
	                                   (Assigned_To__c includes (:cachedRole) OR Visible_To__c includes (:cachedRole))
	                                    AND Is_Visible_To_Community__c = TRUE 
	                                    AND status__c IN:statusFilters
	                                      AND ((Opportunity__r.ID IN:cachedValidOpps AND 
	                                      Opportunity__r.recordtypeid IN:recTypes AND Is_Ongoing__c = false) OR Is_Ongoing__c = true)
	                                      ORDER BY Due_Date__c ASC];
	        }
	        
	        //filter out items that have children - these are not shown
	        //also need to sort any Null Due Dates and move to the end
	        //  i.e. This list should be sorted by nearest Due Date for any Opportunity Item underneath the Item name 
	        
	        //also filter out any Accounts that dont match the CMO acct filter
	        List<Intake_Item__c> newList = new List<Intake_Item__c>();
	        List<Intake_Item__c> nullDueDates = new List<Intake_Item__c>();
	        for (Intake_Item__c i : items) {
	        	System.debug('ITem: ' + i.Name + ' due ' + i.Due_Date__c);
	        	if (i.Intake_Items__r.size()==0) {
	        		if (acctIds.size()>0 && !acctIds.contains(i.Opportunity__r.Account.Parent.Id)) {
	        			//skip CMO did nto match
	        		} else {
		        		if (i.due_date__c==null) {
		        			nullDueDates.add(i);
		        		} else {
		        			newList.add(i);
		        		}
	        		}
	        	}
	        }
	        for (Intake_Item__c i : nullDueDates) {
	        	newList.add(i);
	        }
	        
	        //we have final list
	        items = newList;
	        
	        cachedItems.put(recType,items);
	        
	        //now match the name passed in
	        if (itemName != null){
	        	List<Intake_Item__c> newItems = new List<Intake_Item__c>();
        		for (Intake_Item__c i : cachedItems.get(recType)) {
        			if (i.Name==itemName) {
        				newItems.add(i);
        			}
        		}
        		return newItems;
	        } else return items;
	        
        } else {
        	System.debug('**** query from cache');
        	//we already cached items, find the name matching
        	if (itemName!=null) {
        		List<Intake_Item__c> newItems = new List<Intake_Item__c>();
        		for (Intake_Item__c i : cachedItems.get(recType)) {
        			if (i.Name==itemName) {
        				newItems.add(i);
        			}
        		}
        		return newItems;
        	} else return cachedItems.get(recType);
        }
        	
            
        //return items;
    }
    
    
    @AuraEnabled
    public static List<ItemsByOppRecType> getRecTypeItem(String statusFilter, List<String> cmos){
    	System.debug('**** in getRecTypeItem for filter: ' + statusFilter);
    	System.debug('**** in getRecTypeItem for cmos: ' + cmos);
    	String acctFilter = '';
    	for (String s : cmos) {
    		acctFilter+=s+',';
    	}
    	acctFilter = acctFilter.removeEnd(',');
    	
    	System.debug('**** acctFilter: ' + acctFilter);
    	
        list<intake_item__c> items = getFilteredUploadIntakeItems(null, null, null, statusFilter, acctFilter);
        
        for (intake_item__c i : items) {
            System.debug('***** item found: ' + i.Name + ' ' + i.Opportunity__c);
        }
        
        list<ItemsByOppRecType> iList = new list<ItemsByOppRecType>();
        Map<string, Map<STring,Integer>> recordTypeItemMap = new Map<string, Map<STring,Integer>>();
        Map<String,Integer> oppCount = new Map<String,Integer>();
        Map<String,Intake_Item__c> itemMap = new Map<String,Intake_Item__c>();
        Map<String,intake_item__c> sortedDueDateMap = new Map<String,intake_item__c>();
        Map<STring,String> oppStatusMap = new Map<String, String>();
        
        For(intake_item__c i :items){
            Integer count = oppCount.get(i.name);
            if (count==null) count = 0;
            oppCount.put(i.name,count+1); 
            itemMap.put(i.name,i);
            
            //set status for this Item Name
            if (statusFilter=='All Items') {
                if (i.status__c==DiligenceVars.IntakePendingStatus || i.status__c=='Additional Input Needed') {
                            updateStatusMap(oppStatusMap, i, DiligenceVars.IntakePendingStatus);
                } else if (oppStatusMap.get(i.Opportunity__r.recordtype.name+i.name)!=DiligenceVars.IntakePendingStatus && i.status__c=='Submitted' ) {
                            updateStatusMap(oppStatusMap, i, 'Submitted');    			                
                }  else if (oppStatusMap.get(i.Opportunity__r.recordtype.name+i.name)!=DiligenceVars.IntakePendingStatus && oppStatusMap.get(i.Opportunity__r.recordtype.name+i.name)!='Submitted' && i.status__c=='Accepted' ) {
                            updateStatusMap(oppStatusMap, i, 'Completed');    	
                }
            }
            String recTypeName = i.Is_Ongoing__c ? ONGOING_DILIGENCE_RECTYPE : i.Opportunity__r.recordtype.name;
            if(recordTypeItemMap.get(recTypeName) != NULL){
                //Set<string> oppsL = recordTypeItemMap.get(i.Opportunity__r.recordtype.name);
                //oppsL.add(i.name);
                //recordTypeItemMap.put(i.Opportunity__r.recordtype.name,oppsL);
                Map<STring,Integer> oppsMap = recordTypeItemMap.get(recTypeName);
                
                Integer prevPending = recordTypeItemMap.get(recTypeName).get(i.Name);
                if (prevPending==null) prevPending = 0;
                Integer pending = (i.status__c == DiligenceVars.IntakePendingStatus ? 1 : 0);
                oppsMap.put(recTypeName+i.Name,pending+prevPending);
                recordTypeItemMap.put(recTypeName,oppsMap);       
                    
            } else{
                Map<String, Integer> oppsMap = new Map<String, Integer>();
                
                Integer pending = (i.status__c == DiligenceVars.IntakePendingStatus ? 1 : 0);
                oppsMap.put(recTypeName+i.Name,pending);
                recordTypeItemMap.put(recTypeName,oppsMap); 
            }
        }
        
        
        
        For(string k: recordTypeItemMap.KeySet()){
            ItemsByOppRecType j = new ItemsByOppRecType();
            j.recordtypename = k;
            j.cmos = new Map<Id,String>();
	                
            system.debug('Record Type:' + j);
            //Set<string> itemNames = recordTypeItemMap.get(k);
            Map<String, Integer> itemNames = recordTypeItemMap.get(k);
            system.debug('itemNames:' + itemNames);
            
            List<IntakeItem> itemWrappers = new List<IntakeItem>();
            Map<STring,String> itemStatusMap = new Map<String,String>();
			For(string s: itemNames.keyset()){
				//if (s.removestart(k)!='Approval of Funding Estimate') {
					
	                IntakeItem i = new IntakeItem();
	                i.name = s.removestart(k);
                    String recTypeName;
                    if (itemMap.get(i.name).Is_Ongoing__c) {
                        recTypeName = itemMap.get(i.name).Opportunity__r.recordtype.name;
                    } else {
                        recTypeName = ONGOING_DILIGENCE_RECTYPE;
                    }
	                i.status = oppStatusMap.get(recTypeName+i.name);
	                
	                System.debug('***** item: ' + itemMap.get(i.name).Id + ' - ' + itemMap.get(i.name).Name);
					String oppNameItemName = recTypeName+i.Name;
					
					if (oppStatusMap.get(oppNameItemName)!=null) i.status = oppStatusMap.get(oppNameItemName);
					 
	                i.action = itemMap.get(i.name).action_url__c;
	                i.isDocument = itemMap.get(i.name).Is_Document__c;
	                i.numPending = itemNames.get(s);
	                System.debug('***** adding numItems count: ' + oppCount.get(s));
	                i.numItems = oppCount.get(s.removestart(k));
	                i.hasChildren = (itemMap.get(i.name).Intake_Items__r.size()>0);
	                //set overall status for this Product
	                System.debug('&&&& status of item: ' + i.status);
	                if (statusFilter=='All Items') {
		                if (itemMap.get(i.name).status__c==DiligenceVars.IntakePendingStatus || itemMap.get(i.name).status__c=='Additional Input Needed') {
		                	//j.status='Action Required';
		                } else if (j.status!=DiligenceVars.IntakePendingStatus && itemMap.get(i.name).status__c=='Submitted' ) {
		                	//j.status='Under Review';		                
		                }  else if (j.status!=DiligenceVars.IntakePendingStatus && j.status!='Submitted' && itemMap.get(i.name).status__c=='Accepted' ) {
		                	//j.status='Completed';
		                }
	                }
	                 
	                //set CMOs
	                if (itemMap.get(i.name).Opportunity__r.Account.Parent.Id!=null) {
	                	j.cmos.put(itemMap.get(i.name).Opportunity__r.Account.Parent.Id,itemMap.get(i.name).Opportunity__r.Account.Parent.Name);
	                }
	    				
					itemWrappers.add(i);
				//}
            }
            j.ItemList = itemWrappers;
            iList.add(j);
        }
        
        system.debug('getRecTypeItem Final List:' + iList);
        
        return iList;
        
    }

    private static void updateStatusMap(Map<STring,String> statusMap, Intake_Item__c item, String status) {
        if (item.Is_Ongoing__c) {
            statusMap.put(ONGOING_DILIGENCE_RECTYPE, status);
        } else {
            statusMap.put(item.Opportunity__r.recordtype.name+item.name,status);
        }
    }

    @AuraEnabled
    public static Boolean hasAccounts() {
        return !MyAccountItemsCtlr.getAccounts().isEmpty();
    }

    @AuraEnabled
    public static Boolean hasOpportunities() {
        return !MyItemsCtlr.getOpenOpportunities().isEmpty();
    }

    @AuraEnabled
    public static Boolean hasUrgentItems() {
        return !UrgentItemsCtlr.getUrgentItems().isEmpty();
    }

}