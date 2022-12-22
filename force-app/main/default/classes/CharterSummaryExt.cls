/*=====================================================================
 * Charter School Capital, Inc
 * Name: CharterSummaryExt
 * Description: Extension for CharterSummary VF Page
 * Created Date: [04/20/2015]
 * Created By: [John Caughie]
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]               [FirstName LastName]         [Short description for changes]
 =====================================================================*/

public with sharing class CharterSummaryExt {

    private Account acct {get; set;}
    private List<Account> listCharters {get; set;}

    public CharterSummaryExt(ApexPages.StandardController stdController) {
        acct = (Account)stdController.getRecord();
        listCharters = new List<Account>();
        listCharters.add(acct);
        System.debug(listCharters);
    }

    public String getBop(){
        List<Account> bop = new List<Account> ([SELECT Bop__r.Name FROM Account WHERE id = :acct.id]);
        String bopName = bop[0].Bop__r.Name;
        return bopName;
    }

    
    //Get list of aggregate school attendances per charter for VF page
    public List<AggregateResult> getSchoolAtt() {
         List<AggregateResult> sa =  CharterSummaryHelper.attendanceSummary(listCharters);
         return sa;
    }

    //Get summary of aggregate funded receivables per charter for VF page
    public List<AggregateResult> getFundedRecSummary(){
        List<AggregateResult> fr =  CharterSummaryHelper.annualReceivableSummary(listCharters);    
        return fr;
    
    }
    
    //Get summary of aggregate funded receivables for VF page    
    public List<AggregateResult> getCharterRecSummary(){
        List<AggregateResult> crs =  CharterSummaryHelper.totalReceivableSummary(listCharters);  
        return crs;

    }        
}