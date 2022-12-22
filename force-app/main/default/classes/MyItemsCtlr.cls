public class MyItemsCtlr {
   
    @AuraEnabled
    public static List<Opportunity> getOpenOpportunities(List<Id> cmos, String statusfilter){
    	List<String> result = new List<STring>();
        
        String role;
        
        User u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        system.debug('user '+u); 
        if (test.isrunningtest()) {
        	role = 'School';
        } else {
	        
        	   
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        role = drm.role__c;
	        system.debug('role: '+role);
        }

        Set<Id> cmoIds = MyAccountItemsCtlr.getCMOIds(cmos);
        
        List<String> oppids = getOppsForContactRole(u.ContactId, role);
        List<Opportunity> opps = new List<Opportunity>();
        for (Opportunity opp: [
            SELECT Id, IsClosed, IsWon, Target_Wire_Date__c, Funding_Date__c, Targeted_Funding_Date__c, NET_Amount_Requested__c,Reporting_Value__c, Name, Client_Facing_Opportunity_Name__c,
                AccountId,
                Account.ParentId,
                Account.Parent.ParentId,
                Account.Parent.Parent.ParentId
            FROM Opportunity
            WHERE Id IN :oppids 
            AND IsClosed=false
            AND Id IN (
                SELECT Opportunity__c
                FROM Intake_Item__c
                WHERE Opportunity__c IN :oppIds
                AND (Assigned_To__c includes (:role) or Visible_To__c includes (:role))
                AND Is_Visible_To_Community__c = true
                AND Is_Ongoing__c = false
                AND Status__c IN :MyAccountItemsCtlr.getStatusFilter(statusfilter)
            )
            ORDER BY Target_Wire_Date__c ASC
        ]) {
            if (cmoIds.isEmpty() || cmoIds.contains(opp.AccountId) || cmoIds.contains(opp.Account.ParentId) || cmoIds.contains(opp.Account.Parent.ParentId) || cmoIds.contains(opp.Account.Parent.Parent.ParentId)) {
                opps.add(opp);
            }
        }

        system.debug('**Opps: ' + opps);
        return opps;
    }

    public static List<Opportunity> getOpenOpportunities(){
        return getOpenOpportunities(null, null);
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

    
    public static List<String> getOppsForContactRole(String contactId, String role){
        List<String> opps = new List<String>();
        For(Community_Contact_Role__c item:[SELECT id,Opportunity__c,ROle__c FROM Community_Contact_Role__c WHERE Contact__c = :contactId and Role__c =:role]){
            opps.add(item.Opportunity__c);
        }
        return opps;
    }

}