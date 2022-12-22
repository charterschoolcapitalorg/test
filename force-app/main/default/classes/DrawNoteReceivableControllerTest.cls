/**=====================================================================
 * Appirio, Inc
 * Name: DrawNoteReceivableControllerTest
 * Description: T-287375 : Test Class for custom controller DrawNoteReceivableController
 * Created Date: [06/18/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [06/24/2014]                [Rajeev Arya]               [I-118064 - Replace the DrawNote LKP field on Funded Receivable]
 =====================================================================*/
@isTest
private class DrawNoteReceivableControllerTest {
	static Draw_Note__c drawNote = new Draw_Note__c();
	static Account investor = new Account();
	static Account investor1 = new Account();
	static Redemption__c red = new Redemption__c();
	static Draw_Note__c drawNoteOld = new Draw_Note__c();
	static Draw_Note__c drawNoteOld1 = new Draw_Note__c();
	static State_Province__c testOpState = new State_Province__c();
	static map<String,RecordType> rtMap = new map<String,RecordType>();
	private static void createTestData(){
		list<Draw_Note_TX__c> drtxlist = new list<Draw_Note_TX__c>();
		list<Funded_Receivable__c> frlist = new list<Funded_Receivable__c>();
		list<Funded_Receivable__c> frlistAssigned = new list<Funded_Receivable__c>();
		map<ID,Draw_Note_TX__c> mapFrIdToDRTX = new map<ID,Draw_Note_TX__c>();
		
		//TestHelper.createCustomSettingToSetPageSize('DrawNoteReceivable');
		
		testOpState = TestHelper.createOperatingState();
		insert testOpState;
		
		rtMap = TestHelper.createRecordTypeMap();
		
		investor = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'Rajeev Investor');
		investor1 = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'Arya Investors');
		
		Account school = TestHelper.createAccountForRecordType(rtMap.get('School').Id, 'Rajeev School');
		school.Operating_State__c = testOpState.Id;
		update school;
		
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
		
		Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;

		RPA__c RPA = TestHelper.createRPA(acc.Id);
		insert RPA;
		
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
		
		/*for assigned receivables*/
		for(Integer i = 0; i < 5; i++){
			Funded_Receivable__c fundedRec = TestHelper.createFundedRec(school.Id, RPA.Id);
			fundedRec.FV_Amount__c = 5000 + i;
			fundedRec.Upfront_Purchase_Price__c = 4500 + i;
			fundedRec.Purchase_Date__c = date.today() +10 + i;
			fundedRec.Expected_Pay_Date__c = date.today() + 30 + i;
			fundedRec.Distribution_Date__c = date.today() + 20 + i;
			frlistAssigned.add(fundedRec);		
		}
		insert frlistAssigned;
		Integer i = 0;
		Integer j = 0;
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
		system.debug('unassigned are ' + frlist);
		
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
		
		list <Funded_Receivable__c> frdebug = [select Payments_Applied__c,FV_Amount__c, FV_Amount_Due__c,id from Funded_Receivable__c where id in: frlistAssigned];
		
		list <Funded_Receivable__c> receiveList = [select lien_holder__c,
	        				Financeable__c,	lien_holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c,
       						Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c, Upfront_Purchase_Price__c
        					from Funded_Receivable__c
        					where FV_Amount_Due__c != 0.00 and School__r.Operating_State__c =: drawNote.Operating_State__c] ;
		system.debug('assigned receivables are ' + frdebug);
		system.debug('receive list is ' + receiveList);
		/*for assigned receivables*/
		
		/*Redemption Creation*/
		red = TestHelper.createRedemption(school.Id);
		insert red;
		/*Redemption Creation*/	
		
		/*Creation of allocations to created receivables*/		
		Allocation__c Allocation = TestHelper.createAllocation(frlistAssigned[0].id,red.Id,200);
		insert Allocation;
		Allocation__c Allocation1 = TestHelper.createAllocation(frlistAssigned[1].id,red.Id,400);
		insert Allocation1;
		/*Creation of allocations to created receivables*/	
	}
	
	static testMethod void ControllerTest(){
		Boolean NewDraw = true;
		PageReference pageRef = Page.DrawNoteReceivable;
        Test.setCurrentPage(pageRef);
		createTestData();
		DrawNoteReceivableController controllerEmpty =  new DrawNoteReceivableController();
		
		if(NewDraw){
			ApexPages.currentPage().getParameters().put('AccountId',investor.Id);
			DrawNoteReceivableController controllerAccount =  new DrawNoteReceivableController();
			
			controllerAccount.draw = TestHelper.createDrawNote();
			controllerAccount.draw.Operating_State__c = testOpState.Id;
			controllerAccount.SaveDrawNote();
			system.assertNotEquals(controllerAccount.draw.Id, null);
			system.assertEquals(controllerAccount.LienFilterSelected, true);
			
			Integer CountOfAssigned = 0;
			controllerAccount.Unassigned = true;
			controllerAccount.PartialPaid = true;
			controllerAccount.filteredByCheckbox();
			system.assertNotEquals(controllerAccount.RowList[0].FVAmount,controllerAccount.RowList[0].FVAmountDue);
			system.assertEquals(controllerAccount.RowList[0].DrwNoteTX,'-');
			for(DrawNoteReceivableWrapper drWrap : controllerAccount.RowList){
				if(drWrap.DrwNoteTX != '-'){
					CountOfAssigned ++;
				}
			}
			system.assertEquals(CountOfAssigned,0);
			
			Integer CountOfPartialPaid = 0;
			controllerAccount.Unassigned = true;
			controllerAccount.PartialPaid = false;
			controllerAccount.filteredByCheckbox();
			for(DrawNoteReceivableWrapper drWrap : controllerAccount.RowList){
				if(drWrap.FVAmount != drWrap.FVAmountDue){
					CountOfPartialPaid ++;
				}
			}
			system.assertEquals(CountOfPartialPaid>0, true);
			
			CountOfAssigned = 0;
			controllerAccount.Unassigned = false;
			controllerAccount.filteredByCheckbox();
			for(DrawNoteReceivableWrapper drWrap : controllerAccount.RowList){
				if(drWrap.DrwNoteTX != '-'){
					CountOfAssigned ++;
				}
			}
			system.assertEquals(CountOfAssigned>0 , true);
			
			//ControllerFilterTest(true,true);
			system.debug('to check for FV Amount due ' + controllerAccount.RowList);
			system.debug('receivable map is ' + controllerAccount.ReceivablesMap.values());
			//ControllerFilterTest(false,true);
			//ControllerFilterTest(false,false);
			
			List<SelectOption> LienList = controllerAccount.getListOfLienHolder();
			controllerAccount.selectedHolder = '---Select---';
			controllerAccount.filteredByLien();
			controllerAccount.selectedHolder = LienList[0].getValue();//String.valueOf(LienList[0]);
			system.debug('select lien is ' + controllerAccount.selectedHolder);
			system.debug('lien list is ' +controllerAccount.setLienHolderIds);
			controllerAccount.filteredByLien();
		
			
			List<SelectOption> DrawList = controllerAccount.getListOfDrawNotes();
			controllerAccount.selectedHolderDrawNote = '---Select---';
			controllerAccount.filteredByDrawNote();
			controllerAccount.selectedHolderDrawNote = DrawList[0].getValue();
			system.debug('select draw is ' + controllerAccount.selectedHolderDrawNote);
			system.debug('draw list is ' +controllerAccount.setDrawNoteIds);
			controllerAccount.filteredByDrawNote();
			
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
						
			controllerAccount.sortExpression = 'LienHolder';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'UpfrontPurchasePrice';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'DrawNote';
			controllerAccount.sortDirection = 'ASC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'FinanceableFlag';
			controllerAccount.sortDirection = 'DESC';
			controllerAccount.getSortDirection();
			controllerAccount.sortWrapper();
			
			controllerAccount.sortExpression = 'FVAmountDue';
			controllerAccount.sortDirection = 'ASC';
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
			
			controllerAccount.sortExpression = 'DistributionDate';
			controllerAccount.sortDirection = 'ASC';
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
		
			controllerAccount.RowListSelected = new list<DrawNoteReceivableWrapper>();
			controllerAccount.SelectAll = true;
			controllerAccount.SelectAllReceivables();
			system.assertEquals (controllerAccount.AssignDrawBtn,false);
			
			controllerAccount.SelectAll = true;
			controllerAccount.SelectAllReceivables();
			system.assertEquals (controllerAccount.AssignDrawBtn,false);
			system.assertEquals (controllerAccount.RowListSelected.isEmpty(),false);
			
			controllerAccount.SelectAll = false;
			controllerAccount.SelectAllReceivables();
			system.assertEquals (controllerAccount.RowListSelected.isEmpty(),true);
			
			Apexpages.currentPage().getParameters().put('myParam','1');
			DrawNoteReceivableWrapper recWrapTest = controllerAccount.ReceivablesMap.get(1);
			recWrapTest.checkbox = true;
			controllerAccount.SelectReceivables();
			system.assertEquals (controllerAccount.RowListSelected.isEmpty(),false);
			recWrapTest.checkbox = false;
			controllerAccount.SelectReceivables();
			system.assertEquals (controllerAccount.RowListSelected.isEmpty(),true);
			
			recWrapTest.checkbox = true;
			controllerAccount.SelectReceivables();
			controllerAccount.rID = 1;
			controllerAccount.RemoveReceivable();
			system.assertEquals (controllerAccount.RowListSelected.isEmpty(),true);
			
			recWrapTest.checkbox = true;
			controllerAccount.SelectReceivables();
			controllerAccount.AssignDraw();
			system.assertEquals(recWrapTest.Assigned,true);
			
			NewDraw = false;
		}
		
		if(!NewDraw){
			ApexPages.currentPage().getParameters().put('DrawNoteid',drawNote.Id);
			DrawNoteReceivableController controller =  new DrawNoteReceivableController();
		}
		//controller.
		
		//system.assertNotEquals(pay.Id, null);
	}
	
	static private void ControllerFilterTest(Boolean TestUnassigned, Boolean TestPartialPaid){
		DrawNoteReceivableController controllerAccountForFilter =  new DrawNoteReceivableController();
		controllerAccountForFilter.Unassigned = TestUnassigned;
		controllerAccountForFilter.PartialPaid = TestPartialPaid;
		controllerAccountForFilter.filteredByCheckbox();
	}
	static private void ControllerSelectAllTest(Boolean SelectAllTest){
		DrawNoteReceivableController controllerAccountForAll =  new DrawNoteReceivableController();
		controllerAccountForAll.SelectAll = SelectAllTest;
		controllerAccountForAll.SelectAllReceivables();
	}
}