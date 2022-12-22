/**=====================================================================
 * Appirio, Inc
 * Name: ADMINActivityControllerTest Class
 * Description: T-288639 - Test Class for Controller Class for ADMINActivity Page
 * Created Date: [07/03/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 * [07/21/2014]            [Rajeev Arya]              [T-295831 - Journal Entries development]
 * [03/22/2017]            [John Caughie]             [Loan journal test classes]
 =====================================================================*/
@isTest
private class ADMINActivityControllerTest{
	static Draw_Note__c drawNote = new Draw_Note__c();
	static Redemption__c red = new Redemption__c();
	static Account investor = new Account();
	static Account investor1 = new Account();
	static Account CharterHolder = new Account();
	static Account school = new Account();
	static Account cmo = new Account();
	static Account school1 = new Account();
	static Draw_Note__c drawNoteOld = new Draw_Note__c();
	static Draw_Note__c drawNoteOld1 = new Draw_Note__c();
	static State_Province__c testOpState = new State_Province__c();
	static map<String,RecordType> rtMap = new map<String,RecordType>();
	static map<String,RecordType> frMap = new map<String,RecordType>();
	
	private static void createTestData(){
		TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Commission__c, Funded_Receivable__c, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');
		list<Draw_Note_TX__c> drtxlist = new list<Draw_Note_TX__c>();
		list<Funded_Receivable__c> frlistAssigned = new list<Funded_Receivable__c>();
		list<Funded_Receivable__c> frlist = new list<Funded_Receivable__c>();
		list<Allocation__c> allocList = new list <Allocation__c>();
		map<ID,Draw_Note_TX__c> mapFrIdToDRTX = new map<ID,Draw_Note_TX__c>();
				
		/*Operating State Creation*/
		testOpState = TestHelper.createOperatingState();
		insert testOpState;
		
		State_Province__c testOpStateCA = TestHelper.createOperatingState();
		testOpStateCA.name = 'CA';
		insert testOpStateCA;
		/*Operating State Creation*/
		
		rtMap = TestHelper.createRecordTypeMap();
		
		/*Investor Creation*/
		investor = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'Two Sigma');
		investor1 = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'PCSRC Inv2');
		Account PCSRC = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'PCSRC Inv');
		List<Account> invs = new List<Account>();
		investor1.Ownership_Transfer_Borrowing__c = true;
		investor1.Ownership_Accounting_Reference__c = 'PCSRC';
		invs.add(investor1);
		PCSRC.Ownership_Transfer_Borrowing__c = true;
		PCSRC.Ownership_Accounting_Reference__c = 'PCSRC';
		invs.add(PCSRC);
		update invs;
		/*Investor Creation*/

		
		//CMO Creation
		cmo = TestHelper.createAccountForRecordType(rtMap.get('COE_District').Id, 'CMO Arya');
		//CMO Creation
		
		/*Charter Holder Creation*/
		CharterHolder = TestHelper.createAccountForRecordType(rtMap.get('Charter_Holder').Id, 'Arya Charter');
		CharterHolder.CMO__c = cmo.Id;
		CharterHolder.Operating_State__c = testOpStateCA.ID;
		update CharterHolder;
		/*Charter Holder Creation*/
		
		/*school Creation*/
		school = TestHelper.createAccountForRecordType(rtMap.get('School').Id, 'Rajeev School');
		school.Operating_State__c = testOpState.Id;
		school.Charter_Holder__c = CharterHolder.Id;
		school.NetSuite_ID_CSC__c = '00234';
		update school;
		
		school1 = TestHelper.createAccountForRecordType(rtMap.get('School').Id, 'Arya School');
		school1.Operating_State__c = testOpStateCA.Id;
		school1.Charter_Holder__c = CharterHolder.Id;
		school.NetSuite_ID_CSC__c = '10234';
		update school1;
		/*school Creation*/
		
		/*Funded Receivable Opportunity*/
		Opportunity opp = TestHelper.createOpportunity(school, 'RAOpp');
		opp.closedate = Date.today() + 120;
		insert opp;		
		/*Funded Receivable Opportunity*/
		
		/*Draw Note Creation*/
		drawNote = TestHelper.createDrawNote();
		drawNote.investor__c = investor.Id;
		drawNote.Operating_State__c = testOpState.Id;
		drawNote.status__c = 'Active';
		drawNote.Adjusted_Amount_Borrowed__c = 100.00;
		insert drawNote;
		
		drawNoteOld = TestHelper.createDrawNote();
		drawNoteOld.investor__c = PCSRC.Id;
		drawNoteOld.Operating_State__c = testOpState.Id;
		drawNoteOld.status__c = 'Active';
		insert drawNoteOld;
		
		
		draw_note__c draw = [select id, status__c from draw_note__c where id =:drawNote.Id ];
		system.debug(LoggingLevel.ERROR,'status 1 is ' + draw.status__c);
		
		draw_note__c draw12 = [select id, status__c from draw_note__c where id =:drawNoteOld.Id ];
		system.debug(LoggingLevel.ERROR,'status 12 is ' + draw12.status__c);
		
		drawNoteOld1 = TestHelper.createDrawNote();
		drawNoteOld1.investor__c = investor1.Id;
		drawNoteOld1.Operating_State__c = testOpState.Id;
		insert drawNoteOld1;
		/*Draw Note Creation*/
		
		/*PCSRC Investor and Draw Note Creation*/
		/*PCSRC = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'PCSRC Inv');
		
		drawNotePC = TestHelper.createDrawNote();
		drawNotePC.investor__c = PCSRC.Id;
		drawNotePC.Operating_State__c = testOpState.Id;
		insert drawNotePC;*/
		/*PCSRC Investor and Draw Note Creation*/
		
		/*Redemption Creation*/
		red = TestHelper.createRedemption(school.Id);
		red.Date_Cleared__c = Date.today() + 2;
		insert red;
		
		Redemption__c red1 = TestHelper.createRedemption(school.Id);
		red1.Date_Cleared__c = Date.today() + 2;
		insert red1;
		/*Redemption Creation*/		
		
		/*RPA's Account Creation*/	
		Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;
		/*RPA's Account Creation*/	
		
		/*RPA Creation for Receivables*/	
		RPA__c RPA = TestHelper.createRPA(acc.Id);
		//RPA.Program_Fee_Percent__c = 12.5;
		insert RPA;
		/*RPA Creation for Receivables*/				
		
		/*Creation of assigned receivables and related Draw Note TX records*/
		Integer j = 0;
		for(Integer i = 0; i < 10; i++){
			if(j<5){
				Funded_Receivable__c fundedRec = TestHelper.createFundedRec(school.Id, RPA.Id);
				fundedRec.FV_Amount__c = 5000 + i;
				fundedRec.Payments_Applied__c = 100;
				fundedRec.Upfront_Purchase_Price__c = 2000 + i;
				fundedRec.Maturity_Date__c = date.today() + i + 40;
				fundedRec.Program_Fees_Collected__c = 10;
				//fundedRec.Program_Fee_Earned__c = 20;
				fundedRec.Charter_Holder__c = CharterHolder.ID;
				fundedRec.Transaction_Fee_Collected__c = 30;
				fundedRec.Unpaid_Balance_Receivables_Collected__c = 40;
				fundedRec.Bond_or_Other_Payment__c = 50;
				fundedRec.Penalty_Interest__c = 60;
				fundedRec.Refund_Reimbursements__c = 25;
				fundedRec.Application_Fee_Credit__c = 23;
				fundedRec.Blocked_Account_Fee_Collected__c = 12;
				//fundedRec.net_to_school__c = 43;
				fundedRec.Source_Opportunity__c = opp.Id;
				frlistAssigned.add(fundedRec);	
			}
			else{
				Funded_Receivable__c fundedRec = TestHelper.createFundedRec(school1.Id, RPA.Id);
				fundedRec.FV_Amount__c = 6000 + i;
				fundedRec.Payments_Applied__c = 100;
				fundedRec.Upfront_Purchase_Price__c = 2000 + i;
				fundedRec.Maturity_Date__c = date.today() + i + 40;
				fundedRec.Program_Fees_Collected__c = 10;
				//fundedRec.Program_Fee_Earned__c = 20;
				fundedRec.Transaction_Fee_Collected__c = 30;
				fundedRec.Unpaid_Balance_Receivables_Collected__c = 40;
				fundedRec.Bond_or_Other_Payment__c = 50;
				fundedRec.Penalty_Interest__c = 60;
				fundedRec.Refund_Reimbursements__c = 25;
				fundedRec.Application_Fee_Credit__c = 23;
				fundedRec.Blocked_Account_Fee_Collected__c = 12;
				//fundedRec.net_to_school__c = 43;
				fundedRec.Source_Opportunity__c = opp.Id;
				frlistAssigned.add(fundedRec);
			}
			j++;	
		}
		insert frlistAssigned;
		
		Integer i = 0;
		j = 0;
		for(Funded_Receivable__c funRec : frlistAssigned){
			if(j<3){
				Draw_Note_TX__c drtx = TestHelper.createDrawNoteTx(drawNoteOld.Id,funRec.Id,300.00);
				drtx.Status__c = 'Active';
				drtxlist.add(drtx);
			}
			else{
				Draw_Note_TX__c drtx = TestHelper.createDrawNoteTx(drawNoteOld1.Id,funRec.Id,300.00);
				drtx.Status__c = 'Active';
				drtxlist.add(drtx);
			}
			i++;
			j++;			
		}
		insert drtxlist;
				
		for(Draw_Note_TX__c drx : drtxlist){
			mapFrIdToDRTX.put(drx.Funded_Receivable__c,drx);
		}
		
		for(Funded_Receivable__c funRec : frlistAssigned){
			Draw_Note_TX__c drRec = mapFrIdToDRTX.get(funRec.ID);
			//funRec.Draw_Note_TX__c = drRec.Id;
			if(drRec.Draw_Note__c == drawNoteOld.Id){
				funRec.Lien_Holder__c = investor.Id;
				funRec.FV_Amount__c = 10;
				Allocation__c Allocation = TestHelper.createAllocation(funRec.id,red.Id,10);
				Allocation.Previous_Principal_Due__c = 300;																//2017.04.18 J Caughie - Added for new allocation fields
				allocList.add(Allocation);
			}
			else{
				funRec.Lien_Holder__c = investor1.Id;
			}
			/*Creation of allocations to created receivables*/	
			Allocation__c Allocation = TestHelper.createAllocation(funRec.id,red.Id,10);
			Allocation.Previous_Principal_Due__c = 300;																	//2017.04.18 J Caughie - Added for new allocation fields
			allocList.add(Allocation);
		}		
		update frlistAssigned;
		insert allocList;
		/*Creation of assigned receivables and related Draw Note TX records*/
		
		//Creation of extra allocation of the first receivable
		Allocation__c Allocation1 = TestHelper.createAllocation(frlistAssigned[0].id,red.Id,20);
		Allocation1.Previous_Principal_Due__c = 290;
		Allocation1.Previous_Payment_Date__c = red1.Date_Cleared__c;
		insert Allocation1;
		
		
		/*Payment Sub Creation*/
		
		Payment_Sub__c paysub = TestHelper.createPaymentSub(drawNote.id, 120);
		paysub.Redemption__c = red1.id;
		paysub.Paid_to__c = 'CSC';
		insert paysub;
		
		Payment_Sub__c paysub1 = TestHelper.createPaymentSub(drawNoteOld.id, 140);
		paysub1.Redemption__c = red1.id;
		paysub.Paid_to__c = 'CSC';
		insert paysub1;
		/*Payment Sub Creation*/

		Draw_Entry__c deLastMonth = new Draw_Entry__c(Activity_Type__c = 'Monthly Interest', Activity_Date__c = Date.today() - 30, Payment_Amount__c = 0, Interest_Fwd__c = 5.00, Interest_Paid__c = 0, Over_Payment_Amount__c = 0,  Draw_Note__c = drawNote.Id);
		Draw_Entry__c deThisMonth = new Draw_Entry__c(Activity_Type__c = 'Monthly Interest', Activity_Date__c = Date.today(), Payment_Amount__c = 10, Interest_Fwd__c = 10.00, Interest_Paid__c = 0, Over_Payment_Amount__c = 10, Draw_Note__c = drawNote.Id);
		insert deLastMonth;
		insert deThisMonth;

		Draw_Entry__c paymentMonth1 = new Draw_Entry__c(Activity_Type__c = 'Allocation', Activity_Date__c = Date.today() - 15, Payment_Amount__c = 15, Interest_Fwd__c = 5.00, Interest_Paid__c = 0, Principal_Paid__c = 15, Draw_Note__c = drawNote.Id, Source_Payment_Type__c = 'Allocation');
		Draw_Entry__c paymentMonth2 = new Draw_Entry__c(Activity_Type__c = 'Re-Financed', Activity_Date__c = Date.today() - 15, Payment_Amount__c = 25, Interest_Fwd__c = 0.00, Interest_Paid__c = 10, Principal_Paid__c = 15, Draw_Note__c = drawNote.Id, Source_Payment_Type__c = 'Re-Finance');
		insert paymentMonth1;
		insert paymentMonth2;

	}

	private static void createLoanTestData(){
		
		createCustomSettingToByPassTriggersAndRules('Account, RPA__c, Account, Funded_Receivable__c, Redemption__c, Allocation__c');
		Map<String, List<Account>> mapCharterSchools = TestHelperBulk.createCharterSchoolStructure(50, 2);
		Map<String, RPA__c> charterIdToRpaMap = TestHelperBulk.createCharterRPAs(mapCharterSchools.get('Charters'));
		List<Funded_Receivable__c> loans = new List<Funded_Receivable__c>();
		List<Redemption__c> redemptions  = new List<Redemption__c>();
		List<Allocation__c> allocations = new List<Allocation__c>();
		frMap = TestHelper.createReceivableTypeMap();

		//create loans
		Integer legacyId = 0;
		for(Account a : mapCharterSchools.get('Schools')){
			Funded_Receivable__c fr = new Funded_Receivable__c(Name = 'Test ' + a.Name, RecordTypeId = frMap.get('Loan').Id, Principal__c = 100000, School__c = a.Id, Charter_Holder__c = a.Charter_Holder__c, RPA__c = charterIdToRpaMap.get(a.Charter_Holder__c).Id, Loan_Date__c = Date.newInstance(2017, 01, 15), Loan_Rate__c = 10, Commitment_Fee__c = 6000, Legal_Fees__c = 3500, Unpaid_Balance_Receivables_Collected__c = 5000, purchaseUID__c = 'fr' + legacyId);
			loans.add(fr);
			Redemption__c rd = new Redemption__c(School__c = a.Id, Amount_Received__c = 50000, LegacyID__c = 'rd' + legacyId, Date_Cleared__c = Date.newInstance(2017, 1, 17));
			redemptions.add(rd);
			Allocation__c al = new Allocation__c(Funded_Receivable__r = new Funded_Receivable__c(purchaseUID__c = 'fr' + legacyId), Face_Amount_Applied__c = 49722.22, Interest_Applied__c = 277.78, Redemption__r = new Redemption__c(LegacyID__c = 'rd' + legacyId), Previous_Principal_Due__c = 100000);
			allocations.add(al);
			//include loans purchased after the end date
			fr = new Funded_Receivable__c(Name = 'Test ' + a.Name, RecordTypeId = frMap.get('Loan').Id, Principal__c = 100000, School__c = a.Id, Charter_Holder__c = a.Charter_Holder__c, RPA__c = charterIdToRpaMap.get(a.Charter_Holder__c).Id, Loan_Date__c = Date.newInstance(2017, 02, 15), Loan_Rate__c = 10);
			loans.add(fr);
			legacyId++;
		}
		insert loans;
		insert redemptions;
		insert allocations;
	
	}
	
	static testMethod void ADMINControllerTest(){
		PageReference pageRef = Page.ADMINActivity; //replace with your VF page name
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		/*controller.dateSelected = Date.today().format();
		controller.CalculateInterest();
		controller.dateSelected = (Date.today() + 1).format();
		controller.CalculateInterest();*/
		
		createTestData();
		//controller.startDate = Date.today().format();
		//controller.endDate = (Date.today() + 30).format();
		//controller.GenerateExcelReport();
		//controller.CreateJournalEntries();
		//controller.startDate = (Date.today() - 30).format();
		//controller.endDate = '';
		//controller.GenerateExcelReport();
		//controller.CreateJournalEntries();
		
		//controller.startDateOther = (Date.today() - 100).format();
		//controller.endDateOther = (Date.today() + 30).format();
		//controller.CreatePurchaseJournalEntries();
		//list<journal_entries__c> journlistrec = [select id from journal_entries__c where Funded_Receivable__c != null];
		//system.assertEquals(journlistrec.IsEmpty(), false);
		/*for(Funded_Receivable__c fr : [select id, is_journaled__c from Funded_Receivable__c]){
			system.assertEquals(fr.is_journaled__c, true );
		}*/
		//controller.startDateOther = (Date.today() - 30).format();
		//controller.endDateOther = '';
		//controller.CreatePurchaseJournalEntries();
		
		
		controller.startDateDraw = (Date.today() - 100).format();
		controller.endDateDraw = (Date.today() + 30).format();
		Test.StartTest();
		controller.CreatePCSRCJournalEntries();											//2016.10.03 J Caughie - Updated from CreateDrawJournalEntries
		Test.stopTest();
		boolean check = false;
		for(Draw_Note__c dr : [select id, is_journaled__c from Draw_Note__c]){
			if (dr.is_journaled__c == true){
				check = true;
			}
		}
		system.assertEquals(true, check); 
		//controller.startDateDraw = (Date.today() - 30).format();
		//controller.endDateDraw = '';
		//controller.CreatePCSRCJournalEntries();
		
		/*controller.startDateRed = (Date.today() - 100).format();
		controller.endDateRed = (Date.today() + 30).format();
		controller.CreateRedemptionJournalEntries();									//2016.10.03 J Caughie - Updated from CreateDrawJournalEntries
		boolean checkred = false;
		for(Redemption__c r : [select id, is_journaled__c from Redemption__c]){
			if (r.is_journaled__c == true){
				checkred = true;
			}
		}*/
		//system.assertEquals(checkred, true); 
		//controller.startDateRed = (Date.today() - 30).format();
		//controller.endDateRed = '';
		//controller.CreateRedemptionJournalEntries();

	}

	static testMethod void DrawInterestFailTest(){ 		//2015.08.13 J Caughie Test Classes for new journal 
		
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();

		controller.startDateDrawInt = (Date.today() - 30).format();
		controller.endDateDrawInt = '';
		
		test.StartTest();
		controller.CreateMonthlyDrawEntries();
		test.StopTest();

		List<Journal_Entries__c> jeList = new List<Journal_Entries__c>([SELECT ID, Debit__c, Credit__c FROM Journal_Entries__c WHERE Source_Table__c = 'Monthly Draw Interest']);
		System.assertEquals(jeList.size(), 0, 'Nothing generated as no end date entered');	

	}

	static testMethod void DrawInterestTest(){ 		//2015.08.13 J Caughie Test Classes for new journal 
		
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();

		controller.startDateDrawInt = (Date.today() - 30).format();
		controller.endDateDrawInt = Date.today().format();

		test.StartTest();
		controller.CreateMonthlyDrawEntries();
		test.StopTest();
		
		List<Journal_Entries__c> jeList = new List<Journal_Entries__c>([SELECT ID, Debit__c, Credit__c FROM Journal_Entries__c WHERE Source_Table__c = 'Monthly Draw Interest']);
		System.debug(jeList);
		System.assertEquals(jeList.size(), 2, 'A debit and a credit generated');
		System.assertEquals((jeList[0].Debit__c + jeList[0].Credit__c + jeList[1].Debit__c + jeList[1].Credit__c), 10, 'Total Drs + Crs');

	}

	static testMethod void TestDrawNoteJournal(){		//2016.10.03 J Caughie - Test Draw Note

		PageReference pageRef = Page.ADMINActivity;
		Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();

		controller.startDateDrawEntry = (Date.today() - 90).format();
		controller.endDateDrawEntry = (Date.today() - 60).format();

		test.StartTest();
		controller.CreateDrawNoteJournalEntries();
		test.StopTest();

		List<Journal_Entries__c> jeList = new List<Journal_Entries__c>([SELECT ID, Debit__c, Credit__c FROM Journal_Entries__c WHERE Source_Table__c = 'Draw']);
		System.debug(jeList);
		System.assertEquals(jeList.size(), 2, 'A debit and a credit generated');
		Decimal je1Debit = jeList[0].Debit__c == null ? 0 : jeList[0].Debit__c;
		Decimal je1Credit = jeList[0].Credit__c == null ? 0 : jeList[0].Credit__c;
		Decimal je2Debit = jeList[1].Debit__c == null ? 0 : jeList[1].Debit__c;
		Decimal je2Credit = jeList[1].Credit__c == null ? 0 : jeList[1].Credit__c;
		System.assertEquals((je1Debit + je1Credit + je2Debit + je2Credit), 200, 'Total Drs + Crs');

	}

	static testMethod void TestDrawNotePaymentJournal(){		//2016.10.25 J Caughie - Test Draw Payments

		PageReference pageRef = Page.ADMINActivity;
		Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();

		controller.startDateDrawPayments = (Date.today() - 30).format();
		controller.endDateDrawPayments = (Date.today() - 0).format();

		test.StartTest();
		controller.CreateMonthlyDrawPayments();
		test.StopTest();

		List<Journal_Entries__c> jeList = new List<Journal_Entries__c>([SELECT ID, Debit__c, Credit__c FROM Journal_Entries__c WHERE Source_Table__c = 'Draw Entries']);
		System.debug('Payment Jnls' + jeList);
		System.assertEquals(jeList.size(), 5, 'Should generate 2 jnls for one entry and 3 for the other');
		Decimal je1Debit = jeList[0].Debit__c == null ? 0 : jeList[0].Debit__c;
		Decimal je1Credit = jeList[0].Credit__c == null ? 0 : jeList[0].Credit__c;
		Decimal je2Debit = jeList[1].Debit__c == null ? 0 : jeList[1].Debit__c;
		Decimal je2Credit = jeList[1].Credit__c == null ? 0 : jeList[1].Credit__c;
		Decimal je3Debit = jeList[2].Debit__c == null ? 0 : jeList[2].Debit__c;
		Decimal je3Credit = jeList[2].Credit__c == null ? 0 : jeList[2].Credit__c;
		Decimal je4Debit = jeList[3].Debit__c == null ? 0 : jeList[3].Debit__c;
		Decimal je4Credit = jeList[3].Credit__c == null ? 0 : jeList[3].Credit__c;
		Decimal je5Debit = jeList[4].Debit__c == null ? 0 : jeList[4].Debit__c;
		Decimal je5Credit = jeList[4].Credit__c == null ? 0 : jeList[4].Credit__c;
		System.assertEquals((je1Debit + je2Debit + je3Debit + je4Debit + je5Debit), 40, 'Total Crs');
		System.assertEquals((je1Credit + je2Credit + je3Credit + je4Credit + je5Credit), 40, 'Total Drs');
	}

	static testMethod void DrawPaymentFailTest(){ 		//2017.01.03 J Caughie Test Negative Classes for draw payment 
		
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();

		controller.datePayments = '';
		
		test.StartTest();
		controller.CalculatePayments();
		test.StopTest();

        List<Draw_Entry__c> de = [SELECT Id, Source_Payment_Type__c, Interest_Paid__c FROM Draw_Entry__c WHERE Activity_Type__c = 'Quarterly Interest'];
		System.assertEquals(de.size(), 0, 'Nothing generated as no date entered');	

	}

	static testMethod void DrawPaymentTest(){ 			//2017.01.03 J Caughie Test Classes for draw payment 
		
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		
		//Create Operating State
		State_Province__c stateProvince = TestHelper.createStateProvince('Test State', true);
		System.debug(TestHelper.createRecordTypeMap().get('Investor'));

		//Create Investor account of type Investor for above operating state
		Account ewb = new Account(Name = 'East West Bank', Operating_State__c = stateProvince.Id, RecordTypeId = TestHelper.createRecordTypeMap().get('Investor').Id);
		insert ewb;
		System.debug('inv: ' + ewb);

		//Create draws for above investor
		List<Draw_Note__c> draws = new List<Draw_Note__c>();
		for (Integer i = 0; i < 100; i++){
			Draw_Note__c d = TestHelper.createDrawNoteDetailed(100000, ewb, stateProvince);
			draws.add(d);
		}
		System.debug('no: ' + draws.size());
		//Draw_Note__c drawNote = TestHelper.createDrawNoteDetailed(100000, ewb, stateProvince);
        insert draws;
        draws = [SELECT Id, Interest_Due__c, Borrow_Date__c, Last_Activity_Date__c, Note_Rate__c, Principal_Due__c
						FROM Draw_Note__c WHERE Status__c = 'Active' AND Investor__R.Name = 'East West Bank'];
		System.debug('note: ' + draws[0]);
		
		controller.datePayments = Date.today().format();
		controller.investor = 'East West Bank';
		
		test.StartTest();
		controller.CalculatePayments();
		test.StopTest();

        List<Draw_Entry__c> de = [SELECT Id, Source_Payment_Type__c, Interest_Paid__c FROM Draw_Entry__c WHERE Activity_Type__c = 'Quarterly Interest'];
		System.assertEquals(de.size(), 100, 'One entry for all draws');	

	}

	static testMethod void TestInvestorGetter(){		//2017.01.03 J Caughie Test Classes for draw payment
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();

		test.StartTest();
		List<SelectOption> se = controller.getInvestors();
		test.StopTest();

		System.assertEquals(se.size(), 3, 'Three investors created in createTestData method');
	}

	static testMethod void LoanJournalFailTest(){ 		//2017.03.22 J Caughie Test Negative Classes for loan journals 
		
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();

		controller.startLoanCalculationDate = '';
		
		test.StartTest();
		controller.createMonthlyLoanEntries();
		test.StopTest();

        List<Journal_Entries__c> je = [SELECT Id FROM Journal_Entries__c];
		System.assertEquals(je.size(), 0, 'Nothing generated as no date entered');	

	}	

	static testMethod void LoanJournalTest(){ 		//2017.03.22 J Caughie Test Classes for loan journals 
		
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createLoanTestData();

		controller.startLoanCalculationDate = '12/31/2016';
		controller.endLoanCalculationDate = '01/31/2017';
		
		test.StartTest();
		controller.createMonthlyLoanEntries();
		test.StopTest();

        List<Journal_Entries__c> entries = [SELECT Debit__c, Credit__c FROM Journal_Entries__c WHERE Source_Table__c = 'Loan Interest'];
        System.debug(entries);
        System.assertEquals(200, entries.size(), 'Should be 2 journals x 100 loans');
        System.assertEquals(195.52, (entries[0].Debit__c != null ? entries[0].Debit__c : 0 + entries[0].Credit__c != null ? entries[0].Credit__c : 0), 'Should be 14 days interest on 50,277.78 @ 10%');
        List<Journal_Entries__c> redemptionEntries = [SELECT Debit__c, Credit__c FROM Journal_Entries__c WHERE Source_Table__c = 'Loan Redemption'];
        System.debug(redemptionEntries);
		System.assertEquals(500, redemptionEntries.size(), 'Should be 5 journals x 100 redemptions');
		AggregateResult jnlTotals = [Select sum(Debit__c) debits, sum(Credit__c) credits FROM Journal_Entries__c];
		System.assertEquals(jnlTotals.get('debits'), jnlTotals.get('credits'), 'Total debits should equal credits');
		AggregateResult purchJnlTotals = [Select sum(Debit__c) debits, sum(Credit__c) credits FROM Journal_Entries__c WHERE Source_Table__c = 'Loan'];
		System.assertEquals(purchJnlTotals.get('debits'), 100 * 100000, '100 Loans at 100,000');
	}

	static testMethod void testCalculateInterestGoodDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.dateSelected = Date.today().format();
		test.StartTest();
		controller.CalculateInterest();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			if (m.getDetail() == 'The Batch process is completed for Draw Interest Calculation') {
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
		AggregateResult jnlTotals = [Select sum(Debit__c) debits, sum(Credit__c) credits FROM Journal_Entries__c];
		System.assertEquals(jnlTotals.get('debits'), jnlTotals.get('credits'), 'Total debits should equal credits');
	}

	static testMethod void testCalculateInterestBadDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.dateSelected = (Date.today() + 2).format();
		test.StartTest();
		pageRef = controller.CalculateInterest();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			System.debug('Message: ' + m);
			if (m.getSummary() == 'The Selected Date cannot be a future date. Please select another'){
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
	}

	static testMethod void testGenerateExcelGoodDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDate = Date.today().format();
		controller.endDate = (Date.today() + 30).format();
		test.StartTest();
		controller.GenerateExcelReport();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			if (m.getDetail() == 'The required Month End report has been downloaded to your system') {
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
		AggregateResult jnlTotals = [Select sum(Debit__c) debits, sum(Credit__c) credits FROM Journal_Entries__c];
		System.assertEquals(jnlTotals.get('debits'), jnlTotals.get('credits'), 'Total debits should equal credits');
	}

	static testMethod void testGenerateExcelBadDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDate = (Date.today() - 30).format();
		controller.endDate = '';
		test.StartTest();
		pageRef = controller.GenerateExcelReport();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			System.debug('Message: ' + m);
			if (m.getSummary() == 'Both Start Date and End Date must be filled'){
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
	}

	static testMethod void testCreateJournalsGoodDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDate = Date.today().format();
		controller.endDate = (Date.today() + 30).format();
		test.StartTest();
		controller.CreateJournalEntries();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			if (m.getDetail() == 'The Month End Interest Journal Entries have been created and saved') {
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
		AggregateResult jnlTotals = [Select sum(Debit__c) debits, sum(Credit__c) credits FROM Journal_Entries__c];
		System.assertEquals(jnlTotals.get('debits'), jnlTotals.get('credits'), 'Total debits should equal credits');
	}

	static testMethod void testCreateJournalsBadDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDate = (Date.today() - 30).format();
		controller.endDate = '';
		test.StartTest();
		pageRef = controller.CreateJournalEntries();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			System.debug('Message: ' + m);
			if (m.getSummary() == 'Both Start Date and End Date must be filled'){
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
	}

	static testMethod void testCreatePurchaseJournalEntriesGoodDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDateOther = (Date.today() - 100).format();
		controller.endDateOther = (Date.today() + 30).format();
		test.StartTest();
		controller.CreatePurchaseJournalEntries();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			if (m.getDetail() == 'The Purchase Journal Entries have been created and saved') {
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
		//AggregateResult jnlTotals = [Select sum(Debit__c) debits, sum(Credit__c) credits FROM Journal_Entries__c];
		//System.assertEquals(jnlTotals.get('debits'), jnlTotals.get('credits'), 'Total debits should equal credits');
	}

	static testMethod void testCreatePurchaseJournalEntriesBadDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDateOther = (Date.today() - 30).format();
		controller.endDateOther = '';
		test.StartTest();
		pageRef = controller.CreatePurchaseJournalEntries();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			System.debug('Message: ' + m);
			if (m.getSummary() == 'Both Start Date and End Date must be filled'){
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
	}

	static testMethod void testCreateRedemptionJournalEntriesGoodDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDateRed = (Date.today() - 100).format();
		controller.endDateRed = (Date.today() + 30).format();
		test.StartTest();
		controller.CreateRedemptionJournalEntries();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			if (m.getDetail() == 'The Redemption Journal Entries have been created and saved') {
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
		AggregateResult jnlTotals = [Select sum(Debit__c) debits, sum(Credit__c) credits FROM Journal_Entries__c];
		System.assertEquals(jnlTotals.get('debits'), jnlTotals.get('credits'), 'Total debits should equal credits');
	}

	static testMethod void testCreateRedemptionJournalEntriesBadDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDateRed = (Date.today() - 30).format();
		controller.endDateRed = '';
		test.StartTest();
		pageRef = controller.CreateRedemptionJournalEntries();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			System.debug('Message: ' + m);
			if (m.getSummary() == 'Both Start Date and End Date must be filled'){
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
	}

	static testMethod void testCreatePCSRCJournalEntriesBadDate(){
		PageReference pageRef = Page.ADMINActivity;
        Test.setCurrentPage(pageRef);
		ADMINActivityController controller =  new ADMINActivityController();
		createTestData();
		controller.startDateDraw = (Date.today() - 30).format();
		controller.endDateDraw = '';
		test.StartTest();
		pageRef = controller.CreatePCSRCJournalEntries();
		test.StopTest();
		List<Apexpages.Message> messages = ApexPages.getMessages();
		Boolean messageIncluded = false;
		for(Apexpages.Message m : messages){
			System.debug('Message: ' + m);
			if (m.getSummary() == 'Both Start Date and End Date must be filled'){
				messageIncluded = true;
			}
		}
		System.assertEquals(true, messageIncluded, 'Message not returned');
	}


    private static void createCustomSettingToByPassTriggersAndRules(String objectsToBypass){
        BypassRulesandTriggers__c customSetting = new BypassRulesandTriggers__c();
        customSetting.Name = 'test Custom Setting';
        customSetting.SetupOwnerId = userInfo.getUserId();
        customSetting.Trigger_Objects__c = objectsToBypass;
        customSetting.Triggers_Disabled__c = true;
        customSetting.Validation_Rules_Disabled__c = true;
        insert customSetting;
    }



}