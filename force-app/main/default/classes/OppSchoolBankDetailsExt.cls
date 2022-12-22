/**=====================================================================
 * Name: OppSchoolBankDetailsExt
 * Description: 
 * Created Date: 
 * Created By: 
 * Date Modified                Modified By                 Description of the update
 * 
 * 2022.06.13                   Slava Krel                  Usage picklist value change   
 =====================================================================================**/
public with sharing class OppSchoolBankDetailsExt {

    private final Opportunity opp;

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public OppSchoolBankDetailsExt(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
    }

    public List<Bank_Usage__c> getOppSchoolsBanks() {
        List<Bank_Usage__c> banks = new List<Bank_Usage__c>();
        banks = [Select Account__r.Name, Account_Name__c, Account_Number__c, Routing_Number__c, Reference__c, Usage__c, Bank__r.Name 
                FROM Bank_Usage__c 
                WHERE Account__c IN (SELECT School__c FROM Opp_School__c WHERE Opportunity__c = :opp.Id) 
                    AND Usage__c = :'School Funding Account'
                ORDER BY Account__r.Name];

        return banks;
    }

    public List<Account> getOppSchoolsDetails(){

        List<Account> accs = [Select Name, EWS_Level_Visual__c, Date_Opened__c, Grade_Level_Served__c, School_District__c, COE__c, Legal_Name__c, Authorizer_A__c,
                (Select Name, Attendance_Type__c, Fiscal_Year__c, Report_Date__c, Total_Attendance__c From School_Attendance__r WHERE Active__c = TRUE),
                (Select Name, End_Date__c, Location__c, Start_Date__c, Comments__c, Landlord__c, Type__c From Leases__r WHERE Active__c = TRUE),
                (Select Name, Purchase_ID__c, School__r.Name, FV_Amount_Due__c, FV_Amount__c, Purchase_Date__c, Expected_Pay_Date__c From Funded_Receivables__r WHERE Status__c = 'Active' ORDER BY Purchase_Date__c DESC),
                (Select Name, Description__c, Fiscal_Year__c, Report_Date__c, Total_Enrollment__c From Enrollments__r ORDER BY Fiscal_Year__c ASC LIMIT 3),
                (Select Name, Start_Date__c, End_Date__c, Status__c, Authorizer__r.Name, Term__c From Terms__r WHERE Status__c = 'Active'),
                (Select Name, Account_Number__c, Routing_Number__c, Bank__r.Name From Bank_Usage1__r WHERE Usage__c = 'School Funding Account'),
                (Select Name, Type__c, Client_Alert_Details__c From Client_Alerts__r WHERE Active__c = TRUE)
                From Account a
                WHERE id in (SELECT School__c FROM Opp_School__c WHERE Opportunity__c = :opp.Id)];

        System.debug(accs);
        return accs;
    }

    public List<Client_Alert__c> getOppCharterClientAlerts(){

        List<Client_Alert__c> alerts = [Select Name, Type__c, Client_Alert_Details__c
                From Client_Alert__c
                WHERE Account__c = :opp.AccountId AND Active__c = TRUE];

        System.debug(alerts);
        return alerts;

    }

    public List<CSC_Action_Item__c> getOppCharterActionItems(){

        List<CSC_Action_Item__c> charterItems = [Select Name, Status__c, Action_Item_Name__c, Sort_Order__c, Date_Requested__c,
                                                    Received_Date__c, Review_Date__c, Expiration_Date__c,
                                                    Next_Action_Date__c, Comments__c, Order__c, Assigned_To__r.Name
                                                    From CSC_Action_Item__c 
                                                    WHERE CSC_Action_List__r.Account__c = :opp.AccountId 
                                                        AND CSC_Action_List__r.Action_List_Name__c LIKE '%File Review%' 
                                                    ORDER BY Order__c];

        System.debug(charterItems);
        return charterItems;

    }

    public List<CSC_Action_Item__c> getOppCharterCMOActionItems(){

        List<CSC_Action_Item__c> cmoItems = [Select Name, Status__c, Action_Item_Name__c, Sort_Order__c, Date_Requested__c,
                                                    Received_Date__c, Review_Date__c, Expiration_Date__c,
                                                    Next_Action_Date__c, Comments__c, Order__c, Assigned_To__r.Name
                                                    From CSC_Action_Item__c 
                                                    WHERE CSC_Action_List__r.Account__c = :opp.Account.CMO__c 
                                                        AND CSC_Action_List__r.Action_List_Name__c = 'Management Company' 
                                                    ORDER BY Order__c];

        System.debug(cmoItems);
        return cmoItems;

    }

    public List<CSC_Action_List__c> getOppSchoolActionLists(){

        List<Opp_School__c> oppSchools = [SELECT School__c FROM Opp_School__c WHERE Opportunity__c = :opp.Id];
        List<Id> ids = new List<Id>();
        for(Opp_School__c o : oppSchools){
            ids.add(o.School__c);
        }


        List<CSC_Action_List__c> schoolLists = [Select Account__r.Name, (Select Name, Status__c, Action_Item_Name__c, Sort_Order__c, Date_Requested__c,
                                                    Received_Date__c, Review_Date__c, Expiration_Date__c,
                                                    Next_Action_Date__c, Comments__c, Order__c, Assigned_To__r.Name
                                                    From CSC_Action_Items__r Order BY Order__c)
                                                    From CSC_Action_List__c
                                                    WHERE Account__c in :ids AND Action_List_Name__c LIKE '%File Review%'];

        System.debug(schoolLists);
        return schoolLists;

    }

    @InvocableMethod(label='Get Active Attendance Records' description='Inserts the accounts specified and returns the IDs of the new accounts.')
    public static List<List<School_Attendance__c>> getActiveAttendances(List<Id> oppIds){
        List<School_Attendance__c> atts = new List<School_Attendance__c>();
        List<List<School_Attendance__c>> listAttendances = new List<List<School_Attendance__c>>();
        List<Id> schoolIds = new List<Id>();
        List<Opp_School__c> oppSchools = [SELECT Id, School__r.Id FROM Opp_School__c WHERE Opportunity__r.Id in :oppIds];
        for(Opp_School__c o : oppSchools){
            schoolIds.add(o.School__r.Id);
        }
        atts = [Select School__c, Name, Attendance_Type__c, Fiscal_Year__c, Report_Date__c, Total_Attendance__c From School_Attendance__c WHERE Active__c = true and School__c in :schoolIds];
        //atts = [Select School__c, Name, Attendance_Type__c, Fiscal_Year__c, Report_Date__c, Total_Attendance__c From School_Attendance__c WHERE School__c in :schoolIds];
        listAttendances.add(atts);
        return listAttendances;
    }


}