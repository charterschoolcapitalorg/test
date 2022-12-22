/**=====================================================================
* Appirio, Inc
* Name: ADMINActivityController Class
* Description: T-288639 - Controller Class for ADMINActivity Page
* Created Date: [07/03/2014]
* Created By: [Rajeev Arya] (Appirio)
*
* Date Modified            Modified By                 Description of the update
* [07/07/2014]            [Rajeev Arya]              [FR Month End Reporting - Export to Excel]
* [07/16/2014]            [Rajeev Arya]              [I-121455 - Bugs in Month End Reporting]
* [07/16/2014]            [Rajeev Arya]              [T-295831 - Journal Entries development]
* [08/07/2014]            [John Caughie]             [Added additional field for Class, Dept, Memo, Entry, Location, Name & Draw exclude drafts]
* [10/07/2014]            [John Caughie]             [Added Purchase UID, Financeable, Calculator Discount & CSC PP]
* [10/29/2014]            [John Caughie]             [Added purchase journal grouping by Opp Ref & Date - two receivables from same opp with different purchase dates and two opps in same month]
* [01/03/2017]            [John Caughie]             [Added draw payments (paying EWB etc) section]
* [01/24/2017]            [John Caughie]             [Amended draw payment journal section - removed overpayments]
* [03/22/2017]            [John Caughie]             [Create Loan entries redemptions & monthly interest]
* [04/18/2017]            [John Caughie]             [Updated accrued loan interest calculations]
* [01/30/2020]            [John Caughie]             [Added "class" logic for journals]
=====================================================================*/

public with sharing class ADMINActivityController {
    public transient String dateSelected {get; set;}
    public transient String datePayments {get; set;}                                                        //2017.01.03 J Caughie
    public String investor {get  {
        if(investor == null){
            investor = 'East West Bank';
        }
        return investor;
    }
                            set;}                                                                          //2017.01.03 J Caughie
    public transient String startDate {get; set;}
    public transient String endDate {get; set;}
    public transient String startDateOther {get; set;}
    public transient String endDateOther {get; set;}
    public transient String startDateDraw {get; set;}
    public transient String endDateDraw {get; set;}
    public transient String startDateRed {get; set;}
    public transient String endDateRed {get; set;}
    public transient String startDateDrawInt {get; set;}
    public transient String endDateDrawInt {get; set;}
    public transient String startDateDrawEntry {get; set;}
    public transient String endDateDrawEntry {get; set;}
    public transient String startDateDrawPayments {get; set;}
    public transient String endDateDrawPayments {get; set;}
    public transient String startLoanCalculationDate {get; set;}                                            //2017.03.22 J Caughie
    public transient String endLoanCalculationDate {get; set;}                                              //2017.03.22 J Caughie       
    //public transient list<MonthEndReportWrapper> MonthEndWrapperList {get; set;}
    public transient map<id, MonthEndReportWrapper> MonthEndWrapperMap {get; set;}
    public transient map<Id, Decimal> ReceivableToAllocSumMap; 
    
    public transient Date defaultDate;
    public ADMINActivityController(){
        ReceivableToAllocSumMap = new map<Id, Decimal>();
        transient Integer previousMonth;
        transient Integer year;
        previousMonth = Date.Today().month() - 1;
        year = Date.Today().year();
        transient Date firstDayOfMonth = date.newinstance(year, previousMonth, 1);
        defaultDate = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        dateSelected = defaultDate.format();
        datePayments = Date.today().format();                                                                    //2017.01.03 J Caughie
        ////system.debug('date is ' + dateSelected);
        ////system.debug('previous month is ' + previousMonth); 
    }
    
    public PageReference CalculateInterest(){
        ////system.debug('dateSelected is ' + dateSelected); 
        ////system.debug('Date.parse(dateSelected) is ' + Date.parse(dateSelected));
        
        if(Date.parse(dateSelected) > Date.today()){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The Selected Date cannot be a future date. Please select another');
            ApexPages.addMessage(myMsg);
        }
        else{
            database.executebatch(new DrawInterestCalculation_Batch(Date.parse(dateSelected)),200);
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Batch process is completed for Draw Interest Calculation');
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    
    //2017.01.03 J Caughie
    
    public List<SelectOption> getInvestors(){
        
        List<SelectOption> options = new List<SelectOption>();
        for(Account a: [SELECT Name FROM Account WHERE RecordType.Name = 'Investor']){
            options.add(new SelectOption(a.Name, a.Name));
        }
        
        return options;
        
    }
    
    public PageReference CalculatePayments(){
        //Prevents creating payments for next month as the month-end interest payments may have not been run.
        if(datepayments == '' || Date.parse(datePayments) > Date.newInstance(Date.today().year(), Date.today().month() + 1, 0)){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The Selected Date cannot be blank or a future date. Please select another date.');
            ApexPages.addMessage(myMsg);
        }
        else{
            database.executebatch(new DrawPayment_Batch(Date.parse(datePayments), investor) ,200);
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Batch process is completed for Draw Payment Calculation');
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    
    //2017.01.03 J Caughie
    
    public PageReference GenerateExcelReport(){
        if(startDate == '' || endDate == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled');
            ApexPages.addMessage(myMsg);
        }
        else{
            CreateFundedReceivableList();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The required Month End report has been downloaded to your system');
            ApexPages.addMessage(myMsg);
            ////system.debug('check');
            return Page.ADMINActivityExportToSchool;
        }
        return null;
    }
    
    public void CreateFundedReceivableList(){
        if(MonthEndWrapperMap == null || MonthEndWrapperMap.isEmpty()){
            //system.debug(LoggingLevel.ERROR,'I am here');
            transient Date Start_Date = Date.parse(startDate);
            transient Date End_Date = Date.parse(endDate);
            transient set<ID> processedReceivables = new set<ID>();
            //transient map<Id, Draw_Note_TX__c> ReceivableToDrawTXMap = new map<Id, Draw_Note_TX__c>();
            //transient map<Id, Funded_Receivable__c> IdToReceivableMap = new map<Id, Funded_Receivable__c>();
            //transient set <ID> frIds = new set<ID>();
            MonthEndWrapperMap = new map<id, MonthEndReportWrapper>();
            ReceivableToAllocSumMap = new map<Id, Decimal>();
            Draw_Note_TX__c DrwTX = new Draw_Note_TX__c();
            
            //Find relevant receivables
            for(Funded_Receivable__c FundedRec : [SELECT id, School__r.Operating_State__r.Name, School__r.NetSuite_ID_CSC__c, Maturity_Date__c,
                                                  Charter_Holder__r.CMO__r.Name, School__r.Name, Purchase_Date__c, name,FV_Amount__c, Receivable_Interest__c,
                                                  Discount_Amount__c,Daily_Rate__c, School__r.Charter_Holder__r.name, Maturity_Buffer__c,
                                                  School__r.Operating_State__r.State_Name__c, Purchase_ID__c, Calculator_Discount__c, Financeable__c, Upfront_Purchase_Price__c,
                                                  Source_School_Attendance_Record__r.Name, Expected_Pay_Date__c, RecordType.DeveloperName, Final_Payment_Date__c, RecordTypeId, RecordType.Name,
                                                    (SELECT Draw_Note__r.Investor__r.Name, Draw_Note__r.Note_Description__c, Refinanced_Date__c,
                                                        Funded_Receivable__c, Draw_Note__r.Borrow_Date__c, Draw_Note__r.Status__c,
                                                        Draw_Note__r.Investor__r.Ownership_Transfer_Borrowing__c, Draw_Note__r.Investor__r.Ownership_Accounting_Reference__c,
                                                        Funded_Receivable__r.School__r.NetSuite_ID_CSC__c
                                                        FROM Draw_Note_TXs__r
                                                        WHERE Status__c IN ('Active', 'Refinanced', 'Paid')
                                                        AND Draw_Note__r.Borrow_Date__c <= :End_Date
                                                        ORDER BY Refinanced_Date__c ASC NULLS LAST)
                                                  FROM Funded_Receivable__c
                                                  WHERE (Final_Payment_Date__c >: Start_Date OR Final_Payment_Date__c =: NULL)
                                                  AND Purchase_Date__c <=: End_Date
                                                  ]){
                                                        MonthEndWrapperMap.put(FundedRec.Id, new MonthEndReportWrapper(FundedRec, DrwTX, 'CSC', 0.00, 0.00, 0.00,
                                                                                                                     0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
                                                                                                                     0.00, 0.00, 0.00, 0.00, Start_Date, End_Date, FundedRec.School__r.NetSuite_ID_CSC__c,
                                                                                                                     FundedRec.School__r.Operating_State__r.State_Name__c, FundedRec.Purchase_ID__c, FundedRec.Financeable__c,
                                                                                                                     FundedRec.Calculator_Discount__c, FundedRec.Upfront_Purchase_Price__c, FundedRec.Source_School_Attendance_Record__r.Name,
                                                                                                                     FundedRec.Expected_Pay_Date__c));
                                                        System.debug('+++++++++');
                                                        System.debug(FundedRec);
            }
            
            //Find correct sum of allocations for each receivable
            for(Allocation__c alloc : [SELECT Face_Amount_Applied__c, Funded_Receivable__c
                                       FROM Allocation__c
                                       WHERE Funded_Receivable__c IN : MonthEndWrapperMap.keySet()
                                       AND Redemption__r.Date_Cleared__c <=: End_Date]){
                                           if(!ReceivableToAllocSumMap.containsKey(alloc.Funded_Receivable__c)){
                                               //system.debug(LoggingLevel.ERROR,'receivable is ' +alloc.Funded_Receivable__c + 'its alloc amount is '+alloc.Face_Amount_Applied__c);
                                               ReceivableToAllocSumMap.put(alloc.Funded_Receivable__c,alloc.Face_Amount_Applied__c);
                                           }else{
                                               //system.debug(LoggingLevel.ERROR,'receivable is ' +alloc.Funded_Receivable__c);
                                               decimal amount = ReceivableToAllocSumMap.get(alloc.Funded_Receivable__c);
                                               //system.debug(LoggingLevel.ERROR,'its filtered alloc amount is ' +alloc.Face_Amount_Applied__c);
                                               amount += alloc.Face_Amount_Applied__c;
                                               ReceivableToAllocSumMap.put(alloc.Funded_Receivable__c,amount);
                                           }
                                       }
            
            //Find correct Draw Note TX for each receivable
            for(Draw_Note_TX__c drtx : [SELECT id, Draw_Note__r.Investor__r.Name, Draw_Note__r.Note_Description__c,
                                        Funded_Receivable__c, Draw_Note__r.Borrow_Date__c, Draw_Note__r.Status__c,
                                        Draw_Note__r.Investor__r.Ownership_Transfer_Borrowing__c, Draw_Note__r.Investor__r.Ownership_Accounting_Reference__c,
                                        Funded_Receivable__r.School__r.NetSuite_ID_CSC__c
                                        FROM Draw_Note_TX__c
                                        WHERE Funded_Receivable__c IN : MonthEndWrapperMap.keySet()
                                        AND Draw_Note__r.Borrow_Date__c <=: End_Date
                                        AND Draw_Note__r.Status__c != 'Draft'
                                        ORDER BY Draw_Note__r.Borrow_Date__c DESC, CreatedDate DESC]){
                                            //system.debug('drtx record si ' + drtx);             					//J Caughie added draft filter 2014.08.11
                                            if(!processedReceivables.contains(drtx.Funded_Receivable__c)){
                                                MonthEndWrapperMap.get(drtx.Funded_Receivable__c).dntx = drtx;
                                                processedReceivables.add(drtx.Funded_Receivable__c);
                                            }       
                                            
                                        }
            
            //Evaluate calculated fields for each receivable
            for(id recId : MonthEndWrapperMap.keySet()){
                // CalculateValues(MonthEndWrapperMap.get(recId), Start_Date, End_Date);
                if(MonthEndWrapperMap.get(recId).FunRec.RecordType.DeveloperName == 'Funded_Receivable' || MonthEndWrapperMap.get(recId).FunRec.RecordType.DeveloperName == 'Loan'){
                    CalculateInvestorPeriodInterest(MonthEndWrapperMap.get(recId), ReceivableToAllocSumMap, Start_Date, End_Date);
                    CalculateInvestorTotalInterest(MonthEndWrapperMap.get(recId), Start_Date, End_Date);
                    System.debug('*** MonthEndWrapperMap ***');
                    System.debug(MonthEndWrapperMap.get(recId));
                }
            }
            ReceivableToAllocSumMap.Clear();
        }
    }
    
    public void CalculateValues(MonthEndReportWrapper merWrap, Date Start_Date, Date End_Date){
        
        //system.debug(LoggingLevel.ERROR,'FV amount is ' +merWrap.FunRec.FV_Amount__c + 'alloc sum is ' +ReceivableToAllocSumMap.get(merWrap.FunRec.Id) + ' fun rec id is '+merWrap.FunRec.Id);
        //system.debug(LoggingLevel.ERROR,'alloc sum is ' +ReceivableToAllocSumMap.get(merWrap.FunRec.Id));
        merWrap.FaceValueDue = (merWrap.FunRec.FV_Amount__c == null ? 0.00 : merWrap.FunRec.FV_Amount__c) - (ReceivableToAllocSumMap.get(merWrap.FunRec.Id) == null ? 0.00 : ReceivableToAllocSumMap.get(merWrap.FunRec.Id));
        
        ReceivableToAllocSumMap.remove(merWrap.FunRec.Id);
        //system.debug(LoggingLevel.ERROR,'days between is ' +merWrap.FunRec.Purchase_Date__c.daysBetween(End_Date));
        //system.debug(LoggingLevel.ERROR,'merWrap.FaceValueDue is ' +merWrap.FaceValueDue);
        //system.debug(LoggingLevel.ERROR,'merWrap.FunRec.Receivable_Interest__c is ' +merWrap.FunRec.Receivable_Interest__c);
        //system.debug(LoggingLevel.ERROR,'merWrap.FunRec.Discount_Amount__c is ' +merWrap.FunRec.Discount_Amount__c);
        //system.debug(LoggingLevel.ERROR,'merWrap.FunRec.Daily_Rate__c is ' +merWrap.FunRec.Daily_Rate__c);
        //system.debug(LoggingLevel.ERROR,'merWrap.FunRec.Maturity_Buffer__c is ' +merWrap.FunRec.Maturity_Buffer__c);
        
        merWrap.AccruedInterestTotal = merWrap.FaceValueDue == 0.00 ? (merWrap.FunRec.Receivable_Interest__c == null ? 0.00 : merWrap.FunRec.Receivable_Interest__c) : Math.Min((merWrap.FunRec.Discount_Amount__c == null ? 0.00 : merWrap.FunRec.Discount_Amount__c), Math.Max ( 0.00,  (merWrap.FunRec.Purchase_Date__c.daysBetween(End_Date) * (merWrap.FunRec.Daily_Rate__c == null ? 0.00 : merWrap.FunRec.Daily_Rate__c))));
        //system.debug('investor is '+ merWrap.dntx.Draw_Note__r.Investor__r.Name);
        //merWrap.AccruedInterestCSC = (merWrap.dntx.Draw_Note__r.Investor__r.Name != null && merWrap.dntx.Draw_Note__r.Investor__r.Name.contains('PCSRC')) ? Math.Min((merWrap.FunRec.Discount_Amount__c == null ? 0.00 : merWrap.FunRec.Discount_Amount__c), Math.Max ( 0,  (merWrap.FunRec.Purchase_Date__c.daysBetween(merWrap.dntx.Draw_Note__r.Borrow_Date__c) * (merWrap.FunRec.Daily_Rate__c == null ? 0.00 : merWrap.FunRec.Daily_Rate__c)))) : merWrap.AccruedInterestTotal;
        merWrap.AccruedInterestCSC = (merWrap.dntx.Draw_Note__r.Investor__r.Name != null && merWrap.dntx.Draw_Note__r.Investor__r.Ownership_Transfer_Borrowing__c) ? Math.Min((merWrap.FunRec.Discount_Amount__c == null ? 0.00 : merWrap.FunRec.Discount_Amount__c), Math.Max ( 0,  (merWrap.FunRec.Purchase_Date__c.daysBetween(merWrap.dntx.Draw_Note__r.Borrow_Date__c) * (merWrap.FunRec.Daily_Rate__c == null ? 0.00 : merWrap.FunRec.Daily_Rate__c)))) : merWrap.AccruedInterestTotal;
        
        ////system.debug('record is ' +merWrap);
        ////system.debug('merWrap.FaceValueDue is '+merWrap.FaceValueDue);
        ////system.debug('accrued total is ' +merWrap.AccruedInterestTotal);
        ////system.debug('AccruedInterestCSC is ' +merWrap.AccruedInterestCSC);
        merWrap.AccruedInterestPCSRC = (merWrap.AccruedInterestTotal == null ? 0.00 : merWrap.AccruedInterestTotal) - (merWrap.AccruedInterestCSC == null ? 0.00 : merWrap.AccruedInterestCSC);
        
        merWrap.PeriodInterestTotal = (merWrap.AccruedInterestTotal == null ? 0.00 : merWrap.AccruedInterestTotal) - Math.Min((merWrap.FunRec.Discount_Amount__c == null ? 0.00 : merWrap.FunRec.Discount_Amount__c), Math.Max ( 0,  (merWrap.FunRec.Purchase_Date__c.daysBetween(Start_Date) * (merWrap.FunRec.Daily_Rate__c == null ? 0.00 : merWrap.FunRec.Daily_Rate__c))));
        
        //merWrap.PeriodInterestCSC = (merWrap.dntx.Draw_Note__r.Investor__r.Name != null && merWrap.dntx.Draw_Note__r.Investor__r.Name.contains('PCSRC') && merWrap.dntx.Draw_Note__r.Borrow_Date__c <= Start_Date) ? 0.00 : (merWrap.AccruedInterestCSC == null ? 0.00 : merWrap.AccruedInterestCSC) - Math.Min((merWrap.FunRec.Discount_Amount__c == null ? 0.00 : merWrap.FunRec.Discount_Amount__c), Math.Max ( 0,  (merWrap.FunRec.Purchase_Date__c.daysBetween(Start_Date) * (merWrap.FunRec.Daily_Rate__c == null ? 0.00 : merWrap.FunRec.Daily_Rate__c))));
        merWrap.PeriodInterestCSC = (merWrap.dntx.Draw_Note__r.Investor__r.Name != null && merWrap.dntx.Draw_Note__r.Investor__r.Ownership_Transfer_Borrowing__c && merWrap.dntx.Draw_Note__r.Borrow_Date__c <= Start_Date) ? 0.00 : (merWrap.AccruedInterestCSC == null ? 0.00 : merWrap.AccruedInterestCSC) - Math.Min((merWrap.FunRec.Discount_Amount__c == null ? 0.00 : merWrap.FunRec.Discount_Amount__c), Math.Max ( 0,  (merWrap.FunRec.Purchase_Date__c.daysBetween(Start_Date) * (merWrap.FunRec.Daily_Rate__c == null ? 0.00 : merWrap.FunRec.Daily_Rate__c))));
        
        merWrap.PeriodInterestPCSRC = (merWrap.PeriodInterestTotal == null ? 0.00 : merWrap.PeriodInterestTotal) - (merWrap.PeriodInterestCSC == null ? 0.00 : merWrap.PeriodInterestCSC);
        
        If(merWrap.FaceValueDue == 0.00){
            merWrap.GainTotal = (merWrap.FunRec.Discount_Amount__c == null ? 0.00 : merWrap.FunRec.Discount_Amount__c) - (merWrap.AccruedInterestTotal == null ? 0.00 : merWrap.AccruedInterestTotal);
            If (merWrap.dntx.Draw_Note__r.Investor__r.Name != null){
                //If(merWrap.dntx.Draw_Note__r.Investor__r.Name.contains('PCSRC')){
                If(merWrap.dntx.Draw_Note__r.Investor__r.Ownership_Transfer_Borrowing__c){
                    merWrap.GainPCSRC = merWrap.GainTotal;
                }
                else{
                    merWrap.GainCSC = merWrap.GainTotal;
                }
            }else{
                merWrap.GainCSC = merWrap.GainTotal;
            }
        }
        else{
            merWrap.UnamortTotal = (merWrap.FunRec.Discount_Amount__c == null ? 0.00 : merWrap.FunRec.Discount_Amount__c) - (merWrap.AccruedInterestTotal == null ? 0.00 : merWrap.AccruedInterestTotal);
            If (merWrap.dntx.Draw_Note__r.Investor__r.Name != null){
                //If(merWrap.dntx.Draw_Note__r.Investor__r.Name.contains('PCSRC')){
                If(merWrap.dntx.Draw_Note__r.Investor__r.Ownership_Transfer_Borrowing__c){
                    merWrap.UnamortPCSRC = merWrap.UnamortTotal;
                }
                else{
                    merWrap.UnamortCSC = merWrap.UnamortTotal;
                }
            }else{
                merWrap.UnamortCSC = merWrap.UnamortTotal;
            }
        }
        
    }
    
    public PageReference CreateJournalEntries(){
        if(startDate == '' || endDate == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled');
            ApexPages.addMessage(myMsg);
        }
        else{
            CreateFundedReceivableList();
            JournalEntriesLogic();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Month End Interest Journal Entries have been created and saved');
            ApexPages.addMessage(myMsg);
            ////system.debug('check');
        }
        return null;
    }
    
    public void JournalEntriesLogic(){
        
        transient list <Journal_Entries__c> lstJournalEntries = new list <Journal_Entries__c>();
        for(MonthEndReportWrapper merWrap : MonthEndWrapperMap.values()){
            System.debug('*** MonthEndWrapperMap ***');
            System.debug(merWrap);
            String accountingClass = getClass(merWrap.FunRec.RecordType.DeveloperName);
            //2019.05.17 J Caughie - added two strings to remove dependency on PCSRC
            String investorReference = merWrap.dntx.Draw_Note__r.Investor__r.Ownership_Accounting_Reference__c;
            //String accountReference = merWrap.dntx.Draw_Note__r.Investor__r.Ownership_Accounting_Reference__c == 'CSFC' ? merWrap.CSFC_Netsuite : merWrap.PCSRC_Netsuite;
            // String accountReference = investorReference != null ? (String)merWrap.dntx.Funded_Receivable__r.School__r.get('NetSuite_ID_' + investorReference + '__c') : '';
            String accountReference = merWrap.CSC_Netsuite;
            //System.debug('here I am!');
            //System.debug(investorReference);
            //System.debug(merWrap.GainCSC);
            if((merWrap.GainTotal > 0.00 && merWrap.CurrentOwner == 'CSC') || merWrap.PeriodInterestCSC > 0.00){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '13000 Discount',
                                                            Internal_ID__c = '173',
                                                            Debit__c = (merWrap.GainTotal + merWrap.PeriodInterestCSC),
                                                            Credit__c = null,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'CSC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = merWrap.CSC_Netsuite,								// Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }
            if((merWrap.GainTotal > 0.00 && merWrap.CurrentOwner == 'CSC')){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '42000 Gain on Acquired Receivables',
                                                            Internal_ID__c = '108',
                                                            Debit__c = null,
                                                            Credit__c = merWrap.GainTotal,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'CSC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = merWrap.CSC_Netsuite,								// Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }
            if(merWrap.PeriodInterestCSC > 0.00){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '41000 Interest Income on Acquired Rec',
                                                            Internal_ID__c = '54',
                                                            Debit__c = null,
                                                            Credit__c = merWrap.PeriodInterestCSC,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'CSC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = merWrap.CSC_Netsuite,								// Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }
            Decimal csfcGain = merWrap.CurrentOwner == 'CSFC' ? merWrap.GainTotal : 0;
            if(merWrap.PeriodInterestCSFC > 0){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '13000 Discount',
                                                            Internal_ID__c = '173',
                                                            Debit__c = merWrap.PeriodInterestCSFC + csfcGain,
                                                            Credit__c = null,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'CSC : CSFC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = accountReference,                                 // Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }  
            if(merWrap.GainTotal > 0.00 && merWrap.CurrentOwner == 'CSFC'){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '42000 Gain on Acquired Receivables',
                                                            Internal_ID__c = '108',
                                                            Debit__c = null,
                                                            Credit__c = merWrap.GainTotal,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'CSC : CSFC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = accountReference,                                 // Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }
            if(merWrap.PeriodInterestCSFC > 0){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '41000 Interest Income on Acquired Rec',
                                                            Internal_ID__c = '54',
                                                            Debit__c = null,
                                                            Credit__c = merWrap.PeriodInterestCSFC,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'CSFC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = accountReference,                                 // Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }            
            Decimal pcsrcGain = merWrap.CurrentOwner == 'PCSRC' ? merWrap.GainTotal : 0;
            if(merWrap.PeriodInterestPCSRC > 0){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '13000 Discount',
                                                            Internal_ID__c = '173',
                                                            Debit__c = merWrap.PeriodInterestPCSRC + pcsrcGain,
                                                            Credit__c = null,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'CSC : PCSRC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = accountReference,                                 // Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }  
            if(merWrap.GainTotal > 0.00 && merWrap.CurrentOwner == 'PCSRC'){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '42000 Gain on Acquired Receivables',
                                                            Internal_ID__c = '108',
                                                            Debit__c = null,
                                                            Credit__c = merWrap.GainTotal,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'CSC : PCSRC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = accountReference,                                 // Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }
            if(merWrap.PeriodInterestPCSRC > 0){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '41000 Interest Income on Acquired Rec',
                                                            Internal_ID__c = '54',
                                                            Debit__c = null,
                                                            Credit__c = merWrap.PeriodInterestPCSRC,
                                                            Funded_Receivable__c = merWrap.FunRec.Id,
                                                            Source_Table__c = 'Monthly Report',
                                                            Subsidiary__c = 'PCSRC',
                                                            Class__c = accountingClass,									// Added 8/7/14
                                                            Department__c = 'NA',							// Added 8/7/14
                                                            Memo__c = '',												// Added 8/7/14
                                                            Name__c = accountReference,                                 // Added 8/7/14
                                                            Location__c = merWrap.Location,								// Added 8/7/14
                                                            Transaction_Date__c = Date.parse(endDate)));
            }            
        }
        
        insert lstJournalEntries; 
    }
    
    public PageReference CreatePurchaseJournalEntries(){
        if(startDateOther == '' || endDateOther == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled');
            ApexPages.addMessage(myMsg);
        }
        else{
            CreateFundedReceivableListForPurchaseJournal();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Purchase Journal Entries have been created and saved');
            ApexPages.addMessage(myMsg);
            ////system.debug('check');
        }
        return null;
    }
    
    public void CreateFundedReceivableListForPurchaseJournal(){
        
        transient list <Journal_Entries__c> lstJournalEntries = new list <Journal_Entries__c>();
        transient list <Funded_Receivable__c> lstFundRecPurchase = new list <Funded_Receivable__c>();
        //transient map <ID, Decimal> OppIdToNetSchoolMap = new map <ID, Decimal>();
        //transient map <ID, Date> OppIdToCloseDateMap = new map <ID, Date>();
        transient map <String, Decimal> OppSchoolToNetSchoolMap = new map <String, Decimal>();								// J Caughie 2014.08.14 - added to journal Net to School per school
        transient map <String, Date> OppSchoolToCloseDateMap = new map <String, Date>();									// J Caughie 2014.08.14 - added to journal Net to School per school
        transient map <String, ID> OppSchoolToOpportunityMap = new map <String, ID>();										// J Caughie 2014.08.14 - added to journal Net to School per school
        transient map <String, String> OppSchoolToNetuiteIDMap = new map <String, String>();								// J Caughie 2014.08.14 - added to journal Net to School per school
        transient map <String, String> OppSchoolToStateMap = new map <String, String>();									// J Caughie 2014.08.14 - added to journal Net to School per school
        //transient map <ID, String> OppIdToNetSuiteCH = new map <ID, String>();
        transient Date CloseDate;
        transient Decimal NetToSchool;
        transient Decimal amount;
        for(Funded_Receivable__c FundRecPurchase : [SELECT id, Program_Fees_Collected__c, Purchase_Date__c, Transaction_Fee_Collected__c,
                                                    School__r.NetSuite_ID_CSC__c, Discount_Amount__c, School__r.Operating_State__r.State_Name__c,
                                                    Unpaid_Balance_Receivables_Collected__c, Bond_or_Other_Payment__c, Penalty_Interest__c,
                                                    Refund_Reimbursements__c,Application_Fee_Credit__c, Blocked_Account_Fee_Collected__c, FV_Amount__c,
                                                    Source_Opportunity__c, Program_Fee_Earned__c, Net_to_School__c,Source_Opportunity__r.CloseDate, School__c,
                                                    Opp_Date_Identifier__c, RecordType.DeveloperName, Donated_Discount_Receivable__c
                                                    FROM Funded_Receivable__c
                                                    WHERE RecordType.DeveloperName != 'Invoice' 
                                                    AND Purchase_Date__c >: Date.parse(startDateOther)
                                                    AND Purchase_Date__c <=: Date.Parse(endDateOther)
                                                    AND Is_Journaled__c =: FALSE
                                                    ORDER BY Source_Opportunity__r.CloseDate,
                                                    Source_Opportunity__r.Name,
                                                    Purchase_Date__c]){										//2014.10.29 J Caughie - Added Opp_Date_Identifier__c
                                                        String accountingClass = getClass(FundRecPurchase.RecordType.DeveloperName);
                                                        if(FundRecPurchase.Program_Fees_Collected__c <> null && FundRecPurchase.Program_Fees_Collected__c > 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '23000 Unearned Program Fee',
                                                                                                        Internal_ID__c = '203',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Program_Fees_Collected__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass, 													// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Transaction_Fee_Collected__c <> null && FundRecPurchase.Transaction_Fee_Collected__c > 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '44000 Transaction Fees',
                                                                                                        Internal_ID__c = '244',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Transaction_Fee_Collected__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Unpaid_Balance_Receivables_Collected__c <> null && FundRecPurchase.Unpaid_Balance_Receivables_Collected__c > 0.00){
                                                            //lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10200 Cash : East West Bank Funding #2070',
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10250 Cash : TCB Funding #8888',
                                                                                                        Internal_ID__c = '890',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Unpaid_Balance_Receivables_Collected__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Bond_or_Other_Payment__c <> null && FundRecPurchase.Bond_or_Other_Payment__c > 0.00){
                                                            //lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10200 Cash : East West Bank Funding #2070',
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10250 Cash : TCB Funding #8888',
                                                                                                        Internal_ID__c = '890',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Bond_or_Other_Payment__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Bond_or_Other_Payment__c <> null && FundRecPurchase.Bond_or_Other_Payment__c < 0.00){
                                                            //lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10200 Cash : East West Bank Funding #2070',
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10250 Cash : TCB Funding #8888',
                                                                                                        Internal_ID__c = '890',
                                                                                                        Debit__c = -FundRecPurchase.Bond_or_Other_Payment__c,
                                                                                                        Credit__c = null,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Penalty_Interest__c <> null && FundRecPurchase.Penalty_Interest__c > 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '46100 Other Income : Interest Income',
                                                                                                        Internal_ID__c = '248',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Penalty_Interest__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Refund_Reimbursements__c <> null && FundRecPurchase.Refund_Reimbursements__c > 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '83100 Sales Expense : Reimbursement/Refund',
                                                                                                        Internal_ID__c = 'xxx',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Refund_Reimbursements__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Refund_Reimbursements__c <> null && FundRecPurchase.Refund_Reimbursements__c < 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '83100 Sales Expense : Reimbursement/Refund',
                                                                                                        Internal_ID__c = 'xxx',
                                                                                                        Debit__c = -FundRecPurchase.Refund_Reimbursements__c,
                                                                                                        Credit__c = null,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Application_Fee_Credit__c <> null && FundRecPurchase.Application_Fee_Credit__c <> 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '46200 Other Income : Credit Application Fees',
                                                                                                        Internal_ID__c = 'xxx',
                                                                                                        Debit__c = math.abs(FundRecPurchase.Application_Fee_Credit__c),
                                                                                                        Credit__c = null,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Blocked_Account_Fee_Collected__c <> null && FundRecPurchase.Blocked_Account_Fee_Collected__c > 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '21300 Blocked Fees Held',
                                                                                                        Internal_ID__c = 'xxx',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Blocked_Account_Fee_Collected__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.FV_Amount__c <> null && FundRecPurchase.FV_Amount__c  > 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '12000 Purchased Receivables',
                                                                                                        Internal_ID__c = '122',
                                                                                                        Debit__c = FundRecPurchase.FV_Amount__c,
                                                                                                        Credit__c = null,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Discount_Amount__c <> null && FundRecPurchase.Discount_Amount__c  > 0.00){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '13000 Discount',
                                                                                                        Internal_ID__c = '173',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Discount_Amount__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Program_Fee_Earned__c <> null && FundRecPurchase.Program_Fee_Earned__c > 0.00 && FundRecPurchase.School__r.Operating_State__r.State_Name__c == 'California'){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '23000 Unearned Program Fee',
                                                                                                        Internal_ID__c = '203',
                                                                                                        Debit__c = FundRecPurchase.Program_Fee_Earned__c,
                                                                                                        Credit__c = null,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '43000 Program Fee Revenue',
                                                                                                        Internal_ID__c = '243',
                                                                                                        Debit__c = null,
                                                                                                        Credit__c = FundRecPurchase.Program_Fee_Earned__c,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        if(FundRecPurchase.Donated_Discount_Receivable__c){
                                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '71040 Charitable Contributions',
                                                                                                        Internal_ID__c = '263',
                                                                                                        Debit__c = FundRecPurchase.Discount_Amount__c,
                                                                                                        Credit__c = null,
                                                                                                        Funded_Receivable__c = FundRecPurchase.Id,
                                                                                                        Source_Table__c = 'Purchase',
                                                                                                        Subsidiary__c = 'CSC',
                                                                                                        Class__c = accountingClass,														// Added 8/7/14
                                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                                        Name__c = FundRecPurchase.School__r.NetSuite_ID_CSC__c,							// Added 8/7/14
                                                                                                        Location__c = FundRecPurchase.School__r.Operating_State__r.State_Name__c,		// Added 8/7/14
                                                                                                        Transaction_Date__c = FundRecPurchase.Purchase_Date__c));
                                                        }
                                                        
                                                        FundRecPurchase.Is_Journaled__c = true;
                                                        lstFundRecPurchase.add(FundRecPurchase);
                                                        
                                                        NetToSchool = FundRecPurchase.Net_to_School__c == null ? 0.00 : FundRecPurchase.Net_to_School__c;
                                                        //CloseDate = FundRecPurchase.Source_Opportunity__r.CloseDate;
                                                        CloseDate = FundRecPurchase.Purchase_Date__c;																					//2014.10.29 J Caughie
                                                        //CharterId =
                                                        
                                                        //amount = OppIdToNetSchoolMap.get(FundRecPurchase.Source_Opportunity__c);
                                                        amount = OppSchoolToNetSchoolMap.get(FundRecPurchase.Opp_Date_Identifier__c);
                                                        if(amount == null){
                                                            //OppIdToCloseDateMap.put(FundRecPurchase.Source_Opportunity__c,CloseDate);
                                                            //OppIdToNetSchoolMap.put(FundRecPurchase.Source_Opportunity__c,NetToSchool);
                                                            //OppIdToNetSuiteCH.put(FundRecPurchase.Source_Opportunity__c,CharterID);
                                                            OppSchoolToCloseDateMap.put(FundRecPurchase.Opp_Date_Identifier__c, CloseDate);													// J Caughie 2014.08.14 - added to journal Net to School per school
                                                            OppSchoolToNetSchoolMap.put(FundRecPurchase.Opp_Date_Identifier__c, NetToSchool);												// J Caughie 2014.08.14 - added to journal Net to School per school
                                                            OppSchoolToOpportunityMap.put(FundRecPurchase.Opp_Date_Identifier__c, FundRecPurchase.Source_Opportunity__c);					// J Caughie 2014.08.14 - added to journal Net to School per school
                                                            OppSchoolToNetuiteIDMap.put(FundRecPurchase.Opp_Date_Identifier__c, FundRecPurchase.School__r.NetSuite_ID_CSC__c);				// J Caughie 2014.08.14 - added to journal Net to School per school
                                                            OppSchoolToStateMap.put(FundRecPurchase.Opp_Date_Identifier__c, FundRecPurchase.School__r.Operating_State__r.State_Name__c);	// J Caughie 2014.08.14 - added to journal Net to School per school
                                                        }else{
                                                            //OppIdToNetSchoolMap.put(FundRecPurchase.Source_Opportunity__c,NetToSchool + amount);
                                                            OppSchoolToNetSchoolMap.put(FundRecPurchase.Opp_Date_Identifier__c, NetToSchool + amount);								// J Caughie 2014.08.14 - added to journal Net to School per school
                                                        }
                                                        
                                                        /*if(!OppIdToNetSchoolMap.containsKey(FundRecPurchase.Source_Opportunity__c)){
        //system.debug(LoggingLevel.ERROR,'receivable is ' +alloc.Funded_Receivable__c + 'its alloc amount is '+alloc.Face_Amount_Applied__c);
        OppIdToCloseDateMap.put(FundRecPurchase.Source_Opportunity__c,CloseDate);
        OppIdToNetSchoolMap.put(FundRecPurchase.Source_Opportunity__c,NetToSchool);
        }
        else{
        //system.debug(LoggingLevel.ERROR,'receivable is ' +alloc.Funded_Receivable__c);
        amount = OppIdToNetSchoolMap.get(FundRecPurchase.Source_Opportunity__c);
        //system.debug(LoggingLevel.ERROR,'its filtered alloc amount is ' +alloc.Face_Amount_Applied__c);
        amount += NetToSchool;
        OppIdToNetSchoolMap.put(FundRecPurchase.Source_Opportunity__c,amount);
        }*/
                                                    }
        
        for(String OppDate : OppSchoolToNetSchoolMap.KeySet()){
            //lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10200 Cash : East West Bank Funding #2070',
            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10250 Cash : TCB Funding #8888',
                                                        Internal_ID__c = '890',
                                                        Debit__c = null,
                                                        Credit__c = OppSchoolToNetSchoolMap.get(OppDate),
                                                        Opportunity__c = OppSchoolToOpportunityMap.get(OppDate),
                                                        Source_Table__c = 'Purchase',
                                                        Subsidiary__c = 'CSC',
                                                        Class__c = '103',
                                                        Department__c = 'NA',
                                                        Memo__c = '',
                                                        Name__c = OppSchoolToNetuiteIDMap.get(OppDate),
                                                        Location__c = OppSchoolToStateMap.get(OppDate),
                                                        Transaction_Date__c = OppSchoolToCloseDateMap.get(OppDate)));
            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10250 Cash : TCB Funding #8888',
                                                        Internal_ID__c = '890',
                                                        Debit__c = OppSchoolToNetSchoolMap.get(OppDate),
                                                        Credit__c = null,
                                                        Opportunity__c = OppSchoolToOpportunityMap.get(OppDate),
                                                        Source_Table__c = 'Purchase',
                                                        Subsidiary__c = 'CSC',
                                                        Class__c = '103',
                                                        Department__c = 'NA',
                                                        Memo__c = '',
                                                        Name__c = OppSchoolToNetuiteIDMap.get(OppDate),
                                                        Location__c = OppSchoolToStateMap.get(OppDate),
                                                        Transaction_Date__c = OppSchoolToCloseDateMap.get(OppDate)));
            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10150 Cash : TCB Operating #8821',
                                                        Internal_ID__c = '889',
                                                        Debit__c = null,
                                                        Credit__c = OppSchoolToNetSchoolMap.get(OppDate),
                                                        Opportunity__c = OppSchoolToOpportunityMap.get(OppDate),
                                                        Source_Table__c = 'Purchase',
                                                        Subsidiary__c = 'CSC',
                                                        Class__c = '103',
                                                        Department__c = 'NA',
                                                        Memo__c = '',
                                                        Name__c = OppSchoolToNetuiteIDMap.get(OppDate),
                                                        Location__c = OppSchoolToStateMap.get(OppDate),
                                                        Transaction_Date__c = OppSchoolToCloseDateMap.get(OppDate)));
        }     // J Caughie 2014.08.14 - added to journal Net to School per school
        
        /*for(Id OppId : OppIdToNetSchoolMap.KeySet()){
        lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '10200 Cash: East West Bank Funding #2070',
        Debit__c = null,
        Credit__c = OppIdToNetSchoolMap.get(OppId),
        Opportunity__c = OppId,
        Source_Table__c = 'Purchase',
        Subsidiary__c = 'CSC',
        Class__c = '',												// Added 8/7/14
        Department__c = 'NA',							// Added 8/7/14
        Memo__c = '',												// Added 8/7/14 
        Transaction_Date__c = OppIdToCloseDateMap.get(OppId)));
        }*/
        
        update lstFundRecPurchase;
        
        insert lstJournalEntries;
    }
    
    public PageReference CreatePCSRCJournalEntries(){
        if(startDateDraw == '' || endDateDraw == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled');
            ApexPages.addMessage(myMsg);
        }
        else{
            CreateDrawTXListForDrawJournal();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Draw Journal Entries have been created and saved');
            ApexPages.addMessage(myMsg);
            ////system.debug('check');
        }
        return null;
    }
    
    public void CreateDrawTXListForDrawJournal(){
        
        transient list <Journal_Entries__c> lstJournalEntries = new list <Journal_Entries__c>();
        transient list <Draw_Note__c> lstDrawNote = new list <Draw_Note__c>();
        transient set<ID> processedDrawIds = new set<ID>();
        
        // 2021.08.03 - J Caughie
        // Additional section to determine the last lien holder of the receivables on these draws
        Set<Id> recIds = new Set<Id>();
        for(Draw_Note_TX__c drawTX : [SELECT Funded_Receivable__r.Id
                                    FROM Draw_Note_TX__c 
                                    WHERE draw_note__r.Borrow_Date__c >: Date.parse(startDateDraw)
                                    AND draw_note__r.Borrow_Date__c <=: Date.parse(endDateDraw)
                                    AND draw_note__r.Is_Journaled__c = FALSE
                                    AND draw_note__r.Status__c = 'Active'
                                    AND draw_note__r.Investor__r.Ownership_Transfer_Borrowing__c = True]){

                                        recIds.add(drawTX.Funded_Receivable__r.Id);
                                    }


        // 2021.10.25 - J Caughie
        // Calculations for Deposit in Transit value as draw amount isn't always the correct value!
        List<AggregateResult> draws = [SELECT Draw_Note__c, Sum(DailyInterest_Unamortized__c) UNAM, SUM(FV_Amount_TX__c) FV 
                                        FROM Draw_Note_TX__c 
                                        WHERE draw_note__r.Borrow_Date__c >: Date.parse(startDateDraw)
                                        AND draw_note__r.Borrow_Date__c <=: Date.parse(endDateDraw)
                                        AND draw_note__r.Is_Journaled__c = FALSE
                                        AND draw_note__r.Status__c = 'Active'
                                        AND draw_note__r.Investor__r.Ownership_Transfer_Borrowing__c = True
                                        GROUP BY Draw_Note__c];
        Map<Id, Decimal> drawToDepositValue = new Map<Id, Decimal>();

        for(AggregateResult ar : draws){
            System.debug('ar : ' + ar);
            Id draw = (ID) ar.get('Draw_Note__c');
            Decimal discount = (Decimal)ar.get('UNAM');
            Decimal fv = (Decimal)ar.get('FV');
            drawToDepositValue.put(draw,  fv - discount);
        }

        System.debug(drawToDepositValue);
                
                
        List<Funded_Receivable__c> drawRecs = new List <Funded_Receivable__c>();
        drawRecs = [SELECT Id, Name, (SELECT Id, Name, draw_note__r.Investor__r.Ownership_Accounting_Reference__c FROM Draw_Note_TXs__r WHERE draw_note__r.Borrow_Date__c <=: Date.parse(startDateDraw) AND Status__c = 'Refinanced' ORDER BY Draw_Date__c DESC) FROM Funded_Receivable__c wHERE Id IN: recIds];
        Map<ID, Funded_Receivable__c> fundedRecMap = new Map<ID, Funded_Receivable__c>(drawRecs);
        
        for(Draw_Note_TX__c drawTX : [SELECT id, Draw_Note__c, draw_note__r.Borrow_Date__c, draw_note__r.Total_Amount_Borrowed__c, draw_note__r.Operating_State__r.State_Name__c, FV_Amount_TX__c,
                                      DailyInterest_Unamortized__c, Funded_Receivable__r.School__r.NetSuite_ID_CSC__c,
                                      draw_note__r.Total_Transfer_Value__c, draw_note__r.Investor__r.Ownership_Transfer_Borrowing__c, draw_note__r.Investor__r.Ownership_Accounting_Reference__c,
                                      draw_note__r.Investor__r.Deposit_in_Transit_A_C__c, Funded_Receivable__r.RecordType.DeveloperName, Funded_Receivable__r.Id, Funded_Receivable__r.School__r.Operating_State__r.State_Name__c
                                      FROM Draw_Note_TX__c 
                                      WHERE draw_note__r.Borrow_Date__c >: Date.parse(startDateDraw)
                                      AND draw_note__r.Borrow_Date__c <=: Date.parse(endDateDraw)
                                      AND draw_note__r.Is_Journaled__c =: FALSE
                                      AND draw_note__r.Status__c = 'Active'
                                      AND draw_note__r.Investor__r.Ownership_Transfer_Borrowing__c = True]){
                                      //AND draw_note__r.Investor__r.name like '%PCSRC%']){
                                          
                                                                        /*                                                      }
                                        for(draw_note__c draw : [select id, Borrow_Date__c, Total_Amount_Borrowed__c from Draw_Note__c
                                        where Borrow_Date__c >: Date.parse(startDateDraw)
                                        AND Borrow_Date__c <=: Date.parse(endDateDraw)
                                        AND Is_Journaled__c =: FALSE
                                        AND Status__c = 'Active'
                                        AND Investor__r.name like '%PCSRC%']){*/
                                          //2019.05.17 J Caughie - added to remove PCSRC dependency
                                        String accountingClass = getClass(drawTX.Funded_Receivable__r.RecordType.DeveloperName);
                                        String investorReference = drawTX.Draw_Note__r.Investor__r.Ownership_Accounting_Reference__c;
                                        String depositInTransit = drawTX.Draw_Note__r.Investor__r.Deposit_in_Transit_A_C__c;
                                        //String schoolNetsuiteId = drawTX.Draw_Note__r.Investor__r.Ownership_Accounting_Reference__c == 'CSFC' ? drawTX.Funded_Receivable__r.School__r.NetSuite_ID_CSFC__c : drawTX.Funded_Receivable__r.School__r.NetSuite_ID_PCSRC__c;
                                        //String schoolNetsuiteId = (String)drawTX.getSObject('Funded_Receivable__r').getSObject('School__r').get('NetSuite_ID_' + investorReference + '__c');
                                        String schoolNetsuiteId = drawTX.Funded_Receivable__r.School__r.NetSuite_ID_CSC__c;
                                        
                                        String seller = 'CSC';
                                        if(fundedRecMap.containsKey(drawTX.Funded_Receivable__r.Id)){
                                            for(Draw_Note_TX__c dntx : fundedRecMap.get(drawTX.Funded_Receivable__r.Id).Draw_Note_TXs__r){
                                                String sellerRef = dntx.draw_note__r.Investor__r.Ownership_Accounting_Reference__c;
                                                if(String.isNotBlank(sellerRef)){
                                                    seller = sellerRef;
                                                    break;
                                                }
                                            }
                                        }

                                        /* 
                                        Add this to calculate Deposit in Transit amount

                                        SELECT Draw_Note__c, Sum(DailyInterest_Unamortized__c) UNAM, SUM(FV_Amount_TX__c) FV FROM Draw_Note_TX__c WHERE Draw_Note__r.Borrow_Date__c = Last_Month GROUP BY Draw_Note__c

                                        */

                                        if(!processedDrawIds.contains(drawTX.Draw_Note__c)){
                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '11999 Cash : Deposit in Transit',
                                                                                        Internal_ID__c = '169',
                                                                                        //Debit__c = drawTX.draw_note__r.Total_Transfer_Value__c,                        // 2014.11.13 J Caughie - corrected field to use
                                                                                        //Debit__c = drawTX.draw_note__r.Total_Amount_Borrowed__c,                       // 2019.03.01 J Caughie - changed to amount borrowed
                                                                                        Debit__c = drawToDepositValue.get(drawTX.Draw_Note__c),                          // 2021.10.25 J Caughie - added new calculations
                                                                                        Credit__c = null,
                                                                                        Draw_Note__c = drawTX.Draw_Note__c,
                                                                                        Source_Table__c = 'Draw',
                                                                                        Subsidiary__c = seller,
                                                                                        Class__c = accountingClass,																	// Added 8/7/14
                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                        Name__c = '169',																// Added 8/7/14
                                                                                        Location__c = drawTX.Draw_Note__r.Operating_State__r.State_Name__c,				// Added 8/7/14
                                                                                        Transaction_Date__c = drawTX.draw_note__r.Borrow_Date__c));
                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '11997 Cash : Deposit in Transit - ' + investorReference,
                                                                                        Internal_ID__c = '759',
                                                                                        Debit__c = null,
                                                                                        //Credit__c = drawTX.draw_note__r.Total_Transfer_Value__c,                       // 2014.11.13 J Caughie - corrected field to use
                                                                                        //Credit__c = drawTX.draw_note__r.Total_Amount_Borrowed__c,                        // 2019.03.01 J Caughie - changed to amount borrowed
                                                                                        Credit__c = drawToDepositValue.get(drawTX.Draw_Note__c),                          // 2021.10.25 J Caughie - added new calculations
                                                                                        Draw_Note__c = drawTX.Draw_Note__c,
                                                                                        Source_Table__c = 'Draw',
                                                                                        Subsidiary__c = seller + ' : ' + investorReference,
                                                                                        Class__c = accountingClass,																	// Added 8/7/14
                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                        Name__c = depositInTransit,																// Added 8/7/14
                                                                                        Location__c = drawTX.Draw_Note__r.Operating_State__r.State_Name__c,				// Added 8/7/14
                                                                                        Transaction_Date__c = drawTX.draw_note__r.Borrow_Date__c));
                                            lstDrawNote.add(new Draw_Note__c (id = drawTX.Draw_Note__c, Is_Journaled__c = true));
                                            system.debug(LoggingLevel.ERROR,'setting jou ');
                                            processedDrawIds.add(drawTX.Draw_Note__c);
                                        }
                                        
                                        if(drawTX.FV_Amount_TX__c != null){
                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '12000 Purchased Receivables',
                                                                                        Internal_ID__c = '122',
                                                                                        Debit__c = null,
                                                                                        Credit__c = drawTX.FV_Amount_TX__c,
                                                                                        Draw_Note__c = drawTX.Draw_Note__c,
                                                                                        Draw_Note_TX__c = drawTX.id,
                                                                                        Source_Table__c = 'Draw',
                                                                                        Subsidiary__c = seller,
                                                                                        Class__c = accountingClass,																	// Added 8/7/14
                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                        Name__c = drawTX.Funded_Receivable__r.School__r.NetSuite_ID_CSC__c,				// Added 8/7/14
                                                                                        Location__c = drawTX.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,				// Added 8/7/14
                                                                                        Transaction_Date__c = drawTX.draw_note__r.Borrow_Date__c));
                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '12000 Purchased Receivables',
                                                                                        Internal_ID__c = '122',
                                                                                        Debit__c = drawTX.FV_Amount_TX__c,
                                                                                        Credit__c = null,
                                                                                        Draw_Note__c = drawTX.Draw_Note__c,
                                                                                        Draw_Note_TX__c = drawTX.id,
                                                                                        Source_Table__c = 'Draw',
                                                                                        Subsidiary__c = seller + ' : ' + investorReference,
                                                                                        Class__c = accountingClass,																	// Added 8/7/14
                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                        Name__c = schoolNetsuiteId,			// Added 8/7/14
                                                                                        Location__c = drawTX.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,				// Added 8/7/14
                                                                                        Transaction_Date__c = drawTX.draw_note__r.Borrow_Date__c));
                                        }
                                        
                                        if(drawTX.DailyInterest_Unamortized__c != null){
                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '13000 Discount',
                                                                                        Internal_ID__c = '173',
                                                                                        Debit__c = drawTX.DailyInterest_Unamortized__c,
                                                                                        Credit__c = null,
                                                                                        Draw_Note__c = drawTX.Draw_Note__c,
                                                                                        Draw_Note_TX__c = drawTX.id,
                                                                                        Source_Table__c = 'Draw',
                                                                                        Subsidiary__c = seller,
                                                                                        Class__c = accountingClass,																	// Added 8/7/14
                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                        Name__c = drawTX.Funded_Receivable__r.School__r.NetSuite_ID_CSC__c,				// Added 8/7/14
                                                                                        Location__c = drawTX.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,				// Added 8/7/14
                                                                                        Transaction_Date__c = drawTX.draw_note__r.Borrow_Date__c));
                                            lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '13000 Discount',
                                                                                        Internal_ID__c = '173',
                                                                                        Debit__c = null,
                                                                                        Credit__c = drawTX.DailyInterest_Unamortized__c,
                                                                                        Draw_Note__c = drawTX.Draw_Note__c,
                                                                                        Draw_Note_TX__c = drawTX.id,
                                                                                        Source_Table__c = 'Draw',
                                                                                        Subsidiary__c = seller + ' : ' + investorReference,
                                                                                        Class__c = accountingClass,																	// Added 8/7/14
                                                                                        Department__c = 'NA',												// Added 8/7/14
                                                                                        Memo__c = '',																	// Added 8/7/14
                                                                                        Name__c = schoolNetsuiteId,			// Added 8/7/14
                                                                                        Location__c = drawTX.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,				// Added 8/7/14
                                                                                        Transaction_Date__c = drawTX.draw_note__r.Borrow_Date__c));
                                        }
                                      }
        
        insert lstJournalEntries;
        system.debug(LoggingLevel.ERROR,'saving ');
        System.debug('draw entries ' + lstDrawNote);
        update lstDrawNote;
    }
    
    public PageReference CreateRedemptionJournalEntries(){
        if(startDateRed == '' || endDateRed == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled');
            ApexPages.addMessage(myMsg);
        }
        else{
            CreatePaymentStubsListForRedemptionJournal();
            system.debug('check123');
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Redemption Journal Entries have been created and saved');
            ApexPages.addMessage(myMsg);
            //system.debug('check');  
        }
        return null;
    }
    
    public void CreatePaymentStubsListForRedemptionJournal(){
        transient list <Journal_Entries__c> lstJournalEntries = new list <Journal_Entries__c>();
        transient list <Redemption__c> lstRedemption = new list <Redemption__c>();
        transient map<ID, Decimal> RedToCSCSumMap = new map<ID, Decimal>();
        //transient map<ID, Decimal> RedToPCSRCSumMap = new map<ID, Decimal>();
        //2019.05.17 J Caughie - replace PCSRC with all owner investors
        transient Map<ID, Map<String, Decimal>> RedToInvestorSumMap = new Map<ID, Map<String, Decimal>>();
        transient Map<String, Decimal> investorToRedSum = new Map<String, Decimal>();
        transient set<ID> setProcessedRedIds = new Set<ID>();
        
        for(Payment_Sub__c paySub : [SELECT id, Redemption__c, Payment_Against__r.Investor__r.Name, Payment_Against__r.Investor__r.Ownership_Accounting_Reference__c,
                                        Paid_To__c, Amount__c 
                                     FROM Payment_Sub__c
                                     WHERE Redemption__r.Is_Journaled__c =: FALSE 
                                     AND Redemption__r.Date_Cleared__c >: Date.parse(startDateRed) 
                                     AND Redemption__r.Date_Cleared__c <=: Date.parse(endDateRed)
                                     AND Paid_To__c in ('Investor','CSC')]){
                                         
                                         
                                    // 
                                         //if(paySub.Paid_To__c == 'Investor' && paySub.Payment_Against__r.Investor__r.Name.contains('PCSRC')){ 
                                         //    if(!RedToPCSRCSumMap.containsKey(paySub.Redemption__c)){
                                         //        RedToPCSRCSumMap.put(paySub.Redemption__c,paySub.Amount__c);
                                         //        setProcessedRedIds.add(paySub.Redemption__c);
                                         //    }else{
                                         //        Decimal amount = RedToPCSRCSumMap.get(paySub.Redemption__c);
                                         //        RedToPCSRCSumMap.put(paySub.Redemption__c,paySub.Amount__c + amount);
                                         //    }
                                         //}
                                         //else{
                                         //    if(!RedToCSCSumMap.containsKey(paySub.Redemption__c)){
                                         //        RedToCSCSumMap.put(paySub.Redemption__c,paySub.Amount__c);
                                         //        setProcessedRedIds.add(paySub.Redemption__c);
                                         //    }else{
                                         //        Decimal amount = RedToCSCSumMap.get(paySub.Redemption__c);
                                         //        RedToCSCSumMap.put(paySub.Redemption__c,paySub.Amount__c + amount);
                                         //    }
                                         //}
                                    //

                                        System.debug('paySub ' + paySub);

                                        //2019.05.17 J Caughie - replaced PCSRC dependent section making it investor neutral                                       
                                        if(paySub.Paid_To__c == 'Investor' && paySub.Payment_Against__r.Investor__r.Ownership_Accounting_Reference__c != null){
                                            System.debug('Inv ref: ' + paySub.Payment_Against__r.Investor__r.Ownership_Accounting_Reference__c);    
                                            //create map of redemptions to a map of investor to value
                                            if(RedToInvestorSumMap.containsKey(paySub.Redemption__c)){
                                                System.debug('existing');
                                                investorToRedSum = RedToInvestorSumMap.get(paySub.Redemption__c).clone();
                                                System.debug('investorToRedSum: ' + investorToRedSum);
                                                if(investorToRedSum.containsKey(paySub.Payment_Against__r.Investor__r.Ownership_Accounting_Reference__c)){
                                                    Decimal amount = investorToRedSum.get(paySub.Payment_Against__r.Investor__r.Ownership_Accounting_Reference__c);
                                                    investorToRedSum.put(paySub.Payment_Against__r.Investor__r.Ownership_Accounting_Reference__c, paySub.Amount__c + amount);
                                                    System.debug('investorToRedSum after: ' + investorToRedSum);
                                                } else {
                                                    investorToRedSum.put(paySub.Payment_Against__r.Investor__r.Ownership_Accounting_Reference__c,paySub.Amount__c);
                                                    System.debug('investorToRedSum after: ' + investorToRedSum);
                                                    //setProcessedRedIds.add(paySub.Redemption__c);
                                                }
                                                RedToInvestorSumMap.put(paySub.Redemption__c, investorToRedSum);
                                            } else {
                                                System.debug('new');
                                                investorToRedSum = new Map<String, Decimal>();
                                                investorToRedSum.put(paySub.Payment_Against__r.Investor__r.Ownership_Accounting_Reference__c, paySub.Amount__c);
                                                System.debug('redemp: ' + paySub.Redemption__c);
                                                System.debug(investorToRedSum);
                                                RedToInvestorSumMap.put(paySub.Redemption__c, investorToRedSum.clone());
                                                System.debug(RedToInvestorSumMap);
                                                setProcessedRedIds.add(paySub.Redemption__c);
                                            }
                                        } else {
                                            //create a map of redemptions to csc value
                                            if(RedToCSCSumMap.containsKey(paySub.Redemption__c)){
                                                Decimal amount = RedToCSCSumMap.get(paySub.Redemption__c);
                                                RedToCSCSumMap.put(paySub.Redemption__c,paySub.Amount__c + amount); 
                                            } else {
                                                RedToCSCSumMap.put(paySub.Redemption__c,paySub.Amount__c);
                                                setProcessedRedIds.add(paySub.Redemption__c);
                                            }
                                        }
                                    }
        System.debug('cscs ' + RedToCSCSumMap);
        System.debug('investors ' + RedToInvestorSumMap);
        System.debug('processed redemptions' + setProcessedRedIds);

        
        for(Redemption__c Red : [SELECT id, Date_Paid__c, Date_Cleared__c, School__r.NetSuite_ID_CSC__c, School__r.Operating_State__r.State_Name__c
                                FROM Redemption__c 
                                WHERE id in : setProcessedRedIds]){

            //Create journal entries for CSC values redeemed
            if(RedToCSCSumMap.get(Red.Id) > 0.00){
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '11999 Cash : Deposit in Transit',
                                                             Internal_ID__c = '169',
                                                             Debit__c = RedToCSCSumMap.get(Red.Id),
                                                             Credit__c = null,
                                                             Redemption__c = Red.id,
                                                             Source_Table__c = 'Redemption',
                                                             Subsidiary__c = 'CSC',
                                                             Class__c = '103',  												// J Caughie 2014.08.14
                                                             Department__c = 'NA',									// J Caughie 2014.08.14
                                                             Memo__c = '',														// J Caughie 2014.08.14
                                                             Name__c = Red.School__r.NetSuite_ID_CSC__c,						// J Caughie 2014.08.14
                                                             Location__c = Red.School__r.Operating_State__r.State_Name__c,		// J Caughie 2014.08.14
                                                             Transaction_Date__c = Red.Date_Cleared__c));
                lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '12000 Purchased Receivables',
                                                             Internal_ID__c = '122',
                                                             Debit__c = null,
                                                             Credit__c = RedToCSCSumMap.get(Red.Id),
                                                             Redemption__c = Red.id,
                                                             Source_Table__c = 'Redemption',
                                                             Subsidiary__c = 'CSC',
                                                             Class__c = '103',													// J Caughie 2014.08.14
                                                             Department__c = 'NA',									// J Caughie 2014.08.14
                                                             Memo__c = '',														// J Caughie 2014.08.14
                                                             Name__c = Red.School__r.NetSuite_ID_CSC__c,						// J Caughie 2014.08.14
                                                             Location__c = Red.School__r.Operating_State__r.State_Name__c,		// J Caughie 2014.08.14
                                                             Transaction_Date__c = Red.Date_Cleared__c));
                
            }

            //
                // if redemption in set for each investor create journals
                //if(RedToPCSRCSumMap.get(Red.Id) > 0.00){
                //    lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '11997 Cash : Deposit in Transit - PCSRC',
                //                                                 Debit__c = RedToPCSRCSumMap.get(Red.Id),
                //                                                 Credit__c = null,
                //                                                 Redemption__c = Red.id,
                //                                                 Source_Table__c = 'Redemption',
                //                                                 Subsidiary__c = 'CSC : PCSRC',
                //                                                 Class__c = '',														// J Caughie 2014.08.14
                //                                                 Department__c = 'NA',									// J Caughie 2014.08.14
                //                                                 Memo__c = '',														// J Caughie 2014.08.14
                //                                                 Name__c = Red.School__r.NetSuite_ID_PCSRC__c,						// J Caughie 2014.08.14
                //                                                 Location__c = Red.School__r.Operating_State__r.State_Name__c,		// J Caughie 2014.08.14
                //                                                 Transaction_Date__c = Red.Date_Paid__c));
                //    lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '12000 Purchased Receivables',
                //                                                 Debit__c = null,
                //                                                 Credit__c = RedToPCSRCSumMap.get(Red.Id),
                //                                                 Redemption__c = Red.id,
                //                                                 Source_Table__c = 'Redemption',
                //                                                 Subsidiary__c = 'CSC : PCSRC',
                //                                                 Class__c = '',														// J Caughie 2014.08.14
                //                                                 Department__c = 'NA',									// J Caughie 2014.08.14
                //                                                 Memo__c = '',														// J Caughie 2014.08.14
                //                                                 Name__c = Red.School__r.NetSuite_ID_PCSRC__c,						// J Caughie 2014.08.14
                //                                                 Location__c = Red.School__r.Operating_State__r.State_Name__c,		// J Caughie 2014.08.14
                //                                                 Transaction_Date__c = Red.Date_Paid__c));
                    
                //}
            //

            //2019.05.17 J Caughie - loop through investor payments    
            //TODO loop/for each investor payment
            if(RedToInvestorSumMap.keySet().contains(Red.Id)){
                System.debug('investor keyset ' + RedToInvestorSumMap.get(Red.Id).keySet());
                for(String investor : RedToInvestorSumMap.get(Red.Id).keySet()){
                    System.debug('investor ' + investor);
                    String subsidiary = (investor == '' ? 'CSC' : ('CSC : ' + investor));
                    String netsuiteAcc = '';
                    String internalID = '';
                    if(investor == 'CSFC'){
                        netsuiteAcc = '11996 Cash : Deposit in Transit - ' + investor;
                        internalID = '931';
                    } else if(investor == 'PCSRC'){
                        netsuiteAcc = '11997 Cash : Deposit in Transit - ' + investor;
                        internalID = '759';
                    }
                    //String accName = (String)Red.getSObject('School__r').get('NetSuite_ID_' + (investor != '' ? 'CSC' : investor) + '__c');
                    lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = netsuiteAcc,
                                                                 Internal_ID__c = internalID,
                                                                 Debit__c = RedToInvestorSumMap.get(Red.Id).get(investor),
                                                                 Credit__c = null,
                                                                 Redemption__c = Red.id,
                                                                 Source_Table__c = 'Redemption',
                                                                 Subsidiary__c = subsidiary,
                                                                 Class__c = '103',                                               
                                                                 Department__c = 'NA',                           
                                                                 Memo__c = '',                                                
                                                                 Name__c = Red.School__r.NetSuite_ID_CSC__c,                
                                                                 Location__c = Red.School__r.Operating_State__r.State_Name__c,
                                                                 Transaction_Date__c = Red.Date_Paid__c));
                    lstJournalEntries.add(new Journal_Entries__c(NetSuite_Account__c = '12000 Purchased Receivables',
                                                                 Internal_ID__c = '122',
                                                                 Debit__c = null,
                                                                 Credit__c = RedToInvestorSumMap.get(Red.Id).get(investor),
                                                                 Redemption__c = Red.id,
                                                                 Source_Table__c = 'Redemption',
                                                                 Subsidiary__c = subsidiary,
                                                                 Class__c = '103',                                               
                                                                 Department__c = 'NA',                           
                                                                 Memo__c = '',                                                
                                                                 Name__c = Red.School__r.NetSuite_ID_CSC__c,                
                                                                 Location__c = Red.School__r.Operating_State__r.State_Name__c,
                                                                 Transaction_Date__c = Red.Date_Paid__c));
                }
                
            }


            Red.Is_Journaled__c = true;
            if(Red.Date_Cleared__c == null){
                Red.Date_Cleared__c = Date.today();
            }
            lstRedemption.add(Red);
        
        }
        
        insert lstJournalEntries;
        update lstRedemption;
    }
    
    
    //2015.08.13 J Caughie - Methods to create monthly draw interest
    public PageReference CreateMonthlyDrawEntries(){
        if(startDateDrawInt == '' || endDateDrawInt == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled in.');
            ApexPages.addMessage(myMsg);
        }
        else{
            CreateMonthlyDrawInterest();
            system.debug('check123');
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Monthly Draw Interest Journal Entries have been created and saved');
            ApexPages.addMessage(myMsg);
            system.debug('check');  
        }
        return null;
    }
    
    public void CreateMonthlyDrawInterest(){
        
        transient List<Journal_Entries__c> lstJournalEntries = new List<Journal_Entries__c>();
        transient List<Draw_Entry__c> lstDrawEntries = new List<Draw_Entry__c>();
        
        //transient String journalName = '';
        //transient String subsidiaryName = '';
        transient String netsuiteAccountDebit = '';
        
        transient Map<String, Journal_Entries__c> mapJournalEntries = new Map<String, Journal_Entries__c>();
        
        lstDrawEntries = [SELECT Draw_Note__r.Operating_State__r.State_Name__c, Draw_Note__r.Investor__r.Name,
                          Draw_Note__r.Note_Description__c, Activity_Type__c, Activity_Date__c, Interest_Fwd__c, 
                          Interest_Paid__c, Draw_Note__r.Name, Draw_Note__r.Investor__r.NetSuite_ID_CSC__c
                          FROM Draw_Entry__c 
                          WHERE (Draw_Note__r.Investor__r.Name = 'East West Bank' OR Draw_Note__r.Investor__r.Name = 'Two Sigma') AND
                            (
                              ((Activity_Date__c = : Date.parse(startDateDrawInt) OR Activity_Date__c = : Date.parse(endDateDrawInt)) AND Activity_Type__c = 'Monthly Interest' AND Interest_Fwd__c > 0) OR
                              (Activity_Date__c > :Date.parse(startDateDrawInt) AND Activity_Date__c <= :Date.parse(endDateDrawInt) AND Activity_Type__c IN ('Payment', 'Quarterly Interest'))
                            )
                        ];
        
        //Section for calculating Debit journal entries
        for(Draw_Entry__c de : lstDrawEntries){
            if(!mapJournalEntries.containsKey(de.Draw_Note__r.Name)){
                
                if(de.Draw_Note__r.Investor__r.Name == 'Two Sigma'){
                    netsuiteAccountDebit = '51300 Interest Cost : Interest Cost Exception Facility';
                    //subsidiaryName = 'CSC';
                } else if (de.Draw_Note__r.Investor__r.Name == 'East West Bank') {
                    netsuiteAccountDebit = '51400 Interest Cost : Interest Cost East West Bank';
                    //subsidiaryName = 'CSC';
                } /*else if (de.Draw_Note__r.Investor__r.Name == 'PCSRC, LLC'){
                    subsidiaryName = 'CSC : PCSRC';
                    }*/
                
                mapJournalEntries.put(de.Draw_Note__r.Name , 
                                      new Journal_Entries__c(NetSuite_Account__c = netsuiteAccountDebit,
                                                             Debit__c = 0,
                                                             Credit__c = 0,
                                                             Source_Table__c = 'Monthly Draw Interest',
                                                             Draw_Note__c = de.Draw_Note__c,
                                                             Subsidiary__c = 'CSC',
                                                             Class__c = '103',
                                                             Department__c = 'NA',
                                                             Memo__c = de.Draw_Note__r.Note_Description__c,
                                                             Name__c = de.Draw_Note__r.Investor__r.NetSuite_ID_CSC__c,
                                                             Location__c = de.Draw_Note__r.Operating_State__r.State_Name__c,
                                                             Transaction_Date__c = Date.parse(endDateDrawInt)));
            }
            Journal_Entries__c je = mapJournalEntries.get(de.Draw_Note__r.Name);
            
            if(de.Activity_Type__c == 'Monthly Interest'){
                if(de.Activity_Date__c == Date.parse(startDateDrawInt)){
                    je.Debit__c = (je.Debit__c - de.Interest_Fwd__c).setScale(2);
                } else {
                    je.Debit__c = (je.Debit__c + de.Interest_Fwd__c).setScale(2);
                }
            } else {
                je.Debit__c = (je.Debit__c  + de.Interest_Paid__c).setScale(2);
            }
            
        }
        
        lstJournalEntries.addAll(mapJournalEntries.values());
        mapJournalEntries.clear();
        
        //section for calculating Credit Journal entries
        for(Draw_Entry__c de : lstDrawEntries){
            String netsuiteAccountCredit = '';
            if(!mapJournalEntries.containsKey(de.Draw_Note__r.Name)){
                
                if(de.Draw_Note__r.Investor__r.Name == 'Two Sigma'){
                    netsuiteAccountCredit = '24200 Interest Payable : Int Payable Exception Facility';
                    //subsidiaryName = 'CSC';
                } else if (de.Draw_Note__r.Investor__r.Name == 'East West Bank') {
                    netsuiteAccountCredit = '24400 Interest Payable : Int Payable East West Bank';
                    //subsidiaryName = 'CSC';
                } /*else if (de.Draw_Note__r.Investor__r.Name == 'PCSRC, LLC'){
                    journalName = pcsrcCredit;
                    subsidiaryName = 'CSC : PCSRC';
                    }*/
                
                mapJournalEntries.put(de.Draw_Note__r.Name , 
                                      new Journal_Entries__c(NetSuite_Account__c = netsuiteAccountCredit,
                                                             Debit__c = 0,
                                                             Credit__c = 0,
                                                             Source_Table__c = 'Monthly Draw Interest',
                                                             Draw_Note__c = de.Draw_Note__c,
                                                             Subsidiary__c = 'CSC',
                                                             Class__c = '103',
                                                             Department__c = 'NA',
                                                             Memo__c = de.Draw_Note__r.Note_Description__c,
                                                             Name__c = de.Draw_Note__r.Investor__r.NetSuite_ID_CSC__c,
                                                             Location__c = de.Draw_Note__r.Operating_State__r.State_Name__c,
                                                             Transaction_Date__c = Date.parse(endDateDrawInt)));
                
            }
            Journal_Entries__c je = mapJournalEntries.get(de.Draw_Note__r.Name);
            
            if(de.Activity_Type__c == 'Monthly Interest'){
                if(de.Activity_Date__c == Date.parse(startDateDrawInt)){
                    je.Credit__c = (je.Credit__c - de.Interest_Fwd__c).setScale(2);
                } else {
                    je.Credit__c = (je.Credit__c + de.Interest_Fwd__c).setScale(2);
                }
            } else {
                je.Credit__c = (je.Credit__c  + de.Interest_Paid__c).setScale(2);
            }
            
        }
        
        lstJournalEntries.addAll(mapJournalEntries.values());
        insert lstJournalEntries;
        
        
    }
    //2015.08.13 J Caughie - Methods to create monthly draw interest
    
    //2016.10.03 J Caughie - Create Draw Note journals (EWB & Two Sigma)
    public PageReference CreateDrawNoteJournalEntries(){
        if(startDateDrawEntry == '' || endDateDrawEntry == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled in.');
            ApexPages.addMessage(myMsg);
        } else {
            CreateMonthlyDrawNoteJournals();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Draw Note Journal Entries have been created and saved');
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    
    public void CreateMonthlyDrawNoteJournals(){
        
        transient List<Journal_Entries__c > drawJnls = new List<Journal_Entries__c >();
        transient List<Draw_Note__c> monthlyDraws = new List<Draw_Note__c>();
        
        for(Draw_Note__c d : [SELECT Id, Name, Total_Amount_Borrowed_formula__c, Borrow_Date__c, Operating_State__r.State_Name__c,
                              Note_Description__c, Investor__r.Name, Investor__r.NetSuite_ID_CSC__c 
                              FROM Draw_Note__c 
                              WHERE Status__c in ('Active', 'Paid')
                              AND Is_Journaled__c = False
                              AND Borrow_Date__c > : Date.parse(startDateDrawEntry) AND Borrow_Date__c <= : Date.parse(endDateDrawEntry) 
                              AND Investor__r.Name IN ('East West Bank', 'Two Sigma') 
                              ORDER BY Investor__c, Borrow_Date__c]){
                                  Journal_Entries__c debitJnl = new Journal_Entries__c ();
                                  Journal_Entries__c creditJnl = new Journal_Entries__c ();
                                  
                                  debitJnl = createJournalEntry(d.Id, null, null, null, null, d.Total_Amount_Borrowed_formula__c,
                                                                null, d.Borrow_Date__c, '103', 'NA',d.Operating_State__r.State_Name__c,
                                                                d.Note_Description__c, d.Investor__r.NetSuite_ID_CSC__c,
                                                                '10200 Cash : East West Bank Funding #2070', 'Draw', 'CSC', null);
                                  drawJnls.add(debitJnl);
                                  
                                  String investorAcc;
                                  if(d.Investor__r.Name == 'East West Bank'){
                                      investorAcc = '27400 Secured Borrowings : East West Bank Line';
                                  } else {         
                                      investorAcc = '27200 Secured Borrowings : Exception Facility';
                                  }
                                  
                                  creditJnl = createJournalEntry(d.Id, null, null, null, null, null, d.Total_Amount_Borrowed_formula__c,
                                                                 d.Borrow_Date__c, '103', 'NA',d.Operating_State__r.State_Name__c,
                                                                 d.Note_Description__c, d.Investor__r.NetSuite_ID_CSC__c,
                                                                 investorAcc, 'Draw', 'CSC', null);       
                                  drawJnls.add(creditJnl);
                                  Draw_Note__c updatedDraw = new Draw_Note__c();
                                  updatedDraw.id = d.id;
                                  updatedDraw.Is_Journaled__c = true;
                                  monthlyDraws.add(updatedDraw);
                              }
        
        insert drawJnls;
        update monthlyDraws;
        
    }
    //2016.10.03 J Caughie - Create Draw Note journals (EWB & Two Sigma)
    
    
    //2016.10.24 J Caughie - Create Draw Payment Journals
    
    public PageReference CreateMonthlyDrawPayments(){
        if(startDateDrawPayments == '' || endDateDrawPayments == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled in.');
            ApexPages.addMessage(myMsg);
        } else {
            CreateMonthlyDrawPaymentJournals();
            CreateMonthlyDrawRefinanceJournals();
            CreateMonthlyDrawAdHocJournals();
            CreateMonthlyCreditLineDrawdownsJournal();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Draw Note Payment Journal Entries have been created and saved');
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    
    public void CreateMonthlyDrawPaymentJournals(){
        
        transient List<Journal_Entries__c > drawJnls = new List<Journal_Entries__c >();
        //transient List<Draw_Entry__c> monthlyPayments = new List<Draw_Entry__c>();
        
        List<AggregateResult> ars = new List<AggregateResult>();
        ars = [SELECT Draw_Note__c, Draw_Note__r.Investor__r.Name, Draw_Note__r.Investor__r.NetSuite_ID_CSC__c, Draw_Note__r.Operating_State__r.State_Name__c, Activity_Date__c, Draw_Note__r.Note_Description__c, SUM(Payment_Amount__c) paid, SUM(Interest_Paid__c) int, SUM(Principal_Paid__c) prin, SUM(Over_Payment_Amount__c) overp 
               FROM Draw_Entry__c 
               WHERE Activity_Date__c > :Date.parse(startDateDrawPayments) AND Activity_Date__c <= :Date.parse(endDateDrawPayments) 
               AND Source_Payment_Type__c IN ('Allocation', 'Over Payment')
               AND Draw_Note__r.Investor__r.Name IN ('East West Bank', 'Two Sigma') 
               GROUP BY Draw_Note__r.Investor__r.Name, Draw_Note__r.Investor__r.NetSuite_ID_CSC__c, Draw_Note__r.Operating_State__r.State_Name__c, Activity_Date__c, Draw_Note__c, Draw_Note__r.Note_Description__c];
        
        for(AggregateResult a : ars){
            
            Journal_Entries__c cashJnl = new Journal_Entries__c ();
            Journal_Entries__c principalJnl = new Journal_Entries__c ();
            Journal_Entries__c interestJnl = new Journal_Entries__c ();
            Journal_Entries__c overPaymentJnl = new Journal_Entries__c ();
            Decimal overpayment = 0, underpayment = 0;
            String cashAcc, principalAcc, interestAcc, overPaymentAcc;
            
            //create overpayment and underpayment values = sum(over_payment_amount__c)
            //reset to zero if EWB and deduct underpayment from payment amount otherwise else create overpayment jnl 
            if((Decimal) a.get('overp') > 0){
                underpayment = (Decimal) a.get('overp');
                overpayment = underpayment;
            }
            
            if(a.get('Name') == 'East West Bank'){
                cashAcc = '10700 Cash : East West Bank ITF #9100';
                principalAcc = '27400 Secured Borrowings : East West Bank Line';
                interestAcc = '24400 Interest Payable : Int Payable East West Bank';
                overPaymentAcc = '10100 Cash : East West Bank Operating #9134';
                overpayment = 0;
            } else {
                cashAcc = '11999 Cash : Deposit in Transit';
                principalAcc = '27200 Secured Borrowings : Exception Facility';
                interestAcc = '24200 Interest Payable : Int Payable Exception Facility';
                overPaymentAcc = '11450 Cash : US Bank Checking #7688';
                underpayment = 0;
            }
            
            cashJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                         null, ((Decimal) a.get('paid') - underpayment), (Date) a.get('Activity_Date__c'),
                                         '103', 'NA', (String) a.get('State_Name__c'),
                                         (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), cashAcc,
                                         'Draw Entries', 'CSC', null);
            drawJnls.add(cashJnl);
            
            if((Decimal) a.get('prin') > 0){
                principalJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                                  (Decimal) a.get('prin'), null, (Date) a.get('Activity_Date__c'),
                                                  '103', 'NA', (String) a.get('State_Name__c'),
                                                  (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), principalAcc,
                                                  'Draw Entries', 'CSC', null);       
                drawJnls.add(principalJnl);
            }
            
            if((Decimal) a.get('int') > 0){
                interestJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                                 (Decimal) a.get('int'), null, (Date) a.get('Activity_Date__c'),
                                                 '103', 'NA', (String) a.get('State_Name__c'),
                                                 (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), interestAcc,
                                                 'Draw Entries', 'CSC', null);       
                drawJnls.add(interestJnl);
            }
            
            //if((Decimal) a.get('overp') > 0){
            //only create if overpayment amount > 0, ie is not EWB
            if(overpayment > 0){    
                overPaymentJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                                    //(Decimal) a.get('overp'), null, (Date) a.get('Activity_Date__c'),
                                                    overpayment, null, (Date) a.get('Activity_Date__c'),
                                                    '103', 'NA', (String) a.get('State_Name__c'),
                                                    (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), overPaymentAcc,
                                                    'Draw Entries', 'CSC', null);       
                drawJnls.add(overPaymentJnl);
            }                
            
            //Draw_Entry__c updatedDraw = new Draw_Entry__c();
            //updatedDraw.id = d.id;
            //updatedDraw.Is_Journaled__c = true;
            //monthlyDraws.add(updatedDraw);
        }
        System.debug(drawJnls);
        insert drawJnls;
        //update monthlyDraws;
        
    }
    
    public void CreateMonthlyDrawAdHocJournals(){
        
        transient List<Journal_Entries__c > drawJnls = new List<Journal_Entries__c >();
        //transient List<Draw_Entry__c> monthlyPayments = new List<Draw_Entry__c>();
        
        List<AggregateResult> ars = new List<AggregateResult>();
        ars = [SELECT Draw_Note__c, Draw_Note__r.Investor__r.Name, Draw_Note__r.Investor__r.NetSuite_ID_CSC__c, Draw_Note__r.Operating_State__r.State_Name__c, Activity_Date__c, Draw_Note__r.Note_Description__c, SUM(Payment_Amount__c) paid, SUM(Interest_Paid__c) int, SUM(Principal_Paid__c) prin, SUM(Over_Payment_Amount__c) overp 
               FROM Draw_Entry__c 
               WHERE Activity_Date__c > :Date.parse(startDateDrawPayments) AND Activity_Date__c <= :Date.parse(endDateDrawPayments) 
               AND Source_Payment_Type__c = 'Ad Hoc'
               AND Draw_Note__r.Investor__r.Name IN ('East West Bank', 'Two Sigma') 
               GROUP BY Draw_Note__r.Investor__r.Name, Draw_Note__r.Investor__r.NetSuite_ID_CSC__c, Draw_Note__r.Operating_State__r.State_Name__c, Activity_Date__c, Draw_Note__c, Draw_Note__r.Note_Description__c];
        
        for(AggregateResult a : ars){
            
            Journal_Entries__c cashJnl = new Journal_Entries__c ();
            Journal_Entries__c principalJnl = new Journal_Entries__c ();
            Journal_Entries__c interestJnl = new Journal_Entries__c ();
            Journal_Entries__c overPaymentJnl = new Journal_Entries__c ();
            String cashAcc, principalAcc, interestAcc, overPaymentAcc;
            
            if(a.get('Name') == 'East West Bank'){
                cashAcc = '10700 Cash : East West Bank ITF #9100';
                principalAcc = '27400 Secured Borrowings : East West Bank Line';
                interestAcc = '24400 Interest Payable : Int Payable East West Bank';
                overPaymentAcc = '10100 Cash : East West Bank Operating #9134';
            } else {
                cashAcc = '10200 Cash : East West Bank Funding #2070';
                principalAcc = '27200 Secured Borrowings : Exception Facility';
                interestAcc = '24200 Interest Payable : Int Payable Exception Facility';
                overPaymentAcc = '11450 Cash : US Bank Checking #7688';
            }
            
            cashJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                         null, (Decimal) a.get('paid'), (Date) a.get('Activity_Date__c'),
                                         '103', 'NA', (String) a.get('State_Name__c'),
                                         (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), cashAcc,
                                         'Draw Entries', 'CSC', null);
            drawJnls.add(cashJnl);
            
            if((Decimal) a.get('prin') > 0){
                principalJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                                  (Decimal) a.get('prin'), null, (Date) a.get('Activity_Date__c'),
                                                  '103', 'NA', (String) a.get('State_Name__c'),
                                                  (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), principalAcc,
                                                  'Draw Entries', 'CSC', null);       
                drawJnls.add(principalJnl);
            }
            
            if((Decimal) a.get('int') > 0){
                interestJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                                 (Decimal) a.get('int'), null, (Date) a.get('Activity_Date__c'),
                                                 '103', 'NA', (String) a.get('State_Name__c'),
                                                 (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), interestAcc,
                                                 'Draw Entries', 'CSC', null);       
                drawJnls.add(interestJnl);
            }
            
            if((Decimal) a.get('overp') > 0){
                overPaymentJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                                    (Decimal) a.get('overp'), null, (Date) a.get('Activity_Date__c'),
                                                    '103', 'NA', (String) a.get('State_Name__c'),
                                                    (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), overPaymentAcc,
                                                    'Draw Entries', 'CSC', null);       
                drawJnls.add(overPaymentJnl);
            }                
            
            //Draw_Entry__c updatedDraw = new Draw_Entry__c();
            //updatedDraw.id = d.id;
            //updatedDraw.Is_Journaled__c = true;
            //monthlyDraws.add(updatedDraw);
        }
        System.debug(drawJnls);
        insert drawJnls;
        //update monthlyDraws;
        
    }
    
    public void CreateMonthlyDrawRefinanceJournals(){
        
        transient List<Journal_Entries__c > drawJnls = new List<Journal_Entries__c >();
        //transient List<Draw_Entry__c> monthlyPayments = new List<Draw_Entry__c>();
        
        List<AggregateResult> ars = new List<AggregateResult>();
        ars = [SELECT Draw_Note__c, Draw_Note__r.Investor__r.Name, Draw_Note__r.Investor__r.NetSuite_ID_CSC__c, Draw_Note__r.Operating_State__r.State_Name__c, Activity_Date__c, Draw_Note__r.Note_Description__c, SUM(Payment_Amount__c) paid, SUM(Interest_Paid__c) int, SUM(Principal_Paid__c) prin, SUM(Over_Payment_Amount__c) overp 
               FROM Draw_Entry__c 
               WHERE Activity_Date__c > :Date.parse(startDateDrawPayments) AND Activity_Date__c <= :Date.parse(endDateDrawPayments) 
               AND Source_Payment_Type__c = 'Re-Finance'
               AND Draw_Note__r.Investor__r.Name = 'Two Sigma' 
               GROUP BY Draw_Note__r.Investor__r.Name, Draw_Note__r.Investor__r.NetSuite_ID_CSC__c, Draw_Note__r.Operating_State__r.State_Name__c, Activity_Date__c, Draw_Note__c, Draw_Note__r.Note_Description__c];
        
        for(AggregateResult a : ars){
            System.debug('Refis: ' + a);
            Journal_Entries__c cashJnl = new Journal_Entries__c ();
            Journal_Entries__c principalJnl = new Journal_Entries__c ();
            Journal_Entries__c interestJnl = new Journal_Entries__c ();
            Journal_Entries__c overPaymentJnl = new Journal_Entries__c ();
            Decimal overpayment = 0;
            String cashAcc, principalAcc, interestAcc, overPaymentAcc;
            
            cashAcc = '10200 Cash : East West Bank Funding #2070';
            principalAcc = '27200 Secured Borrowings : Exception Facility';
            interestAcc = '24200 Interest Payable : Int Payable Exception Facility';
            overPaymentAcc = '10100 Cash : East West Bank Operating #9134';
            
            if((Decimal) a.get('overp') > 0){
                overpayment = (Decimal) a.get('overp');
            }
            
            cashJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                         null, ((Decimal) a.get('paid') - overpayment), (Date) a.get('Activity_Date__c'),
                                         '103', 'NA', (String) a.get('State_Name__c'),
                                         (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), cashAcc,
                                         'Draw Entries', 'CSC', null);
            drawJnls.add(cashJnl);
            
            if((Decimal) a.get('prin') > 0){
                principalJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                                  (Decimal) a.get('prin'), null, (Date) a.get('Activity_Date__c'),
                                                  '103', 'NA', (String) a.get('State_Name__c'),
                                                  (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), principalAcc,
                                                  'Draw Entries', 'CSC', null);       
                drawJnls.add(principalJnl);
            }
            
            if((Decimal) a.get('int') > 0){
                interestJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
                                                 (Decimal) a.get('int'), null, (Date) a.get('Activity_Date__c'),
                                                 '103', 'NA', (String) a.get('State_Name__c'),
                                                 (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), interestAcc,
                                                 'Draw Entries', 'CSC', null);       
                drawJnls.add(interestJnl);
            }
            
            /*if((Decimal) a.get('overp') > 0){
            overPaymentJnl = createJournalEntry((String) a.get('Draw_Note__c'), null, null, null, null,
            (Decimal) a.get('overp'), null, (Date) a.get('Activity_Date__c'),
            null, 'NA', (String) a.get('State_Name__c'),
            (String) a.get('Note_Description__c'), (String) a.get('NetSuite_ID_CSC__c'), overPaymentAcc,
            'Draw Entries', 'CSC');       
            drawJnls.add(overPaymentJnl);
            }*/
            
            //Draw_Entry__c updatedDraw = new Draw_Entry__c();
            //updatedDraw.id = d.id;
            //updatedDraw.Is_Journaled__c = true;
            //monthlyDraws.add(updatedDraw);
        }
        
        insert drawJnls;
        //update monthlyDraws;
    }
    
    //2016.10.24 J Caughie - Create Draw Payment Journals
    

    //2021.10.21 J Caughie - Draw drawdowns for credit line
    public void CreateMonthlyCreditLineDrawdownsJournal(){
        transient List<Draw_Note__c> draws = new List<Draw_Note__c>();
        transient List<Journal_Entries__c> drawdownJournals = new List<Journal_Entries__c>();
        //filter for TCB as that was the only investor journal data provided
        draws = [SELECT Name, (SELECT Disbursement_Date__c, Amount_Requested__c FROM Drawdowns__r WHERE Disbursement_Date__c > :Date.parse(startDateDrawPayments) AND Disbursement_Date__c <= :Date.parse(endDateDrawPayments) ORDER BY Disbursement_Date__c) FROM Draw_Note__c WHERE RecordType.DeveloperName = 'Credit_Line' AND Status__c = 'Active' AND Investor__r.Name = 'Texas Capital Bank'];
        for(Draw_Note__c dn : draws){
            if(dn.Drawdowns__r.size() > 0){
                for(Drawdown__c ddown : dn.Drawdowns__r){
                    Journal_Entries__c debitJE = new Journal_Entries__c();
                    debitJE = createJournalEntry(dn.Id, null, null, null, null,
                        ddown.Amount_Requested__c, null, ddown.Disbursement_Date__c, 
                        null, 'Finance & Accounting ', null,
                        dn.Name.right(dn.Name.length() - 2), '4415', '10020 Cash : TCB Funding #8888',
                        'Drawdown', 'CSC', '890');
                    drawdownJournals.add(debitJE);
                    Journal_Entries__c creditJE = new Journal_Entries__c();
                    creditJE = createJournalEntry(dn.Id, null, null, null, null,
                        null, ddown.Amount_Requested__c, ddown.Disbursement_Date__c, 
                        null, 'Finance & Accounting ', null,
                        dn.Name.right(dn.Name.length() - 2), '4415', '27500 Secured Borrowings : Texas Capital Bank Facility',
                        'Drawdown', 'CSC', '896');
                    drawdownJournals.add(creditJE);
                }
            }
        }
        if(drawdownJournals.size() > 0){
            insert drawdownJournals;
        }
    }

    
    //2017.03.22 J Caughie - Loan Monthly Interest journals
    public PageReference createMonthlyLoanEntries(){
        if(startLoanCalculationDate == '' || endLoanCalculationDate == ''){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Both Start Date and End Date must be filled in.');
            ApexPages.addMessage(myMsg);
        } else {
            createLoanInterestJournals();
            createMonthlyLoanAllocationJournals();
            createMonthlyLoanPurchaseJournals();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Loan Journal Entries have been created and saved');
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    
    public void createLoanInterestJournals(){
        List<Journal_Entries__c> loanInterestJournals = new List<Journal_Entries__c>();
        
        //get a list of loans open during the date range
        List<Funded_Receivable__c> openLoans = new List<Funded_Receivable__c>();
        openLoans = [SELECT Id, Principal__c, Name, School__r.Operating_State__r.State_Name__c,
                    School__r.NetSuite_ID_CSC__c, Loan_Date__c, Loan_Rate__c 
                    FROM Funded_Receivable__c 
                    WHERE RecordType.DeveloperName = 'Loan' AND 
                    (
                        (Status__c = 'Active' AND Loan_Date__c <= :Date.parse(endLoanCalculationDate)) OR 
                        (Status__c = 'Inactive' AND Final_Payment_Date__c > :Date.parse(endLoanCalculationDate) AND 
                            Loan_Date__c <= : Date.parse(endLoanCalculationDate))
                    )];
        System.debug(openLoans.size());
        
        //get a map of loan to allocations/dates for above loans prior to the end date
        Map<Id, AggregateResult> loanAllocationMap = new Map<id,AggregateResult>([Select Funded_Receivable__r.Id, sum(Face_Amount_Applied__c) total, max(Redemption_Date_Cleared__c) maxDate from Allocation__c where Funded_Receivable__r.Id in : openLoans and Redemption_Date_Cleared__c  <= :Date.parse(endLoanCalculationDate) Group BY Funded_Receivable__r.Id]); 
        System.debug(loanAllocationMap.size());
        
        //calculate outstanding balance on loans and create journal entries
        for(Funded_Receivable__c fr : openLoans){
            Date start;
            Date stop = Date.parse(endLoanCalculationDate);
            Decimal principal, rate, interest;
            
            //default for new loans or those without allocations
            start = fr.Loan_Date__c > Date.parse(startLoanCalculationDate) ? fr.Loan_Date__c : Date.parse(startLoanCalculationDate);
            principal = fr.Principal__c;
            rate = fr.Loan_Rate__c;
            System.debug('Loan: ' + fr);
            
            //if allocations exist update parameters for calculations
            if(loanAllocationMap.get(fr.Id) != null){
                //reset startdate with last payment date before end date
                if((Date)loanAllocationMap.get(fr.Id).get('maxDate') > start){
                    start = (Date)loanAllocationMap.get(fr.Id).get('maxDate');
                }
                principal -= (Decimal)loanAllocationMap.get(fr.Id).get('total');
            }
            System.debug('Allocation: ' + loanAllocationMap.get(fr.Id));
            interest = HelperClass.CalculateInterest(principal, start, stop, rate);
            System.debug('Interest: ' + interest);
            loanInterestJournals.add(createJournalEntry(null, null, fr.Id, null, null,
                                                        interest, null, Date.parse(endLoanCalculationDate), 
                                                        '102', 'NA', fr.School__r.Operating_State__r.State_Name__c,
                                                        null, fr.School__r.NetSuite_ID_CSC__c, '13500 Interest Receivable',
                                                        'Loan Interest', 'CSC', '779'));
            loanInterestJournals.add(createJournalEntry(null, null, fr.Id, null, null,
                                                        null, interest, Date.parse(endLoanCalculationDate), 
                                                        '102', 'NA', fr.School__r.Operating_State__r.State_Name__c,
                                                        null, fr.School__r.NetSuite_ID_CSC__c, '45100 Interest Income NR',
                                                        'Loan Interest', 'CSC', '246'));
        }
        
        System.debug(loanInterestJournals);
        insert loanInterestJournals;
    }
    
    public void createMonthlyLoanAllocationJournals(){
        List<Journal_Entries__c> monthlyLoanAllocationJournals = new List<Journal_Entries__c>();
        Set<Redemption__c> updateRedemptions = new Set<Redemption__c>();
        
        //list of allocations for date range
        List<Allocation__c> loanAllocations = new List<Allocation__c>([SELECT Total_Applied__c , Face_Amount_Applied__c, Interest_Applied__c, Redemption__c, 
                                                                        Redemption_Date_Cleared__c, Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,
                                                                        Funded_Receivable__r.School__r.NetSuite_ID_CSC__c, Previous_Payment_Date__c,
                                                                        Previous_Principal_Due__c, Funded_Receivable__r.Loan_Rate__c 
                                                                        FROM Allocation__c 
                                                                        WHERE Redemption_Date_Cleared__c <= :Date.parse(endLoanCalculationDate) AND
                                                                        Redemption_Date_Cleared__c > :Date.parse(startLoanCalculationDate) AND
                                                                        Funded_Receivable__r.RecordType.Name = 'Loan']);
        //System.debug('Allocations: ' + loanAllocations);
        
        //create list of journal entries
        for(Allocation__c al : loanAllocations){
            System.debug(al);
            updateRedemptions.add(new Redemption__c(id = al.Redemption__c, Is_Journaled__c = True));
            monthlyLoanAllocationJournals.add(ADMINActivityController.createJournalEntry(null, null, null, null, al.Redemption__c,
                                                                                         al.Total_Applied__c, null, al.Redemption_Date_Cleared__c, 
                                                                                         '102', 'NA', al.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,
                                                                                         null, al.Funded_Receivable__r.School__r.NetSuite_ID_CSC__c, '11999 Cash : Deposit in Transit',
                                                                                         'Loan Redemption', 'CSC', '169'));
            monthlyLoanAllocationJournals.add(ADMINActivityController.createJournalEntry(null, null, null, null, al.Redemption__c,
                                                                                         null, al.Face_Amount_Applied__c, al.Redemption_Date_Cleared__c, 
                                                                                         '102', 'NA', al.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,
                                                                                         null, al.Funded_Receivable__r.School__r.NetSuite_ID_CSC__c, '13200 Note Receivables',
                                                                                         'Loan Redemption', 'CSC', '172'));
            monthlyLoanAllocationJournals.add(ADMINActivityController.createJournalEntry(null, null, null, null, al.Redemption__c,
                                                                                         null, al.Interest_Applied__c, al.Redemption_Date_Cleared__c, 
                                                                                         '102', 'NA', al.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,
                                                                                         null, al.Funded_Receivable__r.School__r.NetSuite_ID_CSC__c, '13500 Interest Receivable',
                                                                                         'Loan Redemption', 'CSC', '779'));
            
            //2017.04.18 J Caughie - Updated interest calculation
            Decimal accruedInterest = al.Interest_Applied__c;
            if(al.Previous_Payment_Date__c == null || al.Previous_Payment_Date__c < Date.parse(startLoanCalculationDate)){
                accruedInterest = HelperClass.CalculateInterest(al.Previous_Principal_Due__c, Date.parse(startLoanCalculationDate), al.Redemption_Date_Cleared__c, al.Funded_Receivable__r.Loan_Rate__c);
            } else {
                accruedInterest = HelperClass.CalculateInterest(al.Previous_Principal_Due__c, al.Previous_Payment_Date__c, al.Redemption_Date_Cleared__c, al.Funded_Receivable__r.Loan_Rate__c);
            }
            //2017.04.18 J Caughie - Updated interest calculation
            monthlyLoanAllocationJournals.add(ADMINActivityController.createJournalEntry(null, null, null, null, al.Redemption__c,
                                                                                         accruedInterest, null, al.Redemption_Date_Cleared__c, 
                                                                                         '102', 'NA', al.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,
                                                                                         null, al.Funded_Receivable__r.School__r.NetSuite_ID_CSC__c, '13500 Interest Receivable',
                                                                                         'Loan Redemption', 'CSC', '779'));    
            monthlyLoanAllocationJournals.add(ADMINActivityController.createJournalEntry(null, null, null, null, al.Redemption__c,
                                                                                         null, accruedInterest, al.Redemption_Date_Cleared__c, 
                                                                                         '102', 'NA', al.Funded_Receivable__r.School__r.Operating_State__r.State_Name__c,
                                                                                         null, al.Funded_Receivable__r.School__r.NetSuite_ID_CSC__c, '45100 Interest Income NR',
                                                                                         'Loan Redemption', 'CSC', '246'));    
        }
        
        //insert entries
        System.debug(monthlyLoanAllocationJournals);
        insert monthlyLoanAllocationJournals;
        updateRedemptions(new List<Redemption__c>(updateRedemptions));
        
    }
    
    public void createMonthlyLoanPurchaseJournals(){
        
        List<Journal_Entries__c> monthlyLoanPurchaseJournals = new List<Journal_Entries__c>();
        List<Funded_Receivable__c> updateLoans = new List<Funded_Receivable__c>();
        List<Funded_Receivable__c> fundedLoans = new List<Funded_Receivable__c>();
        
        //Loans added during period
        fundedLoans = [SELECT Id, Principal__c, Commitment_Fee__c, Legal_Fees__c, Unpaid_Balance_Receivables_Collected__c,
                        Net_to_School__c,  Name, School__r.Operating_State__r.State_Name__c, School__r.NetSuite_ID_CSC__c,
                        Loan_Date__c 
                        FROM Funded_Receivable__c
                        WHERE RecordType.Name = 'Loan' AND Purchase_Date__c <= :Date.parse(endLoanCalculationDate) AND
                        Purchase_Date__c > : Date.parse(startLoanCalculationDate)];
        
        for(Funded_Receivable__c fr : fundedLoans){
            System.debug(fr);
            updateLoans.add(new Funded_Receivable__c(id = fr.Id, Is_Journaled__c =true));
            monthlyLoanPurchaseJournals.add(ADMINActivityController.createJournalEntry(null, null, fr.id, null, null,
                                                                                       fr.Principal__c, null, fr.Loan_Date__c, 
                                                                                       '102', 'NA', fr.School__r.Operating_State__r.State_Name__c,
                                                                                       null, fr.School__r.NetSuite_ID_CSC__c, '13200 Note Receivables',
                                                                                       'Loan', 'CSC', '172'));
            
            if(fr.Commitment_Fee__c != null && fr.Commitment_Fee__c > 0){
                monthlyLoanPurchaseJournals.add(ADMINActivityController.createJournalEntry(null, null, fr.id, null, null,
                                                                                           null, fr.Commitment_Fee__c, fr.Loan_Date__c, 
                                                                                           '102', 'NA', fr.School__r.Operating_State__r.State_Name__c,
                                                                                           null, fr.School__r.NetSuite_ID_CSC__c, '45200 Commitment Fee Income',
                                                                                           'Loan', 'CSC', null));
            }
            
            if(fr.Legal_Fees__c != null && fr.Legal_Fees__c > 0){
                monthlyLoanPurchaseJournals.add(ADMINActivityController.createJournalEntry(null, null, fr.id, null, null,
                                                                                           null, fr.Legal_Fees__c, fr.Loan_Date__c, 
                                                                                           '102', 'NA', fr.School__r.Operating_State__r.State_Name__c,
                                                                                           'Legal Fees', fr.School__r.NetSuite_ID_CSC__c, '10200 Cash : East West Bank Funding #2070',
                                                                                           'Loan', 'CSC', null));
            }
            
            if(fr.Unpaid_Balance_Receivables_Collected__c  != null && fr.Unpaid_Balance_Receivables_Collected__c > 0){
                monthlyLoanPurchaseJournals.add(ADMINActivityController.createJournalEntry(null, null, fr.id, null, null,
                                                                                           null, fr.Unpaid_Balance_Receivables_Collected__c , fr.Loan_Date__c, 
                                                                                           '102', 'NA', fr.School__r.Operating_State__r.State_Name__c,
                                                                                           'Other Payments', fr.School__r.NetSuite_ID_CSC__c, '11999 Cash : Deposit in Transit',
                                                                                           'Loan', 'CSC', '169'));
            }
            
            if(fr.Net_to_School__c != null && fr.Net_to_School__c > 0){
                monthlyLoanPurchaseJournals.add(ADMINActivityController.createJournalEntry(null, null, fr.id, null, null,
                                                                                           null, fr.Net_to_School__c , fr.Loan_Date__c, 
                                                                                           '102', 'NA', fr.School__r.Operating_State__r.State_Name__c,
                                                                                           'Net to school', fr.School__r.NetSuite_ID_CSC__c, '10200 Cash : East West Bank Funding #2070',
                                                                                           'Loan', 'CSC', null));
            }
        }
        
        insert monthlyLoanPurchaseJournals;
        updateFundedReceivables(updateLoans);
        
    }
    
    public void updateRedemptions(List<Redemption__c> recs){
        update recs;
    }
    
    public void updateFundedReceivables(List<Funded_Receivable__c> funRecs){
        update funRecs;
    }
    
    //2017.03.22 J Caughie - Loan Monthly Interest journals
    
    //2020.01.30 J Caughie - Class calculation
    private String getClass(String recType){
        switch on recType {
            when 'Funded_Receivable' {
                return '103';
            }
            when 'Loan' {
                return '102';
            }
            when else {
                return 'xxx';
            }
        }
    }

    //2016.10.03 J Caughie - create journal entry 
    private static Journal_Entries__c createJournalEntry(Id drawNote, Id drawNoteTX, Id fundedReceivable, Id opp, Id redemption,
                                                         Decimal debit, Decimal credit, Date transactionDate, 
                                                         String jClass, String department, String location,
                                                         String memo, String name, String nsAccount,
                                                         String source, String subsidiary, String internalId){
                                                             Journal_Entries__c j = new Journal_Entries__c();
                                                             j.Draw_Note__c = drawNote;
                                                             j.Draw_Note_TX__c = drawNoteTX;
                                                             j.Funded_Receivable__c = fundedReceivable;
                                                             j.Opportunity__c = opp;
                                                             j.Redemption__c = redemption;
                                                             j.Debit__c = debit;
                                                             j.Credit__c = credit;
                                                             j.Transaction_Date__c = transactionDate;
                                                             j.Class__c = jClass;
                                                             j.Department__c = department;
                                                             j.Location__c = location;
                                                             j.Memo__c = memo;
                                                             j.Name__c = name;
                                                             j.NetSuite_Account__c = nsAccount;
                                                             j.Source_Table__c = source;
                                                             j.Subsidiary__c = subsidiary;
                                                             j.Internal_ID__c = internalId;
                                                             return j;
                                                         }
    
    
    private static void CalculateInvestorPeriodInterest(MonthEndReportWrapper merWrap, map<Id, Decimal> ReceivableToAllocSumMap, Date Start_Date, Date End_Date){
        //Funded Receivable should include sub queried Draw Note TXs
        // MonthEndReportWrapper merWrap, Date Start_Date, Date End_Date

        //unrounded daily rate for calculations

        // Map<String, Decimal> investorInterest = new Map<String, Decimal>();
        // investorInterest.put('CSC', 0);
        // investorInterest.put('CSFC', 0);
        // investorInterest.put('PCSRC', 0);
        Date calculateInterestFrom; 
        Date calculateInterestTo;
        // Date firstBorrowDate;
        Date priorRefinancingDate;
        Decimal periodInterest;
        Decimal totalInterestThisPeriod;
        Decimal unroundedDailyRate = merWrap.FunRec.Discount_Amount__c / (merWrap.FunRec.Purchase_Date__c.daysBetween(merWrap.FunRec.Maturity_Date__c));
        Date minimumDate = Start_Date < merWrap.FunRec.Purchase_Date__c ? merWrap.FunRec.Purchase_Date__c : Start_Date;
        Date maximumDate = End_Date < merWrap.FunRec.Maturity_Date__c ? End_Date : merWrap.FunRec.Maturity_Date__c;
        if(merWrap.FunRec.Final_Payment_Date__c != null && merWrap.FunRec.Final_Payment_Date__c < maximumDate) {
            maximumDate = merWrap.FunRec.Final_Payment_Date__c; 
        }

        // Date priorMaximumDate = Start_Date < merWrap.FunRec.Maturity_Date__c ? Start_Date : merWrap.FunRec.Maturity_Date__c;
        // if(merWrap.FunRec.Final_Payment_Date__c != null && merWrap.FunRec.Final_Payment_Date__c < priorMaximumDate) {
        //     priorMaximumDate = merWrap.FunRec.Final_Payment_Date__c; 
        // }

        //total interest this period date
        totalInterestThisPeriod = minimumDate.daysBetween(maximumDate) * unroundedDailyRate;
        // System.debug('totalInterestThisPeriod ' + totalInterestThisPeriod);

        //total interest to end of last period
        // totalInterestToStartDate = (priorMaximumDate == fundedReceivable.Maturity_Date__c) ? FundedReceivable.Discount_Amount__c : fundedReceivable.Daily_Rate__c * (fundedReceivable.Purchase_Date__c.daysBetween(priorMaximumDate));
        // System.debug('totalInterestToStartDate ' + totalInterestToStartDate);
        // System.debug('minimumDate ' + minimumDate);
        // System.debug('priorMaximumDate ' + priorMaximumDate);

        if(merWrap.FunRec.Draw_Note_TXs__r.size() > 0){
            for(Draw_Note_TX__c dtx : merWrap.FunRec.Draw_Note_TXs__r){
                // priorRefinancingDate = dtx.Refinanced_Date__c;
                if(priorRefinancingDate != null && minimumDate < priorRefinancingDate){
                    calculateInterestFrom = priorRefinancingDate;
                } else {
                    calculateInterestFrom = minimumDate;
                }
                // calculateInterestFrom = minimumDate > priorRefinancingDate > minimumDate priorRefinancingDate: ;
                // System.debug('1st calculateInterestFrom: ' + calculateInterestFrom);
                // System.debug('1st calculateInterestTo: ' + calculateInterestTo);
                calculateInterestTo = maximumDate;
                periodInterest = 0;
                
                if(dtx.Draw_Note__r.Borrow_Date__c > calculateInterestFrom) calculateInterestFrom = dtx.Draw_Note__r.Borrow_Date__c;
                if(dtx.Refinanced_Date__c != null && dtx.Refinanced_Date__c < calculateInterestTo) calculateInterestTo = dtx.Refinanced_Date__c;
                // System.debug('2nd calculateInterestFrom: ' + calculateInterestFrom);
                // System.debug('2nd calculateInterestTo: ' + calculateInterestTo);
                //calculate owner interest
                if(calculateInterestFrom < calculateInterestTo){
                    periodInterest = calculateInterestFrom.daysBetween(calculateInterestTo) * unroundedDailyRate;
                }
                // System.debug(dtx.Draw_Note__r.Investor__r.Name);
                // System.debug(calculateInterestFrom);
                // System.debug(calculateInterestTo);
                // System.debug(periodInterest);
        
                if(dtx.Draw_Note__r.Investor__r.Name == 'PCSRC, LLC'){
                    // investorInterest.put('PCSRC', investorInterest.get('PCSRC') + periodInterest);
                    merWrap.PeriodInterestPCSRC += periodInterest;
                }
                if(dtx.Draw_Note__r.Investor__r.Name == 'CSFC'){
                    // investorInterest.put('CSFC', investorInterest.get('CSFC') + periodInterest);
                    merWrap.PeriodInterestCSFC += periodInterest;
                }
                if(dtx.Draw_Note__r.Investor__r.Name != 'PCSRC, LLC' && dtx.Draw_Note__r.Investor__r.Name != 'CSFC'){
                    // investorInterest.put('CSC', investorInterest.get('CSC') + periodInterest);
                    merWrap.PeriodInterestCSC += periodInterest;
                }
                priorRefinancingDate = dtx.Refinanced_Date__c;
                // if(firstBorrowDate == null ) firstBorrowDate = calculateInterestFrom;
            }
        } 
        // else {
        //     calculateInterestFrom = minimumDate;
        //     calculateInterestTo = maximumDate;
        //     periodInterest = calculateInterestFrom.daysBetween(calculateInterestTo) * fundedReceivable.Daily_Rate__c;
        //     investorInterest.put('CSC', investorInterest.get('CSC') + periodInterest);
        // }
        
        // Interest between purchase and first Draw if needed
        // System.debug('firstBorrowDate' + firstBorrowDate);
        // System.debug('Start_Date' + Start_Date);
        // System.debug('minimumDate' + minimumDate);
        // System.debug('totalInterestThisPeriod' + totalInterestThisPeriod);
        // System.debug('CSC' + investorInterest.get('CSC').setScale(2));
        // System.debug('CSFC' + investorInterest.get('CSFC').setScale(2));
        // System.debug('PCSRC' + investorInterest.get('PCSRC').setScale(2));
        if(totalInterestThisPeriod > (merWrap.PeriodInterestCSC.setScale(2) + merWrap.PeriodInterestCSFC.setScale(2) + merWrap.PeriodInterestPCSRC.setScale(2))){
            // investorInterest.put('CSC', totalInterestThisPeriod - investorInterest.get('CSFC') - investorInterest.get('PCSRC'));
            merWrap.PeriodInterestCSC = totalInterestThisPeriod - merWrap.PeriodInterestCSFC - merWrap.PeriodInterestPCSRC;
        }

        //zero sum - fix total interest rounding issues
        // investorInterest.put('CSC', totalInterestToDate - totalInterestToStartDate - investorInterest.get('PCSRC') - investorInterest.get('CSFC'));  

        //round to two decimals
        // for(String s : investorInterest.keySet()){
            // System.debug('who: ' + s);
            // System.debug(investorInterest.get(s).setScale(2));
            // investorInterest.put(s, investorInterest.get(s).setScale(2));
        // }

        merWrap.FaceValueDue = (merWrap.FunRec.FV_Amount__c == null ? 0.00 : merWrap.FunRec.FV_Amount__c) - (ReceivableToAllocSumMap.get(merWrap.FunRec.Id) == null ? 0.00 : ReceivableToAllocSumMap.get(merWrap.FunRec.Id));
        ReceivableToAllocSumMap.remove(merWrap.FunRec.Id);

        // merWrap.PeriodInterestCSC = investorInterest.get('CSC').setScale(2);
        // merWrap.PeriodInterestCSFC = investorInterest.get('CSFC').setScale(2);
        // merWrap.PeriodInterestPCSRC = investorInterest.get('PCSRC').setScale(2);
        // merWrap.PeriodInterestTotal = investorInterest.get('CSC').setScale(2) + investorInterest.get('CSFC').setScale(2) + investorInterest.get('PCSRC').setScale(2);
        merWrap.PeriodInterestCSC = merWrap.PeriodInterestCSC.setScale(2);
        merWrap.PeriodInterestCSFC = merWrap.PeriodInterestCSFC.setScale(2);
        merWrap.PeriodInterestPCSRC = merWrap.PeriodInterestPCSRC.setScale(2);
        merWrap.PeriodInterestTotal = merWrap.PeriodInterestCSC + merWrap.PeriodInterestCSFC + merWrap.PeriodInterestPCSRC;


        // return investorInterest;
    
    }

    private static void CalculateInvestorTotalInterest(MonthEndReportWrapper merWrap, Date Start_Date, Date End_Date){
        //Funded Receivable should include sub queried Draw Note TXs
      
        // Map<String, Decimal> investorInterest = new Map<String, Decimal>();
        // investorInterest.put('CSC', 0);
        // investorInterest.put('CSFC', 0);
        // investorInterest.put('PCSRC', 0);
        // String currentOwner = 'CSC';
        // Boolean currentOwnerSet = false;
        Date calculateInterestFrom; 
        Date calculateInterestTo;
        // Date firstBorrowDate;
        Date priorRefinancingDate;
        Decimal totalInterest;
        Decimal totalInterestToDate;
        Decimal unamortizedInterest;
        Decimal unroundedDailyRate = merWrap.FunRec.Discount_Amount__c / (merWrap.FunRec.Purchase_Date__c.daysBetween(merWrap.FunRec.Maturity_Date__c));
        Date minimumDate = merWrap.FunRec.Purchase_Date__c;
        Date maximumDate = End_Date < merWrap.FunRec.Maturity_Date__c ? End_Date : merWrap.FunRec.Maturity_Date__c;
        
        if(merWrap.FunRec.Final_Payment_Date__c != null && merWrap.FunRec.Final_Payment_Date__c < maximumDate) maximumDate = merWrap.FunRec.Final_Payment_Date__c;

        totalInterestToDate = (minimumDate.daysBetween(maximumDate) * unroundedDailyRate).setScale(2);
        unamortizedInterest = merWrap.FunRec.Discount_Amount__c - totalInterestToDate;
        System.debug('totalInterestToDate ' + totalInterestToDate);        
        System.debug('unamortizedInterest ' + unamortizedInterest);        

        if(merWrap.FunRec.Draw_Note_TXs__r.size() > 0){
            for(Draw_Note_TX__c dtx : merWrap.FunRec.Draw_Note_TXs__r){
                // if(dtx.Draw_Note__r.Borrow_Date__c > End_Date){
                //     continue;
                // }
                // priorRefinancingDate = dtx.Refinanced_Date__c;
                if(priorRefinancingDate != null && minimumDate < priorRefinancingDate){
                    calculateInterestFrom = priorRefinancingDate;
                } else {
                    calculateInterestFrom = minimumDate;
                }
                System.debug(dtx.Draw_Note__r.Investor__r.Name);
                System.debug(calculateInterestFrom);
                System.debug(calculateInterestTo);
                // calculateInterestFrom = minimumDate;
                calculateInterestTo = maximumDate;
                totalInterest = 0;
                // firstBorrowDate = dtx.Draw_Note__r.Borrow_Date__c;
                if(dtx.Draw_Note__r.Borrow_Date__c > calculateInterestFrom) calculateInterestFrom = dtx.Draw_Note__r.Borrow_Date__c;
                if(dtx.Refinanced_Date__c != null && dtx.Refinanced_Date__c < calculateInterestTo) calculateInterestTo = dtx.Refinanced_Date__c;
                
                //calculate owner interest
                if(calculateInterestFrom < calculateInterestTo){
                    totalInterest = calculateInterestFrom.daysBetween(calculateInterestTo) * unroundedDailyRate;
                }
                
                // System.debug(dtx.Draw_Note__r.Investor__r.Name);
                // System.debug(calculateInterestFrom);
                // System.debug(calculateInterestTo);
                // System.debug('totalinterest ' + totalInterest);
                // System.debug(dtx);
                if(dtx.Draw_Note__r.Investor__r.Name == 'PCSRC, LLC'){
                    // System.debug(investorInterest.get('PCSRC'));
                    merWrap.AccruedInterestPCSRC += totalInterest;
                    merWrap.CurrentOwner = 'PCSRC';
                    // investorInterest.put('PCSRC', investorInterest.get('PCSRC') + totalInterest);
                    // if(currentOwnerSet) currentOwnerSet = 'PCSRC';
                }
                if(dtx.Draw_Note__r.Investor__r.Name == 'CSFC'){
                    // System.debug(investorInterest.get('CSFC'));
                    merWrap.AccruedInterestCSFC += totalInterest;
                    merWrap.CurrentOwner = 'CSFC';
                    // investorInterest.put('CSFC', investorInterest.get('CSFC') + totalInterest);
                    // if(currentOwnerSet) currentOwnerSet = 'PCSRC';
                }
                if(dtx.Draw_Note__r.Investor__r.Name != 'PCSRC, LLC' && dtx.Draw_Note__r.Investor__r.Name != 'CSFC'){
                    // System.debug(investorInterest.get('CSC'));
                    merWrap.AccruedInterestCSC += totalInterest;
                    merWrap.CurrentOwner = 'CSC';
                    // investorInterest.put('CSC', investorInterest.get('CSC') + totalInterest);
                }
                priorRefinancingDate = dtx.Refinanced_Date__c;
                // currentOwnerSet = true;
            }
        }

        //zero sum - fixtotal interest rounding issues
        // investorInterest.put(currentOwner, totalInterestToDate - investorInterest.get('PCSRC') - investorInterest.get('CSFC'));        

        if(totalInterestToDate > (merWrap.AccruedInterestCSC.setScale(2) + merWrap.AccruedInterestCSFC.setScale(2) + merWrap.AccruedInterestPCSRC.setScale(2))){
            merWrap.AccruedInterestCSC = totalInterestToDate - merWrap.AccruedInterestCSFC - merWrap.AccruedInterestPCSRC;
            // investorInterest.put('CSC', totalInterestToDate - investorInterest.get('CSFC') - investorInterest.get('PCSRC'));
        }

        //round to two decimals
        // for(String s : investorInterest.keySet()){
        //     System.debug('who: ' + s);
        //     System.debug(investorInterest.get(s).setScale(2));
        //     // investorInterest.put(s, investorInterest.get(s).setScale(2));
        // }
        // merWrap.AccruedInterestCSC = investorInterest.get('CSC').setScale(2);
        // merWrap.AccruedInterestCSFC = investorInterest.get('CSFC').setScale(2);
        // merWrap.AccruedInterestPCSRC = investorInterest.get('PCSRC').setScale(2);
        // merWrap.AccruedInterestTotal = investorInterest.get('CSC').setScale(2) + investorInterest.get('CSFC').setScale(2) + investorInterest.get('PCSRC').setScale(2);
        merWrap.AccruedInterestCSC = merWrap.AccruedInterestCSC.setScale(2);
        merWrap.AccruedInterestCSFC = merWrap.AccruedInterestCSFC.setScale(2);
        merWrap.AccruedInterestPCSRC = merWrap.AccruedInterestPCSRC.setScale(2);
        merWrap.AccruedInterestTotal = merWrap.AccruedInterestCSC.setScale(2) + merWrap.AccruedInterestCSFC.setScale(2) + merWrap.AccruedInterestPCSRC.setScale(2);
        if(merWrap.FunRec.Final_Payment_Date__c != null && merWrap.FunRec.Final_Payment_Date__c <= End_Date){
            merWrap.UnamortTotal = 0;
            merWrap.GainTotal = unamortizedInterest;
        } else {
            merWrap.UnamortTotal = unamortizedInterest;
            merWrap.GainTotal = 0;
        }
        


        // return investorInterest;
      
    }

    public class MonthEndReportWrapper{
        public Funded_Receivable__c FunRec {get;set;}
        public Draw_Note_TX__c dntx {get;set;}
        public String CurrentOwner {get;set;}
        public Decimal FaceValueDue {get;set;}
        public Decimal AccruedInterestCSC {get;set;}
        public Decimal AccruedInterestCSFC {get;set;}
        public Decimal AccruedInterestPCSRC {get;set;}
        public Decimal AccruedInterestTotal {get;set;}
        public Decimal PeriodInterestCSC {get;set;}
        public Decimal PeriodInterestCSFC {get;set;}
        public Decimal PeriodInterestPCSRC {get;set;}
        public Decimal PeriodInterestTotal {get;set;}
        public Decimal UnamortCSC {get;set;}
        public Decimal UnamortPCSRC {get;set;}
        public Decimal UnamortTotal {get;set;}
        public Decimal GainCSC {get;set;}
        public Decimal GainPCSRC {get;set;}
        public Decimal GainTotal {get;set;}
        public Date StartDate {get;set;}
        public Date EndDate {get;set;}
        public String CSC_Netsuite {get;set;}														// J Caughie 2014.08.15
        public String Location {get;set;}															// J Caughie 2014.08.15
        public String Purchase_ID {get;set;}														// J Caughie 2014.10.07
        public String Financeable {get;set;}														// J Caughie 2014.10.07
        public Decimal CalculatorDiscount {get;set;}												// J Caughie 2014.10.07
        public Decimal UpfrontPP {get;set;}															// J Caughie 2014.10.07
        public String SourceAttRecord {get;set;}                                                    // J Caughie 2015.01.28
        public Date ExpectedPayDate {get;set;}                                                      // J Caughie 2018.08.14
        
        public MonthEndReportWrapper(Funded_Receivable__c FunRec, Draw_Note_TX__c dntx, String CurrentOwner, Decimal FaceValueDue, Decimal AccruedInterestCSC,
                                     Decimal AccruedInterestCSFC, Decimal AccruedInterestPCSRC, Decimal AccruedInterestTotal, Decimal PeriodInterestCSC,
                                     Decimal PeriodInterestCSFC, Decimal PeriodInterestPCSRC, Decimal PeriodInterestTotal, Decimal UnamortCSC,
                                     Decimal UnamortPCSRC, Decimal UnamortTotal, Decimal GainCSC, Decimal GainPCSRC,
                                     Decimal GainTotal, Date StartDate, Date EndDate, String CSC_Netsuite, String Location,
                                     String Purchase_ID, String Financeable, Decimal CalculatorDiscount, Decimal UpfrontPP, String SourceAttRecord, Date ExpectedPayDate){
                                         
                                         this.FunRec = FunRec;
                                         this.dntx=dntx;
                                         this.CurrentOwner=CurrentOwner;
                                         this.FaceValueDue = FaceValueDue;
                                         this.AccruedInterestCSC = AccruedInterestCSC;
                                         this.AccruedInterestCSFC = AccruedInterestCSFC;
                                         this.AccruedInterestPCSRC = AccruedInterestPCSRC;
                                         this.AccruedInterestTotal = AccruedInterestTotal;
                                         this.PeriodInterestCSC = PeriodInterestCSC;
                                         this.PeriodInterestCSFC = PeriodInterestCSFC;
                                         this.PeriodInterestPCSRC = PeriodInterestPCSRC;
                                         this.PeriodInterestTotal = PeriodInterestTotal;
                                         this.UnamortCSC = UnamortCSC;
                                         this.UnamortPCSRC = UnamortPCSRC;
                                         this.UnamortTotal = UnamortTotal;
                                         this.GainCSC = GainCSC;
                                         this.GainPCSRC = GainPCSRC;
                                         this.GainTotal = GainTotal;
                                         this.StartDate = StartDate;
                                         this.EndDate = EndDate;
                                         this.CSC_Netsuite = CSC_Netsuite;
                                         this.Location = Location;
                                         this.Purchase_ID = Purchase_ID;
                                         this.Financeable = Financeable;
                                         this.CalculatorDiscount = CalculatorDiscount;
                                         this.UpfrontPP = UpfrontPP;
                                         this.SourceAttRecord = SourceAttRecord;
                                         this.ExpectedPayDate = ExpectedPayDate;
                                         
                                     }
    }
}