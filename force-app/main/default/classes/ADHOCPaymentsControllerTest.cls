/**=====================================================================
 * Appirio, Inc
 * Name: ADHOCPaymentsControllerTest
 * Description: T-287375 - Test Class for the controller ADHOCPaymentsController
 * Created Date: [06/17/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 
 =====================================================================*/
@isTest
private class ADHOCPaymentsControllerTest {
	static Draw_Note__c drawNote = new Draw_Note__c();
	static map<String,RecordType> rtMap = new map<String,RecordType>();
	private static void createTestData(){
		list<Draw_Note_TX__c> drtxlist = new list<Draw_Note_TX__c>();
		
		rtMap = TestHelper.createRecordTypeMap();
		
		Account investor = TestHelper.createAccountForRecordType(rtMap.get('Investor').Id, 'Rajeev Investor');
		
		State_Province__c testOpState = TestHelper.createOperatingState();
		insert testOpState;
		
		drawNote = TestHelper.createDrawNote();
		//drawNote.Total_Amount_Borrowed__c = 23000.00;
		drawNote.investor__c = investor.Id;
		drawNote.Operating_State__c = testOpState.Id;
		insert drawNote;
		//from draw_note__c where id =: ApexPages.currentPage().getParameters().get('id')
		
		Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;

		RPA__c RPA = TestHelper.createRPA(acc.Id);
		insert RPA;

		Funded_Receivable__c fundedRec = TestHelper.createFundedRec(acc.Id, RPA.Id);
		insert fundedRec;
		
		for(Integer i = 0; i < 3; i++){
			Draw_Note_TX__c drtx = TestHelper.createDrawNoteTx(drawNote.Id,fundedRec.Id,300.00+i);
			drtxlist.add(drtx);			
		}
		insert drtxlist;
	}
	
	static testMethod void ADHOCControllerTest(){
		PageReference pageRef = Page.ADHOCPayments; //replace with your VF page name
        Test.setCurrentPage(pageRef);
		createTestData();
		ApexPages.currentPage().getParameters().put('id',drawNote.Id);
		ADHOCPaymentsController controller =  new ADHOCPaymentsController();
		controller.AmountPaid = 20.00;
		controller.DatePaid = Date.parse(date.Today().format());
		drawNote.Last_Pay_Date__c = Date.parse(date.Today().format());
		controller.SaveADHOCPayment();
		
		Payment_Sub__c paysub = [select id from Payment_Sub__c where Payment_Against__c =: drawNote.Id];
		Payment__c pay = [select id from Payment__c where payment_sub__c =: paysub.Id and Draw_Note__c =: drawNote.Id];
		system.assertNotEquals(paysub.Id, null);
		system.assertNotEquals(pay.Id, null);
	}
}