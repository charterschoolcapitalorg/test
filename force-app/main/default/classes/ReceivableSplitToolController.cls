/**=====================================================================
 * Appirio, Inc
 * Name: ReceivableSplitToolController
 * Description: [Task T-272509 : Receivable Split VF Page - Jaipur first spec]
 * Created Date: [04/16/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                     Description of the update
 * [MON DD, YYYY]               [FirstName LastName]            [Short description for changes]
 *  08.21.2014                  John Caughie                    Added field for Receivable_Type__c
 *  11.06.2014                  John Caughie                    Added fields for Current Draw Note to FR & Refinance Date to DrTx
 *  05.06.2016                  John Caughie                    Added Non-financeable Reason to queries
 =====================================================================*/
public with sharing class ReceivableSplitToolController {

    public list<ReceivableSplitWrapper> listWrapperTab1{get;set;}
    public list<ReceivableSplitWrapper> listWrapperTab2{get;set;}
    public double splitPercent{get;set;}
    public Id payOutDateId{get;set;}
    public Funded_Receivable__c dummyReceivable{get;set;}

    // constructor
    public ReceivableSplitToolController(ApexPages.StandardController sc){
        splitPercent = 0.0;
        payOutDateId = sc.getId();
        listWrapperTab1 = new list<ReceivableSplitWrapper>();
        listWrapperTab2 = new list<ReceivableSplitWrapper>();
        populateWrapperforTab1();
    }

    // method to populate wrapper to be shown on tab 1
    private void populateWrapperforTab1(){
        for(Funded_Receivable__c rec : getListReceivable()){
            listWrapperTab1.add(new ReceivableSplitWrapper(rec));
        }
    }

    // method to get list receivable records for pay out date record
    private List<Funded_Receivable__c> getListReceivable(){
        List<Funded_Receivable__c> listRecevable = [Select f.purchaseUID__c, f.forReview__c, f.clientID__c, f.Upfront_Purchase_Price__c,
                                                        f.StopInterestCalculation__c, f.Split_From_Receivable__c,
                                                        f.Source_Payout_Date_Record__c, f.Source_Opportunity__c,
                                                        f.Source_Funding_Estimate_Receivable__c,
                                                        f.School__c, f.RecordTypeId,
                                                        f.Receivable_Interest__c,
                                                         f.Discount_Rate__c,
                                                         f.RPA__c, f.Purchase_Date__c,
                                                         f.Payments_Applied__c, f.PCSRC_Purchase_Date__c,f.Opportunity_Owner_ID__c, f.Name,
                                                         f.Max_Deferred_Purchase_Price__c, f.Maturity_Date__c, f.Maturity_Buffer__c,
                                                         f.MDPP_Adjustment__c, f.Lien_Holder__c, f.Final_Payment_Date__c,
                                                         f.Initial_Purchase_Factor__c, f.Id, f.Gain__c, f.GRV_Amount__c, f.GRV_Amount_Due__c,
                                                          f.Financeable__c, f.Non_financeable_Reason__c, f.FV_Amount__c,
                                                          f.FV_Amount_Due__c, f.Expected_Pay_Date__c,
                                                          f.Distribution_Date__c,
                                                          f.Description__c, f.Days_Outstanding__c,
                                                          f.Daily_Rate__c, f.Competitive_Pricing__c,
                                                          f.Charter_Holder__c,f.Calculator_Audit_Log__c,f.Attendance_Audit_Log__c, f.Receivable_Type__c,
                                                          f.Current_Draw_Note__c, f.Source_School_Attendance_Record__c,
                                                          f.Issue__c, f.Notes__c
                                                    From Funded_Receivable__c f
                                                    where Source_Payout_Date_Record__c = :payOutDateId];
        if(!listRecevable.isEmpty()){
            return listRecevable;
        }

        return new List<Funded_Receivable__c>();
    }

    // method to be called on clicking of Calculate Splits on tab 2
    public pagereference calculateSplits(){
        listWrapperTab2 = new list<ReceivableSplitWrapper>();
        dummyReceivable = new Funded_Receivable__c();
        for(ReceivableSplitWrapper wrapper : listWrapperTab1){
            if(wrapper.isSelected){
                wrapper.SplitValue = ((splitPercent * wrapper.rec.GRV_Amount__c)/100).setScale(0);
                wrapper.NewValue = wrapper.rec.GRV_Amount__c - wrapper.SplitValue;
                listWrapperTab2.add(wrapper);
            }
        }
        return null;
    }

    // Method to be called on clicking of Apply Splits on tab 2
    public void applySplits(){
        list<Funded_Receivable__c> listReceivableToUpsert = new list<Funded_Receivable__c>();
        Funded_Receivable__c rec;
        Funded_Receivable__c clonedRec;
        if(dummyReceivable.Name == null || dummyReceivable.Name == '' ||
                            dummyReceivable.Expected_Pay_Date__c == null || dummyReceivable.Distribution_Date__c == null){
            apexPages.addMessage(new ApexPages.Message(Apexpages.Severity.Error,
                'Split-Off Receivable Name, Expected Pay Date, and Distribution Date are required to apply splits'));
            return;
        }
        map<Id, Funded_Receivable__c> mapRecIdClonedRec = new map<Id, Funded_Receivable__c>();

        for(ReceivableSplitWrapper wrapper : listWrapperTab2){
            rec = wrapper.rec;
            clonedRec = rec.clone(false, true);

            clonedRec.source_payout_date_record__c = null;
            clonedRec.Split_From_Receivable__c  = rec.Id;
            clonedRec.Name = dummyReceivable.Name;
            clonedRec.Expected_Pay_Date__c = dummyReceivable.Expected_Pay_Date__c;
            clonedRec.Distribution_Date__c = dummyReceivable.Distribution_Date__c;

            // populate split values in cloned rec
            clonedRec.GRV_Amount__c = wrapper.splitValue;
            rec.GRV_Amount__c = wrapper.newValue;

            if(rec.FV_Amount__c <> null){
                clonedRec.FV_Amount__c = ((splitPercent * rec.FV_Amount__c)/100).setScale(0);
                rec.FV_Amount__c = rec.FV_Amount__c - clonedRec.FV_Amount__c;
            }

            if(rec.Max_Deferred_Purchase_Price__c <> null){
                clonedRec.Max_Deferred_Purchase_Price__c = ((splitPercent * rec.Max_Deferred_Purchase_Price__c)/100).setScale(0);
                rec.Max_Deferred_Purchase_Price__c = rec.Max_Deferred_Purchase_Price__c - clonedRec.Max_Deferred_Purchase_Price__c;
            }

            if(rec.Upfront_Purchase_Price__c <> null){
                clonedRec.Upfront_Purchase_Price__c = ((splitPercent * rec.Upfront_Purchase_Price__c)/100).setScale(0);
                rec.Upfront_Purchase_Price__c = rec.Upfront_Purchase_Price__c - clonedRec.Upfront_Purchase_Price__c;
            }

            listReceivableToUpsert.add(rec);
            mapRecIdClonedRec.put(rec.Id, clonedRec);
        }

        listReceivableToUpsert.addAll(mapRecIdClonedRec.values());

        system.debug('ORIGINAL : ' + listReceivableToUpsert);
        system.debug('CLONED : ' + listReceivableToUpsert);
        try{
            upsert listReceivableToUpsert;
            list<Draw_Note_TX__c> listDrawNoteTxToUpsert = new list<Draw_Note_TX__c>();
            Draw_Note_TX__c clonedDrawNoteTX;

            for(Draw_Note_TX__c drawNoteTx : [Select d.View__c, d.Status__c, d.Purchase_Date__c, d.PurchaseID__c, d.Name,
                                                    d.Line_Number__c, d.LegacyParentID__c, d.LegacyID__c, d.Last_Activity_Date__c,
                                                    d.Id, d.Funded_Receivable__c, d.Draw_Note__c, d.DrawHeaderID__c, d.DrawDetailID__c,
                                                    d.Discount_Amount__c, d.Daily_Interest_Amount__c, d.DailyInterest_Unamortized__c,
                                                    d.DailyInterest_Transfer__c, d.Current__c, d.Class__c,
                                                    d.Amount_Borrowed__c, d.Refinanced_Date__c
                                            From Draw_Note_TX__c d
                                            Where Funded_Receivable__c in : mapRecIdClonedRec.keySet()]){

                clonedDrawNoteTX = drawNoteTx.clone(false, true);
                clonedDrawNoteTX.Funded_Receivable__c = mapRecIdClonedRec.get(drawNoteTx.Funded_Receivable__c).Id;
                clonedDrawNoteTX.Amount_Borrowed__c = ((splitPercent * drawNoteTx.Amount_Borrowed__c)/100).setScale(0);

                drawNoteTx.Amount_Borrowed__c = drawNoteTx.Amount_Borrowed__c - clonedDrawNoteTX.Amount_Borrowed__c;

                listDrawNoteTxToUpsert.add(drawNoteTx);
                listDrawNoteTxToUpsert.add(clonedDrawNoteTX);
            }

            if(!listDrawNoteTxToUpsert.isEmpty()){
                upsert listDrawNoteTxToUpsert;
            }


        }catch(Exception ex){
            system.debug('exception while inserting/updating records ' + ex.getMessage());
        }
    }


    /**************
    Inner Class : ReceivableSplitWrapper
    isSelected : indicates whether the receivable record is selected on tab 1 or not
    rec : Receivable__c record
    newValue : new FA_Amount__c for the receivable record
    splitValue : FA_Amount for the cloned receivable record
    ***************/
    public class ReceivableSplitWrapper{
        public boolean isSelected{get;set;}
        public Funded_Receivable__c rec{get;set;}
        public double newValue{get;set;}
        public double splitValue{get;set;}

        public ReceivableSplitWrapper(Funded_Receivable__c rec){
            this.isSelected = false;
            this.rec = rec;
            this.newValue = 0.0;
            this.SplitValue = 0.0;
        }

    }
}