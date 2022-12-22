/**=====================================================================
 * Appirio, Inc
 * Name: RedemptionDetailsControllerTest
 * Description: T-287375 : Test Class for custom controller RedemptionDetailsController
 * Created Date: [06/19/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [06/24/2014]                 [Rajeev Arya]               [I-118064 - Replace the DrawNote LKP field on Funded Receivable]
 * [06/25/2014]                 [Rajeev Arya]               [I-117958 - Allow Redemption of Unassigned Receivables]
 * [06/27/2014]                 [Rajeev Arya]               [I-118987 - Adding, changes and removing fields on Redemption UI]
 * [08/29/2016]                 [John Caughie]              [Amended tests to incorporate 'proper' structure, ie RPA off a Charter not School] 
 =====================================================================*/
@isTest
private class RedemptionDetailsControllerTest {
	static Draw_Note__c drawNote = new Draw_Note__c();
	static Redemption__c red = new Redemption__c();
	static Account investor = new Account();
	static Account investor1 = new Account();
	static Account CharterHolder = new Account();
	static Account school = new Account();
	static Account school1 = new Account();
	static Draw_Note__c drawNoteOld = new Draw_Note__c();
	static Draw_Note__c drawNoteOld1 = new Draw_Note__c();
	static State_Province__c testOpState = new State_Province__c();
	static map<String,RecordType> rtMap = new map<String,RecordType>();
	private static void createTestData(){
		list<Draw_Note_TX__c> drtxlist = new list<Draw_Note_TX__c>();
		list<Funded_Receivable__c> frlistAssigned = new list<Funded_Receivable__c>();
		list<Funded_Receivable__c> frlist = new list<Funded_Receivable__c>();
		list<RPA__c> RPAList = new list<RPA__c>();
		list<Terms_Letter__c> TermsLetterList = new list<Terms_Letter__c>();
		list<Program_Fee__c> ProgFeeList = new list<Program_Fee__c>();
		map<ID,Draw_Note_TX__c> mapFrIdToDRTX = new map<ID,Draw_Note_TX__c>();



        //Deactivate triggers on other objects that are not necessary for this test.	2015.06.17 J Caughie
        BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'RPA__c; Program_Fee__c; Terms_Letter__c',
                                            Triggers_Disabled__c = true,
                                            Validation_Rules_Disabled__c = true,
                                            Workflow_Rules_Disabled__c = true);

		
		//TestHelper.createCustomSettingToSetPageSize('DrawNoteReceivable');
		
		/*Operating State Creation*/
		testOpState = TestHelper.createOperatingState();
		insert testOpState;
		/*Operating State Creation*/
		
		rtMap = TestHelper.createRecordTypeMap();
		
		/*Investor Creation*/
		investor = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'Rajeev Investor');
		investor1 = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'Arya Investors');
		/*Investor Creation*/
		
		/*Charter Holder Creation*/
		CharterHolder = TestHelper.createAccountForRecordType(rtMap.get('Charter_Holder').Id, 'Arya Charter');
		/*Charter Holder Creation*/
		
		/*school Creation*/
		school = TestHelper.createAccountForRecordType(rtMap.get('School').Id, 'Rajeev School');
		school.Operating_State__c = testOpState.Id;
		school.Charter_Holder__c = CharterHolder.Id;
		update school;
		
		school1 = TestHelper.createAccountForRecordType(rtMap.get('School').Id, 'Arya School');
		school1.Operating_State__c = testOpState.Id;
		school1.Charter_Holder__c = CharterHolder.Id;
		update school1;
		/*school Creation*/
				
		/*Draw Note Creation*/
		drawNote = TestHelper.createDrawNote();
		drawNote.investor__c = investor.Id;
		drawNote.Operating_State__c = testOpState.Id;
		insert drawNote;
		
		drawNoteOld = TestHelper.createDrawNote();
		drawNoteOld.investor__c = investor.Id;
		drawNoteOld.Operating_State__c = testOpState.Id;
		insert drawNoteOld;
		
		drawNoteOld1 = TestHelper.createDrawNote();
		drawNoteOld1.investor__c = investor1.Id;
		drawNoteOld1.Operating_State__c = testOpState.Id;
		insert drawNoteOld1;
		/*Draw Note Creation*/
		
		/*Payment sub Creation*/
		Payment_Sub__c paySub = TestHelper.createPaymentSub(drawNote.Id,500);
		insert paySub;
		/*Payment sub Creation*/
		
		/*Redemption Creation*/
		red = TestHelper.createRedemption(school.Id);
		red.Payment_Sub__c = paySub.Id;
		insert red;
		/*Redemption Creation*/		
		
		/*RPA's Account Creation*/	
		Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;
		/*RPA's Account Creation*/	
		
		/*RPA Creation for Receivables*/	
		RPA__c RPA = TestHelper.createRPA(CharterHolder.Id);															//2016.08.29 J Caughie changed from acc to CharterHolder
		insert RPA;
		/*RPA Creation for Receivables*/
		
		/*Creation of RPA records*/		
		Integer j = 0;
		for(Integer i = 0; i < 5; i++){
			if(j<2){
				RPA__c RPA1 = TestHelper.createRPA(CharterHolder.Id);													//2016.08.29 J Caughie changed from school to CharterHolder
				RPAList.add(RPA1);					
			}
			else{
				RPA__c RPA1 = TestHelper.createRPA(CharterHolder.Id);													//2016.08.29 J Caughie changed from school to CharterHolder
				RPAList.add(RPA1);
			}
			j++;
		}
		insert RPAList;
		/*Creation of RPA records*/
		
		/*Creation of Terms Letter Records*/
		for(RPA__c FeesRPA : RPAList )	{
			TermsLetterList.add(TestHelper.createDraftTermsLetter(CharterHolder.Id, FeesRPA.ID));						//2016.08.29 J Caughie changed from acc to CharterHolder
		}
		insert TermsLetterList;
		/*Creation of Terms Letter Records*/
		
		/*Creation of Program Fee Records*/
		for(Terms_Letter__c tms : TermsLetterList){
			Program_Fee__c fees = TestHelper.createProgramFee(tms.Id);
			ProgFeeList.add(fees);
		}
		insert ProgFeeList;
		/*Creation of Program Fee Records*/
		
		/*Creation of RPA Redemption records*/
		RPA_Redemption__c rpaRed = TestHelper.createRPARedemption(RPAList[0].id,red.id);
		insert rpaRed;
		RPA_Redemption__c rpaRed1 = TestHelper.createRPARedemption(RPAList[1].id,red.id);
		insert rpaRed1;
		/*Creation of RPA Redemption records*/
		
		/*for unassigned receivables*/
		for(Integer i = 0; i < 5; i++){
			Funded_Receivable__c fundedRec = TestHelper.createFundedRec(school.Id, RPA.Id);
			fundedRec.FV_Amount__c = 10000 + i;
			fundedRec.Payments_Applied__c = 200;
			fundedRec.Upfront_Purchase_Price__c = 9000 + i;
			fundedRec.Purchase_Date__c = date.today() + i;
			fundedRec.Expected_Pay_Date__c = date.today() +20 + i;
			fundedRec.Distribution_Date__c = date.today() + 10 + i;
			frlist.add(fundedRec);
		}
		insert frlist;
		/*for unassigned receivables*/
		
		/*Creation of assigned receivables and related Draw Note TX records*/
		j = 0;
		for(Integer i = 0; i < 10; i++){
			if(j<5){
				Funded_Receivable__c fundedRec = TestHelper.createFundedRec(school.Id, RPA.Id);
				fundedRec.FV_Amount__c = 5000 + i;
				fundedRec.Upfront_Purchase_Price__c = 4500 + i;
				fundedRec.Purchase_Date__c = date.today() +10 + i;
				fundedRec.Expected_Pay_Date__c = date.today() + 30 + i;
				fundedRec.Distribution_Date__c = date.today() + 20 + i;
				frlistAssigned.add(fundedRec);	
			}
			else{
				Funded_Receivable__c fundedRec = TestHelper.createFundedRec(school1.Id, RPA.Id);
				fundedRec.FV_Amount__c = 6000 + i;
				fundedRec.Upfront_Purchase_Price__c = 5500 + i;
				fundedRec.Purchase_Date__c = date.today() +20 + i;
				fundedRec.Expected_Pay_Date__c = date.today() + 40 + i;
				fundedRec.Distribution_Date__c = date.today() + 30 + i;
				frlistAssigned.add(fundedRec);	
			}
			j++;
				
		}
		insert frlistAssigned;
		
		Integer i = 0;
		j = 0;
		for(Funded_Receivable__c funRec : frlistAssigned){
			if(j<3){
				Draw_Note_TX__c drtx = TestHelper.createDrawNoteTx(drawNoteOld.Id,funRec.Id,300.00+i);
				drtx.Status__c = 'Active';
				drtxlist.add(drtx);
			}
			else{
				Draw_Note_TX__c drtx = TestHelper.createDrawNoteTx(drawNoteOld1.Id,funRec.Id,300.00+i);
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
			}
			else{
				funRec.Lien_Holder__c = investor1.Id;
			}
			
		}		
		update frlistAssigned;
		/*Creation of assigned receivables and related Draw Note TX records*/
		
		/*Creation of allocations to created receivables*/		
		Allocation__c Allocation = TestHelper.createAllocation(frlistAssigned[0].id,red.Id,200);
		insert Allocation;
		Allocation__c Allocation1 = TestHelper.createAllocation(frlistAssigned[1].id,red.Id,400);
		insert Allocation1;
		/*Creation of allocations to created receivables*/	
		
		/*list <Funded_Receivable__c> frdebug = [select Payments_Applied__c,FV_Amount__c, FV_Amount_Due__c,id,Draw_Note_TX__r.Draw_Note__c from Funded_Receivable__c where id in: frlistAssigned];
		
		list <Funded_Receivable__c> receiveList = [select lien_holder__c, Draw_Note_TX__r.name, Draw_Note_TX__r.status__c, Draw_Note_TX__r.Draw_Note__r.name,
	        				Financeable__c,	lien_holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c,
       						Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c, Upfront_Purchase_Price__c
        					from Funded_Receivable__c
        					where FV_Amount_Due__c != 0.00 and School__r.Operating_State__c =: drawNote.Operating_State__c] ;
		system.debug('assigned receivables are ' + frdebug);
		system.debug('receive list is ' + receiveList);*/
		
	}
	
	/***************************************
	To test for new Redemption to be created
	****************************************/
	static testMethod void ControllerTest(){
		Boolean NewRed = true;
		PageReference pageRef = Page.RedemptionDetails;
        Test.setCurrentPage(pageRef);
		createTestData();
		
		Redemption__c redZero = TestHelper.createRedemption(school1.Id);
		redZero.Amount_Received__c = 0.00;
		insert redZero;
		
		ApexPages.currentPage().getParameters().put('Redemptionid',redZero.Id);
		RedemptionDetailsController controllerWithZeroAmount =  new RedemptionDetailsController();
		Test.startTest();
		if(NewRed){
			ApexPages.currentPage().getParameters().put('id',school.Id);
			RedemptionDetailsController controllerAccount =  new RedemptionDetailsController();
			controllerAccount.red = TestHelper.createRedemption(school.Id);
			//controllerAccount.red.Redemption_Payor__c = 'TEST RAJEEV';
			controllerAccount.SaveRedemption();
			system.assertNotEquals(controllerAccount.red.Id, null);
			
			List<SelectOption> SchoolList = controllerAccount.getListOfSchool();
			controllerAccount.selectedschool = '---Select---';
			controllerAccount.filteredBySchool();
			controllerAccount.selectedschool = school.Id;//String.valueOf(LienList[0]);
			system.debug('select school is ' + controllerAccount.selectedschool);
			controllerAccount.filteredBySchool();
			system.assertEquals(controllerAccount.RowList[0].School,school.name);
			
			/*controllerAccount.Unassigned = true;
			//SchoolList = controllerAccount.getListOfSchool();
			controllerAccount.selectedschool = '---Select---';
			controllerAccount.filteredBySchool();
			controllerAccount.selectedschool = school1.Id;//String.valueOf(LienList[0]);
			system.debug('select school is ' + controllerAccount.selectedschool);
			controllerAccount.filteredBySchool();
			//system.assertEquals(controllerAccount.RowList[0].School,school1.name);
			*/
			
			Integer CountOfAssigned = 0;
			controllerAccount.Unassigned = true;
			controllerAccount.filteredByCheckbox();
			system.assertEquals(controllerAccount.RowList[0].DrawNote,'-');
			for(FundedReceivableWrapper frWrap : controllerAccount.RowList){
				if(frWrap.DrawNote != '-'){
					CountOfAssigned ++;
				}
			}
			system.assertEquals(CountOfAssigned,0);
			
			CountOfAssigned = 0;
			controllerAccount.Unassigned = false;
			controllerAccount.filteredByCheckbox();
			for(FundedReceivableWrapper frWrap : controllerAccount.RowList){
				if(frWrap.DrawNote != '-'){
					CountOfAssigned ++;
				}
			}
			//system.assertEquals(CountOfAssigned,10);
			
			/*Sorting test on Funded Receivable Wrapper*/
			controllerAccount.sortExpression = 'RecName';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.selectedPageNumber = 1;
			controllerAccount.getList();
			controllerAccount.addPaginationOnFormList();
			//controllerAccount.selectedPageNumber = 0;
			//controllerAccount.getList();
			//controllerAccount.addPaginationOnFormList();
			
			controllerAccount.sortExpression = 'CharterHolder';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'Description';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'FVAmountDue';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'FVAmount';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			system.assertEquals(controllerAccount.RowList[0].FVAmount,5000);
			
			controllerAccount.sortExpression = 'School';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'DrawNote';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'DistributionDate';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'ExpPayDate';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'PurchaseDate';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			/*Sorting test on Funded Receivable Wrapper*/
			
			/*Sorting test on RPA Wrapper*/
			controllerAccount.sortExpression = 'RPAAccount';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPAAccount';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPAName';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPAName';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPAStatus';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPAStatus';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPADate';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPAEndDate';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			//controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPAProgramFee';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			
			controllerAccount.sortExpression = 'RPAProgramFee';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortRPAWrapper();
			/*Sorting test on RPA Wrapper*/
			
			/* testing on allocations*/
			Apexpages.currentPage().getParameters().put('myParam','1');
			FundedReceivableWrapper recWrapTest = controllerAccount.ReceivablesMap.get(1);
			recWrapTest.newPayment = '200';
			controllerAccount.AllocatePayment();
			system.assertEquals (controllerAccount.WrapperAllocateList.isEmpty(),false);
			system.assertNotEquals (controllerAccount.RedRemainAmount,controllerAccount.red.Remaining_Amount__c);
			recWrapTest.newPayment = '300';
			controllerAccount.AllocatePayment();
			system.assertEquals (controllerAccount.WrapperAllocateList.isEmpty(),false);
			system.assertNotEquals (controllerAccount.RedRemainAmount,controllerAccount.red.Remaining_Amount__c);
			controllerAccount.SaveAllocations();
			
			Apexpages.currentPage().getParameters().put('myParam','2');
			FundedReceivableWrapper recWrapTest1 = controllerAccount.ReceivablesMap.get(2);
			recWrapTest1.newPayment = '';
			controllerAccount.AllocatePayment();
			system.assertEquals (controllerAccount.WrapperAllocateList.isEmpty(),false);
			recWrapTest1.newPayment = '-200';
			controllerAccount.AllocatePayment();
			system.assertEquals (controllerAccount.WrapperAllocateList.isEmpty(),false);
			/* testing on allocations*/
			
			/* testing on RPA Program Fees*/
			Apexpages.currentPage().getParameters().put('myFees','1');
			RPAWrapper recRPAWrap = controllerAccount.RPAMap.get(1);
			recRPAWrap.newFees = '200';
			controllerAccount.AllocateFees();
			system.assertEquals (controllerAccount.WrapperRPARedList.isEmpty(),false);
			system.assertNotEquals (controllerAccount.RedRemainAmount,controllerAccount.red.Remaining_Amount__c);
			recRPAWrap.newFees = '300';
			controllerAccount.AllocateFees();
			system.assertEquals (controllerAccount.WrapperRPARedList.isEmpty(),false);
			system.assertNotEquals (controllerAccount.RedRemainAmount,controllerAccount.red.Remaining_Amount__c);
			controllerAccount.SaveRPAProgramFees();
			
			Apexpages.currentPage().getParameters().put('myFees','2');
			RPAWrapper recRPAWrap1 = controllerAccount.RPAMap.get(2);
			recRPAWrap1.newFees = '';
			controllerAccount.AllocateFees();
			system.assertEquals (controllerAccount.WrapperRPARedList.isEmpty(),false);
			recRPAWrap1.newFees = '-200';
			controllerAccount.AllocateFees();
			system.assertEquals (controllerAccount.WrapperRPARedList.isEmpty(),false);
			/* testing on RPA Program Fees*/
			NewRed = false;
			Test.stopTest();
		}

	}
	
	/*************************************************
	To test for existing Redemption
	**************************************************/
	static testMethod void ControllerTestExistingRed(){
		PageReference pageRef1 = Page.RedemptionDetails;
        Test.setCurrentPage(pageRef1);
		createTestData();
		ApexPages.currentPage().getParameters().put('Redemptionid',red.Id);
		RedemptionDetailsController controller =  new RedemptionDetailsController();
		controller.SavePaymentSubs();
	}
	
	/********************************************************
	To test for existing Redemption with Other Fees Applied
	*********************************************************/
	static testMethod void ControllerTestOtherFees(){
		PageReference pageRefOther = Page.RedemptionDetails;
        Test.setCurrentPage(pageRefOther);
		createTestData();
		ApexPages.currentPage().getParameters().put('Redemptionid',red.Id);
		RedemptionDetailsController controllerOther =  new RedemptionDetailsController();
		controllerOther.OtherFee = 20;
		controllerOther.SaveOtherFees();
		controllerOther.SavePaymentSubs();
	}
	
	/***********************************************************************
	To test for existing Redemption with All to School checkbox set to true
	*************************************************************************/
	static testMethod void ControllerTestAllToSchool(){
		PageReference pageRefAll = Page.RedemptionDetails;
        Test.setCurrentPage(pageRefAll);
		createTestData();
		ApexPages.currentPage().getParameters().put('Redemptionid',red.Id);
		RedemptionDetailsController controllerAll =  new RedemptionDetailsController();
		controllerAll.red.All_To_School__c = true;
		controllerAll.SavePaymentSubs();
	}
}