public with sharing class AccountManagementReportCtrl {
    
    // public AccountManagementReportCtrl() {}

    @AuraEnabled(cacheable=true)
    public static List<AccountManagementReportWrapper> getAccountData(){
        
        List<AccountManagementReportWrapper> accWrappers = new List<AccountManagementReportWrapper>();
        Set<ID> charterIds = new Set<ID>();

        Map<Id,AggregateResult> openRecs = new Map<id,AggregateResult>([SELECT Charter_Holder__r.ID, MAX(Source_Payout_Date_Record__r.Receivable_Representative_Date__c) lastRec, COUNT(Id) os, SUM(FV_Amount_Due__c) fvDue FROM Funded_Receivable__c WHERE Status__c = 'Active' AND RecordType.DeveloperName = 'Funded_Receivable' GROUP BY Charter_Holder__r.ID]);
        charterIds = openRecs.keySet();
        
        Map<Id, String> effRateMap = new Map<Id, String>();
        for(Funded_Receivable__c fr : [SELECT Charter_Holder__c, Effective_Rate__c, Purchase_Date__c FROM Funded_Receivable__c WHERE Status__c = 'Active' AND RecordType.DeveloperName = 'Funded_Receivable' AND MDPP_Adjustment__c = FALSE ORDER BY Charter_Holder__c, Purchase_Date__c DESC]){
            if(!effRateMap.containsKey(fr.Charter_Holder__c)){
                effRateMap.put(fr.Charter_Holder__c, fr.Effective_Rate__c + '%');
            }
        }
        
        //Find accounts with receivables that weren't system generated - cannot find an end date for those
        Set<Id> accountsWithNonDatedRecs = new Set<Id>();
        for(Funded_Receivable__c fr : [SELECT Charter_Holder__c, Effective_Rate__c, Purchase_Date__c FROM Funded_Receivable__c WHERE Status__c = 'Active' AND RecordType.DeveloperName = 'Funded_Receivable' AND MDPP_Adjustment__c = FALSE AND Source_Payout_Date_Record__c = null ORDER BY Charter_Holder__c, Purchase_Date__c DESC]){
            accountsWithNonDatedRecs.add(fr.Charter_Holder__c);
        }
        
        Map<Id,AggregateResult> openWcOpps = new Map<id,AggregateResult>([SELECT Account.ID, MIN(CloseDate) nextWB FROM Opportunity WHERE Whiteboard_Opportunity_WC__c = true GROUP BY Account.ID]);
        
        List<Account> accs = new List<Account>();
        accs = [SELECT Id, Name, Operating_State__r.Name, Owner.Name, Latest_Account_Strategy__c, Latest_Account_Update__c FROM Account WHERE id IN :charterIds ORDER BY Operating_State__r.Name, Name];
        
        for(Account a : accs){
            AccountManagementReportWrapper accWrapper = new AccountManagementReportWrapper();
            String closeDate = 'n/a';
            if(openWcOpps.get(a.Id)!=null){
                closeDate = ((DateTime)openWcOpps.get(a.Id).get('nextWB')).formatGmt('dd MMM');
            }
            String recOut;
            if(openRecs.get(a.Id).get('lastRec')!=null){
                recOut = ((DateTime)openRecs.get(a.Id).get('lastRec')).formatGmt('MMM YY');
            } else {
                recOut = 'Not calculable';
            }
            if(accountsWithNonDatedRecs.contains(a.Id)){
                recOut = 'Not calculable';
            }
            // accWrapper.acc = a;
            accWrapper.accUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Account/' + a.Id + '/view';
            accWrapper.accName = a.Name;
            accWrapper.repUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Report/00O70000004SWKH/view?fv0=' + a.Id;
            accWrapper.linkName = 'Active Receivables';
            accWrapper.accOwner = a.Owner.Name;
            accWrapper.recCount = (Integer)openRecs.get(a.Id).get('os');
            accWrapper.accState = a.Operating_State__r.Name;
            accWrapper.nextWhiteboardOpp = closeDate;
            accWrapper.faceValueDue = (Decimal)openRecs.get(a.Id).get('fvDue');
            accWrapper.boughtUntil = recOut;
            accWrapper.lastEffectiveRate = effRateMap.get(a.Id);
            accWrapper.latestStrategy = a.Latest_Account_Strategy__c;
            accWrapper.latestUpdate = a.Latest_Account_Update__c;
            accWrappers.add(accWrapper);
        }

        return accWrappers;
    }

    // Owner list calculated dynamically in LWC component
    // @AuraEnabled(cacheable=true)
    // public static List<String> getOwnerPicklist(){

    //     Set<String> ownerSet = new Set<String>();
    //     for(Funded_Receivable__c fr : [SELECT Charter_Holder__r.ID, Charter_Holder__r.Owner.Name FROM Funded_Receivable__c WHERE Status__c = 'Active' AND RecordType.DeveloperName = 'Funded_Receivable']){
    //         ownerSet.add(fr.Charter_Holder__r.Owner.Name);
    //     }

    //     List<String> ownerList = new List<String>(ownerSet);
    //     ownerList.sort();
    //     ownerList.add(0, 'All');
    //     // System.debug(ownerList);
    //     return ownerList;

    // }

}