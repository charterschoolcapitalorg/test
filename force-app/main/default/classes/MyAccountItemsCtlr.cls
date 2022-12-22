public class MyAccountItemsCtlr {
    public static final Set<String> EXCLUDE_STATUS = new Set<String> {
        'Submitted',
        'Accepted'
    };
    
    @AuraEnabled
    public static List<Account> getAccounts(List<Id> cmos, String statusfilter){
    	List<String> result = new List<STring>();
        User u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];       
        String role = getUserRole(u.Id);
        return getAcctsForContactRole(u.ContactId, role, cmos, statusfilter);
    }

    public static List<Account> getAccounts(){
        return getAccounts(null, null);
    }
    
    public static String getUserRole(String userId){
        User u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :userId];       
        if (test.isrunningtest()) {
        	return 'School';
        } else {
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
        	return drm.role__c;
        }
    }

    public static Set<Id> getCMOIds(List<Id> cmos) {
        Set<Id> cmoIds = new Set<Id>();
        if (cmos != null) {
            cmoIds.addAll(cmos);
        }
        return cmoIds;
    }

    public static Set<String> getStatusFilter(String statusfilter) {
        Set<String> includeStatuses = new Set<String>();
        for (PicklistEntry ple: Intake_Item__c.Status__c.getDescribe().getPicklistValues()) {
            includeStatuses.add(ple.getValue());
        }
        if (String.isNotBlank(statusfilter) && statusfilter != 'All Items') {
            includeStatuses = new Set<String> { statusfilter };
        }
        return includeStatuses;
    }

    private static List<Account> getAcctsForContactRole(String contactId, String role, List<Id> cmos, String statusfilter){
        Set<Id> acctIds = new Set<Id>();
        for(Community_Contact_Role__c item : [SELECT id, Account__c, Role__c FROM Community_Contact_Role__c WHERE Contact__c = :contactId and Role__c =:role]){
            acctIds.add(item.Account__c);
        }

        //look for child account ids
        acctIds.addAll(new Map<Id,Account>([SELECT Id, ParentId FROM Account WHERE ParentId IN :acctIds ]).keySet());

        Set<Id> cmoIds = getCMOIds(cmos);

        List<Account> accts = new List<Account>();
        for (Account acct: [
            SELECT Id, Name, Parent.Name, Parent.Parent.ParentId, Parent.ParentId, ParentId
            FROM Account
            WHERE Id IN :acctIds
            AND Id IN (
                SELECT Account_Name__c
                FROM Intake_Item__c
                WHERE (Assigned_To__c includes (:role) OR Visible_To__c includes (:role))
                AND Account_Name__c IN :acctIds
                AND Is_Visible_To_Community__c = true
                AND Parent_Intake_Item__c = null
                AND Is_Ongoing__c = true
                AND Status__c NOT IN :EXCLUDE_STATUS
                AND Status__c IN :getStatusFilter(statusfilter)
            )
        ]) {
            if (cmoIds.isEmpty() || cmoIds.contains(acct.Id) || cmoIds.contains(acct.ParentId) || cmoIds.contains(acct.Parent.ParentId) || cmoIds.contains(acct.Parent.Parent.ParentId)) {
                accts.add(acct);
            }
        }
        return accts;
    }
}