global without sharing class PQSchoolSiteInfoCtrl {
    
    public PQSchoolSiteInfoCtrl() {
		System.debug('*****init PQSchoolSiteInfoCtrl');
    }
	
    @AuraEnabled
    public static List<String> getStates() {
		List<String> result = new List<String>();
		     
	   Schema.DescribeFieldResult fieldResult = PQ_Form__c.Mailing_State_Province__c.getDescribe();
	   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	        
	   for( Schema.PicklistEntry f : ple)
	   {
	      result.add(f.getLabel());
	   }       
	   
        return result;
    }
    
    @AuraEnabled
    public static string getAccountByIntake(string inId){
        System.debug('*****in getAccountByIntake: ' + inId);
        Intake_Item__c ii = [Select Id, Opportunity__c from Intake_Item__c where Id=:inId];
        //return '0010R00000MC0u3';
        String ret = [SELECT id, AccountId FROM Opportunity WHERE id =: ii.Opportunity__c].AccountId+'';
        System.debug('*****result: ' + ret);
        return ret;
        
    }
	
    
    @AuraEnabled
    public static List<Account> getTableData(string accId){
        System.debug('*****in getTableData');
        Account a = new Account(School_Number_From_PQ__c=1, Name='', Charter_Number__c='', BillingStreet='', 
                                BillingState='', BillingCity='', BillingPostalCode='', 
                               	CMO_Total_Enrollment__c=0, Phone='');
        
        List<Account> aa = new List<Account>();
        aa.add(a);
        System.debug('*****result: ' + aa);
        return aa;
        
		/*
		User u = [SELECT id,name,ContactId,Profile.Name FROM User WHERE Id= :UserInfo.getUserId()];
        
        STring role;
        
        if (test.isrunningtest()) {
        	role = 'School';
        } else {
	        DiligenceRoleMap__mdt drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt where Profile_name__c=:u.Profile.Name LIMIT 1];	        
	        role = drm.role__c;
        }
        system.debug('role: '+role);
        
        List<Working_Group_List__c> workingGroupList = [SELECT id,Account__c,Legal_Contact__c,Title__c,Position__c,Name,Address__c,Phone__c,Email__c,Board_Member__c,Corporate_Officer__c,First_Name__c,Term_of_Office_Board_Member__c,Term_of_Office_Corporate_Officer__c FROM Working_Group_List__c WHERE Account__c =: accId AND Account__c != NULL];
        if(workingGroupList.isEmpty()){
            workingGroupList.add(new Working_Group_List__c(Position__c = 'Position 1', Account__c = accId, Board_Member__c = true));
            workingGroupList.add(new Working_Group_List__c(Title__c = 'Title 1', Account__c = accId, Corporate_Officer__c = true));
            workingGroupList.add(new Working_Group_List__c(Legal_Contact__c = true, Account__c = accId, Name = 'Last Name'));
        }
        return workingGroupList;
		*/
    }
	
    private static Enrollment__c addENrollment(Id acctId, Decimal totalEnroll) {
        Enrollment__c e = new Enrollment__c();
            e.Total_Enrollment__c = totalEnroll;
            e.School__c = acctId;
            e.RecordTypeId = Schema.SObjectType.Enrollment__c.getRecordTypeInfosByName().get('Projected').getRecordTypeId();
            //e.Fiscal_Year__c = 
            e.Description__c = 'PQ Form Info';
            e.Report_Date__c = date.today();
        return e;
    }
    @AuraEnabled
    public static List<Account> setUpsertData(String upsertData, String accId){
        System.debug('***** in setUpsertData for PQ form: ');
        List<Account> paramData = (List<Account>)System.JSON.deserializeStrict(upsertData, List<Account>.Class);
        System.debug('***** paramData: ' + paramData);
        System.debug('***** accId: ' + accId);
        Set<STring> irn = new Set<String>();
        List<Account> toUpsertData = new List<Account>();
        
        Set<STring> statestr = new Set<STring>();
        
        for (Account a : paramData) {
            if (a.billingstate!=null) {
        		statestr.add(a.billingstate);
            }
        }
        //Operating_State__c
        List<State_Province__c> states = [Select Id, Name from State_Province__c where Name IN:statestr];
        
        for (Account a : paramData) {
            a.ParentId = id.ValueOf(accid);
            a.Charter_Holder__c = id.ValueOf(accid);
            for ( State_Province__c s : states) {
                if (s.Name.equalsignorecase(a.billingstate)) {
                    a.Operating_State__c = s.Id;
                }
            }
            a.recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
            irn.add(a.Charter_Number__c);
            toUpsertData.add(a);
        }
        
        System.debug('irn nums: ' + irn);
        //look for accounts with the IRN #
        Id aId = id.valueOf(accid.left(accid.length()-3));
        String aIdStr = accid.left(accid.length()-3);
        System.debug('aIdStr: ' + aIdStr);
        
        List<Account> parentAcct = [Select Id from account where ParentId=:aIdStr];
        System.debug('parentAcct: ' + parentAcct);
        
        List<Account> accts = [Select Id, Charter_Number__c, ParentId from Account where Charter_Number__c IN:irn and PArentId=:aIdStr];
		//        
        System.debug('***** toUpsert before: ' + toUpsertData);
        
        if (accts.size()==0) {
            //create all of the accounts
            System.debug('***** all new accounts - inserting: ' + toUpsertData);
            insert toUpsertData;
            
            //create enrollment records
            List<Enrollment__c> ee = new List<Enrollment__c>();
            for (Account a : toUpsertData) {
            	ee.add(addENrollment(a.Id, a.CMO_Total_Enrollment__c) );    
            }
            insert ee;
            
            return toUpsertData;
            
        } else {
            //find out which ones are new
            for (Account a : accts) {
                System.debug('***** found account: ' + a);
                //if (a.PArentId==aId) {
                    for (Account toUps : toUpsertData) {
                        if (toUps.Charter_Number__c.equalsignoreCase(a.Charter_Number__c)) {
                            System.debug('***** setting id for ' + toUps + ' to ' + a.Id);
                            toUps.id = a.Id;
                            break;
                        }
                    }
           	 	//}
                
            }
        }
        
        System.debug('***** toUpsert after: ' + toUpsertData);
        
        upsert toUpsertData;
        Set<Id> newIds = new Set<Id>();
        for (Account a: toupsertdata) {
            newids.add(a.Id);
        }
        List<Account> newaccts = [Select Id,CMO_Total_Enrollment__c, (Select Id from Enrollments__r) from Account where ID IN:newids ];
        System.debug('**** newaccts for enrollments: ' + newaccts);
        
        ///create enrollment records
            List<Enrollment__c> ee = new List<Enrollment__c>();
            for (Account aa : newaccts) {
                if (aa.enrollments__r ==null||aa.enrollments__r.size()==0) {
            		ee.add(addENrollment(aa.Id, aa.CMO_Total_Enrollment__c) ); 
            	}
            }
            insert ee;
        return toUpsertData;
    }

    @AuraEnabled
    public static void setDeleteIntake(String toDelete){
		System.debug('***** setDeleteIntake: ' + toDelete);
        List<Account> deleteWGList = (List<Account>)System.JSON.deserializeStrict(toDelete, List<Account>.Class);
        delete deleteWGList;
    }

    @AuraEnabled
    public static void submitStatus(String iiId){
        Intake_Item__c ii = [SELECT id,status__c from Intake_Item__c where Id=:iiId];
        ii.status__c = 'Submitted';
        update ii;
    }


}