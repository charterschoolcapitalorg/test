/*=====================================================================
 * Charter School Capital, Inc
 * Name: ClientSummaryHelper
 * Description: Common classes
 * Created Date: [04/20/2015]
 * Created By: [John Caughie]
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]               [FirstName LastName]         [Short description for changes]
 =====================================================================*/

public with sharing class CharterSummaryHelper{

    //Get aggregate list of school attendances per Calendar Year for VF page
    public static List<AggregateResult> attendanceSummary(List<Account> listCharters){
    
        List<School_Attendance__c> sa = new List<School_Attendance__c>([SELECT id, School__c, total_attendance__c, report_date__c, School__r.Charter_Holder__r.Id
                                                                        FROM School_Attendance__c 
                                                                        WHERE School__r.Charter_Holder__c IN :listCharters
                                                                        ORDER BY School__c, Report_Date__c DESC]);
        
        List<Id> schAttIds = new List<Id>();
    	for(Account acc : listCharters){
            integer year = 9999;
            for(School_Attendance__c schAtt : sa){
                if (schAtt.Report_Date__c.year() != year && acc.id == schAtt.School__r.Charter_Holder__r.Id){
                    schAttIds.add(schAtt.id);
                    year = schAtt.Report_Date__c.year();
                }
            }
        }
        
        List<AggregateResult> returnAtts = new list<AggregateResult >([SELECT Calendar_Year(Report_Date__c) yr, Sum(Total_Attendance__c) total 
                                                                        FROM School_Attendance__c 
                                                                        WHERE id = :schAttIds 
                                                                        GROUP BY Calendar_Year(Report_Date__c) 
                                                                        ORDER BY Calendar_Year(Report_Date__c) DESC]);
        return returnAtts;

    }

    //Get aggregate list of Funded Receivables per Calendar Year for VF page
    public static List<AggregateResult> annualReceivableSummary(List<Account> listCharters){
    
        List<AggregateResult> annualSummary = new List<AggregateResult>([SELECT Calendar_Year(Purchase_Date__c) yr, Sum(GRV_Amount__c) grv, Sum(FV_Amount__c) fv, Sum(Upfront_Purchase_Price__c) pp,
                                                                                Sum(Payments_Applied__c) paid, Sum(FV_Amount_Due__c) open, Sum(Max_Deferred_Purchase_Price__c) mdpp, Sum(Discount_Amount__c) disc
                                                                            FROM Funded_Receivable__c 
                                                                            WHERE Charter_Holder__c IN :listCharters AND MDPP_Adjustment__c != true 
                                                                            GROUP BY Calendar_Year(Purchase_Date__c)
                                                                            ORDER BY Calendar_Year(Purchase_Date__c) Desc]);
        return annualSummary;
    }

    //Get total of Funded Receivables per Calendar Year for VF page
    public static List<AggregateResult> totalReceivableSummary(List<Account> listCharters){
    
        List<AggregateResult> totals = new List<AggregateResult>([SELECT Sum(GRV_Amount__c) grv, Sum(FV_Amount__c) fv, Sum(Upfront_Purchase_Price__c) pp, Sum(Payments_Applied__c) paid, Sum(FV_Amount_Due__c) open, Sum(Max_Deferred_Purchase_Price__c) mdpp, Sum(Discount_Amount__c) disc
                            										FROM Funded_Receivable__c
                            										WHERE Charter_Holder__c IN :listCharters AND MDPP_Adjustment__c != true]);
        return totals;
    }  
}