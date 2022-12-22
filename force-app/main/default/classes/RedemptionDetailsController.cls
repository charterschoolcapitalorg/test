/**=====================================================================
 * Appirio, Inc
 * Name: RedemptionDetailsController
 * Description: T-271502 : Custom Controller class for RedemptionDetails VF page to allocate Receivables to a Redemption
 * Created Date: [04/27/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * [05/12/2014]                 [Noopur Sundriyal]          [T-277641 - Create a Custom Setting for Page Size]
 * [05/25/2014]                 [Rajeev Arya]               [T-280412 - Create Program Fee Allocation]
 * [05/26/2014]                 [Rajeev Arya]               [T-280413 - Create OTHER Allocation]
 * [06/02/2014]                 [Rahul Agrawal]             [Replace Redemption__c.Face_Amount_Applied_Fees__c to Redemption__c.Face_Amount_Applied_Fee__c]
 * [06/13/2014]                 [Rajeev Arya]               [I-117964 - OTHER amount shows zero]
 * [06/23/2014]                 [Rajeev Arya]               [I-118064 - Replace the DrawNote LKP field on Funded Receivable]
 * [06/23/2014]                 [Rajeev Arya]               [I-117958 - Allow Redemption of Unassigned Receivables]
 * [06/24/2014]                 [Rajeev Arya]               [I-118991 - Show INVESTOR Name on Redemption UI]
 * [06/27/2014]                 [Rajeev Arya]               [I-119371 - Add DATE PAID override]
 * [06/27/2014]                 [Rajeev Arya]               [I-118987 - Adding, changes and removing fields on Redemption UI]
 * [06/27/2014]                 [Rajeev Arya]               [I-119342 - Save Allocations creates multiple entries]
 * [06/27/2014]                 [Rajeev Arya]               [I-117920 - Rename PAYMENT SUBS]
 * [04/22/2016]                 [John Caughie]              [Added DBI to SOQL queries]
 * [08/29/2016]                 [John Caughie]              [Added Set for Charter Holder and changed SOQL query from School to Charter]
 * [09/20/2016]                 [John Caughie]              [Logic for interest payment on Loans]
 * [09/29/2016]                 [John Caughie]              [Added payment type]
 * [04/18/2017]                 [John Caughie]              [Added allocation previous balance/payment date details]
  =====================================================================*/

public class RedemptionDetailsController {
    public account acc { get; set; }
    public redemption__c red { get; set; }
    public redemption__c red1 { get; set; }
    public list<Funded_Receivable__c> receiveList { get; set; }
    public list<Allocation__c> allocateList { get; set; }
    public list<RPA_Redemption__c> RPARedemptionList { get; set; }
    public list<Payment_Sub__c> paymentSubList  { get; set; }
    public list<Payment__c> paymentList  { get; set; }
    public String selectedschool {get;set;}
    //public set<String> setLienHolders = new set<String>();
    public set<ID> setDrawNoteIDs = new set<ID>();
    //public list<String> listLienHolders = new list<String>();
    public list<ID> listDrawNoteIDs = new list<ID>();
    //public list<String> AllPayors { get; set; }
    public Allocation__c newallocateRow { get; set; }
    public list<Allocation__c> toBeInsertedAllocatelist = new list<Allocation__c>();
    public list<RPA_Redemption__c> toBeInsertedRPARedemptions = new list<RPA_Redemption__c>();
    public Boolean BeforeRedemptionSection {get; set;}
    public Boolean AfterRedemptionSection {get; set;}
    public Boolean viaAccountPage {get; set;}
    public Boolean RedemptionAllocation {get; set;}
    public Boolean PaymentCrossed {get;set;}
    public Boolean RemainingAmountCrossed {get;set;}
    public Boolean NegativeAmount {get;set;}
    public Boolean AllocationsSaved {get;set;}
    public Boolean RPARedemptionsSaved {get;set;}
    public Boolean SaveRedButton {get;set;}
    public Boolean SaveOtherFeesButton {get;set;}
    public Boolean OtherFeesTextBox {get;set;}
    public Boolean PAAButton {get;set;}
    public Boolean SaveAllocButton {get;set;}
    public Boolean SaveRPAFeesButton {get;set;}
    //ublic Boolean validPayor {get;set;}
    public Boolean validAmtReceived {get;set;}
    public Boolean Unassigned {get;set;}
    public Boolean ShowInterest {get;set;}                                                                              //2017.01.09 J Caughie - Show/Hide interest
    public Boolean DisableTextBoxes {get;set;}
    public set<ID> AllSchoolID = new set<ID>();
    public list<ID> allReceivableID = new list<ID>();
    public set<ID> allRPAIds = new set<Id>();
    public List<FundedReceivableWrapper> RowList {get; set;}
    public List<FundedReceivableWrapper> RowListPage {get; set;}
    public List<AllocationWrapper> WrapperAllocateList {get; set;}
    public List<RPARedemptionWrapper> WrapperRPARedList {get; set;}
    public list<RPAWrapper> WrapperRPAList {get;set;}
    public list<RPA__c> RPAList = new list<RPA__c>();
    public String sortDirection = 'DESC'; //Sort Order
    public String sortExp = 'School'; //initial sort field
    public Map<Integer,FundedReceivableWrapper> ReceivablesMap = new Map<Integer,FundedReceivableWrapper>();
    public map<ID, Draw_Note_TX__c> RecToActiveDRTXMap = new map<ID, Draw_Note_TX__c>();
    public Map<Integer,RPAWrapper> RPAMap = new Map<Integer,RPAWrapper>();
    public Map<String,list<FundedReceivableWrapper>> SchoolToAllReceivablesMap = new Map<String,list<FundedReceivableWrapper>>();
    public Map<String,list<FundedReceivableWrapper>> SchoolToUnassignedReceivablesMap = new Map<String,list<FundedReceivableWrapper>>();
    public Map<ID,Allocation__c> receiveAllocationMap = new Map<ID,Allocation__c>();
    public Map<ID,RPA_Redemption__c> RPAToRPARedemptionMap = new Map<ID,RPA_Redemption__c>();
    public Integer i;
    public integer IdChosen {get;set;}
    public Double RedFaceAmount {get;set;}
    public Decimal RedFaceAmountFees {get;set;}
    public Decimal RedRemitToSchool {get;set;}
    public Decimal RedFeesCollected {get;set;}
    public Double RedRemainAmount {get;set;}
    public String CharterHolder {get;set;}
    public String OtherFees {get;set;}
    //public String Payor {get;set;}
    private List<Account> accounts;
    public Integer selectedPageNumber{get;set;} // Page number of form table
    public PaginationUtility formListPagination{get;set;}
    public String tabOpt {get;set;}
    public Decimal OtherFee;
    public Decimal PreviousOtherFee;
    public Set<ID> charterHolders = new Set<ID>();                                                                  //2016.08.29 J Caughie - added to fix RPA issue
    public Map<Id, Funded_Receivable__c> idToFundedReceivableMap = new Map<Id, Funded_Receivable__c>();             //2017.04.18 J Caughie - added to store previous balance details

    public RedemptionDetailsController() {
        PreviousOtherFee = 0.00;
        RowListPage = new List<FundedReceivableWrapper>();
        paymentSubList = new list<Payment_Sub__c>();
        paymentList = new list<Payment__c>();
        i = 0;
        RedFaceAmount = 0.00;
        RedFeesCollected = 0.00;
        RedRemitToSchool = 0.00;
        WrapperAllocateList = new list<AllocationWrapper>();
        WrapperRPARedList = new list<RPARedemptionWrapper>();
        SaveRedButton = false;
        SaveOtherFeesButton = true;
        OtherFeesTextBox = false;
        PAAButton = false;
        SaveAllocButton= true;
        SaveRPAFeesButton = true;
        BeforeRedemptionSection = true;
        AfterRedemptionSection = false;
        RedemptionAllocation = false;
        Unassigned = false;
        validAmtReceived = false;
        DisableTextBoxes = false;
        //validPayor = false;
        red = new Redemption__c();

        //If(ApexPages.currentPage().getParameters().get('id') == null)
        //{
            //viaAccountPage = false;
        //}
        //red = [select school__c from redemption__c where id =: ApexPages.currentPage().getParameters().get('id')];
        if (ApexPages.currentPage().getParameters().containsKey('Redemptionid')){

            red = [select Date_Paid__c, Payee__c, Other_Fees__c,Face_Amount_Applied_Fee__c, name, Id, School__c, all_to_school__c,Amount_Received__c, Type__c,Date_Received__c, Date_Cleared__c, DBI_Payment__c,
                    Face_Amount_Applied__c, Remaining_Amount__c, Description__c, Payor__c, Payment_Sub__r.Amount__c, Total_Interest_from_Allocations__c, State_Aid__c, non_State_Aid__c
                    from redemption__c
                    where id =: ApexPages.currentPage().getParameters().get('Redemptionid')];
            if(red.School__c != null){
                    red1 = [select name from redemption__c where id =: red.id];
                    RedFaceAmount = red.Face_Amount_Applied__c;
                    RedFeesCollected = red.Face_Amount_Applied_Fee__c;
                    if(red.Payment_Sub__r.Amount__c != null){
                          RedRemitToSchool = red.Payment_Sub__r.Amount__c;
                    }
        
                    system.debug('here1');
                    RedRemainAmount = red.Remaining_Amount__c;
                    if(RedRemainAmount == 0){
                        //PAAButton = true;
                    }
                    acc = [select name, accountnumber, Charter_Holder__r.name, Charter_Holder__c from account where id =: red.School__c];
                    CharterHolder = acc.Charter_Holder__r.name;
                    if(acc.Charter_Holder__c != null){
                        for(account accn:[select id 
                                                        from account 
                                                        where Charter_Holder__c = : acc.Charter_Holder__c
                                                        and id in (select school__c from Funded_Receivable__c)])
                            {
                                AllSchoolID.add(accn.Id);
                                charterHolders.add(acc.Charter_Holder__r.Id);                                               //2016.08.29 J Caughie - Added to fix RPA issue
                            }
                    }
        
                    AllSchoolID.add(acc.id);
                    charterHolders.add(acc.Charter_Holder__r.Id);                                                           //2016.08.29 J Caughie - Added to fix RPA issue
                    BeforeRedemptionSection = false;
                    AfterRedemptionSection = true;
                    SaveRedButton = true;
        
                    If(red.all_to_school__c != true){
                          RedemptionAllocation = true;
                    }
        
                        if(red.Other_Fees__c != null){
                                OtherFees = String.valueOf(red.Other_Fees__c);
                                OtherFeesTextBox = true;
                        }
            }
            else{
                AfterRedemptionSection = true;
                BeforeRedemptionSection = false;
                SaveRedButton = true;
                PAAButton = true;
                OtherFeesTextBox = true;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This Redemption is not related to any School. Please link it to a School');
                ApexPages.addMessage(myMsg);
            }
        }
        else{
        acc = [select name, accountnumber, Charter_Holder__r.name, Charter_Holder__c from account where id =: ApexPages.currentPage().getParameters().get('id')];
            CharterHolder = acc.Charter_Holder__r.name;
            if(acc.Charter_Holder__c != null){
                for(account accn:[select id 
                                                from account 
                                                where Charter_Holder__c = : acc.Charter_Holder__c
                                                and id in (select school__c from Funded_Receivable__c)])

                    {
                        AllSchoolID.add(accn.Id);
                        charterHolders.add(acc.Charter_Holder__r.Id);                                                           //2016.08.29 J Caughie - Added to fix RPA issue
                    }
            }
            
            AllSchoolID.add(acc.id);
            charterHolders.add(acc.Charter_Holder__r.Id);                                                                       //2016.08.29 J Caughie - Added to fix RPA issue
        }

        //AllPayors = [select name from payor__c];

        if (red.Remaining_Amount__c == 0){
            list<Payment_Sub__c> tempPaySubList = [select id from payment_sub__c where redemption__c =: red.id limit 1];
            if (!tempPaySubList.isEmpty()){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Payment Stubs for the selected Allocations have already been created and saved');
                ApexPages.addMessage(myMsg);
                PAAButton = true;
            }
        }
        getReceivableListWithPaymentTextBox();
        getAllocationList();
        system.debug('check3');
        getRPAListWithFeeTextBox();
        getRPARedemptionList();
    }

    public void getReceivableListWithPaymentTextBox(){
            
        for(Draw_Note_TX__c drtx : [select id, Funded_Receivable__c,name,status__c,Draw_Note__r.name, Draw_Note__r.Investor__r.name, 
                                                                draw_note__c 
                                                                from Draw_Note_TX__c 
                                                                where status__c = 'Active']){
                RecToActiveDRTXMap.put(drtx.Funded_Receivable__c, drtx);
        }
        system.debug('check4');
        
        receiveList = [select school__r.Charter_Holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c, Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c,
                        Description__c, Loan_Interest_Due__c, Last_Payment_Received__c
                        from Funded_Receivable__c
                        where school__c in : AllSchoolID
                        and Status__c = 'Active'];

        RowList = new List<FundedReceivableWrapper>();
        FundedReceivableWrapper tr;
        for(Funded_Receivable__c receive : receiveList) {
            //String RecName, String CharterHolder, String School, Date PurchaseDate, Date ExpPayDate, Date DistributionDate, String Description, Decimal FVAmount
            //RecFVAmountDue = receive.FV_Amount_Due__c;
            idToFundedReceivableMap.put(receive.Id, receive);                                                                   //2017.04.18 J Caughie - create a map of Funded Receivables
            Draw_Note_TX__c DnTx = new Draw_Note_TX__c();
            if( RecToActiveDRTXMap.containsKey(receive.Id)){
                                DnTx = RecToActiveDRTXMap.get(receive.Id);
                                
                    tr = new FundedReceivableWrapper(receive.ID, receive.name, receive.school__r.Charter_Holder__r.name, receive.School__r.name,
                                                                        DnTx.Draw_Note__r.name,receive.Purchase_Date__c, receive.Expected_Pay_Date__c,
                                                                        receive.Distribution_Date__c,receive.Description__c,receive.FV_Amount_Due__c,
                                                                        receive.FV_Amount__c,'',i++, receive.Loan_Interest_Due__c, 0);
            }
            else{
                tr = new FundedReceivableWrapper(receive.ID, receive.name, receive.school__r.Charter_Holder__r.name, receive.School__r.name,
                                                                        null,receive.Purchase_Date__c, receive.Expected_Pay_Date__c,
                                                                        receive.Distribution_Date__c,receive.Description__c,receive.FV_Amount_Due__c,
                                                                        receive.FV_Amount__c,'',i++, receive.Loan_Interest_Due__c, 0);
            }
            if(tr.Description == null){
                tr.Description = '-';
            }
            if(tr.DrawNote == null){
                tr.DrawNote = '-';
            }
            RowList.add(tr);

            ReceivablesMap.put(tr.RowID,tr);

            allReceivableID.add(receive.Id);
        }
        
        for(FundedReceivableWrapper frWrap : RowList){
                if(SchoolToAllReceivablesMap.containsKey(frWrap.School)){
                        SchoolToAllReceivablesMap.get(frWrap.School).add(frWrap);
                }
                else{
                SchoolToAllReceivablesMap.put(frWrap.School,new list<FundedReceivableWrapper>{frWrap});
            }
                if(frWrap.DrawNote == '-'){
                    if(SchoolToUnassignedReceivablesMap.containsKey(frWrap.School)){
                                SchoolToUnassignedReceivablesMap.get(frWrap.School).add(frWrap);
                        }
                        else{
                        SchoolToUnassignedReceivablesMap.put(frWrap.School,new list<FundedReceivableWrapper>{frWrap});
                    }
                }
        }
        /*while(k < RowList.size()){
            FundedReceivableWrapper temp = RowList.get(k);
            if(SchoolToAllReceivablesMap.containsKey(temp.School)){
                SchoolToAllReceivablesMap.get(RowList.get(k).School).add(temp);
            }
            else{

                //list<FundedReceivableWrapper> sfr = new list<FundedReceivableWrapper>();
                //sfr.add(RowList.get(k));
                SchoolToAllReceivablesMap.put(RowList.get(k).School,new list<FundedReceivableWrapper>{temp});

            }
            k++;
        }*/
        RowList.sort();
        //map<String, List<FundedReceivableWrapper>> mapSchooolListWrapper = new map<Stirng,List<FundedReceivableWrapper>>();

        /*for(FundedReceivableWrapper fundedRecWrapper : RowList){
            if(!mapSchooolListWrapper.containsKey(fundedRecWrapper.School)){
                mapSchooolListWrapper.put(fundedRecWrapper.School, new list<FundedReceivableWrapper>());
            }
            mapSchooolListWrapper.get(fundedRecWrapper.School).add(fundedRecWrapper);
        }*/
        addPaginationOnFormList();

    }

    public void getAllocationList(){
        AllocationWrapper ar1;
        for(allocation__c allocation : [select Redemption__c,name,Funded_Receivable__c, Funded_Receivable__r.Purchase_Date__c,
                                        Funded_Receivable__r.Receivable_Type__r.name,Funded_Receivable__r.FV_Amount_Due__c,
                                        Face_Amount_Applied__c, Interest_Applied__c
                                        from allocation__c
                                        where Funded_Receivable__c in: allReceivableID and Redemption__c = : red.Id]){
                Draw_Note_TX__c DnTx = new Draw_Note_TX__c();
                    if( RecToActiveDRTXMap.containsKey(allocation.Funded_Receivable__c)){
                        DnTx = RecToActiveDRTXMap.get(allocation.Funded_Receivable__c);
            
                    ar1 = new AllocationWrapper(allocation.Redemption__c, allocation.Funded_Receivable__c,allocation.name, allocation.Funded_Receivable__r.Purchase_Date__c,
                                                DnTx.Draw_Note__c, DnTx.Draw_Note__r.name, DnTx.Draw_Note__r.Investor__r.name, allocation.Funded_Receivable__r.Receivable_Type__r.name, 
                                                allocation.Funded_Receivable__r.FV_Amount_Due__c, allocation.Face_Amount_Applied__c, allocation.Interest_Applied__c);
                    }
                    else{
                        ar1 = new AllocationWrapper(allocation.Redemption__c, allocation.Funded_Receivable__c,allocation.name, allocation.Funded_Receivable__r.Purchase_Date__c,
                                                null,null,null,allocation.Funded_Receivable__r.Receivable_Type__r.name,allocation.Funded_Receivable__r.FV_Amount_Due__c, 
                                                allocation.Face_Amount_Applied__c, allocation.Interest_Applied__c);
                    }
            WrapperAllocateList.add(ar1);
            if(ar1.DrawNoteID != null){
                setDrawNoteIDs.add(ar1.DrawNoteID);
            }
        }
    }

    public void getRPAListWithFeeTextBox(){
        system.debug('check1');
        Integer k = 0;
        RPAList = [select name, id, Account__r.name, status__c, RPA_End_Date__c, RPA_Date__c, Program_Fee__c, Remaining_Fee_to_Collect__c
                        from RPA__c
                        where Account__c in : charterHolders and (Remaining_Fee_to_Collect__c > 0 or status__c = 'Active')
                        ORDER BY RPA_Date__c DESC, RPA_End_Date__c DESC];                                         //2016.08.29 J Caughie - Changed from AllSchoolId to charterHolders, = Active to != Draft status & Balance > 0 & added sorting

        WrapperRPAList = new List<RPAWrapper>();
        RPAWrapper rw;
        for(RPA__c rpaRecord : RPAList) {
            //String RecName, String CharterHolder, String School, Date PurchaseDate, Date ExpPayDate, Date DistributionDate, String Description, Decimal FVAmount
            //RecFVAmountDue = receive.FV_Amount_Due__c;
            rw = new RPAWrapper(rpaRecord.ID, rpaRecord.name, rpaRecord.Account__r.name, rpaRecord.Status__c, rpaRecord.RPA_End_Date__c,
                                        rpaRecord.RPA_Date__c, rpaRecord.Program_Fee__c,'', rpaRecord.Remaining_Fee_to_Collect__c, k);                              //2016.08.29 J Caughie Added fee balance
            k=k+1;
            WrapperRPAList.add(rw);
            system.debug('check2');
            allRPAIds.add(rw.RPAID);
            RPAMap.put(rw.RowID, rw);       }
    }

    public PageReference SaveRedemption(){
        try{
            //validPayor = false;
            validAmtReceived = false;
            //if(red.Payor__c == ''){
            //    validPayor = true;
            //}
            if(red.Amount_Received__c <= 0.00){
                validAmtReceived = true;
            }
            else{
                if (red.id == null){
                    red.school__c = acc.id;
                    insert red;

                    red1 = [select name, remaining_amount__c from redemption__c where id =:red.id limit 1];
                    system.debug('here2');
                    RedRemainAmount = red1.Remaining_Amount__c;
                    system.debug('remaining amount is '+ RedRemainAmount);
                    system.debug('red id is ' + red.Id);
                    BeforeRedemptionSection = false;
                    AfterRedemptionSection = true;
                    SaveRedButton = true;
                                    system.debug('all to school is ' +red.all_to_school__c);
                    If(red.all_to_school__c != true){
                            RedemptionAllocation = true;
                            system.debug('receivable wrapper list is '+ RowListPage);
                            system.debug('RPA wrapper list is '+ WrapperRPAList);
                            system.debug('here2');
                    }
                    else{
                            OtherFeesTextBox = true;
                    }
                }
            }
        }
        catch(Exception e){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR,'Date Paid: Date Paid cannot be a future date');
            ApexPages.addMessage(msg);
        }   
        return null;
    }

    public PageReference AllocatePayment(){

        SaveAllocButton= false;
        try{
            String a = Apexpages.currentPage().getParameters().get('myParam');

            Integer WrapperRowID = Integer.ValueOf(a);

            system.debug('row id is ' +a);
            FundedReceivableWrapper recWrap = ReceivablesMap.get(WrapperRowID);
            PaymentCrossed = false;
            RemainingAmountCrossed = false;
            NegativeAmount = false;
            
            // Adding boolean to allow allocation of $0 with an interest amount
            Boolean isValueAllocated = true;
            if(!isNumeric(recWrap.newPayment)){
                isValueAllocated = false;
            }

            //if(Decimal.valueOf(recWrap.newPayment) > RedRemainAmount){
            //  RemainingAmountCrossed = true;
            //  recWrap.newPayment = '';
            //}
            //else{
                system.debug('m tired');
                //Double FVAmountDue = recWrap.FVAmountDue;
                //system.debug(Decimal.valueOf(recWrap.newPayment));
                system.debug(recWrap.FVAmountDue);
                Funded_Receivable__c frecDue = [select FV_Amount_Due__c from Funded_Receivable__c where id =: recWrap.RecID];
                system.debug('payment is ' + recWrap.newPayment);
                system.debug('amount due is ' + frecDue.FV_Amount_Due__c);
                system.debug('payment numeric? ' + recWrap.newPayment.isNumeric());
                if(!isValueAllocated){
                    NegativeAmount = true;
                    recWrap.newPayment = '';
                    recWrap.intPayment = 0; 
                } 
                //if(recWrap.newPayment <> '' && (Decimal.valueOf(recWrap.newPayment) > red.Amount_Received__c || recWrap.intPayment > red.Amount_Received__c)){  //2016.09.20 - J Caughie removed as intPayment or newPayment would be double counted || Decimal.valueOf(recWrap.newPayment) > RedRemainAmount 
                else if(isValueAllocated && (Decimal.valueOf(recWrap.newPayment) > red.Amount_Received__c || recWrap.intPayment > red.Amount_Received__c)){  //2016.09.20 - J Caughie removed as intPayment or newPayment would be double counted || Decimal.valueOf(recWrap.newPayment) > RedRemainAmount 
                    system.debug('lets try');
                    RemainingAmountCrossed = true;
                    recWrap.newPayment = '';
                    recWrap.intPayment = 0;                                                                     //2016.09.20 - J Caughie
                }
                // else if(recWrap.newPayment <> '' && (Decimal.valueOf(recWrap.newPayment)<= 0.00 || recWrap.intPayment < 0.00)){
                else if(isValueAllocated && (Decimal.valueOf(recWrap.newPayment)< 0.00 || recWrap.intPayment < 0.00)){

                        system.debug('lets try 1');
                        NegativeAmount = true;
                        recWrap.newPayment = '';
                        recWrap.intPayment = 0;                                                                     //2016.09.20 - J Caughie
                }
                // else if(recWrap.newPayment <> '' && Decimal.valueOf(recWrap.newPayment) > frecDue.FV_Amount_Due__c){
                else if(isValueAllocated && Decimal.valueOf(recWrap.newPayment) > frecDue.FV_Amount_Due__c){
                        PaymentCrossed = true;
                        //RedRemainAmount = RedRemainAmount + Decimal.valueOf(recWrap.newPayment);
                        recWrap.newPayment = '';
                        recWrap.intPayment = 0;                                                                     //2016.09.20 - J Caughie
                        if(receiveAllocationMap.get(recWrap.RecID) != null){
                                Allocation__c AllocToBeRemoved = receiveAllocationMap.get(recWrap.RecID);
                                Integer c = 0;
                            Funded_Receivable__c recAlloc = [select FV_Amount_Due__c, FV_Amount__c from Funded_Receivable__c where id = : recWrap.RecID];
                            system.debug('size is' +WrapperAllocateList.size());
                            while (c < WrapperAllocateList.size()){
                                if(WrapperAllocateList.get(c).RecID == AllocToBeRemoved.Funded_Receivable__c  && WrapperAllocateList.get(c).AllocName == ''){
                                        system.debug('about to remove ' +WrapperAllocateList.get(c));
                                        system.debug('here6');
                                        RedRemainAmount = RedRemainAmount + WrapperAllocateList.get(c).FaceAmountApplied + WrapperAllocateList.get(c).LoanInterestApplied;              //2016.09.20 J Caughie + WrapperAllocateList.get(c).LoanInterestApplied
                                        RedFaceAmount = RedFaceAmount - WrapperAllocateList.get(c).FaceAmountApplied - WrapperAllocateList.get(c).LoanInterestApplied;              //2016.09.20 J Caughie - WrapperAllocateList.get(c).LoanInterestApplied
                                        receiveAllocationMap.remove(WrapperAllocateList.get(c).RecID);
                                        WrapperAllocateList.remove(c);
                                        Decimal recFVAmountDue = recAlloc.FV_Amount_Due__c;
                                        recWrap.FVAmountDue = recFVAmountDue;
                                        break;
                                                }
                                c++;
                            }
                        }
                }
                                                
                else{
                    Integer i = 0;
                    RedFaceAmount = 0;
                    /*while (i < WrapperAllocateList.size()){
                        if(WrapperAllocateList.get(i).RedID == red.Id && WrapperAllocateList.get(i).AllocName == null){
                            RedFaceAmount = RedFaceAmount + WrapperAllocateList.get(i).FaceAmountApplied;
                            system.debug('red face amount now is ' +RedFaceAmount);
                        }
                        i++;
                    }
                    if(recWrap.newPayment <> ''){
                        Double RedFaceAmount1 = RedFaceAmount + Decimal.valueOf(recWrap.newPayment);

                        RedRemainAmount = RedRemainAmount - RedFaceAmount1;
                        system.debug('here3' + RedRemainAmount);
                    }*/
                    //else{
                    //  system.debug('here4');
                    //      RedRemainAmount = RedRemainAmount - RedFaceAmount;
                    //}

                    //if(recWrap.newPayment <> ''){
                    //  system.debug('here5');
                    //  RedRemainAmount = RedRemainAmount + Decimal.valueOf(recWrap.newPayment);
                    //}
                    //if(recWrap.newPayment <> '' && Decimal.valueOf(recWrap.newPayment) > RedRemainAmount){

                    //      RemainingAmountCrossed = true;
                    //  recWrap.newPayment = '';
                    //}
                    //else{
                        //if(recWrap.newPayment <> '' && Decimal.valueOf(recWrap.newPayment) > recWrap.FVAmountDue){
                        //  PaymentCrossed = true;
                            //RedRemainAmount = RedRemainAmount + Decimal.valueOf(recWrap.newPayment);
                    //      recWrap.newPayment = '';
                        //}
                        //else{
                            if(receiveAllocationMap.get(recWrap.RecID) != null)
                            {
                                system.debug('yes yes yes');
                                Allocation__c updateAlloc = receiveAllocationMap.get(recWrap.RecID);

                                            Integer j = 0;
                                            Funded_Receivable__c rec1 = [select FV_Amount_Due__c, FV_Amount__c from Funded_Receivable__c where id = : recWrap.RecID];
                                            system.debug('size is' + WrapperAllocateList.size());
                                            while (j < WrapperAllocateList.size()){
                                                if(WrapperAllocateList.get(j).RecID == updateAlloc.Funded_Receivable__c && WrapperAllocateList.get(j).AllocName == ''){
                                                    if(recWrap.newPayment == '' || (Decimal.valueOf(recWrap.newPayment) == 0 && recWrap.intPayment == 0)){
                                                        system.debug('about to remove ' + WrapperAllocateList.get(j));
                                                        system.debug('here6');
                                                        RedRemainAmount = RedRemainAmount + WrapperAllocateList.get(j).FaceAmountApplied + WrapperAllocateList.get(j).LoanInterestApplied;              //2016.09.20 J Caughie + WrapperAllocateList.get(c).LoanInterestApplied
                                                        RedFaceAmount = RedFaceAmount - WrapperAllocateList.get(j).FaceAmountApplied - WrapperAllocateList.get(j).LoanInterestApplied;              //2016.09.20 J Caughie - WrapperAllocateList.get(c).LoanInterestApplied
                                                        receiveAllocationMap.remove(WrapperAllocateList.get(j).RecID);
                                                        WrapperAllocateList.remove(j);
                                                        //Funded_Receivable__c rec1 = [select FV_Amount__c from Funded_Receivable__c where id = : recWrap.RecID];

                                                        Decimal recFVAmountDue = rec1.FV_Amount_Due__c;

                                                        recWrap.FVAmountDue = recFVAmountDue;

                                                    }
                                                    else{
                                                        WrapperAllocateList.get(j).FaceAmountApplied = Decimal.valueOf(recWrap.newPayment);
                                                        WrapperAllocateList.get(j).LoanInterestApplied = recWrap.intPayment;                                                                              //2016.09.20 J Caughie
                                                        system.debug('blank payment is 1' + recWrap.newPayment);
                                                        //Funded_Receivable__c rec1 = [select FV_Amount__c from Funded_Receivable__c where id = : recWrap.RecID];
                                                        recWrap.FVAmountDue = rec1.FV_Amount_Due__c - Decimal.valueOf(recWrap.newPayment);
                                                    }
                                                    break;
                                                }
                                                j++;
                                            }
                                        }
                                        //else{
                                        //  ar2.FaceAmountApplied=Decimal.valueOf(recWrap.newPayment);
                                    //
                                        //  system.debug('blank payment is ' +recWrap.newPayment);
                                    //      Funded_Receivable__c rec1 = [select FV_Amount__c from Funded_Receivable__c where id = : recWrap.RecID];
                                    //      recWrap.FVAmount = rec1.FV_Amount__c - Decimal.valueOf(recWrap.newPayment);
                                    //  }

                            //ReceivableWrapper recWrap = ReceivablesMap.get(IdChosen);
                            else
                            {
                                Allocation__c alloc = new Allocation__c();
                                alloc.Face_Amount_Applied__c = Decimal.valueOf(recWrap.newPayment);
                                alloc.Interest_Applied__c = recWrap.intPayment;                                                 //2016.09.20 J Caughie
                                alloc.Funded_Receivable__c = recWrap.RecID;
                                alloc.Redemption__c = red.Id;
                                //name,Funded_Receivable__r.Purchase_Date__c, Funded_Receivable__r.Lien_Holder__c,Funded_Receivable__r.Receivable_Type__c,receivable__r.FV_Amount_Due__c, Face_Amount_Applied__c
                                //alloc.receivable__r.Purchase_Date__c = recWrap.receiveRec.Purchase_Date__c;
                                receiveAllocationMap.put(recWrap.RecID,alloc);
                                system.debug('alloc is ' + alloc);
                                //toBeInsertedAllocatelist.add(alloc);
                                system.debug('alloc is ' + alloc);
                                recWrap.FVAmountDue = recWrap.FVAmountDue - Decimal.valueOf(recWrap.newPayment);

                                AllocationWrapper ar;
                                Funded_Receivable__c checkRec = [select ID, Purchase_Date__c, /*Draw_Note_TX__r.Draw_Note__c, Draw_Note_TX__r.Draw_Note__r.name,*/ Receivable_Type__r.name,
                                                                FV_Amount_Due__c
                                                                from Funded_Receivable__c
                                                                where id =: recWrap.RecID];
                                Draw_Note_TX__c DnTx = new Draw_Note_TX__c();
                                                        if( RecToActiveDRTXMap.containsKey(checkRec.Id)){
                                                                DnTx = RecToActiveDRTXMap.get(checkRec.Id);
                                        ar = new AllocationWrapper(alloc.Redemption__c,checkRec.ID, '', checkRec.Purchase_Date__c, DnTx.Draw_Note__c,
                                        DnTx.Draw_Note__r.name, DnTx.Draw_Note__r.Investor__r.name, checkRec.Receivable_Type__r.name, checkRec.FV_Amount_Due__c, alloc.Face_Amount_Applied__c, alloc.Interest_Applied__c);
                                                        }
                                                        else{
                                                                ar = new AllocationWrapper(alloc.Redemption__c,checkRec.ID, '', checkRec.Purchase_Date__c, null,
                                        null, null, checkRec.Receivable_Type__r.name, checkRec.FV_Amount_Due__c, alloc.Face_Amount_Applied__c, alloc.Interest_Applied__c);
                                                        }
                                WrapperAllocateList.add(ar);
                                if(ar.DrawNoteID != null){
                                        setDrawNoteIDs.add(ar.DrawNoteID);
                                }

                                //ReceivablesMap.put(tr.RowID,tr);
                                //newallocateRow = [select recWrap.receiveRec.Purchase_Date__c, recWrap.receiveRec.Lien_Holder__c,recWrap.receiveRec.Receivable_Type__c,recWrap.receiveRec.FV_Amount_Due__c, Face_Amount_Applied__c from allocation__c where receivable__c in: allReceivableID];
                                //alloc = select recWrap.receiveRec.Purchase_Date__c, recWrap.receiveRec.Lien_Holder__c,recWrap.receiveRec.Receivable_Type__c,recWrap.receiveRec.FV_Amount_Due__c, Face_Amount_Applied__c from
                                //allocateList.add(alloc);


                            }
                            Integer j = 0;
                            
                            Redemption__c NewRed = [select Remaining_Amount__c,Face_Amount_Applied__c
                                                                        from Redemption__c
                                                                        where id =: red.id];
                            RedFaceAmount = NewRed.Face_Amount_Applied__c;
                            /*while (j < WrapperAllocateList.size()){
                                if(WrapperAllocateList.get(j).RedID == red.Id && WrapperAllocateList.get(j).AllocName == ''){
                                    RedFaceAmount = RedFaceAmount + WrapperAllocateList.get(j).FaceAmountApplied;
                                    system.debug('red face amount now is ' +RedFaceAmount);
                                }
                                j++;
                            }*/
                            RedRemainAmount = NewRed.Remaining_Amount__c;
                            for(AllocationWrapper allocWrap : WrapperAllocateList){
                                if(allocWrap.AllocName == ''){
                                    RedFaceAmount = RedFaceAmount + allocWrap.FaceAmountApplied + allocWrap.LoanInterestApplied;                        //2016.09.20 J Caughie + allocWrap.LoanInterestApplied
                                    system.debug('red face amount now is ' +RedFaceAmount);
                                    RedRemainAmount = RedRemainAmount - allocWrap.FaceAmountApplied - allocWrap.LoanInterestApplied;                     //2016.09.20 J Caughie - allocWrap.LoanInterestApplied
                                    system.debug('remaining amount now is ' + NewRed);
                                }                                
                                        system.debug('here7' + RedRemainAmount);
                                        
                            }
                }
            }

        catch(Exception e)
        {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
            ApexPages.addMessage(msg);
        }
        return null;
    }
    
    public PageReference SaveAllocations(){
        Decimal totalAllocated = 0;

        if(red.Date_Paid__c == null){
                red.Date_Paid__c = Date.today();
                update red;
        }
        toBeInsertedAllocatelist.clear();
        AllocationsSaved = false;

        for(AllocationWrapper ar : WrapperAllocateList){
            if((ar.FaceAmountApplied + ar.LoanInterestApplied) <= 0){
                continue;
            }
            system.debug('inserting...' + ar.AllocName);
            if(ar.AllocName==''){
                Allocation__c newAlloc = new Allocation__c();
                newAlloc.Redemption__c = red.Id;
                newAlloc.Funded_Receivable__c = ar.RecID;
                //only temporary required till the time receivable and allocation connection is broken
                //newAlloc.Receivable__c = 'a0gS00000017mJK';
                //only temporary required till the time receivable and allocation connection is broken
                newAlloc.Face_Amount_Applied__c = ar.FaceAmountApplied;
                newAlloc.Interest_Applied__c = ar.LoanInterestApplied;                                                  //2016.09.20 J Caughie
                if(idToFundedReceivableMap.containsKey(ar.RecID)){
                                newAlloc.Previous_Payment_Date__c = idToFundedReceivableMap.get(ar.RecID).Last_Payment_Received__c;     //2017.04.18 J Caughie - stamp allocation with previous payment date
                                newAlloc.Previous_Principal_Due__c = idToFundedReceivableMap.get(ar.RecID).FV_Amount_Due__c;            //2017.04.18 J Caughie - stamp allocation with previous FV Due
                        }            
                toBeInsertedAllocatelist.add(newAlloc);
                totalAllocated += (ar.FaceAmountApplied + ar.LoanInterestApplied);
            }

            if(totalAllocated > red.Amount_Received__c){
                return null;
            }

            //setDrawNoteIDs.add(ar.DrawNoteID);
            //please please there is an issue here, if i again click save allocations. Then the record which was already inserted before, will get modified in the list
            //toBeInsertedAllocatelist, and then it will have an ID, and then it will give an error while inserting the record.
            //so, we should either alert the user that he should only click save when the allocations are ready to be saved, and no further saving required.
            // or we can reomove the records from this list which have their IDs filled already, and then save remaining ones
        }

        Integer j = 0;
        while(j<toBeInsertedAllocatelist.size()){
            system.debug('allocation id is ' + toBeInsertedAllocatelist.get(j).id);
            if(toBeInsertedAllocatelist.get(j).id != null){
                system.debug('removing allocation to be inserted again');
                toBeInsertedAllocatelist.remove(j);
            }
            j++;
        }

        system.debug('=============' + toBeInsertedAllocatelist);
        if (!toBeInsertedAllocatelist.isEmpty()){
            upsert toBeInsertedAllocatelist;
            Redemption__c NewRed = [select Remaining_Amount__c from Redemption__c where id =: red.id];
            RedRemainAmount = NewRed.Remaining_Amount__c;

        }
        j = 0;
        while(j<toBeInsertedAllocatelist.size()){
            for (AllocationWrapper ar1 : WrapperAllocateList){
                if (ar1.RecID == toBeInsertedAllocatelist.get(j).Funded_Receivable__c && ar1.AllocName == ''){
                    allocation__c sampleAlloc = [select name from allocation__c where id=: toBeInsertedAllocatelist.get(j).id];
                    ar1.AllocName = sampleAlloc.Name;

                    system.debug('allocation name is ' + ar1.AllocName);
                }
            }
            j++;
        }
        system.debug('records inserted are ' + toBeInsertedAllocatelist);
        //public list<Payment_Sub__c> paymentSubList { get; set; }
        /*listDrawNoteIDs.addAll(setDrawNoteIDs);
        j = 0;
        paymentSubList.Clear();
        while(j<listDrawNoteIDs.size()){
            //if (paymentSubList.isEmpty()){
                Decimal paySubAmount = 0;
                for(AllocationWrapper awr : WrapperAllocateList){
                    if(awr.DrawNoteID == listDrawNoteIDs.get(j)){
                        paySubAmount = paySubAmount + awr.FaceAmountApplied;
                    }
                }
                Payment_Sub__c paySub = new Payment_Sub__c();
                Date paidDate = Date.parse(Date.today().format());
                paySub.Amount__c = paySubAmount;
                paySub.Date_Paid__c = paidDate;
                paySub.Paid_To__c = 'School';
                paysub.redemption__c = red.id;
                paysub.Payment_Against__c = listDrawNoteIDs.get(j);
                system.debug('payment sub record is' + paySub);
                paymentSubList.add(paySub);
            //}
            //else{
            //  list<Allocation__c> allocalist = [select id from allocation__c where redemption__c =: red.id order by createddate desc];

            //}

            j++;
        }*/
        AllocationsSaved = true;
        SaveAllocButton= true;

        PAAButton = false;

        return null;
    }

    /**=====================================================================
        VF Page Action Function which is called when the Unassigned Checkbox on the Page
        is checked or unchecked
        =====================================================================*/
    public PageReference filteredByCheckbox(){
        system.debug('unassigned is '+unassigned);
        system.debug('selectedschool is '+selectedschool);
        if (Unassigned == true){
                RowList.clear();
                system.debug('unassigned true');
                if(selectedschool == '---Select---'){
                        for(FundedReceivableWrapper FRRecWrap : ReceivablesMap.values()){
                                system.debug('filtering by unassigned '+ FRRecWrap);
                                if(FRRecWrap.DrawNote == '-'){
                                        system.debug('filtered this one '+ FRRecWrap);
                                        RowList.add(FRRecWrap);
                                }
                        }
                }
                else{
                        Account tempAcc = [select name from account where id=: selectedschool];
                        for(FundedReceivableWrapper FRRecWrap : SchoolToAllReceivablesMap.get(tempAcc.name)){
                                system.debug('filtering by unassigned '+ FRRecWrap);
                                if(FRRecWrap.DrawNote == '-'){
                                        system.debug('filtered this one '+ FRRecWrap);
                                        RowList.add(FRRecWrap);
                                }
                        }
                }
                RowList.sort();
                addPaginationOnFormList();
        }
        
        else{
                system.debug('no true');
                RowList.clear();
                if(selectedschool == '---Select---'){
                        RowList.addAll(ReceivablesMap.values());
                }
                else{
                        Account tempAcc = [select name from account where id=: selectedschool];
                        if(SchoolToAllReceivablesMap.get(tempAcc.name) != null){
                                RowList.addAll(SchoolToAllReceivablesMap.get(tempAcc.name));
                        }
                }
                Integer j = RowList.size() - 1;
                system.debug('row list is ' +RowList);
                RowList.sort();
                addPaginationOnFormList();
        }
        return null;
    }

    public List<SelectOption> getListOfSchool(){
        List<Account> schools = [select id ,name, recordtype.name from account where id in:AllSchoolID ] ;
        List<SelectOption> SchoolOptionList = new List<SelectOption>();
        SchoolOptionList.add(new SelectOption( '---Select---' ,'---Select---'));
        for(Account sch : schools )
        {
            if(SchoolToAllReceivablesMap.containskey(sch.name)){
            SchoolOptionList.add(new SelectOption(sch.Id , sch.Name));
            }
        }
        return SchoolOptionList ;
    }

    public PageReference filteredBySchool(){
        system.debug('select option1 ' +selectedschool);
        List<FundedReceivableWrapper> SchoolFilteredList = new List<FundedReceivableWrapper>(); 
            if(selectedschool != '---Select---'){
                Account tempAcc = [select name from account where id=: selectedschool];
                system.debug('school is ' +tempAcc);
                if(Unassigned == false){
                        SchoolFilteredList = SchoolToAllReceivablesMap.get(tempAcc.name);
                }
                else{
                        SchoolFilteredList = SchoolToUnassignedReceivablesMap.get(tempAcc.name);
                }
                system.debug('select option2' +SchoolFilteredList);
                system.debug('select option3' +RowList);
                RowList.clear();
                if(SchoolFilteredList != null){
                        RowList.addAll(SchoolFilteredList);
                }
                system.debug('select option3' +RowList);
                addPaginationOnFormList();
            }
            else{
                Integer m = 0;
                RowList.clear();
                if(Unassigned == false){
                        for(list<FundedReceivableWrapper> lstAllReceivables : SchoolToAllReceivablesMap.values()){
                        RowList.addAll(lstAllReceivables);
                        }
                }
                else{
                        for(list<FundedReceivableWrapper> lstAllReceivables : SchoolToUnassignedReceivablesMap.values()){
                        RowList.addAll(lstAllReceivables);
                        }
                }
                
                RowList.sort();
                addPaginationOnFormList();
            }
        return null;
    }

    public PageReference SavePaymentSubs(){
        system.debug('greywar 1');
        listDrawNoteIDs.addAll(setDrawNoteIDs);
        system.debug('draw ids are ' + setDrawNoteIDs)  ;
        Integer j = 0;
        paymentSubList.Clear();
        system.debug('greywar 2');
        while(j<listDrawNoteIDs.size()){
            //if (paymentSubList.isEmpty()){
                system.debug('greywar 3');
                Decimal paySubAmount = 0;
                for(AllocationWrapper awr : WrapperAllocateList){
                    system.debug('greywar 3 in loop');
                    if(awr.DrawNoteID == listDrawNoteIDs.get(j)){
                        paySubAmount = paySubAmount + awr.FaceAmountApplied + awr.LoanInterestApplied;
                    }
                }
                Payment_Sub__c paySub = new Payment_Sub__c();
                //Date paidDate = Date.parse(Date.today().format());
                paySub.Amount__c = paySubAmount;
                if(red.Date_Paid__c != null){
                        paySub.Date_Paid__c = red.Date_Paid__c;
                }
                else{
                        paySub.Date_Paid__c = Date.parse(Date.today().format());
                }
                paySub.Paid_To__c = 'Investor';
                paysub.redemption__c = red.id;
                paysub.Payment_Against__c = listDrawNoteIDs.get(j);
                paysub.Payment_Type__c = 'Allocation';
                system.debug('payment sub record is' + paySub);
                paymentSubList.add(paySub);
                system.debug('greywar 4');

            j++;
        }
        Decimal paySubAmountUnassigned = 0;
        for(AllocationWrapper awr : WrapperAllocateList){
                system.debug('greywar 3 in loop');
            if(awr.DrawNoteID == null){
                paySubAmountUnassigned = paySubAmountUnassigned + awr.FaceAmountApplied + awr.LoanInterestApplied;
            }
        }
            Payment_Sub__c paySubUnassigned = new Payment_Sub__c();
            if(paySubAmountUnassigned != 0) {
                paySubUnassigned.Amount__c = paySubAmountUnassigned;
                if(red.Date_Paid__c != null){
                        paySubUnassigned.Date_Paid__c = red.Date_Paid__c;
                }
                else{
                        paySubUnassigned.Date_Paid__c = Date.parse(Date.today().format());
                }
                paySubUnassigned.Paid_To__c = 'CSC';
                paySubUnassigned.redemption__c = red.id;
                paySubUnassigned.Payment_Type__c = 'Allocation';
                system.debug('payment sub record is' + paySubUnassigned);
            } 
                
        if (red.all_to_school__c != true){
            j = 0;
            while(j<paymentSubList.size()){
                if(paymentSubList.get(j).id != null){
                    paymentSubList.remove(j);
                }
                j++;
            }
            if (!paymentSubList.isEmpty()){
                system.debug('greywar 5');
                insert paymentSubList;
                system.debug('payment subs saved');
                for(Payment_Sub__c pSub : paymentSubList){
                    Payment__c pay = new Payment__c();
                    pay.Draw_Note__c = pSub.Payment_Against__c;
                    pay.Payment_Amount__c = pSub.Amount__c;
                    pay.Payment_Sub__c = pSub.Id;
                    pay.Payment_Type__c = pSub.Payment_Type__c;                                                                 //2016.09.29 J Caughie - Added to update type
                    if(red.Date_Paid__c != null){
                                        pay.Date_Paid__c = red.Date_Paid__c;
                                }
                                else{
                                        pay.Date_Paid__c = Date.parse(Date.today().format());
                                }
                    //pay.Payment_Type__c = 'Allocation';
                    paymentList.add(pay);
                }
                if(!paymentList.IsEmpty()){
                    system.debug('greywar 6');
                    insert paymentList;
                    PaymentTriggerManager.calculateDrawInterest(paymentList, red.Id);                                           //2015.08.07 J Caughie - Added to end of process, removed from trigger
                }
            }
            if(paySubUnassigned != null){
                insert paySubUnassigned;
            }
            Redemption__c updatedRed = [select other_fees__c, Remaining_Amount__c from Redemption__c where id=: red.Id];
            if(updatedRed.other_fees__c != null && updatedRed.other_fees__c != 0.00){
                Payment_Sub__c paySubOther = new Payment_Sub__c();
                //Date paidDate = Date.parse(Date.today().format());
                paySubOther.Amount__c = updatedRed.other_fees__c;
                if(red.Date_Paid__c != null){
                                paySubOther.Date_Paid__c = red.Date_Paid__c;
                        }
                        else{
                                paySubOther.Date_Paid__c = Date.parse(Date.today().format());
                        }
                paySubOther.Paid_To__c = 'CSC';
                paySubOther.redemption__c = red.id;
                //paysub.Payment_Against__c = listDrawNoteIDs.get(j);
                paySubOther.Payment_Type__c = 'Other';
                insert paySubOther;
            }

            if(updatedRed.Remaining_Amount__c != 0.00){
                   //Date paidSubDate = Date.parse(Date.today().format());
                   Payment_Sub__c RemainPaySub = new Payment_Sub__c();
                   RemainPaySub.Amount__c = updatedRed.Remaining_Amount__c;
                   if(red.Date_Paid__c != null){
                                                RemainPaySub.Date_Paid__c = red.Date_Paid__c;
                           }
                           else{
                                        RemainPaySub.Date_Paid__c = Date.parse(Date.today().format());
                       }
                   RemainPaySub.Paid_To__c = 'School';
                   RemainPaySub.redemption__c = red.id;
                   RemainPaySub.Payment_Type__c = 'Remit to School';
                   insert RemainPaySub;
                   RedRemitToSchool = updatedRed.Remaining_Amount__c;
                   updatedRed.Payment_Sub__c = RemainPaySub.Id;
                   update updatedRed;
                   RedRemainAmount = 0.00;
           }
           PAAButton = true;
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Payment Stubs for the selected Allocations have been created and saved');
           ApexPages.addMessage(myMsg);
           system.debug('finally it is done');
           //AllDisabled = true;
       }
       else{
           Payment_Sub__c PaySubAlltoSchool = new Payment_Sub__c();
           //Date paidDate1 = Date.parse(Date.today().format());
               PaySubAlltoSchool.Amount__c = red.Amount_Received__c;
               if(red.Date_Paid__c != null){
                                        PaySubAlltoSchool.Date_Paid__c = red.Date_Paid__c;
                   }
                   else{
                                PaySubAlltoSchool.Date_Paid__c = Date.parse(Date.today().format());
                   }
               PaySubAlltoSchool.Paid_To__c = 'School';
               PaySubAlltoSchool.redemption__c = red.id;
               PaySubAlltoSchool.Payment_Type__c = 'Remit to School';
               insert PaySubAlltoSchool;
               //RedFaceAmountSubs = red.Amount_Received__c;
               Redemption__c updatedRed = [select Remaining_Amount__c from Redemption__c where id=: red.Id];
               updatedRed.Payment_Sub__c = PaySubAlltoSchool.Id;
               update updatedRed;
               RedRemainAmount = 0.00;
               PAAButton = true;
               ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Payment Stub for the Redemption has been created and saved');
               ApexPages.addMessage(myMsg);
       }
       return null;
   }

    public void getRPARedemptionList(){

        for(RPA_Redemption__c rpaRed : [select RPA__c, Redemption__c, name, RPA__r.name, RPA__r.Status__c, RPA__r.RPA_Date__c,
                                                                        RPA__r.RPA_End_Date__c, RPA__r.Program_Fee__c,Program_Fee_Collected__c
                                                                        from RPA_Redemption__c
                                                                        where RPA__c in: allRPAIds and Program_Fee_Collected__c > 0
                                                                        ORDER BY RPA__r.RPA_Date__c DESC, Name DESC]){                                          // and Redemption__c = : red.Id]){     2016.08.29 J Caughie added sorting also
                RPARedemptionWrapper rpred;

            rpred = new RPARedemptionWrapper(rpaRed.RPA__c, rpaRed.Redemption__c,rpaRed.name, rpaRed.RPA__r.RPA_Date__c,
                                            rpaRed.RPA__r.name, rpaRed.RPA__r.Status__c, rpaRed.RPA__r.Program_Fee__c,
                                            rpaRed.Program_Fee_Collected__c);
            WrapperRPARedList.add(rpred);
            //setDrawNoteIDs.add(ar1.DrawNoteID);
        }
    }

    public PageReference AllocateFees(){
        SaveRPAFeesButton= false;
        try{
            String Fees = Apexpages.currentPage().getParameters().get('myFees');

            Integer RPAWrapperRowID = Integer.ValueOf(Fees);

            system.debug('row id is ' +Fees);
            RPAWrapper recRPAWrap = RPAMap.get(RPAWrapperRowID);
            PaymentCrossed = false;
            RemainingAmountCrossed = false;
            NegativeAmount = false;
            system.debug('m tired');

            system.debug('payment is ' +recRPAWrap.newFees);
            if(recRPAWrap.newFees <> '' && (Decimal.valueOf(recRPAWrap.newFees) > red.Amount_Received__c|| Decimal.valueOf(recRPAWrap.newFees) > RedRemainAmount)){
                system.debug('lets try');
                RemainingAmountCrossed = true;
                recRPAWrap.newFees = '';

            }
            else if(recRPAWrap.newFees <> '' && Decimal.valueOf(recRPAWrap.newFees)<= 0.00){
                system.debug('lets try 1');
                NegativeAmount = true;
                recRPAWrap.newFees = '';
            }
            else if(recRPAWrap.newFees <> '' && Decimal.valueOf(recRPAWrap.newFees) > recRPAWrap.RPAFeeBalance){
                PaymentCrossed = true;
                recRPAWrap.newFees = '';
            }
            else{
                Integer m = 0;
                RedFaceAmountFees = 0;
                /*while (m < WrapperRPARedList.size()){
                    if(WrapperRPARedList.get(m).RedID == red.Id){
                        //check please
                        RedFaceAmountFees = RedFaceAmountFees + WrapperRPARedList.get(m).ProgramFeeCollected;
                        system.debug('red face amount now is ' +RedFaceAmountFees);
                    }
                    m++;
                }
                if(recRPAWrap.newFees <> ''){
                    //check please
                    Decimal RedFaceAmountFees1 = RedFaceAmountFees + Decimal.valueOf(recRPAWrap.newFees);
                    system.debug('here8');
                    RedRemainAmount = RedRemainAmount - Decimal.valueOf(recRPAWrap.newFees);
                }
                //else{
                //  RedRemainAmount = RedRemainAmount - RedFaceAmountFees;
                //}

                //if(recRPAWrap.newFees <> ''){
                //  RedRemainAmount = RedRemainAmount + Decimal.valueOf(recRPAWrap.newFees);
                //}
                if(recRPAWrap.newFees <> '' && Decimal.valueOf(recRPAWrap.newFees) > RedRemainAmount){

                    RemainingAmountCrossed = true;
                    recRPAWrap.newFees = '';
                }
                else{
                    //check please
                    */
                        if(RPAToRPARedemptionMap.get(recRPAWrap.RPAID) != null)
                        {
                            system.debug('yes yes yes');
                            RPA_Redemption__c updatedRPARedemp = RPAToRPARedemptionMap.get(recRPAWrap.RPAID);

                                        Integer p = 0;
                                            RPA__c rpa1 = [select name from RPA__c where id = : recRPAWrap.RPAID];
                                            while (p < WrapperRPARedList.size()){
                                                if(WrapperRPARedList.get(p).RPAID == updatedRPARedemp.RPA__c  && WrapperRPARedList.get(p).RPARedemptionName == ''){
                                                    if(recRPAWrap.newFees == ''){
                                                        system.debug('about to remove ' +WrapperRPARedList.get(p));
                                                        system.debug('here8');
                                                        RedRemainAmount = RedRemainAmount + WrapperRPARedList.get(p).ProgramFeeCollected;
                                                        //check please
                                                        RedFaceAmountFees = RedFaceAmountFees - WrapperRPARedList.get(p).ProgramFeeCollected;
                                                        RPAToRPARedemptionMap.remove(WrapperRPARedList.get(p).RPAID);
                                                        WrapperRPARedList.remove(p);

                                                    }
                                                    else{
                                                        WrapperRPARedList.get(p).ProgramFeeCollected=Decimal.valueOf(recRPAWrap.newFees);

                                                        system.debug('blank payment is 1' +recRPAWrap.newFees);
                                                    }
                                                    break;
                                                }
                                                p++;
                                            }
                                        }
                            else
                            {
                                RPA_Redemption__c rRed = new RPA_Redemption__c();
                                rRed.Program_Fee_Collected__c = Decimal.valueOf(recRPAWrap.newFees);
                                rRed.RPA__c = recRPAWrap.RPAID;
                                rRed.Redemption__c = red.Id;
                                RPAToRPARedemptionMap.put(recRPAWrap.RPAID,rRed);
                                system.debug('rpa redemption is ' + rRed);

                                RPARedemptionWrapper rRedWrap;
                                RPA__c checkRPA = [select ID, name, RPA_Date__c, RPA_End_Date__c, Status__c,Program_Fee__c
                                                                from RPA__c
                                                                where id =: recRPAWrap.RPAID];


                               // RPARedemptionWrapper rpred;

              //  rpred = new RPARedemptionWrapper(rpaRed.RPA__c, rpaRed.Redemption__c,rpaRed.name, rpaRed.RPA_Date__c,
                                    //      rpaRed.RPA__r.name, rpaRed.RPA__r.Status__c, rpaRed.RPA__r.Program_Fee__c,
                                    //      rpaRed.Program_Fee_Collected__c);
                                rRedWrap = new RPARedemptionWrapper(checkRPA.Id, rRed.Redemption__c,'', checkRPA.RPA_Date__c, checkRPA.name,
                                checkRPA.Status__c, checkRPA.Program_Fee__c, rRed.Program_Fee_Collected__c);
                                WrapperRPARedList.add(rRedWrap);


                            }
                            Integer x = 0;
                            //check please
                            RedFaceAmountFees = 0;
                            while (x < WrapperRPARedList.size()){
                                if(WrapperRPARedList.get(x).RedID == red.Id && WrapperRPARedList.get(x).RPARedemptionName == ''){
                                    //check please
                                    RedFaceAmountFees = RedFaceAmountFees + WrapperRPARedList.get(x).ProgramFeeCollected;
                                    //system.debug('red face amount now is ' +RedFaceAmountFees);
                                }
                                x++;
                            }
                            //check please
                            Redemption__c NewRed = [select Remaining_Amount__c from Redemption__c where id =: red.id];
                            RedRemainAmount = NewRed.Remaining_Amount__c;
                            system.debug('here9');
                            RedRemainAmount = RedRemainAmount - RedFaceAmountFees;
                }
                        //}
                    //}


                    //}
            }

        catch(Exception f)
        {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR,f.getMessage());
            ApexPages.addMessage(msg);
        }
        return null;
    }

    public PageReference SaveRPAProgramFees(){
        toBeInsertedRPARedemptions.clear();
        RPARedemptionsSaved = false;
        for(RPARedemptionWrapper rrw : WrapperRPARedList){
            system.debug('inserting...' + rrw.RPARedemptionName);
            if(rrw.RPARedemptionName==''){
                RPA_Redemption__c newRPARed = new RPA_Redemption__c();
                newRPARed.Redemption__c = red.Id;
                newRPARed.RPA__c = rrw.RPAID;
                newRPARed.Program_Fee_Collected__c = rrw.ProgramFeeCollected;
                toBeInsertedRPARedemptions.add(newRPARed);
            }
        }
        Integer y = 0;
        while(y<toBeInsertedRPARedemptions.size()){
            system.debug('RPA Redemtpion id is ' + toBeInsertedRPARedemptions.get(y).id);
            if(toBeInsertedRPARedemptions.get(y).id != null){
                system.debug('removing RPA Redemptions to be inserted again');
                toBeInsertedRPARedemptions.remove(y);
            }
            y++;
        }
        system.debug('=============' + toBeInsertedRPARedemptions);
        if (!toBeInsertedRPARedemptions.isEmpty()){
            upsert toBeInsertedRPARedemptions;
            Redemption__c NewRed = [select Face_Amount_Applied_Fee__c, Remaining_Amount__c, Total_Interest_from_Allocations__c from Redemption__c where id =: red.id];
            RedRemainAmount = NewRed.Remaining_Amount__c;
            RedFeesCollected = NewRed.Face_Amount_Applied_Fee__c;
        }
        y = 0;
        while(y<toBeInsertedRPARedemptions.size()){
            for (RPARedemptionWrapper rrw1 : WrapperRPARedList){
                if (rrw1.RPAID == toBeInsertedRPARedemptions.get(y).RPA__c && rrw1.RPARedemptionName == ''){
                    RPA_Redemption__c sampleRPARed = [select name from RPA_Redemption__c where id=: toBeInsertedRPARedemptions.get(y).id];
                    rrw1.RPARedemptionName = sampleRPARed.Name;
                    system.debug('RPA Redemption name is ' + rrw1.RPARedemptionName);
                }
            }
            y++;
        }
        system.debug('records inserted are ' + toBeInsertedRPARedemptions);
        RPARedemptionsSaved = true;
        SaveRPAFeesButton= true;
        return null;
    }

    public PageReference OtherFeesApplied(){
        if(OtherFees != ''){
            OtherFee = Decimal.ValueOf(OtherFees);
        }
        else{
            OtherFee = 0.00;
        }
        If(OtherFee < 0){
            OtherFees = '';
            NegativeAmount = true;
        }
        else If(OtherFee > RedRemainAmount ){
            OtherFees = '';
            RemainingAmountCrossed = true;
        }
        else{

            RedRemainAmount = (RedRemainAmount + PreviousOtherFee) - OtherFee;
            PreviousOtherFee = OtherFee;
            SaveOtherFeesButton = false;
        }
        return null;
    }

    public PageReference SaveOtherFees(){
        red.Other_Fees__c = OtherFee;
        update red;
        SaveOtherFeesButton = true;
        OtherFeesTextBox = true;
        return null;
    }

        public static Boolean isNumeric(String s){
            Boolean ReturnValue;
            try{
                Decimal.valueOf(s);
                ReturnValue = TRUE; 
            } catch (Exception e) {
                ReturnValue = FALSE;
            }
            return ReturnValue;
        }

   /***************************************************************
  * Initalize sorting order based on previous value.
  ***************************************************************/
    public String sortExpression {
        get {
            return sortExp;
        }
        set {
                if (value == sortExp)
                sortDirection = (sortDirection == 'ASC')? 'DESC' : 'ASC';
                else
                sortDirection = 'ASC';
                sortExp = value;
        }
    }

  /***************************************************************
  * Return Sorting order
  ***************************************************************/
    public String getSortDirection() {
        if (sortExpression == null || sortExpression == '')
            return 'ASC';
        else
            return sortDirection;
    }

    public void sortWrapper(){
        //RowList.Clear();
        system.debug('==========' + RowList);
        //RowList = new List<ReceivableWrapper>();
        //ReceivableWrapper tr;
        //for(Receivable__c receive : receiveList) {
        //String RecName, String CharterHolder, String School, Date PurchaseDate, Date ExpPayDate, Date DistributionDate, String Description, Decimal FVAmount
        // tr = new ReceivableWrapper(receive.ID, receive.name, receive.opp_school__r.school__r.Charter_Holder__r.name, receive.School__c,
                                        //receive.Purchase_Date__c, receive.Expected_Pay_Date__c,receive.Distribution_Date__c,receive.Description__c,
                                    //      receive.FV_Amount__c,'',i);
        //i=i+1;
        // RowList.add(tr);

        //ReceivablesMap.put(tr.RowID,tr);
        if(sortExp=='RecName'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByName;
        }
        else if(sortExp=='School'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.BySchool;
        }
        else if(sortExp=='DrawNote'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByDrawNote;
        }
        else if(sortExp=='CharterHolder'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByCharterHolder;
        }
        else if(sortExp=='Description'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByDescription;
        }
        else if(sortExp=='ExpPayDate'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByExpectedPayDate;
        }
        else if(sortExp=='DistributionDate'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByDistributionDate;
        }
        else if(sortExp=='PurchaseDate'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByPurchaseDate;
        }
        else if(sortExp=='FVAmount'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByFVAmount;
        }
        else if(sortExp=='FVAmountDue'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByFVAmountDue;
        }
        else if(sortExp=='IntDue'){
            FundedReceivableWrapper.sortBy = FundedReceivableWrapper.SORT_BY.ByIntDue;
        }

        if(sortDirection == 'ASC'){
            FundedReceivableWrapper.sortOrder = FundedReceivableWrapper.SORT_ORDER.ByAsc;
        }
        else{
            FundedReceivableWrapper.sortOrder = FundedReceivableWrapper.SORT_ORDER.ByDesc;
        }
        RowList.sort();
        addPaginationOnFormList();
        system.debug('========' + rowList);

    }

    public void sortRPAWrapper(){

        system.debug('==========' + WrapperRPAList);

        if(sortExp=='RPAAccount'){
            RPAWrapper.sortBy = RPAWrapper.SORT_BY.ByRPAAccount;
        }
        else if(sortExp=='RPAName'){
            RPAWrapper.sortBy = RPAWrapper.SORT_BY.ByRPAName;
        }
        else if(sortExp=='RPAStatus'){
            RPAWrapper.sortBy = RPAWrapper.SORT_BY.ByRPAStatus;
        }
        else if(sortExp=='RPADate'){
            RPAWrapper.sortBy = RPAWrapper.SORT_BY.ByRPADate;
        }
        else if(sortExp=='RPAEndDate'){
            RPAWrapper.sortBy = RPAWrapper.SORT_BY.ByRPAEndDate;
        }
        else if(sortExp=='RPAProgramFee'){
            RPAWrapper.sortBy = RPAWrapper.SORT_BY.ByRPAProgramFee;
        }
        else if(sortExp=='RPAFeeBalance'){
            RPAWrapper.sortBy = RPAWrapper.SORT_BY.RPAFeeBalance;
        }
        if(sortDirection == 'ASC'){
            RPAWrapper.sortOrder = RPAWrapper.SORT_ORDER.ByAsc;
        }
        else{
            RPAWrapper.sortOrder = RPAWrapper.SORT_ORDER.ByDesc;
        }

        WrapperRPAList.sort();
        //addPaginationOnFormList();
        system.debug('========' + WrapperRPAList);

    }

/***************************************************************
* Add pagination on Form list
* PaginationUtility class to used for pagination.
***************************************************************/
    public void addPaginationOnFormList() {
        RowListPage.clear();
        formListPagination = new PaginationUtility();
        selectedPageNumber = 1;
        RowListPage.addAll(RowList);

        //fetch the pagination setting for this page (Added for task T-277641)
        PaginationSettings__c pageSetting = PaginationSettings__c.getValues('RedemptionDetails');

        if(RowListPage.size() > 0) {
            formListPagination.pageSize = (pageSetting != null && pageSetting.PageSize__c != null)? Integer.valueOf(pageSetting.PageSize__c) :10;
            List<Object> tempList = formListPagination.setPagination(RowListPage);
            RowListPage = getWrapperList(tempList);
        }
    }

/************************************************************
* Method to cast object into forms
************************************************************/
    private List<FundedReceivableWrapper> getWrapperList(List<Object> currentList) {
        RowListPage.clear();
        for(Object obj : currentList) {
            RowListPage.add((FundedReceivableWrapper)obj);
        }
        return RowListPage;
    }

/************************************************************
* Method to get pagination list of forms
************************************************************/
    public PageReference getList() {
        RowListPage = getWrapperList(formListPagination.getPage(selectedPageNumber));
        return null;
    }

    public class AllocationWrapper{

        public ID RecID {get;set;}
        public ID RedID {get;set;}
        public String AllocName {get;set;}
        public Date PurchaseDate {get;set;}
        //public String LienHolder {get;set;}
        public ID DrawNoteID {get;set;}
        public String DrawNote {get;set;}
        public String LienHolder {get;set;}
        public String Type {get;set;}
        public Decimal FVAmountDue {get;set;}
        public Decimal FaceAmountApplied {get;set;}
        public Decimal LoanInterestApplied {get;set;}

        public AllocationWrapper(ID RedID, ID RecID,String AllocName, Date PurchaseDate, ID DrawNoteID, String DrawNote, 
                                                        String LienHolder, String Type, Decimal FVAmountDue, Decimal FaceAmountApplied, Decimal LoanInterestApplied){
            this.RedID = RedID;
            this.RecID = RecID;
            this.AllocName = AllocName;
            this.PurchaseDate = PurchaseDate;
            //this.LienHolder = LienHolder;
            this.DrawNoteID = DrawNoteID;
            this.DrawNote = DrawNote;
            this.LienHolder = LienHolder;
            this.Type = Type;
            this.FVAmountDue = FVAmountDue;
            this.FaceAmountApplied = FaceAmountApplied;
            this.LoanInterestApplied = LoanInterestApplied;

        }
    }

    public class RPARedemptionWrapper{

        public ID RPAID {get;set;}
        public ID RedID {get;set;}
        public String RPARedemptionName {get;set;}
        public Date RPADate {get;set;}
        public String RPAName {get;set;}
        public String RPAStatus {get;set;}
        public Decimal RPAProgramFee {get;set;}
        public Decimal ProgramFeeCollected {get;set;}

        public RPARedemptionWrapper(ID RPAID, ID RedID,String RPARedemptionName, Date RPADate, String RPAName, String RPAStatus, Decimal RPAProgramFee,
                                    Decimal ProgramFeeCollected){
            this.RPAID = RPAID;
            this.RedID = RedID;
            this.RPARedemptionName = RPARedemptionName;
            this.RPADate = RPADate;
            this.RPAName = RPAName;
            this.RPAStatus = RPAStatus;
            this.RPAProgramFee = RPAProgramFee;
            this.ProgramFeeCollected = ProgramFeeCollected;

        }
    }
}