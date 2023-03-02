/**=====================================================================
 * Charter School Capital
 * Name: MarketRateTriggerHandler
 * Test Class: MarketRateTriggerHandlerTest
 * Description: 
 * Created Date: 2023, Feb 05
 * Created By: Slava Krel
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/

 public with sharing class MarketRateTriggerHandler {
    
    // Add/remove if needed
    public Map<Id, Market_Rate__c> newMap;
    public Map<Id, Market_Rate__c> oldMap;
    public List<Market_Rate__c> trigNew;
    public List<Market_Rate__c> trigOld;

    public MarketRateTriggerHandler(Map<Id, Market_Rate__c> triggerOldMap, Map<Id, Market_Rate__c> triggerNewMap, List<Market_Rate__c> triggerOld, List<Market_Rate__c> triggerNew) {
        this.oldMap = triggerOldMap;
        this.newMap = triggerNewMap;
        this.trigOld = triggerOld;
        this.trigNew = triggerNew;
    }
    
    public void afterUpdate() {
    }

    public void beforeUpdate() {
        activateMarketRate(trigNew, oldMap);
    }

    // BEGIN CUSTOM METHODS BELOW

    public static void activateMarketRate(List<Market_Rate__c> trigNew, Map<Id, Market_Rate__c> oldMap) {

        Id marRateLockedRecordTypeId = Schema.SObjectType.Market_Rate__c.getRecordTypeInfosByDeveloperName().get('Market_Rate_Locked').getRecordTypeId();
        Id marRateRecordTypeId = Schema.SObjectType.Market_Rate__c.getRecordTypeInfosByDeveloperName().get('Market_Rate').getRecordTypeId();
        Id portfolioRecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('Portfolio').getRecordTypeId();
        Id schoolRecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('School').getRecordTypeId();
        Id chRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Charter_Holder').getRecordTypeId();
        Id businessRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business').getRecordTypeId();

        List<Pricing_Rate__c> upsertPricRateList = new List<Pricing_Rate__c>();
        Map<Account, Pricing_Rate__c> schoolsWithNewPr = new Map<Account, Pricing_Rate__c>();
        List<Account> schoolsToUpdate = new List<Account>();
        Market_Rate__c mrToDeactivate = new Market_Rate__c();
        Map<Pricing_Rate__c, Account> pricRateSchoolToRescore = new Map<Pricing_Rate__c, Account>();
        Map<Pricing_Rate__c, Account> pricRatePortfolioToRescore = new Map<Pricing_Rate__c, Account>();

        for(Market_Rate__c marRate : trigNew) {
            Market_Rate__c oldMarlRate = oldMap.get(marRate.id);
            if(marRate.stage__c != oldMarlRate.stage__c && marRate.stage__c == 'Active' && oldMarlRate.stage__c == 'Draft') {

                // confirm MR active only one
                List<Market_Rate__c> activeMarRateList = [SELECT id, RecordTypeId FROM Market_Rate__c WHERE Current_Monthly_Rate__c = true AND id != :marRate.id];
                if(activeMarRateList?.size() == 1) {
                    
                    marRate.Activation_Date__c = Date.today();
                    marRate.Current_Monthly_Rate__c = true;
                    marRate.RecordTypeId = marRateLockedRecordTypeId;

                    activeMarRateList[0].Deactivation_Date__c = Date.today();
                    activeMarRateList[0].Current_Monthly_Rate__c = false;
                    activeMarRateList[0].Stage__c = 'Deactivated';
                    activeMarRateList[0].RecordTypeId = marRateRecordTypeId;
                    mrToDeactivate = activeMarRateList[0];
                    
                    // I - Account
                    // account hierarchy based on the Top_Level_Parent_Account_Id__c field
                    Map<Account, List<Account>> acctAccts = new Map<Account, List<Account>>();
                    // account PART and NotPART of a POTFOLIO accordingly
                    Map<Id, Account> part = new Map<Id, Account>();
                    Map<Id, Account> notPart = new Map<Id, Account>();
                    // these schools ARE NOT part of portfolio
                    Map<Account, List<Pricing_Rate__c>> acctNotPartWithPR = new Map<Account, List<Pricing_Rate__c>>(); 
                    // these schools ARE part of portfolio
                    Map<Account, List<Pricing_Rate__c>> acctPartWithPR = new Map<Account, List<Pricing_Rate__c>>();
                    // accounts (notPart schools) with active PRs
                    Map<Account, Pricing_Rate__c> acctIdandActivePR = new Map<Account, Pricing_Rate__c>();
                    // II - PR - School related
                    // Pricing rate SCHOOL
                    Map<Id, Pricing_Rate__c> schoolMap = new Map<Id, Pricing_Rate__c>();
                    // active PR and related school
                    Map<Pricing_Rate__c, Id> activePRandAcctId = new Map<Pricing_Rate__c, Id>();
                    // III - PR - Portfolio related
                    // Pricing rate PORTFOLIO
                    Map<Id, Pricing_Rate__c> porfolioMap = new Map<Id, Pricing_Rate__c>();

                    Map<Id, Account> acctMap = new Map<Id, Account>([SELECT Id, Name, Nick_Name__c, Current_Pricing_Rate__c, Top_Level_Parent_Account_Id__c FROM Account WHERE WC_Client_Pricing_School__c = true]);
                    Map<Id, Account> allAccounts = new Map<Id, Account>([SELECT Id, Name, Nick_Name__c, Current_Pricing_Rate__c, Top_Level_Parent_Account_Id__c, ParentId, RecordTypeId FROM Account WHERE RecordTypeId = :chRecordTypeId OR RecordTypeId = :businessRecordTypeId]);

                    List<Pricing_Rate__c> prRateList = [SELECT id, recordtypeid, Portfolio_Rate_Record__c, Account__c, Account__r.Top_Level_Parent_Account_Id__c, Deactivation_Date__c, Final_Discount_Rate__c, Stage__c FROM Pricing_Rate__c];

                    for(Pricing_Rate__c prRate : prRateList) {
                        if(prRate.recordtypeid == portfolioRecordTypeId) {
                            porfolioMap.put(prRate.id, prRate);

                        } else if(prRate.recordtypeid == schoolRecordTypeId) {
                            schoolMap.put(prRate.id, prRate);
                            if(prRate.Account__c != null && prRate.Stage__c == 'Active') {
                                activePRandAcctId.put(prRate, prRate.Account__c);
                            }
                        }
                    }

                    // build Map<Account, List<Account>>
                    for(Id a : acctMap.keySet()){
                        Id eighteenDigit = acctMap.get(a).Top_Level_Parent_Account_Id__c;
                        if(acctAccts.containsKey(allAccounts.get(eighteenDigit))) {
                            acctAccts.get(allAccounts.get(eighteenDigit)).add(acctMap.get(a));
                        } else {
                            acctAccts.put(allAccounts.get(eighteenDigit), new List<Account>{acctMap.get(a)});
                        }
                    }

                    // build part and notPart maps
                    for(Account item : acctAccts.keySet()) {
                        if(acctAccts.get(item) != null) {
                            if(acctAccts.get(item)?.size() > 1) {
                                for(Account subItem : acctAccts.get(item)) {
                                    part.put(subItem.id, subItem);
                                }
                            }
                            if(acctAccts.get(item)?.size() == 1) {
                                for(Account subItem : acctAccts.get(item)) {
                                    notPart.put(subItem.id, subItem);
                                }
                            }
                        }
                    }

                    // Map<Account, Pricing_Rate__c> acctIdandActivePR where PR is active if exist 
                    for(Pricing_Rate__c ap : activePRandAcctId.keySet()) {
                        if(notPart.containsKey(activePRandAcctId.get(ap))) {
                            acctIdandActivePR.put(notPart.get(activePRandAcctId.get(ap)), ap);
                        }
                    }

                    // START THE CORE LOGIC
                    // create, clone, deactivate PRs
                    for(Id schoolId : acctMap.keySet()) {
                        Account school = acctMap.get(schoolId);
                        Pricing_Rate__c pricRate;
                        // not part of portfolio
                        if(acctIdandActivePR.containsKey(school)) { // Map<Account, Pricing_Rate__c>
                            Pricing_Rate__c deactivatePR = acctIdandActivePR.get(school);
                            deactivatePR.Stage__c = 'Deactivated';
                            deactivatePR.Deactivation_Date__c = Date.today();
                            upsertPricRateList.add(deactivatePR);
                            pricRate = clonePricingRateNotPortfolio(deactivatePR, marRate, school);
                            upsertPricRateList.add(pricRate);
                            schoolsWithNewPr.put(school, pricRate);
                        } else {
                            pricRate = createPricingRateNotPortfolio(marRate, school);
                            upsertPricRateList.add(pricRate);
                            pricRateSchoolToRescore.put(pricRate, school); // these we need to rescore and activate after
                            schoolsWithNewPr.put(school, pricRate);
                        }

                        // part of portfolio
                        if(acctPartWithPR.containsKey(school)) {

                        }
                    }

                } else {
                    marRate.addError('There is more than one or no active Market Rate record in the system. Contact you System Administrator.');
                }
            }    
        }

        // create records, rescore, activate, update account
        if(!upsertPricRateList.isEmpty()) {
            upsert upsertPricRateList;

            // rescoring and activation here
            Map<Id, Charter_Term__c> charterTermsMap = new Map<Id, Charter_Term__c>();
            List<Pricing_Rate__c> rescore = new List<Pricing_Rate__c>();
            List<Pricing_Rate__c> prRatesToActivate = new List<Pricing_Rate__c>();
            List<School_Attendance__c> allSchAtt = [SELECT id, name, Fiscal_Year__c, Total_Attendance__c, Report_Date__c FROM School_Attendance__c WHERE Total_Attendance__c != null AND Fiscal_Year__c != null ORDER BY Report_Date__c DESC];
            for (Charter_Term__c chTerm : [SELECT Id, School__c, Type__c FROM Charter_Term__c WHERE Status__c = 'Active']) {
                charterTermsMap.put(chTerm.School__c, chTerm);
            }



            
            // school
            if(!pricRateSchoolToRescore.isEmpty()) {
                // do rescore and activate

                // build a Map<Account, List<School_Attendance__c>> for studCnts
                Map<Id, Account> acctMapSchoolToRescore = new Map<Id, Account>(pricRateSchoolToRescore.values());
                Map<Account, List<School_Attendance__c>> acctSAMap = new Map<Account, List<School_Attendance__c>>();
                for(School_Attendance__c schAtt : allSchAtt){
                    if(acctSAMap.containsKey(acctMapSchoolToRescore.get(schAtt.School__c))){
                        acctSAMap.get(acctMapSchoolToRescore.get(schAtt.School__c)).add(schAtt);
                    } else {
                        acctSAMap.put(acctMapSchoolToRescore.get(schAtt.School__c), new List<School_Attendance__c>{schAtt});
                    }
                }

                for(Pricing_Rate__c rateScoring : pricRateSchoolToRescore.keySet()) {
                    rateScoring.Rescored__c = true;
                    Account school = pricRateSchoolToRescore.get(rateScoring);
                    // set charter terms
                    if (charterTermsMap.containsKey(rateScoring.Account__c)) {
                        rateScoring.Charter_Term_Record__c = charterTermsMap.get(rateScoring.Account__c).Id;
                        rateScoring.Charter_Renewed__c = getCharterRenewed(charterTermsMap.get(rateScoring.Account__c).Type__c);

                        // set student count
                        List<School_Attendance__c> studCnts = acctSAMap.get(school);
                        if(!studCnts.isEmpty()) {
                            School_Attendance__c mstRcntAttend = studCnts[0];
                            School_Attendance__c lstYrAttend;
                            School_Attendance__c twoYrAttend;
                            if (mstRcntAttend.Fiscal_Year__c != null) {
                                rateScoring.Student_Count_Record__c = mstRcntAttend.Id;
                                rateScoring.Student_Count_Current_FY__c = mstRcntAttend.Total_Attendance__c; 
                                String lastFY = getFYValue('lastFY', mstRcntAttend.Fiscal_Year__c);
                                String twoLastFY = getFYValue('twoLastFY', mstRcntAttend.Fiscal_Year__c);
                                for (School_Attendance__c sc : studCnts) {
                                    if (sc.Fiscal_Year__c==lastFY && (lstYrAttend==null || lstYrAttend.Report_Date__c <sc.Report_Date__c)) {
                                        lstYrAttend = sc;
                                    }
                                    if (sc.Fiscal_Year__c==twoLastFY && (twoYrAttend==null || twoYrAttend.Report_Date__c <sc.Report_Date__c)) {
                                        twoYrAttend = sc;
                                    }
                                }
                                if (lstYrAttend!=null) {rateScoring.Student_Count_1_FY_Prior__c = lstYrAttend.Total_Attendance__c;}
                                if (twoYrAttend!=null) {rateScoring.Student_Count_2_FY_Prior__c = twoYrAttend.Total_Attendance__c;}
                            }
                        }
                    }
                    rescore.add(rateScoring);
                }
                if(!rescore.isEmpty()) {
                    update rescore;
                    for(Pricing_Rate__c prRecord : rescore){
                        prRecord.Activation_Date__c = Date.today();
                        prRecord.Stage__c = 'Active';
                        prRatesToActivate.add(prRecord);
                    }
                    update prRatesToActivate;
                }
            }

            // portfolio 
            if(!pricRatePortfolioToRescore.isEmpty()) {
                // do rescore
                // do activate
            }

            

            // update account
            for(Account schUpd : schoolsWithNewPr.keySet()) {
                Id prId = schoolsWithNewPr.get(schUpd).id;
                Decimal fdr = schoolsWithNewPr.get(schUpd).Final_Discount_Rate_Portfolio__c;
                if(prId != null && fdr != null) {
                    schUpd.Current_Pricing_Rate__c = prId;
                    schUpd.Pricing_Discount_Rate__c = fdr;
                    schoolsToUpdate.add(schUpd);
                }                
            }
            update schoolsToUpdate;
        }
        update mrToDeactivate;
    }

    public static String getFYValue(String year, String actFY) {
        String fyValue;
        String curFYStrt = actFY.substringBefore('-');
        String curFYEnd = actFY.substringAfter('-');
        Integer currentFYStart = Integer.valueOf(curFYStrt); 
        Integer currentFYEnd = Integer.valueOf(curFYEnd);
        if(year == 'lastFY') {
            fyValue = String.valueOf(currentFYStart-1)+'-'+String.valueOf(currentFYEnd-1);
        }
        if(year == 'twoLastFY') {
            fyValue = String.valueOf(currentFYStart-2)+'-'+String.valueOf(currentFYEnd-2);
        }
        return fyValue;
    }

    public static String getCharterRenewed(String type) {
        String charterRenewed;
        if (type == 'Initial' || type == 'Extension') {charterRenewed = 'No';}
        if (type == 'Renewal') {charterRenewed = 'Yes';}
        return charterRenewed;
    }

    public static Pricing_Rate__c createPricingRateNotPortfolio(Market_Rate__c marRate, Account school) {
        Pricing_Rate__c prRateCreate = new Pricing_Rate__c(
            Market_Rate__c = marRate.id,
            Reporting_Date__c = Date.today(),
            Reporting_Month__c = PricingRateTriggerHandler.reportingMonth(),
            Account__c = school.id,
            Pricing_Name__c = school.Nick_Name__c + ' - ' + 'School Pricing ' + PricingRateTriggerHandler.today()
        );
        return prRateCreate;
    }

    public static Pricing_Rate__c clonePricingRateNotPortfolio(Pricing_Rate__c prRate, Market_Rate__c marRate, Account school) {
        Pricing_Rate__c prRateCreate = new Pricing_Rate__c(
            Market_Rate__c = marRate.id,
            Stage__c = 'Active',
            Final_Discount_Rate_Portfolio__c = prRate.Final_Discount_Rate__c, // old name Final_Effective_Rate__c
            Reporting_Date__c = Date.today(),
            Reporting_Month__c = PricingRateTriggerHandler.reportingMonth(),
            Account__c = school.id,
            Pricing_Name__c = school.Nick_Name__c + ' - ' + 'School Pricing ' + PricingRateTriggerHandler.today(),
            Activation_Date__c = Date.today(),
            Student_Count_Record__c = prRate.Student_Count_Record__c,
            Student_Count_Current_FY__c = prRate.Student_Count_Current_FY__c,
            Student_Count_1_FY_Prior__c = prRate.Student_Count_1_FY_Prior__c,
            Student_Count_2_FY_Prior__c = prRate.Student_Count_2_FY_Prior__c
        );
        return prRateCreate;
    }
}







// ALL FROM DAN
// public with sharing class MarketRateTriggerHandler {
    
//     public static Boolean triggerActive = true;

//     public static void determineIfActivatingRate(List<Market_Rate__c> triggerRates) {
//         if (!triggerActive) return;
//         for (Market_Rate__c newRate : triggerRates) {
//             if (newRate.Current_Monthly_Rate__c) {
//                 launchPricingRateDuplicationBatch();
//                 break;
//             }
//         }
//     }

//     public static void determineIfActivatingRate(List<Market_Rate__c> triggerRates, Map<Id, Market_Rate__c> oldRates) {
//         if (!triggerActive) return;
//         for (Market_Rate__c updRate : triggerRates) {
//             Market_Rate__c oldRate = oldRates.get(updRate.Id);
//             if (updRate.Current_Monthly_Rate__c && !oldRate.Current_Monthly_Rate__c) {
//                 launchPricingRateDuplicationBatch();
//                 break;
//             }
//         }
//     }

//     private static void launchPricingRateDuplicationBatch() {
//         if (!triggerActive) return;
//         CloneAllActivePricingRatesBatch b = new CloneAllActivePricingRatesBatch();
//         Database.executeBatch(b);
//     }
// }