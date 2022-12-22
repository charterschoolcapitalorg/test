/**=====================================================================
 * Appirio, Inc
 * Name: FundingEstimate_InternalSummary
 * Description: Funding Estimate Intrnal Summary
 * Created Date: [06/../2014]
 * Created By: (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [Feb 09, 2017]               [John Caughie]              [Added feature showing Charter Terms termination date]
 =====================================================================*/
public class FundingEstimate_InternalSummary {

    public Funding_Estimates__c fundingEst{get;set;}
    public list<OppSchoolWrapper> listOppSchoolWrapper{get;set;}
    public Opportunity opp{get;set;}
    public double totalMaxDefPPrice{get;set;}
    public double RPAProjectedBalance{get;set;}
    public double RPAPercentFunded{get;set;}
    public double RPAFeeCollected{get;set;}
    public double RPAFeeRemaining{get;set;}
    public double GRVResoProjectedBalance{get;set;}
    public double FVResoProjectedBalance{get;set;}

    public FundingEstimate_InternalSummary(){
        String fundingEstId = ApexPages.CurrentPage().getParameters().get('Id');
        fundingEst = getFundingEstDetails(fundingEstId);
        RPAProjectedBalance = 0.00;
        RPAPercentFunded = 0.00;
        if(fundingEst <> null){
            getListExistingFundingEstimateReceivables();
            if(fundingEst.Opportunity__c <> null){
                getOpportunityDetail();
                if(opp.RPA__c <> Null){
                    if(opp.RPA__r.RPA_FV_Remaining_Estimate__c <> null){
                        RPAProjectedBalance = opp.RPA__r.RPA_FV_Remaining_Estimate__c - fundingEst.Total_FV_Amount__c;//Total IP FV
                    }
                    if(opp.RPA__r.RPA_Face_Value_Estimate__c <> null && opp.RPA__r.RPA_Face_Value_Estimate__c <> 0){
                        RPAPercentFunded = ((opp.RPA__r.RPA_Face_Value_Estimate__c - RPAProjectedBalance) / opp.RPA__r.RPA_Face_Value_Estimate__c * 100).setScale(2);
                    }
                    if(opp.RPA__r.RPA_Program_Fee_Collected__c <> null){
                        if(FundingEst.Program_Fees_Collected__c <> null){
                            RPAFeeCollected = opp.RPA__r.RPA_Program_Fee_Collected__c + FundingEst.Program_Fees_Collected__c;
                        }else{
                            RPAFeeCollected = opp.RPA__r.RPA_Program_Fee_Collected__c;
                        }
                        if(opp.RPA__r.Program_Fee_Estimate__c <> null){
                            RPAFeeRemaining = opp.RPA__r.Program_Fee_Estimate__c - RPAFeeCollected;
                        }
                    }

                    if(opp.Account.Resolution_GRV_Balance__c <> null){
                        GRVResoProjectedBalance =  opp.Account.Resolution_GRV_Balance__c - fundingEst.Total_GRV_Amount__c;
                    }

                    if(opp.Account.Resolution_FV_Balance__c <> null){
                        FVResoProjectedBalance =  opp.Account.Resolution_FV_Balance__c - fundingEst.Total_FV_Amount__c;
                    }



                }
            }
        }

    }

    private void getOpportunityDetail(){
        opp = new Opportunity();
        for(Opportunity o : [select id, Name, RPA__r.Id, RPA__c, RPA__r.RPA_Face_Value_Estimate__c, RPA__r.Percent_Funded__c,
                                RPA__r.Program_Fee_Estimate__c, Account.Name, CloseDate, RPA__r.Program_Fee_Percent_Estimate__c, 
                                RPA__r.RPA_Program_Fee_Collected__c, RPA__r.Remaining_Fee_to_Collect_Estimate__c, RPA__r.Percent_Fee_Collected_Estimate__c,
                                Funded_Date__c, NET_Amount_Requested__c, RPA__r.RPA_FV_Remaining_Estimate__c, Account.Resolution_GRV__c,
                                Account.Resolution_GRV_Balance__c, Account.Resolution_FV__c, Account.Resolution_FV_Balance__c, RPA__r.RPA_End_Date_Estimate__c
                             from Opportunity
                             where id = : fundingEst.Opportunity__c limit 1]){
            opp = o;
        }
    }

    private Funding_Estimates__c getFundingEstDetails(Id fundingEstId){

        list<Funding_Estimates__c> listFundingEst = [Select id, Opportunity__c, Discount__c, Transaction_Fee_Collected__c,
                                            Program_Fees_Collected__c, Unpaid_Balance_Receivables_Collected__c,
                                            Description_of_Unpaid_Balance_Receivable__c, Application_Fee_Credit__c,
                                            Penalty_Interest__c, Blocked_Account_Fee_Collected__c, Bond_or_Other_Payment__c,
                                            Refund_Reimbursements__c, Transaction_Fee__c, Net_to_School__c,Total_Discount_Amount__c,
                                            Total_GRV_Amount__c, Total_FV_Amount__c, Total_Upfront_Purchase_Price__c, Total_Donated_Discount_Value__c,
                                            Discount_Donated_Opp__c, Net_after_Donation__c
                from Funding_Estimates__c where id=:fundingEstId limit 1];
        if(!listFundingEst.isEmpty()){
            return listFundingEst[0];
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Funding Estimate Record does not exist'));
        }
        return null ;
    }

    private void getListExistingFundingEstimateReceivables(){
        totalMaxDefPPrice = 0;
        list<Funding_Estimate_Receivable__c> listFER = [select id, Name, Purchase_Date__c, Maturity_Buffer__c, Initial_Purchase_Factor__c,
                        Included_in_Estimate__c, School__c, FV_Amount__c, Discount_Amount__c, Upfront_Purchase_Price__c,
                        Max_Deferred_Purchase_Price__c, Days_Outstanding__c, Maturity_Date__c,
                        GRV_Amount__c, Expected_Pay_Date__c, Opp_School__r.Name, Opp_School__c, Opp_School__r.School__r.Charter_Termination__c, Effective_Rate__c,                  //2017.02.09 J Caughie added Opp_School__r.School__r.Charter_Termination__c
                        Is_not_a_Business_Day__c, Donated_Discount_Receivable__c, Discount_Rate__c, Discount_Rate_formula__c
                    from Funding_Estimate_Receivable__c
                    where Funding_Estimate__c = :fundingEst.Id and Included_In_Estimate__c = true];

        map<Id, OppSchoolWrapper> mapOppSchoolIdWrapper = new map<Id, OppSchoolWrapper>();
        OppSchoolWrapper oppWrapper;
        for(Funding_Estimate_Receivable__c fer : listFER){
            if(!mapOppSchoolIdWrapper.containsKey(fer.Opp_School__c)){
                mapOppSchoolIdWrapper.put(fer.Opp_School__c, new OppSchoolWrapper(fer.School__c, fer.Opp_School__r.School__r.Charter_Termination__c));
            }
            oppWrapper = mapOppSchoolIdWrapper.get(fer.Opp_School__c);
            oppWrapper.listFERForOppSchool.add(fer);

            if(fer.GRV_Amount__c <> null){
                oppWrapper.totalGrv = oppWrapper.totalGrv + fer.GRV_Amount__c;
            }

            if(fer.Upfront_Purchase_Price__c <> null){
                oppWrapper.totalUPP = oppWrapper.totalUPP + fer.Upfront_Purchase_Price__c;
            }
            if(fer.FV_Amount__c <> null){
                oppWrapper.totalIPFV = oppWrapper.totalIPFV + fer.FV_Amount__c;
            }
            if(fer.Discount_Amount__c <> null){
                oppWrapper.totalDiscount = oppWrapper.totalDiscount + fer.Discount_Amount__c;
            }
            if(fer.Max_Deferred_Purchase_Price__c <> null){
                totalMaxDefPPrice = totalMaxDefPPrice + fer.Max_Deferred_Purchase_Price__c;
                oppWrapper.totalMaxDefPPrice = oppWrapper.totalMaxDefPPrice + fer.Max_Deferred_Purchase_Price__c;
            }
            if(fer.Is_not_a_Business_Day__c){
                oppWrapper.purchaseDateAlert = true;
            }
        }
        listOppSchoolWrapper = mapOppSchoolIdWrapper.values();
    }

    /*
    Wrapper class to group FER rcords based on School
    */
    public class OppSchoolWrapper{
        public String oppSchoolName{get;set;}
        public list<Funding_Estimate_Receivable__c> listFERForOppSchool{get;set;}
        public double totalGrv{get;set;}
        public double totalUPP{get;set;}
        public double TotalIPFV{get;set;}
        public double totalDiscount{get;set;}
        public double totalMaxDefPPrice{get;set;}
        public Date charterTermination{get;set;}                                                //2017.02.09 J Caughie charter termination date
        public Boolean purchaseDateAlert{get;set;}

        // constructor
        // this will be used when creating list with all the total amounts
        public OppSchoolWrapper(String oppSchoolName, Date charterTermination){
            this.OppSchoolName = oppSchoolName;
            this.listFERForOppSchool = new list<Funding_Estimate_Receivable__c>();
            this.totalGrv = 0;
            this.totalUPP = 0;
            this.TotalIPFV = 0;
            this.totalDiscount = 0;
            this.totalMaxDefPPrice = 0;
            this.charterTermination = charterTermination;
            this.purchaseDateAlert = false;
        }
    }
}