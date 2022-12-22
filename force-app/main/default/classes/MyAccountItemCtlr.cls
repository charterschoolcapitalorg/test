public class MyAccountItemCtlr {
    @AuraEnabled
    public static List<IntakeItemWrapper> getIntakeItems(String accountId, String intakeParentId, List<Id> cmos, String statusfilter){
        return getIntakeItems(new Set<Id> { accountId }, intakeParentId, cmos, statusfilter);
    }

    public static List<IntakeItemWrapper> getIntakeItems(String accountId, String intakeParentId){
        return getIntakeItems(accountId, intakeParentId, null, null);
    }

    public static List<IntakeItemWrapper> getIntakeItems(Set<Id> accountIds, String intakeParentId){
        return getIntakeItems(accountIds, intakeParentId, null, null);
    }

    public static List<IntakeItemWrapper> getIntakeItems(Set<Id> accountIds, String intakeParentId, List<Id> cmos, String statusfilter){
        //return MyItemRowCtlr.getIntakeItems(opportunityId, intakeParentId);
        
        System.debug('**** MyAccountItemCtlr: getIntakeItems for acct: ' + accountIds + ' and parentId: ' + intakeParentId);
        String role = getUserRole(UserInfo.getUserId());

        Set<Id> cmoIds = MyAccountItemsCtlr.getCMOIds(cmos);
        
        List<Intake_Item__c> intakeItems = new List<Intake_Item__c>();
        for (Intake_Item__c it: [
            SELECT Id, Submitted_Date__c, Approved_Date__c, Comment_Required__c, Client_Comments__c, Client_Due__c, Name, Status__c,
                Intake_Item__c.Assigned_To__c,  Client_Facing_Item_Name__c,
                Opportunity__r.Name, Opportunity__r.Client_Facing_Opportunity_Name__c, Opportunity__r.Funded_Date__c, Due_Date__c, Parent_Intake_Item__c, Comments__c, Is_Document__c,
                Opportunity__r.Targeted_Funding_Date__c, Opportunity__c, Intake_Item__c.Opportunity__r.Account.Name, Due__c, 
                Action_URL__c, Is_Pre_Qual__c, RecordTypeId, Status_Reason__c, Show_in_Urgent_Tab__c, Account_Name__c, Account_Name__r.Name,
                Account_Name__r.ParentId,
                Account_Name__r.Parent.ParentId,
                Account_Name__r.Parent.Parent.ParentId,
                (
                    SELECT Id,Submitted_Date__c, Approved_Date__c, Comment_Required__c, Client_Due__c,Client_Facing_Item_Name__c,RecordTypeId,Opportunity__r.Account.Name, Opportunity__r.AccountId, Visible_To__c, Is_Document__c, 
                        Comments__c, Parent_Intake_Item__c, Client_Comments__c, Name,Status__c,Opportunity__r.Name,Opportunity__r.Client_Facing_Opportunity_Name__c,Due_Date__c,Action_URL__c,
                        Document_Name__c, Assigned_To__c, Due__c,Status_Reason__c, Show_in_Urgent_Tab__c, Is_Pre_Qual__c from Intake_Items__r
                    WHERE (Assigned_To__c includes (:role) or Visible_To__c includes (:role))
                    AND Is_Visible_To_Community__c = true
                    AND Is_Ongoing__c = true
                    AND Status__c NOT IN :MyAccountItemsCtlr.EXCLUDE_STATUS
                    AND Status__c IN :MyAccountItemsCtlr.getStatusFilter(statusfilter)
                    ORDER BY Processing_Order__c ASC
                ) 
            FROM Intake_Item__c 
            WHERE (Assigned_To__c includes (:role) or Visible_To__c includes (:role))
            AND Account_Name__c IN :accountIds
            AND Is_Visible_To_Community__c = true
            AND Parent_Intake_Item__c = :intakeParentId
            AND Is_Ongoing__c = true
            AND Status__c NOT IN :MyAccountItemsCtlr.EXCLUDE_STATUS
            AND Status__c IN :MyAccountItemsCtlr.getStatusFilter(statusfilter)
            ORDER BY Processing_Order__c ASC
        ]) {
            if (cmoIds.isEmpty() || cmoIds.contains(it.Account_Name__c) || cmoIds.contains(it.Account_Name__r.ParentId) || cmoIds.contains(it.Account_Name__r.Parent.ParentId) || cmoIds.contains(it.Account_Name__r.Parent.Parent.ParentId)) {
                intakeItems.add(it);
            }
        }
        
        Set<Id> parentIds = new Set<Id>();
        for(Intake_Item__c ii : intakeItems){
	    	parentIds.add(ii.Id);
        } 
        system.debug('Parent Ids: ' + parentIds);
        List<Intake_Item__c> children = [SELECT Parent_Intake_Item__c FROM Intake_Item__c WHERE Parent_Intake_Item__c IN :parentIds];
        Set<Id> childIds = new Set<Id>();
        for(Intake_Item__c ci : children){
            childIds.add(ci.Parent_Intake_Item__c);
        }
        
        system.debug('Child Ids: ' + childIds);
        List<IntakeItemWrapper> wraps = new List<IntakeItemWrapper>();
        for(Intake_Item__c ii : intakeItems){
            IntakeItemWrapper w = new IntakeItemWrapper(ii, role);
            if(childIds.contains(ii.Id)){
                w.hasChildren = true;
            }
            wraps.add(w);
        }        
        system.debug('Returning: ' + wraps);
        
        return wraps;
        
    }
	
	@AuraEnabled
    public static String getUserRole(String userId){
    	if (test.isrunningtest()) {
        	return 'School';
        } else {
	        User u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :userId];       
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        return drm.role__c;
        }
        
    }
}