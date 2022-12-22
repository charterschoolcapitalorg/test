public class IntakeCommunityViewFoldersCtrl {

    public IntakeCommunityViewFoldersCtrl() {

    }

    @AuraEnabled
    public static List<Box_Read_Only_Shares__c> getFolders(){
        system.debug('enter - getFolders');
        User u = [SELECT id,name,ContactId, Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
        
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

    
}