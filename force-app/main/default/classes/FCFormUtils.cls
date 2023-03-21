/* 
Organization: Charter School Capital
Class: FCFormUtils
Created: ??? 
Test class: TestFC, FCApprovalControllerTest, FC_MasterComponent_Ctrl_Test

Change by 
Slava K 20220616 - Reporting_Year__c field added for sorting
Slava K 20220705 - Refactoring
Slava K 20221201 - UCC Search rename
Slava K 20221201 - removing system.debug
Slava K 20230320 - FC Form Data Mapping with Account Snapshots - case-00002404
*/

public  class FCFormUtils {
    
    public static Map<Id,STring> fcRecTypeNames = new Map<Id,STring>();
    public static set<Id> usersReceivedEmailAlready = new Set<Id>();
    
    public static ID UWFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Underwriting').getRecordTypeId();
    public static ID FinanceFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Finance').getRecordTypeId();
    public static ID SummaryFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Summary').getRecordTypeId();
    public static ID ServicingFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Servicing').getRecordTypeId();
    public static ID FacilitiesFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Facilities').getRecordTypeId();
    
    public static ID UWFcDetailRecType = Schema.SObjectType.FC_Details__c.getRecordTypeInfosByDeveloperName().get('Underwriting').getRecordTypeId();
    public static ID FinanceFcDetailRecType = Schema.SObjectType.FC_Details__c.getRecordTypeInfosByDeveloperName().get('Finance').getRecordTypeId();
    public static ID ServicingFcDetailRecType = Schema.SObjectType.FC_Details__c.getRecordTypeInfosByDeveloperName().get('Servicing').getRecordTypeId();
    
    public static ID AcctStrategy = Schema.SObjectType.Account_Snapshot__c.getRecordTypeInfosByDeveloperName().get('Account_Strategy').getRecordTypeId();
    public static ID AcctUpdates = Schema.SObjectType.Account_Snapshot__c.getRecordTypeInfosByDeveloperName().get('Account_Updates').getRecordTypeId();
    
    public static Set<Id> allFcFormTypes = new Set<Id>{UWFcRecType,FinanceFcRecType, SummaryFcRecType,ServicingFcRecType  };
    public static Set<Id> allFcFormDetailTypes = new Set<Id>{UWFcDetailRecType,FinanceFcDetailRecType,ServicingFcDetailRecType  };
    
    public static Set<Id> formsSubmittedForDeptHEadReview = new Set<Id>();
    
    public static boolean sentFinalApproval = false;
    public static boolean sentFinalRejection = false;
    
    public static FC_Email_Templates__c fcEmailTemplates = FC_Email_Templates__c.getOrgDefaults();
    
    static {
        fcRecTypeNames.put(UWFcRecType,'Underwriting');
        fcRecTypeNames.put(FinanceFcRecType, 'Finance');
        fcRecTypeNames.put(SummaryFcRecType,'Summary' );
        fcRecTypeNames.put(ServicingFcRecType, 'Servicing');
        fcRecTypeNames.put(UWFcDetailRecType, 'Underwriting');
        fcRecTypeNames.put(FinanceFcDetailRecType, 'Finance');
        fcRecTypeNames.put(ServicingFcDetailRecType, 'Servicing');
    }
    
    
    EmailTemplate et = null;
        
    
    public static void notifyOppTeamAndDeptHeads(String templateName,Id targetId, Id oId, boolean includeLegalAssistant) {
        
        Set<Id> uids = new Set<Id>();

        Opportunity o = [Select Id,User__c, Legal_Assistant__c, Paralegal__c, Paralegal_Facilities__c, Financial_Review__c from Opportunity where Id=:oId];
        
        List<Id> userIDs = new List<Id>();
        
        if (o.User__c!=null) uids.add(o.user__c);
        if (o.Paralegal__c!=null) uids.add(o.Paralegal__c);
        if (o.Paralegal_Facilities__c!=null) uids.add(o.Paralegal_Facilities__c);
        if (o.Financial_Review__c!=null) uids.add(o.Financial_Review__c);
        if (includeLegalAssistant && o.Legal_Assistant__c!=null) uids.add(o.Legal_Assistant__c);
        
        if (!test.isrunningtest()) {
            for (User deptHEad :  [Select Id from User where Finance_Dept_Head__c = true or Servicing_Dept_Head__c = true
                                   or Underwriting_Dept_Head__c = true]) {
                                       uids.add(deptHEad.Id);      
                                   }
        }

        if (usersReceivedEmailAlready!=null&&usersReceivedEmailAlready.size()>0) {
            uids.removeall(usersReceivedEmailAlready);
        }
       
        userids.addall(uids);
        sendEmailToUsersUsingTemplate(userIds, templateName, targetId);
    }
    
    public static void sendEmailToGroupAndDeptHeadUsingTemplate(String grp, String templateName, Id targetId, Id oppId) {
        FCFormUtils.sendEmailToGroupUsingTemplate(grp,templateName, targetId);
        FCFormUtils.notifyOppTeamAndDeptHeads(templateName,targetId, oppId, false);
    }
    
    public static void sendEmailToGroupAndDeptHeadAndLAUsingTemplate(String grp, String templateName, Id targetId, Id oppId) {
        FCFormUtils.sendEmailToGroupUsingTemplate(grp,templateName, targetId);
        FCFormUtils.notifyOppTeamAndDeptHeads(templateName,targetId, oppId, true);
    }
    
    public static void sendEmailToGroupUsingTemplate(String grp, String templateName, Id targetId) {
        EmailTemplate et = null;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	    
        if (!test.isrunningtest()) {
	        et = [SELECT Id FROM EmailTemplate WHERE Name =:templateName];
	        mail.setTemplateId(et.Id);
        
	        Map<Id,Id> users = FCFormUtils.getUsersFromGroup(grp);
	        
	        //always copy the users in group FC_Managers_For_Email
	        Map<Id,Id> managers = FCFormUtils.getUsersFromGroup('FC_Managers_For_Email');
	        
            if (managers!=null&&managers.size()>0) {	
	        	for (Id m : managers.values()) {
		        	users.put(m, m);
	        	}
	        }
	        
	        usersReceivedEmailAlready.addall(users.keyset());
	        
	        List<Id> userIds = new List<Id>();
	        userids.addall(users.keyset());  
            
            mail.setToAddresses(userids);
        }

        Id userId = UserInfo.getUserId();
        //targteobject id needs to be a contact in order to use merge fields in email template
        mail.setTargetObjectId(defaultContact.Id);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setWhatId(targetId);
        mail.setsaveasactivity(false);
        
        Id uId = UserInfo.getUserId();
        User activeUser = [Select Email, Name From User where Id = : uId limit 1];
        mail.setReplyTo(activeUser.email);//'noreply@csc.com');
        mail.setSenderDisplayName(UserInfo.getName());//'FC Admin');
        mail.setBccSender(false);
        mail.setUseSignature(false);
	        
        if (!test.isrunningtest()) {           
	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
    
    public static void sendEmailToUsersUsingTemplate(List<Id> userIds, String templateName, Id targetId) {
        
        //always copy the users in group FC_Managers_For_Email
        Map<Id,Id> managers = FCFormUtils.getUsersFromGroup('FC_Managers_For_Email');
        if (managers!=null&&managers.size()>0) userIds.addall(managers.keyset());
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        Id userId = UserInfo.getUserId();
        
        EmailTemplate et = null;
        if (!test.isrunningtest()) {
	        et = [SELECT Id FROM EmailTemplate WHERE Name =:templateName];
	        mail.setTemplateId(et.Id);
        }
        
        //targteobject id needs to be a contact in order to use merge fields in email template
        mail.setTargetObjectId(defaultContact.Id);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setWhatId(targetId);
        
        mail.setToAddresses(userids);
        Id uId = UserInfo.getUserId();
        User activeUser = [Select Email, Name From User where Id = : uId limit 1];
        mail.setReplyTo(activeUser.email);//'noreply@csc.com');
        mail.setSenderDisplayName(UserInfo.getName());//'FC Admin');
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setsaveasactivity(false);

        if (!test.isrunningtest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }         
    }
    
    public static String formatDOllarAmount(String s) {
        String val = s;
        return val;
    }

    public static Contact defaultContact {
        get {
            if(defaultContact == null) {
                defaultContact = [Select Id from Contact LIMIT 1];
            }

            return defaultContact;
        }

        private set;
    }
    
     public static Map<String,Group> allGroups {
        get {
            if(allGroups == null) {
                allGroups = new Map<String,Group>();
                for (Group g : [Select Id, DeveloperName, Name from Group]) {
                    allgroups.put(g.DeveloperName, g);
                }
            }

            return allGroups;
        }

        private set;
    }
    
    public static Map<Id,Id> getUsersFromGroup(STring grpName) {
            
        Group g = allgroups.get(grpName);
        
        Map<Id,Id> userIds = new Map<Id,Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String roleType = Schema.SObjectType.Group.getKeyPrefix();
        
        Set<Id> roleIds = new Set<Id>();
        
        
        for ( GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId =:g.Id]) {
                if(((String)gm.UserOrGroupId).startsWith(userType)){
                userIds.put(gm.UserOrGroupId,gm.UserOrGroupId);
            }
            //if this is a Role or a Group, get users for that role also
            if(((String)gm.UserOrGroupId).startsWith(roleType) ){
                roleIds.add(gm.UserOrGroupId);
            }
        }
        
        if (roleids.size()>0) {
            Set<Id> grpIds = new Set<Id>();
            List<Group> grps = [Select Id,Type, Name, DeveloperName, RelatedId From Group where (Type='Role' or Type='Regular') and Id IN:roleIds];
            for (Group g2 : grps) {
                if (g2.type=='Regular') { 
                    userIds.putAll(getUsersFromGroup(g2.DeveloperName));
                } else {
                    grpIds.add(g2.relatedId);
                }
            }

            if (grpIds.size()>0) {
            LIst<User> moreUsers = [SELECT Id FROM User where UserRoleId IN:grpIds and IsActive=True];
                for ( User u : moreUsers) {
                    userIds.put(u.Id,u.Id);
                }
            }
        }
        
        return userIds;
    }
    
    public static STring dateToString(Date dt) {
        try {
            return dt.month()+'/'+dt.day()+'/'+dt.year();
        } catch (Exception e) {
            return '';
        } 
    }
    
    //this method input is a list of FC Detials records, but those records should all belong to 1 Opp
    public static void populateDetailCommentFieldsFromSFData(List<FC_Details__c> details) {
        Set<Id> detIds = new Set<Id>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id,FC_Details__c> oppDetailMap = new Map<Id,FC_Details__c>();
        Id oppId;
        Id acctId;
        Id recTypeId;
        Date closeDate;
        
        for (FC_Details__c d : details) {
            detIds.add(d.Id);
        }
        
        List<FC_Details__c> detailsExpanded = [SELECT Id, Opp_School__r.School__c, Recordtypeid, Servicing_Comments__c, Current_Funding_Comments__c, 
                    Financial_Review_Comments__c, 
                    Current_Year_Surplus_Deficit__c, Net_Assets__c, Indebtedness__c, 
                    Funding_Exposure_Comments__c,Finance_EWS_Comments__c, 
                    Academic_Performance_Comments__c, School_Profile_Comments__c, 
                    State_Specific_Comments__c, Underwriting_EWS_Comments__c, 
                    FC_Form__r.Opportunity__r.Id, FC_Form__r.Opportunity__r.AccountId, 
            FC_Form__r.Opportunity__r.Recordtypeid, FC_Form__r.Opportunity__r.CloseDate FROM FC_Details__c WHERE ID IN:detIds];
            
        System.debug('***** detailsexpanded: ' + detailsExpanded);  
        
        for (FC_Details__c d : detailsEXpanded) {
            oppId = d.FC_Form__r.Opportunity__r.Id;
            closeDate = d.FC_Form__r.Opportunity__r.CloseDate; 
            acctId = d.FC_Form__r.Opportunity__r.AccountId;
            recTypeId = d.FC_Form__r.Opportunity__r.Recordtypeid;
            accIds.add(d.Opp_School__r.School__c);
            break;
        }

        //2018.03.12 J Caughie - changed logic. Use last closed won as the base
        List<Opportunity> opps = [SELECT Id, recordtypeid FROM Opportunity WHERE AccountId=:acctId AND Id !=:oppId and CloseDate <=: closeDate and IsWon = True ORDER BY CloseDate DESC];
              
        //if no opp found, we need to populate the comment fields that are rich text with Plan, Risk:, etc.
        if (opps.size()==0) { 
            for (FC_Details__c newD : detailsExpanded) {
                newD.Financial_Review_Comments__c ='<b>Plan:<br><br>'+'Risks:<br><br>'+'Mitigants:<br><br>'+'FIN Comments:<br><br>';
            }
            update detailsExpanded;
            return;
        } else {
                            
            //now we have the opp get the data and populate
            List<FC_Details__c> oldDetails = [Select Id, Opp_School__r.School__c, Recordtypeid, Servicing_Comments__c, Current_Funding_Comments__c, 
                Financial_Review_Comments__c,Current_Year_Surplus_Deficit__c, Net_Assets__c, Indebtedness__c, 
                Funding_Exposure_Comments__c, Finance_EWS_Comments__c, 
                Academic_Performance_Comments__c, School_Profile_Comments__c, 
                State_Specific_Comments__c, Underwriting_EWS_Comments__c
                from FC_Details__c where FC_Form__r.Opportunity__r.Id=:opps[0].Id];
                            
            for (FC_Details__c oldD : oldDetails) {
                for (FC_Details__c newD : detailsExpanded) {
                    if (newD.Recordtypeid==oldD.recordtypeid && newD.Opp_School__r.School__c==oldD.Opp_School__r.School__c  ) {
                        if (newD.Recordtypeid==UWFcDetailRecType) {
                            //UW fields
                            newD.School_Profile_Comments__c=oldD.School_Profile_Comments__c;
                            newD.State_Specific_Comments__c=oldD.State_Specific_Comments__c;
                            newD.Underwriting_EWS_Comments__c=oldD.Underwriting_EWS_Comments__c;
                        }
                        if (newD.Recordtypeid==FinanceFcDetailRecType) {
                            //FIN fields
                            newD.Current_Funding_Comments__c=oldD.Current_Funding_Comments__c;
                            newD.Financial_Review_Comments__c =(oldD.Financial_Review_Comments__c==null?'<b>Plan:<br><br>'+'Risks:<br><br>'+'Mitigants:<br><br>'+'FIN Comments:<br><br>':oldD.Financial_Review_Comments__c);
                            newD.Finance_EWS_Comments__c=oldD.Finance_EWS_Comments__c;
                            newD.Current_Year_Surplus_Deficit__c = oldD.Current_Year_Surplus_Deficit__c;
                            newD.Net_Assets__c = oldD.Net_Assets__c;
                            newD.Indebtedness__c = oldD.Indebtedness__c;
                        }
                        if (newD.Recordtypeid==ServicingFcDetailRecType) {
                            //Servicing fields
                            newD.Servicing_Comments__c=oldD.Servicing_Comments__c;
                            newD.Funding_Exposure_Comments__c=oldD.Funding_Exposure_Comments__c;
                        }

                        break;
                    }
                }
            }
            update detailsExpanded;
        } 
    }
    
    
    public static List<FC_Details__c> populateDetailFieldsFromSFData(List<FC_Details__c> details) {
        Set<Id> schoolAcctIds = new Set<Id>();
        Set<Id> opPIds = new Set<Id>();
        Set<Id> oppSchoolIds = new Set<Id>();
        
        Set<Id> formIds = new Set<Id>();    
         
        Set<STring> gs_action_item_names_from_acct = new Set<STring>{'Verification of Compliance with Sponsor', 
            'Verification of Compliance with Authorizer'};
        
        for (FC_Details__c d : details) {
            if (d.opp_school__c!=null) { oppSchoolIds.add(d.opp_school__c);}
            formIds.add(d.Fc_form__c);
        }
        
        Map<Id, FC_FOrm__c> formsForUpdate = new Map<Id, FC_FOrm__c>([Select Id, EWS_Fiscal_Year__c from FC_FOrm__c where ID IN: formids]);
        
        //get School Account and Opp fields
        List<Opp_School__c> oppSchools = [SELECT id, COE__r.Payment_Type__c, Opportunity__c, School__c, 
            SChool__r.FDA_County__c ,School__r.ews_level__c, School__r.FDA_Active_County__c, School__r.FDA_Active_District__c,
            School__r.Name,School__r.Date_Opened__c,School__r.Grade_Level_Served__c, 
            school__r.Academic_Performance_Comments__c, school__r.School_Open_Curr_Yr__c,
            SChool__r.FDA_District__c , School__r.COE__r.Payment_Type__c  , School__r.COE__r.Name, School__r.Authorizer_A__r.Name,
            School__r.FV_Total_Amount_Due__c, School__r.FV_Outstanding_School__c,
            Opportunity__r.NET_Amount_Requested__c, 
            Opportunity__r.rpa__c, 
            Opportunity__r.RPA__r.Default_Transaction_Fee__c,Opportunity__r.RPA__r.Program_Fee__c, 
            Opportunity__r.CloseDate,
            School__r.School_District__r.Name,
            School__r.School_District__r.Moody_s_Rating__c,
            School__r.School_District__r.Moody_s_Outlook__c,
            School__r.School_District__r.S_P_Rating__c,
            School__r.School_District__r.S_P_Outlook__c,
            School__r.COE__r.Moody_s_Rating__c,
            School__r.COE__r.Moody_s_Outlook__c,
            School__r.COE__r.S_P_Rating__c,
            School__r.COE__r.S_P_Outlook__c
            FROM opp_School__c WHERE id IN:oppSChoolIds];

        for (Opp_School__c os : oppSChools) {
            schoolAcctIds.add(os.school__c);
            oppIds.add(os.opportunity__c);
        }
        
        //get csc action items attached to the school account
        List<CSC_ACtion_Item__c> aiAcct = [Select Id, Action_Item_Name__c, Account_Id__c, CSC_Action_List__r.Opportunity__c, 
            Opportunity_Id__c, Date_Completed__c, Date_Effective__c from CSC_ACtion_Item__c 
            where CSC_Action_List__r.Account__c IN:schoolAcctIds
            and Action_Item_Name__c IN: gs_action_item_names_from_acct and Date_Effective__c<>null];
            
        
        //get Funding_Estimates__c agttached to the Opp (Use latest if there are multiple)
        List<Funding_Estimates__c> fe = [Select Id, Opportunity__c,  Discount__c, Total_GRV_Amount__c, Total_FV_Amount__c, Program_Fees_Collected__c,
            Transaction_Fee_Collected__c, Total_Max_Deferred_Purchase_Price__c
            from Funding_Estimates__c where Opportunity__c IN:oppIds order by CreatedDate DESC LIMIT 1];
            
        //get csc action items attached to the Opp
        List<CSC_ACtion_Item__c> aiOpp = [Select Id, Action_Item_Name__c, Account_Id__c, CSC_Action_List__r.Opportunity__c, 
            Date_Completed__c, Date_Effective__c from CSC_ACtion_Item__c where 
            (CSC_Action_List__r.Opportunity__c IN:opPIds)
            and Action_Item_Name__c IN: gs_action_item_names_from_acct and Date_Effective__c<>null];
        
        //get Active Charter Term info from SChool Account
        List<Charter_Term__c> terms = [Select Id, Start_Date__c, End_Date__c, School__c, 
            Enrollment_Cap__c, No_Cap_Limit__c
            from Charter_Term__c 
            where School__c IN:schoolAcctIds and Status__c = 'Active'  ORDER BY CreatedDate DESC];
        
        //get  School_Attendance__c recordsfor school account
        List<School_Attendance__c> attends = [Select Id, School__c, Active__c, Report_Date__c, Attendance_Type__c, 
             Total_Attendance__c, Fiscal_Year__c
             from School_Attendance__c where 
            School__c IN:schoolAcctIds ORDER BY CreatedDate DESC];
        
        
        //get Funded Receivables for school account
        List<Funded_Receivable__c> fundRec = [Select Id, Expected_Pay_Date__c, School__c, Status__c, FV_Amount_Due__c 
            from Funded_Receivable__c where status__c = 'Active' and 
            School__c IN:schoolAcctIds ORDER BY CreatedDate DESC];
        SYstem.debug('*****fundRec: ' + fundRec);
        
        //get Funded Estimate Receivables for opp school
        List<Funding_Estimate_Receivable__c> fundEstRec = [Select Id, Name, Effective_Rate__c, Maturity_Buffer__c, Opp_School__c,Included_in_Estimate__c,  
             FV_Amount__c, Funding_Estimate__r.Transaction_Fee__c, Max_Deferred_Purchase_Price__c, expected_pay_date__c, Discount_Rate_formula__c from Funding_Estimate_Receivable__c where 
            Opp_School__c IN:oppSChoolIds and Included_in_Estimate__c = true ORDER BY CreatedDate DESC];
        
        //get Lease info from SChool Account
        List<Lease__c> leases = [Select Id, Start_Date__c, End_Date__c, Account__c, Lease_Nickname__c from Lease__c 
            where Account__c IN:schoolAcctIds and Active__c = true ORDER BY CreatedDate DESC];
                    
        //get EWS info from SChool Account
        List<EWS__c> ews = [Select Id,Fiscal_Year__c, Google_alerts__c, Budgeted_Revenue__c, Budgeted_Surplus_Deficit__c, 
            Closure_Indication__c, Management_changes_in_past_year__c, 
            Current_Academic_Performance__c, Current_Year_1_Academic_Performance__c,
            Year_1_Latest__c, Year_3_Oldest__c, Year_2__c, Quarter_Ending_FY__c,  
            Current_Year_2_Academic_Performance__c,  Account__c, recordtypeid from EWS__c 
            where Account__c IN:schoolAcctIds and Active__c = true ORDER BY CreatedDate DESC];
        
        //get AR info from SChool Account
        Map<Id, Academic_Rating__c> recentARMap = new Map<Id, Academic_Rating__c>();
        List<Account> ars = [SELECT Id, 
                                        (Select Id, 
                                        Account__c, 
                                        Historical_Ratings_Color__c, 
                                        FY__c, 
                                        Academic_Performance_Comments__c, 
                                        Reporting_Year__c 
                                        FROM Academic_Ratings__r 
                                        WHERE Rating_Review_Date__c != null 
                                        ORDER BY Reporting_Year__c DESC Limit 1)
                             FROM Account
                             WHERE Id IN:schoolAcctIds ORDER BY CreatedDate DESC];
        if(!ars.isEmpty()){
            for(Account ar :ars){
                if(!ar.Academic_Ratings__r.isEmpty()){
                    List<Academic_Rating__c> recentAR = ar.Academic_Ratings__r;
                    recentARMap.put(ar.Id, recentAR[0]);
                }
            }
        }
        
        //molinger - get latest Financial object record tied to the School Account
        
        List<Financial__c> finObjs = [Select Id, Total_Liabilities__c, Fiscal_Year__c, Fiscal_QUarter__c,Month__c, 
                 RecordTypeId, Net_Assets__c, Going_Concern__c, 
                 Internal_Control_Issues__c,
                 Account__c, Stated_Net_Income__c, Data_Source__c from Financial__c  
            where account__c IN:schoolAcctIds and Active__c=true ];
                
        for (FC_Details__c d : details) {
            if (d.recordtypeid==UWFcDetailRecType) {
                //UW Details
                for (Opp_School__c os : oppSChools) {
                    if (os.Id==d.Opp_School__c) {
                        d.school_name__c = os.school__r.Name;
                        d.school_open_date__c = os.School__r.Date_Opened__c;
                        
                        d.authorizer__c = os.School__r.Authorizer_A__r.Name; //changed from COE__r
                        d.EWS_Level_UW_Finance__c = os.School__r.ews_level__c;

                        if (os.school__r.Grade_Level_Served__c != null) {
                            Integer pkIndex = os.school__r.Grade_Level_Served__c.indexOf('PK');
                            if (pkIndex != 0) {
                                d.grades_Served__c = 'PK;' + os.school__r.Grade_Level_Served__c.replace('PK','');
                            } else {
                                d.grades_Served__c = os.school__r.Grade_Level_Served__c;
                            }
                        }
                        
                        //term fields
                        for (Charter_Term__c t : terms) {
                            if (t.School__c==os.school__c) {
                                if (t.No_Cap_Limit__c) { 
                                    d.Enrollment_Cap_By_Site__c = 'No Cap';
                                    
                                } else { 
                                    d.Enrollment_Cap_By_Site__c = t.Enrollment_Cap__c+'';
                                    d.Enrollment_Cap_By_Site_Number__c = t.Enrollment_Cap__c;
                                }
                                
                            }
                        }
                        
                        //Charter good standing
                        //      - get off of School Acct, if not found get from Opp and use the same values for all schools
                        d.charter_good_standing__c=null;
                        for(CSC_ACtion_Item__c c: aiAcct) {
                            if (c.Account_Id__c==os.school__c) {
                                if (gs_action_item_names_from_acct.contains(c.Action_Item_Name__c) ) {
                                    String noFindingsDtCompleted = (c.Date_Effective__c==null ? 'N/A' : 
                                        c.Date_Effective__c.month()+'/'+c.Date_Effective__c.day()+'/'+c.Date_Effective__c.year());
                                    d.charter_good_standing__c= noFindingsDtCompleted;
                                }
                            }
                        }
                        //if CSC Action item not found on Account check CSC ACtion Item from Opp
                        if (d.charter_good_standing__c==null) {
                            for(CSC_ACtion_Item__c c: aiOpp) {
                                if (gs_action_item_names_from_acct.contains(c.Action_Item_Name__c) ) {
                                    if (c.CSC_Action_List__r.Opportunity__c==os.Opportunity__c) {
                                        String noFindingsDtCompleted = (c.Date_Effective__c==null ? 'N/A' : 
                                            c.Date_Effective__c.month()+'/'+c.Date_Effective__c.day()+'/'+c.Date_Effective__c.year());                                    
                                        d.charter_good_standing__c= noFindingsDtCompleted;
                                    }
                                    
                                }
                            }
                        }
                        if (d.charter_good_standing__c==null) d.charter_good_standing__c='N/A';
                        
                        for (EWS__c e : ews) {
                            if (e.Account__c==os.school__c) {
                                //these EWS fields are taken from latest EWS object on the School Account - for the Underwriting - Activated record type
                                if (e.recordtypeid==Schema.SObjectType.EWS__c.getRecordTypeInfosByName().get('Underwriting - Activated').getRecordTypeId()) {
                                    Academic_Rating__c ar = recentARMap.get(os.school__c);
                                    d.Concerning_Google_Alert__c = e.Google_alerts__c;
                                    d.Indication_of_Closure__c = e.Closure_Indication__c;
                                    d.Management_Changes_in_the_Last_Year__c = e.Management_changes_in_past_year__c;
                                    d.EWS_Fiscal_Quarter__c = e.Quarter_Ending_FY__c;
                                    Integer fy;
                                    
                                    //get academic_performance__c from ar instead of ews
                                    String fySTr = STring.valueOf(ar?.FY__c);
                                    String newComments = ar?.Academic_Performance_Comments__c;
                                    String orginalComments = os.school__r.Academic_Performance_Comments__c;
                                    String arcomments = '';
                                    if(orginalComments?.length() > 0){
                                        arcomments = orginalComments +'<br/><br/>';
                                    }
                                    if(fySTr?.length() > 0){
                                     	arcomments += 'FY '+fyStr+' ';
                                        if(newComments?.length() > 0){
                                     	   arcomments += newComments;
                                        }
                                    }
                                    d.Academic_Performance_Comments__c=arcomments;
                                    d.academic_performance__c = ar?.Historical_Ratings_Color__c;
                                    break;
                                }
                            }
                        }
                        
                        for (Charter_Term__c t : terms) {
                            if (t.School__c==os.school__c) {
                                d.charter_term__c = dateToString(t.start_Date__c)
                                     + ' - ' + 
                                dateToString(t.end_Date__c); 
                                break;
                            }
                        }
                        
                        //Changed to view the school School_Open_Curr_Yr__c date
                        d.First_Day_of_School_this_Academic_Year__c = os.school__r.School_Open_Curr_Yr__c;
                        
                        for (Lease__c l : leases) {
                            if (l.Account__c==os.school__c) {
                                if (l.start_date__c!=null) {
                                    d.Lease_term__c = (d.Lease_term__c==null?'':d.Lease_term__c) + '\n '+l.Lease_Nickname__c + '\n '+ dateToString(l.start_Date__c) + ' - ' + dateToString(l.end_Date__c); 
                                }
                            }
                        }
                    }
                }
            } else if (d.recordtypeid==FinanceFcDetailRecType) {
                //Financing Details
                //molinger - get data from FInancial object tied to the CHarter Holder Account
                if (finObjs.size()>0) {
                    Financial__c f = FinancialUtils.getLatestFinRecord(finObjs);
                    String prefix = (f.RecordTypeId==FinancialCtrl.monthlyRecType() ? f.month__c+' ' :(f.RecordTypeId==FinancialCtrl.quarterlyRecType() ? f.Fiscal_Quarter__c+' ' : '')  ) + 'FY'+f.Fiscal_Year__c+': ';
                    d.Current_Year_Surplus_Deficit__c = prefix+'$'+String.format((f.Stated_Net_Income__c==null?0:f.Stated_Net_Income__c).format(), new String[]{'0','number','###,###,##0.00'});
                    d.Indebtedness__c = prefix+'$'+String.format((f.Total_Liabilities__c==null?0:f.Total_Liabilities__c).format(), new String[]{'0','number','###,###,##0.00'});
                    d.Net_Assets__c = prefix+'$'+String.format((f.Net_Assets__c==null?0:f.Net_Assets__c).format(), new String[]{'0','number','###,###,##0.00'});
                } 
                
                for (Opp_School__c os : oppSChools) {
                    if (os.Id==d.Opp_School__c) {
                        //Competitive_Pricing_Situation__c
                        // Discount rate replaced with an average 2020.10.15 J Caughie
                        Decimal discount = 0;
                        Set<Decimal> buffers = new Set<Decimal>();
                        Decimal effRate = 0;
                        Integer fercount = 0;

                        for (Funding_Estimate_Receivable__c fer : fundEstRec ) {
                            buffers.add(fer.Maturity_Buffer__c);
                            effRate+=fer.Effective_Rate__c;
                            fercount+=1;
                            discount += fer.Discount_Rate_formula__c;
                        }

                        if (fercount>1) effrate = effrate/fercount;
                        effrate.round(System.RoundingMode.DOWN);
                        
                        if (fercount>1) discount = discount/fercount;
                        discount.round(System.RoundingMode.DOWN);
                        
                        List<Decimal> bufferList = new List<Decimal>(buffers);
                        bufferList.sort();
                        String buffer = '';
                        for (Decimal de : bufferList) {
                            buffer+=de+' - ';
                        }
                        if (buffer.length()>0) {buffer = buffer.removeend(' - '); } else {buffer = '0';}
                        
                        String pFee = '0';
                        if (os.Opportunity__r.RPA__c!=null) pFee = String.format(os.Opportunity__r.RPA__r.Program_Fee__c.format(), new String[]{'0','number','###,###,##0.00'});
                        
                        d.Competitive_Pricing_Situation__c =
                            // discount + '% (Discount Rate) / ' + 
                            discount.setscale(2) + '% (Avg Discount Rate) / ' + 
                            buffer + ' days (Buffer) / ' + 
                            effRate.setscale(2) + '% (Avg Effective Rate) / ' +
                            '$' + pfee + ' (Program Fee) / ' + 
                            os.Opportunity__r.RPA__r.Default_Transaction_Fee__c + '% transaction fee';
                        
                    //Discount__c (Discount Rate)[Funding Estimate]/Maturity Buffer (Buffer)[Funding Estimate Obj - in the internal summary -may be conga calculation?]/Program_Fee__c (Program Fee) [Related RPA>Terms Letter]/Default_Transaction_Fee__c (Transaction Fee) [Related RPA>Terms Letter)
                    
                        d.school_name__c = os.school__r.Name;
                        d.EWS_Level_UW_Finance__c = os.School__r.ews_level__c;
                        //d.finance_comments__c = 'Plan:\n'+'Risks:\n'+'Mitigants:\n'+'Finance Comments:\n';
                        
                        //Attendances
                        STring schoolAttendanceFY;
                        for (SChool_Attendance__c a : attends ) {
                            if (a.School__c==os.school__c) {
                                //get current active school attendance, and previous 6 records for same fiscal year
                                
                                if (a.Active__c) { 
                                    //this is the fiscal year
                                    schoolAttendanceFY = a.fiscal_Year__c;  
                                    break;                          
                                }
                            }
                        }
                        if (schoolAttendanceFY!=null&&schoolAttendanceFY!='') {
                            //we found an active school attendance record
                            Integer count = 0;
                            Integer intSchoolAttendanceFY = fyToYear(schoolAttendanceFY);
                            for (SChool_Attendance__c a : attends ) {
                                if (a.School__c==os.school__c && a.fiscal_year__c==schoolAttendanceFY&&count<=6) {
                                    
                                    d.Current_Attendance__c = (d.Current_Attendance__c==null?'FY ' +intSchoolAttendanceFY + '\n':d.Current_Attendance__c) + 
                                        a.Attendance_Type__c + ' - ' + a.Total_Attendance__c+' ('+a.report_date__c.month()+'/'+a.report_date__c.day()+'/'+a.report_date__c.year()+')'+'\n';
                                    count+=1;
                                }
                            }
                        }
                                                
                        //Funded Estimate Receivable fields
                        Decimal totalFVAmount = 0;
                        Decimal feePct = 0;
                        Decimal maxDeferred = 0;
                        Decimal numFundEstRecv = 0;
                        for (Funding_Estimate_Receivable__c fer : fundEstRec ) {
                            if (fer.Opp_School__c==os.Id) {
                                numFundEstRecv+=1;
                                //for these fields, sum for all Fund Est Receivables for the school
                                totalFVAmount+=(fer.FV_Amount__c==null?0:fer.FV_Amount__c);
                                feePct=fer.Funding_Estimate__r.Transaction_Fee__c;
                                maxDeferred+=(fer.Max_Deferred_Purchase_Price__c==null?0:fer.Max_Deferred_Purchase_Price__c);
                                
                                if (fer.Included_in_Estimate__c) {
                                    d.Receivables_Description__c = (d.Receivables_Description__c==null?'':d.Receivables_Description__c) + fer.Name+' \n ';                              
                                }
                            }
                        }
                        d.transaction_fee__c = totalFVAmount*feePct/100;
                        d.Current_Funding_Face_Value__c = totalFVAmount;
                        d.Maximum_Deferred_Purchase_Price__c = maxDeferred;
                        
                        //EWS fields
                        for (EWS__c e : ews) {
                            if (e.Account__c==os.school__c) {
                                //EWS record for Financial - Activated record tyoe
                                if (e.recordtypeid==Schema.SObjectType.EWS__c.getRecordTypeInfosByName().get('Financial - Activated').getRecordTypeId()) {
                                    d.EWS_Budgeted_Surplus_Deficit__c = e.Budgeted_Surplus_Deficit__c;
                                    d.EWS_Budgeted__c = e.Budgeted_Revenue__c; 
                                    d.EWS_Fiscal_Quarter__c = e.Quarter_Ending_FY__c;             
                                    d.EWS_Fiscal_YEar__c = fyToYear(e.FIscal_Year__c);
                                    d.Concerning_Google_Alert__c = e.Google_alerts__c;
                                    d.Indication_of_Closure__c = e.Closure_Indication__c;
                                    d.Management_Changes_in_the_Last_Year__c = e.Management_changes_in_past_year__c;
                                    
                                    //set Annual_Estimated_Budget__c field on both detail and header
                                    String bsd = String.format(d.EWS_Budgeted_Surplus_Deficit__c.format(), new String[]{'0','number','###,###,##0.00'});
                                    String bud = String.format(d.EWS_Budgeted__c.format(), new String[]{'0','number','###,###,##0.00'});
                                    Decimal exp = d.EWS_Budgeted__c - d.EWS_Budgeted_Surplus_Deficit__c; 
                                    String expStr = String.format(exp.format(), new String[]{'0','number','###,###,##0.00'});
                                    
                                    String annEstBud;
                                    if (e.Quarter_Ending_FY__c == 'Q3' || e.Quarter_Ending_FY__c == 'Q4') {
                                        annEstBud = 'Projected ' + (d.EWS_Fiscal_Year__c + 1) + ' - ' + '\n' +
                                        '$' + bud + ' Anticipated Revenue\n' +
                                        '$' + expStr + ' Projected Expenses\n' +
                                        '$' + bsd + ' Expected Net Surplus';
                                    } else {
                                        annEstBud = 'Projected ' + d.EWS_Fiscal_Year__c + ' - ' + '\n' +
                                        '$' + bud + ' Anticipated Revenue\n' +
                                        '$' + expStr + ' Projected Expenses\n' +
                                        '$' + bsd + ' Expected Net Surplus';
                                    }

                                    d.Annual_Estimated_Budget__c = annEstBud;
                                                                                    
                                    //Need to set Fiscal Year on HEader object also 
                                    formsForUpdate.get(d.fc_form__c).EWS_Fiscal_Year__c =fyToYear(e.FIscal_Year__c); 
                                    formsForUpdate.get(d.fc_form__c).EWS_Fiscal_Quarter__c = e.Quarter_Ending_FY__c; 
                                    d.EWS_Year_1_Attendance__c = e.Year_1_Latest__c;
                                    d.EWS_Year_2_Attendance__c = e.Year_2__c;
                                    d.EWS_Year_3_Attendance__c = e.Year_3_Oldest__c ;
                                    
                                    break;
                                }
                            }
                        }
                        
                    }
                }
                
            } else if (d.recordtypeid==ServicingFcDetailRecType) {
                //Servicing Details
                for (Opp_School__c os : oppSChools) {
                    if (os.Id==d.Opp_School__c) {
                        d.school_name__c = os.school__r.Name;
                        d.intercept_type__c = os.COE__r.Payment_Type__c;
                        // 2020.05.04 J Caughie - as per Jen/Melissa
                        d.fda_status__c = 'County: ' + os.SChool__r.FDA_Active_County__c + '\n District: ' +  os.SChool__r.FDA_Active_District__c;
                        
                        //Funded Receivable fields
                        Decimal totalFVAmount = 0;
                        Decimal numFundEstRecv = 0;
                        Date maxexpectedpaydate = date.newinstance(2000,01,01);
                        
                        for (Funding_Estimate_Receivable__c fer : fundEstRec ) {
                            if (fer.Opp_School__c==os.Id) {
                                numFundEstRecv+=1;
                                totalFVAmount+=(fer.FV_Amount__c==null?0:fer.FV_Amount__c);
                                maxexpectedpaydate = (fer.expected_pay_date__c > maxexpectedpaydate ? fer.expected_pay_date__c : maxexpectedpaydate);
                            }
                        }
                        
                        Decimal totalExposure = 0;
                        Decimal pastDueAmount = 0;
                        Integer bufferDays = 30;
                        Decimal outstandingFV = 0;
                        integer count = 0;

                        if(!fundRec.isEmpty()) {
                            for (Funded_Receivable__c f : fundRec ) {
                                if (f.School__c==os.school__c) {
                                    //totalExposure+=f.FV_Amount_Due__c;
                                    count+=1;
                                    maxexpectedpaydate = (f.expected_pay_date__c > maxexpectedpaydate ? f.expected_pay_date__c : maxexpectedpaydate);
                                    outstandingFV += f.FV_Amount_Due__c;
                                    
                                    if (f.Expected_Pay_Date__c!=null&&f.Expected_Pay_Date__c.addDays(bufferDays)<os.Opportunity__r.CloseDate) {
                                        pastDueAmount+=f.fv_amount_due__c;
                                        
                                    }
                                }
                                d.Number_of_Receivables_Outstanding__c = count;
                            }
                        }
                        
                        d.Past_Due_Amounts__c = pastDueAmount;
                        //d.Number_Payments_Outstanding_Post_Funding__c = numFundEstRecv + (d.Number_of_Receivables_Outstanding__c==null ? 0 : d.Number_of_Receivables_Outstanding__c);
                        d.Number_Payments_Outstanding_Post_Funding__c = (d.Number_of_Receivables_Outstanding__c==null ? 0 : os.opportunity__r.closedate.monthsbetween(maxexpectedpaydate));
                        //total exposure is:   FV_Total_Amount_Due__c (from School Account record) + FV_Amount__c from the Funded Estimate Receivable object that is tied to the Opp School record
                        totalExposure=(os.school__r.FV_Outstanding_School__c==null?0:os.school__r.FV_Outstanding_School__c) + totalFVAmount;    //changed to FV_Outstanding_School__c from FV_Total_Amount_Due__c
                        d.Fund_Receiv_FV_Amount__c =totalExposure; 
                        d.Current_Outstanding_Face_Value__c = outstandingFV;
                        d.Current_Funding_Face_Value__c = totalFVAmount;
                        List<String> args = new String[]{'0','number','###,###,###.##00'};
                        String s = String.format(totalEXposure.format(), args);
                        d.total_Exposure__c = '$' +s +'';
                        
                        //2019.03.14 J Caughie New COE/District information
                        d.COE_Rating__c = '<strong>Name: </strong>'+os.School__r.COE__r.Name+'<br/>'+
                                        '<strong>Moody\'s Rating: </strong>' + os.School__r.COE__r.Moody_s_Rating__c+'<br/>' +
                                        '<strong>Moody\'s Outlook: </strong>' + os.School__r.COE__r.Moody_s_Outlook__c+'<br/>' +
                                        '<strong>S&P Rating: </strong>' + os.School__r.COE__r.S_P_Rating__c+'<br/>'+
                                        '<strong>S&P Outlook: </strong>' + os.School__r.COE__r.S_P_Outlook__c+'<br/>';

                        d.District_Rating__c = '<strong>Name: </strong>'+os.School__r.School_District__r.Name+'<br/>'+
                                        '<strong>Moody\'s Rating: </strong>' + os.School__r.School_District__r.Moody_s_Rating__c+'<br/>' +
                                        '<strong>Moody\'s Outlook: </strong>' + os.School__r.School_District__r.Moody_s_Outlook__c+'<br/>' +
                                        '<strong>S&P Rating: </strong>' + os.School__r.School_District__r.S_P_Rating__c+'<br/>'+
                                        '<strong>S&P Outlook: </strong>' + os.School__r.School_District__r.S_P_Outlook__c+'<br/>';
                    }
                }
            } 
        }
        update details;
        update formsForUpdate.values();
        return details;
    }
    
    public static Integer fyToYear(String s) {
        Integer returnVal;
        try {
            if (s!=null) {
                returnVal = Integer.valueOf(s.right(2));
                returnVal+=2000;
                return returnVal;
            } else return null; 
        } catch (EXception e) {
            return null;
        }
    }
    
    //input for this method is list of FC FOrms, but shoudl only be for 1 Opp
    public static void populateHeaderCommentFieldsFromSFData(List<FC_Form__c> forms) {
        Set<Id> formIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        
        Id oppId;
        Id acctId;
        Id recTypeId;
        Date closeDate;
        
        for (FC_Form__c d : forms) {
            formIds.add(d.Id);
        }
        
        
        List<FC_Form__c> formsExpanded = [Select Id, RecordTypeId, 
                    Underwriting_Comments__c, Underwriting_Recommendation__c, Underwriting_Review_Section_Comments__c, 
                    Current_Year_Surplus_Deficit__c, Net_Assets__c, Indebtedness__c, Audit_Findings__c, Funding_Plan__c, 
                    Current_Funding_Comments__c, Outstanding_Info_Needed_for_Funding__c, Outstanding_Info_Needed_to_Fund_FIN__c, Outstanding_Info_Needed_to_Fund_SVC__c, 
                    Financial_Review_Comments__c, 
                    Funding_Exposure_Comments__c, 
                    State_Specific_Finance_Comments__c, 
                    Opportunity__r.Id, Opportunity__r.AccountId, Opportunity__r.Recordtypeid, Opportunity__r.CloseDate from FC_Form__c where ID IN:formIds];
        
        System.debug('***** formsExpanded: '+formsExpanded);
            
        for (FC_Form__c f : formsExpanded) {
            oppId = f.Opportunity__r.Id;
            closeDate = f.Opportunity__r.CloseDate;
            acctId = f.Opportunity__r.AccountId;
            recTypeId = f.Opportunity__r.Recordtypeid;
            break;
        }
 
        //2018.03.12 J Caughie - changed logic. Use last closed won as the base
        List<Opportunity> opps = [SELECT Id, recordtypeid FROM Opportunity WHERE AccountId=:acctId 
            AND Id !=:oppId AND CloseDate <=: closeDate AND IsWon = True ORDER BY CloseDate DESC];

        //if no other opp found, we need to pupolate the comment fields that are rich text with Plan, Risk:, etc.
        if (opps.size()==0) { 
            for (FC_Form__c newD : formsExpanded) {
                newD.Underwriting_Comments__c='<b>Plan:<br><br>'+'Risks:<br><br>'+'Mitigants:<br><br>'+'UW Comments:<br><br>';
                newD.Financial_Review_Comments__c='<b>Plan:<br><br>'+'Risks:<br><br>'+'Mitigants:<br><br>'+'FIN Comments:<br><br>';
            }
            update formsExpanded;
            return;
        } else {
                        
            //now we have the opp get the data and populate
            List<FC_Form__c> oldFOrms = [Select Id, Recordtypeid, 
                    Underwriting_Comments__c, Underwriting_Recommendation__c, Underwriting_Review_Section_Comments__c, 
                    Current_Year_Surplus_Deficit__c, Net_Assets__c, Indebtedness__c, Audit_Findings__c, Funding_Plan__c, 
                    Current_Funding_Comments__c, Outstanding_Info_Needed_for_Funding__c, Outstanding_Info_Needed_to_Fund_FIN__c, Outstanding_Info_Needed_to_Fund_SVC__c, 
                    Financial_Review_Comments__c, 
                    Funding_Exposure_Comments__c, 
                    State_Specific_Finance_Comments__c 
                    from FC_Form__c where Opportunity__c=:opps[0].Id];
            
            System.debug('***** oldFOrms: '+oldFOrms);
                    
            for (FC_Form__c oldD : oldForms) {
                for (FC_Form__c newD : formsExpanded) {
                    
                    if (newD.Recordtypeid==oldD.recordtypeid) {
                        if (newD.Recordtypeid==UWFcRecType) {
                            //UW fields
                            newD.Underwriting_Review_Section_Comments__c=oldD.Underwriting_Review_Section_Comments__c;
                            newD.Underwriting_Recommendation__c=oldD.Underwriting_Recommendation__c;
                            newD.Underwriting_Comments__c=(oldD.Underwriting_Comments__c==null?'<b>Plan:<br><br>'+'Risks:<br><br>'+'Mitigants:<br><br>'+'UW Comments:<br><br>':oldD.Underwriting_Comments__c);
                            newD.Outstanding_Info_Needed_for_Funding__c = oldD.Outstanding_Info_Needed_for_Funding__c;
                        }
                        if (newD.Recordtypeid==FinanceFcRecType) {
                            //FIN fields
                            newD.Current_Funding_Comments__c=oldD.Current_Funding_Comments__c;
                            newD.Financial_Review_Comments__c=(oldD.Financial_Review_Comments__c==null?'<b>Plan:<br><br>'+'Risks:<br><br>'+'Mitigants:<br><br>'+'FIN Comments:<br><br>':oldD.Financial_Review_Comments__c);
                            newD.State_Specific_Finance_Comments__c=oldD.State_Specific_Finance_Comments__c;
                            newD.Current_Year_Surplus_Deficit__c =oldD.Current_Year_Surplus_Deficit__c;
                            newD.Net_Assets__c =oldD.Net_Assets__c;
                            newD.Indebtedness__c =oldD.Indebtedness__c;
                            newD.Outstanding_Info_Needed_to_Fund_FIN__c = oldD.Outstanding_Info_Needed_to_Fund_FIN__c;
                            newD.Audit_Findings__c =oldD.Audit_Findings__c;
                            newD.Funding_Plan__c =oldD.Funding_Plan__c;
                            
                        }
                        if (newD.Recordtypeid==ServicingFcRecType) {
                            //Servicing fields
                            newD.Funding_Exposure_Comments__c=oldD.Funding_Exposure_Comments__c;
                            newD.Outstanding_Info_Needed_to_Fund_SVC__c = oldD.Outstanding_Info_Needed_to_Fund_SVC__c;
                        }
                        
                        break;
                    }
                }
            }
            update formsexpanded;
        }
    }
    
    public static List<FC_Form__c> populateHeaderFieldsFromSFData(List<FC_Form__c> forms) {
        Set<Id> oppIds = new Set<Id>();
        Set<Id> rpaIds = new Set<Id>();
        
        Set<Id> chAcctIds = new Set<Id>();
        Set<Id> cmoAcctIds = new Set<Id>();
        
        Map<Id, FC_Form__c> oppFormMap = new Map<Id, FC_Form__c>();
        Map<Id, Opportunity> acctOppMap = new Map<Id, Opportunity>();
        Map<Id, Id> schoolOppIdMap = new Map<Id, Id>();
        
        Set<String> sos_action_item_names_from_acct = new Set<String>{
            'SOS GOOD STANDING CERTIFICATE', 'MANAGEMENT CO. SOS GOOD STANDING CERT.','MANAGEMENT CO. SOS GOOD STANDING CERTIFICATE'};

        Set<String> sos_action_item_names_from_acct_state = new Set<String>{'SOS GOOD STANDING CERTIFICATE (DOMESTIC)'};

        Set<String> uc_action_item_names_from_acct = new Set<String>{'UCC SEARCH'};
        
        Set<String> lien_action_item_names_from_acct = new Set<String>{'COUNTY LIEN SEARCH', 'COUNTY Tax LIEN SEARCH', 'COUNTY TAX LIEN SEARCH (AND LITIGATION SUMMARIES)'};
        
        Set<String> aoi_action_item_names_from_acct = new Set<String>{'MANAGEMENT CO. CERTIFIED AOI\'s', 'CERTIFIED ARTICLES OF INCORPORATION'};
        
        Set<String> action_item_names_from_acct = new Set<String>();
        action_item_names_from_acct.addall(sos_action_item_names_from_acct);
        action_item_names_from_acct.addall(sos_action_item_names_from_acct_state);
        action_item_names_from_acct.addall(uc_action_item_names_from_acct);
        action_item_names_from_acct.addall(lien_action_item_names_from_acct);
        action_item_names_from_acct.addall(aoi_action_item_names_from_acct);
        
        Set<String> action_item_names_from_opp = new Set<String>();
        action_item_names_from_opp.addall(lien_action_item_names_from_acct);                    
        
        List<FC_Form__c> formsForUpdate = new List<FC_Form__c>();
        
        for (FC_Form__c f : forms) {
            if (f.opportunity__c!=null) {oppids.add(f.opportunity__c);}
        }
        
        //get opp and charter holder fields
        Map<Id,Opportunity> opps = new Map<Id,Opportunity>([SELECT Id, Amount, Account.Resolution_GRV_Balance__c, 
            Account.Resolution_FV_Balance__c , NET_Amount_Requested__c, CloseDate, AccountId, RPA__c, Account.Account_Strategy__c, 
            Account.Client_Update__c, Account.Date_CS_Last_Visited_School__c, User__c, User__r.Name, 
            State__c, Account.Name, Account.cmo__r.Name, Account.cmo__c, 
            Account.Default_Discount_Rate__c , Account.Default_Maturity_Buffer__c , Account.Default_Initial_Purchase_Factor__c , 
            RPA__r.Default_Transaction_Fee__c, RPA__r.Program_Fee__c, 
            Initial_Draw_Date__c, Total_Max_Loan_Amount__c, Interest_Rate__c, Commitment_Fee__c, Last_Draw_Date__c, Maturity_Date__c, 
            (Select Id, School__c from Opp_Schools__r)
            FROM Opportunity WHERE id IN:oppIds]);
                    
        for (Opportunity o : opps.values()) {
            //charter hodler acct ids
            if (o.accountId!=null) {chAcctIds.add(o.accountID);acctOppMap.put(o.accountId,o);}
            //get CMO acct ids, needed for the csc action items
            if (o.Account.cmo__c!=null) {cmoAcctIds.add(o.Account.cmo__c);}
            //RPA Ids
            if (o.rpa__c!=null) {rpaids.add(o.rpa__c);}
            //school ids
            if (o.opp_schools__r!=null&&o.opp_schools__r.size()>0) {
                for (Opp_school__c oc : o.opp_schools__r) {
                    schoolOppIdMap.put(oc.school__c, o.Id);
                }
            }
        }
        
        Set<Id> combinedAcctIds = new Set<Id>();
        combinedAcctIds.addall(cmoAcctIds);
        combinedAcctIds.addall(chAcctIds);
        
        //get Funding_Estimates__c agttached to the Opp (Use latest if there are multiple)
        List<Funding_Estimates__c> fe = [Select Id, Opportunity__c,  Discount__c, Total_GRV_Amount__c, Total_FV_Amount__c, Program_Fees_Collected__c,
            Transaction_Fee_Collected__c, Total_Max_Deferred_Purchase_Price__c
            from Funding_Estimates__c where Opportunity__c IN:oppIds order by CreatedDate DESC LIMIT 1];
        
        
        List<RPA__c> rpa = [Select Id, RPA_Face_Value_Estimate__c, RPA_FV_Remaining__c, program_fee__c, Default_Transaction_Fee__c, 
                RPA_FV_Remaining_Estimate__c, RPA_End_Date_Estimate__c, RPA_End_Date__c, Program_Fee_Estimate__c
            from RPA__c where Id IN:rpaids];
            
        //get csc action items attached to the opportunity
        List<CSC_ACtion_Item__c> aiOpp = [Select Id, Action_Item_Name__c, Date_Effective__c, CSC_Action_List__r.Opportunity__c, Opportunity_Id__c, Date_Completed__c from CSC_ACtion_Item__c 
            where CSC_Action_List__r.Opportunity__c IN:oppids
            and Action_Item_Name__c IN: action_item_names_from_opp and Date_Effective__c<>null];
            
        //get csc action items attached to the charter holder acct
        system.debug('!!! combinedAcctIds = ' + combinedAcctIds);
        system.debug('!!! action_item_names_from_acct = ' + action_item_names_from_acct);
        List<CSC_ACtion_Item__c> aiAcct = [
            SELECT Id, 
            Action_Item_Name__c, 
            Date_Effective__c, 
            Account_Id__c, 
            CSC_Action_List__r.Account__r.recordtypeid, 
            CSC_Action_List__r.Account__r.Incorporation_State__r.Name, 
            Date_Completed__c,
            action_item_mapping__c 
            FROM CSC_ACtion_Item__c 
            WHERE (CSC_Action_List__r.Account__c IN:combinedAcctIds)
            AND (Action_Item_Name__c IN : action_item_names_from_acct OR Action_Item_Mapping__c IN : action_item_names_from_acct) 
            AND Date_Effective__c<>null];
        system.debug('!!! aiAcct = ' + aiAcct);
        
        //get  School_Attendance__c recordsfor school accounts
        List<School_Attendance__c> attends = [Select Id, School__c, School__r.Name, Active__c, Attendance_Type__c, 
             Total_Attendance__c, Fiscal_Year__c
             from School_Attendance__c where 
            School__c IN:schoolOppIdMap.keyset() and Active__c=True ORDER BY CreatedDate DESC];
        
        //get Account Strategy/Updates from CHarter Holder Account
        List<Account_Snapshot__c> acctSnaps = [Select Id, recordtypeid, Account_Strategy__c, Account_Updates__c, Department__c, CreatedDate, CreatedBy.Name from 
            Account_Snapshot__c where account__c 
            IN:chAcctIds ORDER BY CreatedDate DESC];
        
        //molinger - get latest Financial object record tied to the Charter Holder Account
        
         List<Financial__c> finObjs = [Select Id, Total_Liabilities__c, Fiscal_Year__c, Fiscal_QUarter__c,Month__c, 
                 RecordTypeId, Net_Assets__c, Going_Concern__c, 
                 Internal_Control_Issues__c, 
                 Account__c, Stated_Net_Income__c, Data_Source__c from Financial__c  
            where account__c IN:chAcctIds and Active__c=true];
        
        for (FC_Form__c f : forms) {
            Opportunity o = opps.get(f.opportunity__c);
                        
            //field mappings
            if (f.recordtypeid==SummaryFcRecType) {
                //summary fc form
                f.State__c = o.state__c;
                f.Account_Manager__c = o.User__r.Name;
                f.Date_CS_Last_Visited_School__c = o.Account.Date_CS_Last_Visited_School__c;
                f.charter_holder__c = o.Account.Name;

                for (Account_Snapshot__c s : acctSnaps) {
                    if (s.recordtypeid==AcctStrategy && (s.Department__c == 'Client Services' || s.Department__c == 'Intervention')) {
                        f.Account_Strategy__c = s.CreatedDate.format('M/d/yyyy') + ' - ' + s.CreatedBy.Name + '\n\n' + s.Account_Strategy__c;
                        break;
                    }
                }
                for (Account_Snapshot__c s : acctSnaps) {
                    if (s.recordtypeid==AcctUpdates && (s.Department__c == 'Client Services' || s.Department__c == 'Intervention')) {
                        f.Client_Update__c = s.CreatedDate.format('M/d/yyyy') + ' - ' + s.CreatedBy.Name + '\n\n' + s.Account_Updates__c;
                        break;
                    }
                }

                f.funding_date__c = o.CloseDate;

            } else if (f.recordtypeid==UWFcRecType) {
                //Underwriting                
                f.State__c = o.state__c;
                f.charter_holder__c = o.Account.Name;
                f.management_company__c = o.Account.cmo__r.Name;
                
                //for each Action Item type we need to loop through all items to get all possible values
                //default to blank
                f.UCC_Search_Results__c= null;
                for(CSC_ACtion_Item__c c: aiAcct) {
                    if(c.action_item_mapping__c != null) {
                        system.debug('!!! mapping is not null');
                        if (uc_action_item_names_from_acct.contains(c.action_item_mapping__c.toUpperCase()) ) {
                            String dtCOmpleted = (c.Date_Effective__c==null ? 'N/A' : 
                                c.Date_Effective__c.month()+'/'+c.Date_Effective__c.day()+'/'+c.Date_Effective__c.year());
                            
                            //see if this AI is for the CHarter or CMO Accounts
                            if (c.CSC_Action_List__r.Account__c==o.AccountId || c.CSC_Action_List__r.Account__c==o.Account.CMO__c) {
                                //there should only one UCC attached to the Charter                            
                                String noFindingsDtEffective = (c.Date_Effective__c==null ? 'N/A' : 
                                    c.Date_Effective__c.month()+'/'+c.Date_Effective__c.day()+'/'+c.Date_Effective__c.year());  
                                
                                if (c.Date_Effective__c!=null && noFindingsDtEffective != 'N/A') {
                                    STring prefix;
                                    if (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDBusAccount) {prefix =' CMO - ';}
                                    else if  (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDCharterAccount) {prefix = ' Charter - ';}
                                    f.UCC_Search_Results__c= prefix + noFindingsDtEffective;
                                }
                            }
                        }
                    }
                }
                
                if (f.UCC_Search_Results__c==null) f.UCC_Search_Results__c='N/A';   
                
                //default to blank
                f.Certified_Articles_of_Incorporation__c=null;
                for(CSC_ACtion_Item__c c: aiAcct) { 
                    if (aoi_action_item_names_from_acct.contains(c.Action_Item_Name__c.toUpperCase())) {  
                        //CMO   
                        String dtCOmpleted = (c.Date_Effective__c==null ? 'N/A' : 
                            c.Date_Effective__c.month()+'/'+c.Date_Effective__c.day()+'/'+c.Date_Effective__c.year());
                            
                        if (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDBusAccount) {
                            if (f.Certified_Articles_of_Incorporation__c==null) {
                                    f.Certified_Articles_of_Incorporation__c= ' CMO - ' +dtCOmpleted;
                            } else {
                                f.Certified_Articles_of_Incorporation__c += '\n CMO - ' +dtCOmpleted;
                            }
                        }
                        
                        //Charter Holder
                        if (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDCharterAccount) {
                            if (f.Certified_Articles_of_Incorporation__c==null) {
                                    f.Certified_Articles_of_Incorporation__c= ' Charter - ' +dtCOmpleted;
                            } else {
                                f.Certified_Articles_of_Incorporation__c += '\n Charter - ' +dtCOmpleted;
                            }
                        }
                    }
                }

                if (f.Certified_Articles_of_Incorporation__c==null) f.Certified_Articles_of_Incorporation__c='N/A';
                
                //default to blank
                f.SOS_Good_Standing__c=null;

                for(CSC_ACtion_Item__c c: aiAcct) { 
                    if (sos_action_item_names_from_acct.contains(c.Action_Item_Name__c.toUpperCase()) || sos_action_item_names_from_acct_state.contains(c.Action_Item_Name__c.toUpperCase())) {
                        String dtCOmpleted = (c.Date_Effective__c==null ? 'N/A' : 
                            c.Date_Effective__c.month()+'/'+c.Date_Effective__c.day()+'/'+c.Date_Effective__c.year());
                        
                        //CMO 
                        if (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDBusAccount) {
                            if (f.SOS_Good_Standing__c==null) {
                                    f.SOS_Good_Standing__c= 'CMO - ' + dtCOmpleted;
                            } else {
                                f.SOS_Good_Standing__c += '\nCMO - ' +dtCOmpleted;
                            }
                        }
                        //Charter Holder
                        if (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDCharterAccount) {
                            if (f.SOS_Good_Standing__c==null) {
                                    f.SOS_Good_Standing__c= ' Charter - ' +dtCOmpleted;
                            } else {
                                f.SOS_Good_Standing__c += '\n Charter - ' +dtCOmpleted;
                            }
                        }
                    }
                }
                if (f.SOS_Good_Standing__c==null) {f.SOS_Good_Standing__c='N/A';}
                
                //default to blank
                f.County_Level_Lien_Search_Results__c=null;
                for(CSC_ACtion_Item__c c: aiAcct) {
                    if (lien_action_item_names_from_acct.contains(c.Action_Item_Name__c.toUpperCase())) {
                        String noFindingsDtCompleted = (c.Date_Effective__c==null ? 'N/A' : 
                            c.Date_Effective__c.month()+'/'+c.Date_Effective__c.day()+'/'+c.Date_Effective__c.year());
                        //there shoudl be only one of these attachedto the Charter  
                        String prefix;
                        if (f.County_Level_Lien_Search_Results__c==null) {
                            if (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDBusAccount) {prefix =' CMO - ';}
                            else if  (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDCharterAccount) {prefix = ' Charter - ';}
                                
                            f.County_Level_Lien_Search_Results__c= prefix + noFindingsDtCompleted;

                        } else {
                            if (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDBusAccount) {prefix =' CMO - ';}
                            else if  (c.CSC_Action_List__r.Account__r.recordtypeid==RecordTypes.IDCharterAccount) {prefix = ' Charter - ';}
                            
                            f.County_Level_Lien_Search_Results__c += prefix + noFindingsDtCompleted;
                        }
                    }
                }

                if (f.County_Level_Lien_Search_Results__c==null) f.County_Level_Lien_Search_Results__c='N/A';
                
                
            } else if (f.recordtypeid==FinanceFcRecType) {
                //Finance fields
                Decimal totalFVAmountFromFE = 0;
                if (fe.size()>0 &&fe[0].Opportunity__c==o.Id) {
                    //Funding estimate fields
                    f.GRV_Left_On_Board__c = (o.Account.Resolution_GRV_Balance__c==null?0:o.Account.Resolution_GRV_Balance__c)  - 
                                            (fe[0].Total_GRV_Amount__c==null?0:fe[0].Total_GRV_Amount__c);
                    f.FV_Left_On_Board__c = (o.Account.Resolution_FV_Balance__c==null?0:o.Account.Resolution_FV_Balance__c)  - 
                                            (fe[0].Total_FV_Amount__c==null?0:fe[0].Total_FV_Amount__c);
                                            
                    totalFVAmountFromFE = (fe[0].Total_FV_Amount__c==null?0:fe[0].Total_FV_Amount__c);
                    f.Fee_Collected_this_transaction__c = fe[0].Program_Fees_Collected__c;
                    f.Transaction_Fee__c = fe[0].Transaction_Fee_Collected__c;
                    f.transaction_fee__c = fe[0].Transaction_Fee_Collected__c;
                } 
                
                //molinger - get data from FInancial object tied to the CHarter Holder Account
                if (finObjs.size()>0) {
                    Financial__c fin = FinancialUtils.getLatestFinRecord(finObjs);
                    
                    String prefix = (fin.RecordTypeId==FinancialCtrl.monthlyRecType() ? fin.month__c+' ' :(fin.RecordTypeId==FinancialCtrl.quarterlyRecType() ? fin.Fiscal_Quarter__c+' ' : '')  ) + 'FY'+fin.Fiscal_Year__c+': ';
                    
                    f.Current_Year_Surplus_Deficit__c = prefix+'$'+String.format((fin.Stated_Net_Income__c==null?0:fin.Stated_Net_Income__c).format(), new String[]{'0','number','###,###,##0.00'});
                    f.Indebtedness__c = prefix+'$'+String.format((fin.Total_Liabilities__c==null?0:fin.Total_Liabilities__c).format(), new String[]{'0','number','###,###,##0.00'});
                    f.Net_Assets__c = prefix+'$'+String.format((fin.Net_Assets__c==null?0:fin.Net_Assets__c).format(), new String[]{'0','number','###,###,##0.00'});
                    
                    if (fin.Going_Concern__c!=null) f.Audit_Findings__c = prefix+'Audit Going Concern: '+fin.Going_Concern__c;
                    if (fin.Internal_Control_Issues__c!=null) f.Audit_Findings__c = (f.Audit_Findings__c == null ? '' : f.Audit_Findings__c + '\r\n') + prefix+'Internal Control Issues: '+fin.Internal_Control_Issues__c;
                } 
                
                for (School_Attendance__c sa : attends) {
                    Id oppId = schoolOppIdMap.get(sa.school__c);
                    if (oppId!=null&&oppId==o.Id) {
                        //this is school for this form
                        f.current_attendance__c = (f.current_attendance__c==null?'':f.current_attendance__c)+
                            sa.Total_Attendance__c+ ' - ' + sa.School__r.Name +  '\n';      
                    }
                }
                        
                //opp fields
                f.initial_draw__c = o.Initial_Draw_Date__c;
                f.Total_Maximum_Loan_Amount__c = o.Total_Max_Loan_Amount__c;
                f.Interest_Rate__c = o.Interest_Rate__c;
                f.Commitment_Fee__c = o.Commitment_Fee__c;
                f.Last_Draw_Date__c = o.Last_Draw_Date__c;
                f.Maturity_Date__c = o.Maturity_Date__c;
                
                //rpa fields
                if (rpa.size()>0 ) {
                    for (RPA__c r : rpa) {
                        if (o.rpa__c==r.Id) {
                            f.RPA_Initial__c = r.RPA_Face_Value_Estimate__c;
                            f.RPA_Remaining__c = r.RPA_FV_Remaining_Estimate__c - totalFVAmountFromFE ;
                            f.RPA_Expiration_Date__c = r.RPA_End_Date_Estimate__c;
                            f.Program_Fee__c = r.Program_Fee_Estimate__c;
                        }   
                    }
                }               
                    
            } else if (f.recordtypeid==ServicingFcRecType) {
                //Servicing Fields - there are no Servicing head fields for now
            }
        }
        
        update forms;
        return formsForUpdate;
    }
    
    public static List<FC_Form__c> createFCForms(Opportunity o) {
        List<FC_Form__c> forms = new List<FC_Form__c>();
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId=:o.AccountId AND Id!=:o.Id AND recordtypeid=:o.recordtypeid ORDER BY CloseDate DESC];
        Id prevOppId;
        Id prevFCFOrmId;
        if (opps.size()>0) {
            prevOppId=opps[0].Id;
        }
        List<FC_Form__c> prevforms = new List<FC_Form__c>();
        if (prevOppId!=null) {
            prevforms = [Select Id from FC_FOrm__c where RecordTypeId=:SummaryFcRecType
                and Opportunity__c=:prevOppId];
        } 
        if (prevforms.size()>0) {
            prevFCFOrmId = prevforms[0].Id; 
        }
        
        if (o.recordtypeid==recordtypes.IDFacilitiesOpp) {
            FC_Form__c f = new FC_Form__c();
            f.opportunity__c = o.Id;
            f.name = 'FC Form: ' + o.Name;
            f.Approval_Tier__c = 'Facilities';
            f.recordtypeid = FacilitiesFcRecType;
            if (prevFCFOrmId!=null) f.Previous_FC_Form__c = prevFCFOrmId;
            forms.add(f);
            insert forms;
        } else {
            //first create summary form
            FC_Form__c f = new FC_Form__c();
            f.opportunity__c = o.Id;
            f.name = 'FC Form: ' + o.Name;
            if (o.RecordTypeId==RecordTypes.IDFOFOpp || o.RecordTypeId==RecordTypes.IDFacilitiesOpp ) f.Email_Final_Approval__c = true;
            f.recordtypeid = SummaryFcRecType;
            f.Approval_Tier__c = 'Working Capital';
            if (prevFCFOrmId!=null) f.Previous_FC_Form__c = prevFCFOrmId;
            forms.add(f);
            insert forms;
            Id summaryFormId = forms[0].Id;
            
            //now create the rest with a link to the summary form
            for (Id i : allFcFormTypes) {
                if (i!=SummaryFcRecType) {
                    f = new FC_Form__c();
                    f.Approval_Tier__c = 'Working Capital';
                    f.opportunity__c = o.Id;
                    f.name = fcRecTypeNames.get(i) + ' FC Charter Level: ' + o.Name;
                    f.recordtypeid = i;
                    if (prevFCFOrmId!=null) f.Previous_FC_Form__c = prevFCFOrmId;
                    f.summary_fc_form__c = summaryFormId;
                    forms.add(f);
                }
            }
            upsert forms;
        }
        return forms;
    }
    
    public static List<FC_Details__c> createFCDetails(List<Opp_School__c> oss) {
        
        Set<Id> osIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<Id,Id> oppOppSchoolMap = new Map<Id,Id>();
        
         for(Opp_School__c oppSchool : oss) {
            osIds.add(opPSchool.Id);
            oppIds.add(oppSchool.opportunity__c);
            oppOppSchoolMap.put(oppSchool.opportunity__c,opPSchool.Id );
        }
        
        Map<Id,Opp_School__c> oppSchoolFull = new Map<Id,Opp_School__c>([Select Id, School__c, Opportunity__c, School__r.Name from Opp_School__c where id IN:osids]);
                
        List<FC_Details__c> details = new List<FC_Details__c>();
        List<FC_Form__c> forms = [Select Id, recordtypeid, Opportunity__c, Opportunity__r.Name from FC_Form__c where Opportunity__c IN:oppIds];
                
        for (FC_Form__c f : forms) {
            for (Opp_School__c os : oppSchoolFull.values() ) {
                if (f.recordtypeid!=SummaryFcRecType && f.recordtypeid!=FacilitiesFcRecType) {
                    FC_Details__c fd = new FC_Details__c();
                    fd.FC_Form__c = f.Id;
                    if (f.recordtypeid==UWFcRecType) fd.recordtypeid = UWFcDetailRecType;
                    if (f.recordtypeid==FinanceFcRecType) fd.recordtypeid = FinanceFcDetailRecType;
                    if (f.recordtypeid==ServicingFcRecType) fd.recordtypeid = ServicingFcDetailRecType;
                    fd.Opp_School__c = os.Id;
                    details.add(fd);
                }
            }
        }
        
        insert details;
        return details;
    }
    
    public static Id financeDirector {
    	get {
            if(financeDirector == null) {
            	try {
                	financeDirector = [Select Id from USer where Finance_Dept_Head__c = true].Id;
            	} catch (Exception e) {}
            }

            return financeDirector;
        }
        private set;
    }

    public static Id uwDirector {
    	get {
            if(uwDirector == null) {
            	try {
                	uwDirector = [Select Id from USer where Underwriting_Dept_Head__c = true].Id;
            	} catch (Exception e) {}
            }

            return uwDirector;
        }
        private set;
    }
    
    public static CSC_Action_Item__c updateCSCActioNItem(CSC_Action_Item__c ai, Id ownerID) {
        
        ai.Date_Completed__c = date.today();
		Id userForAssignment; 	
		if (ai.Department__c=='Finance - Director of Finance and Risk Analysis') {
			userForAssignment = financeDirector;
			
		} else if (ai.Department__c=='Director of Underwriting') {
			userForAssignment = uwDirector;
			
		} else if (ai.Department__c=='Underwriting - LA' 
				|| ai.Department__c=='Legal Assistant') {
			userForAssignment = ai.CSC_Action_List__r.Opportunity__r.Legal_Assistant__c;
			
		} else if (ai.Department__c=='Client Services - AM/ CSR' 
				|| ai.Department__c=='Client Services - CSR'
				|| ai.Department__c=='Client Services - ISR/CSR'
				|| ai.Department__c=='Client Services Rep. (CSR)'
				|| ai.Department__c=='Client Services - AM'
				|| ai.Department__c=='Facilities/AM') {
			userForAssignment = ai.CSC_Action_List__r.Opportunity__r.User__c;
		
		} else if (ai.Department__c=='Financial Analyst') {
            userForAssignment = UserInfo.getUserId();
			
		} else if (ai.Department__c=='Paralegal' 
				|| ai.Department__c=='Facilities Paralegal'
				|| ai.Department__c=='Underwriting - PL'
				) {
			userForAssignment = ai.CSC_Action_List__r.Opportunity__r.Paralegal__c;
		}
		
		//default to owner if user is not found
		if (userForAssignment==null) userForAssignment = ownerId;

		ai.Assigned_To__c = userForAssignment;
        ai.Status__c = 'Completed';
        return ai;
        
    }

    //2019.03.04 J Caughie - added to ignore assignments and assign directly to the user
    public static CSC_Action_Item__c updateActionItem(CSC_Action_Item__c ai, Id userId){
        ai.Date_Completed__c = date.today();
        ai.Assigned_To__c = userId;
        ai.Status__c = 'Completed';
        return ai;
    }

    public static CSC_Action_Item__c nullCSCActioNItem(CSC_Action_Item__c ai, Id ownerID) {
        ai.Date_Completed__c = null;
        ai.Assigned_To__c = null;
        ai.Status__c = '';
        return ai;
    }

}