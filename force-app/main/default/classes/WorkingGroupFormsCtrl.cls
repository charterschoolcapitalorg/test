/**
 * Created by Ivan Garcia on 4/3/2018.
 */

global class WorkingGroupFormsCtrl {
    public WorkingGroupFormsCtrl() {

    }
	
    @AuraEnabled
    public static List<String> getBoardPositions() {
		List<String> result = new List<String>();
		
	    result.add('Member');
        result.add('Chair');
       
        return result;
    }
    
    @AuraEnabled
    public static List<String> getCorporatePositions() {
		List<String> result = new List<String>();

	    //result.add('Corporate Officer');
        result.add('President');
        result.add('Vice President');
        result.add('Board Chair');
        result.add('Vice Chairman');
        result.add('CEO');
        result.add('CFO');
        result.add('COO');
        result.add('Treasurer');
        result.add('Secretary');
       
        return result;
    }

    @AuraEnabled
    public static List<String> getGoverningPositions() {
        List<String> result = new List<String>();
        
        result.add('Member');
        result.add('Chair');
       
        return result;
    }
    
    @AuraEnabled
    public static List<String> getAdministratorPositions() {
        List<String> result = new List<String>();
        
        result.add('Executive Director');
        result.add('Principal');
        result.add('Superintendent');
        result.add('Other');
       
        return result;
    }
    /*
    @AuraEnabled
    public static string getAccountByIntake(string inId){
        return [SELECT id,Opportunity__r.AccountId FROM Intake_Item__c WHERE id =: inId].Opportunity__r.AccountId;
    }
    */

    //2018.10.10 J Caughie - replaced string method with record return method
    @AuraEnabled
    public static Intake_Item__c getAccountByIntake(string inId){
        return [SELECT id, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.State__c FROM Intake_Item__c WHERE id =: inId];
    }

    @AuraEnabled
    public static List<Working_Group_List__c> getTableData(string accId){
        User u = [SELECT id,name,ContactId,Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
        
        STring role;
        
        if (test.isrunningtest()) {
        	role = 'School';
        } else {
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        role = drm.role__c;
        }
        system.debug('role: '+role);
        
        List<Working_Group_List__c> workingGroupList = [
            SELECT id,
            Account__c,
            Legal_Contact__c,
            Title__c,
            Position__c,
            Name,
            Address__c,
            Phone__c,
            Email__c,
            Board_Member__c,
            Corporate_Officer__c,
            First_Name__c,
            Term_of_Office_Board_Member__c,
            Term_of_Office_Corporate_Officer__c, 
            Governing_Body__c, 
            Vacant_Position__c, 
            School_Administrator__c, 
            Role__c 
            FROM Working_Group_List__c 
            WHERE Account__c =: accId 
            AND Account__c != NULL 
            AND recordtype.developername = 'Working_Capital'];
        

        Integer countBoard = 0, countOfficer = 0, countLegal = 0, countGoverning = 0, countAdministrators = 0;
        for(Working_Group_List__c wgl : workingGroupList){
            if (wgl.Board_Member__c) {
                countBoard++;
            } else if (wgl.Corporate_Officer__c) {
                countOfficer++;
            } else if (wgl.Legal_Contact__c) {
                countLegal++;
            } else if (wgl.Governing_Body__c){
                countGoverning++;
            } else if (wgl.School_Administrator__c){
                countAdministrators++;
            }
        }

        if(countBoard == 0){
            workingGroupList.add(new Working_Group_List__c(Position__c = 'Position 1', Account__c = accId, Board_Member__c = true, Vacant_Position__c = false, First_Name__c=null));
        }
        if(countOfficer == 0){
            workingGroupList.add(new Working_Group_List__c(Title__c = 'Title 1', Account__c = accId, Corporate_Officer__c = true, Vacant_Position__c = false, First_Name__c=null));
        }
        if(countAdministrators == 0){
            workingGroupList.add(new Working_Group_List__c(Role__c = 'Role 1' , Account__c = accId, School_Administrator__c = true, Vacant_Position__c = false, First_Name__c=null));
        }
        if(countLegal == 0){
            workingGroupList.add(new Working_Group_List__c(Legal_Contact__c = true, Account__c = accId, First_Name__c=null));
        }

        //Boolean workginGroupEmpty = workingGroupList.isEmpty(); 
        //if(workginGroupEmpty == true){
        //    workingGroupList.add(new Working_Group_List__c(Position__c = 'Position 1', Account__c = accId, Board_Member__c = true, Vacant_Position__c = false));
        //    workingGroupList.add(new Working_Group_List__c(Title__c = 'Title 1', Account__c = accId, Corporate_Officer__c = true, Vacant_Position__c = false));
        //    workingGroupList.add(new Working_Group_List__c(Legal_Contact__c = true, Account__c = accId));
        //}


        //add governing body if AZ
        String state = [SELECT Operating_State__r.Name FROM Account WHERE Id = :accId].Operating_State__r.Name;
        System.debug('Account state ' + state);
        if(state == 'AZ' && countGoverning == 0){
            workingGroupList.add(new Working_Group_List__c(Governing_Body__c = true, Position__c = 'Position 1', Account__c = accId, Vacant_Position__c = false, First_Name__c=null));
        }

        return workingGroupList;
    }

    @AuraEnabled
    public static List<Working_Group_List__c> setUpsertData(String upsertData, String accId, String oppId){
        List<Working_Group_List__c> paramData = (List<Working_Group_List__c>)System.JSON.deserializeStrict(upsertData, List<Working_Group_List__c>.Class);
        List<Working_Group_List__c> toUpsertData = new List<Working_Group_List__c>();
        for(Working_Group_List__c item: paramData){
            if(item.Account__c == NULL){
                item.Account__c = accId;
            }
            if(item.Opportunity__c == NULL){
                item.Opportunity__c = oppId;
            }
            toUpsertData.add(item);

        }
        upsert toUpsertData;
        //return toUpsertData;
        return getTableData(accId);
    }

    @AuraEnabled
    public static void setDeleteIntake(String toDelete){
        List<Working_Group_List__c> deleteWGList = (List<Working_Group_List__c>)System.JSON.deserializeStrict(toDelete, List<Working_Group_List__c>.Class);
        delete deleteWGList;
    }

    @AuraEnabled
    public static void submitStatus(String iiId){
        Intake_Item__c ii = [SELECT id,status__c from Intake_Item__c where Id=:iiId];
        ii.status__c = 'Submitted';
        update ii;
    }

}