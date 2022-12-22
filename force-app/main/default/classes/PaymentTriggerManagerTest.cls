/**=====================================================================
 * Appirio, Inc
 * Test Class Name: PaymentTriggerManagerTest
 * Class Name: PaymentTriggerManager.cls
 * Description: T-286173: To test functionality of above mentioned.
 * Created Date: June 12th, 2014	
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * 2016.06.30                   John Caughie                 Added parameter to createTestData and test class for Two Sigma
 * 2016.07.11                   John Caughie                 Test Two Sigma overpayment 
 * 2017.01.24                   John Caughie                 Added drawEntry.Payment_Amount__c value
 =====================================================================*/
@isTest
private class PaymentTriggerManagerTest {
  private static Payment__c payment;
  private static Draw_Note__c drawNote;
  private static Draw_Entry__c oldDrawEntry;
    
  static testMethod void myUnitTest() {
  	createTestData('Test Investor', false);
    //Assert to check that insert of payment created new Draw Entry with activity type "Payment"
    System.assertEquals([SELECT ID, Activity_Type__c 
                         FROM Draw_Entry__c 
                         WHERE Draw_Note__c =: drawNote.ID 
                               AND ID !=: oldDrawEntry.ID].Activity_Type__c, 'Payment');

  }

  static testMethod void myUnitTestTwoSigma() {
    createTestData('Two Sigma', false);
    //Assert to check that insert of payment created new Draw Entry with activity type "Payment"
    System.assertEquals([SELECT ID, Activity_Type__c 
                         FROM Draw_Entry__c 
                         WHERE Draw_Note__c =: drawNote.ID 
                               AND ID !=: oldDrawEntry.ID].Activity_Type__c, 'Payment');

  }

  //2016.07.11 J Caughie - Test Two Sigma draw overpayment
  static testMethod void testTwoSigmaOverpayment() {
    createTestData('Two Sigma', true);
    //Assert to check that insert of payment created new Draw Entry with activity type "Payment"
    System.debug('payments: ' + [SELECT id, Payment_Type__c, Payment_Amount__c FROM Payment__c 
                         WHERE Draw_Note__c =: drawNote.ID]);
    //Confirm that the second payment has been reversed for Two Sigma overpayments
    System.assertEquals([SELECT id, Payment_Type__c, Payment_Amount__c FROM Payment__c 
                         WHERE Draw_Note__c =: drawNote.ID 
                               AND Payment_Amount__c = -100000].Payment_Type__c, 'Over Payment');

  }

  //2016.07.11 J Caughie - Test Two Sigma draw overpayment
  static testMethod void testTwoSigmaNonOverpayment() {
    createTestData('East West Bank', true);
    //Confirm that the second payment has not been reversed for non-Two Sigma overpayments
    System.assertEquals([SELECT id, Payment_Type__c, Payment_Amount__c FROM Payment__c 
                         WHERE Draw_Note__c =: drawNote.ID 
                               AND Payment_Amount__c = -100000].size(), 0, 'Should be no entry for EWB overpayment');

  }


  //Create necessary test data.
  private static void createTestData (String investor, Boolean testOverpayment) {
    BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
                                            Triggers_Disabled__c = false,
                                            Validation_Rules_Disabled__c = false,
                                            Workflow_Rules_Disabled__c = false);
    insert ProfileCustomSettings;    
    
    State_Province__c operatingState = TestDataUtility.createOperatingState();

    Map<String,Schema.RecordTypeInfo> rtMapByName = new Map<String,Schema.RecordTypeInfo>();

		Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
		rtMapByName = d.getRecordTypeInfosByName();
		String charterRecTypeId = rtMapByName.get('Charter Holder').getRecordTypeId();
    String investorRecTypeId = rtMapByName.get('Investor').getRecordTypeId();
    
    Account testCharterHolder = TestDataUtility.createAccountForRecordType(charterRecTypeId, 'SchoolTest', operatingState.ID, true);
    Account inv = TestDataUtility.createAccountForRecordType(investorRecTypeId, investor, operatingState.ID, true);

  	RPA__c testRPA = new RPA__c();
  	testRPA.Account__c = testCharterHolder.ID;
  	testRPA.RPA_Type__c = 'Original';
  	testRPA.Status__c = 'Draft';
  	testRPA.Library_Type__c = 'Underwriting';
  	insert testRPA;
          	
  	Funded_Receivable__c fundRec1 = TestDataUtility.createFundedReceivable(1000, testCharterHolder.ID, testRPA.ID);
  	fundRec1.Payments_Applied__c = 500;
  	//fundRec1.Source_Funding_Estimate_Receivable__c = funEstRec.ID;
  	insert fundRec1;

			drawNote = TestHelper.createDrawNote();
		drawNote.Status__c = 'Active';
		drawNote.Operating_State__c = operatingState.ID;
		drawNote.Borrow_Date__c = date.parse('1/12/2013');
		drawNote.Note_Rate__c = 2;
    drawNote.Investor__c = inv.Id;

		//drawNote.Total_Amount_Borrowed__c = 1000;
		//drawNote.Principal_Due__c = 500;
		insert drawNote;

		Payment_Sub__c paymentSub = TestHelper.createPaymentSub(drawNote.Id, 5000);
		insert paymentSub;

		list<Draw_Note_TX__c> lstDrawTX = new list<Draw_Note_TX__c>();
		
		Draw_Note_TX__c drNoteTX;
		for(Integer i = 0; i<3; i++){
      drNoteTX = new Draw_Note_TX__c();
      drNoteTX.Status__c = 'Active';
      drNoteTX.Draw_Note__c = drawNote.Id;
      drNoteTX.Class__c = 're';
      drNoteTX.Amount_Borrowed__c = 500;
      drNoteTX.Funded_Receivable__c = fundRec1.Id;
      
      lstDrawTX.add(drNoteTX);
   }
        
   insert lstDrawTX;

    oldDrawEntry = new Draw_Entry__c();
    oldDrawEntry.Principal__c = 2.00;
    oldDrawEntry.Activity_Date__c = date.parse('1/12/2014');
    oldDrawEntry.Draw_Note__c = drawNote.Id;
    oldDrawEntry.Ending_Principal__c= 1000.00;
    oldDrawEntry.Interest_Fwd__c = 8.00;
    oldDrawEntry.Principal_Paid__c = 1000.00;
    oldDrawEntry.Payment_Amount__c = 1000;
    insert oldDrawEntry;

		payment = TestHelper.createPayment(drawNote.Id, 5000, paymentSub.Id);
		payment.Draw_Note__c = drawNote.ID;
		insert payment;


    if(testOverpayment){

      Draw_Entry__c entry = new Draw_Entry__c(Draw_Note__c = drawNote.Id, Payment_Amount__c = 5000, Principal_Paid__c = 5000);
      insert entry;

      System.debug('Draw: ' + [Select Principal_Due__c FROM Draw_Note__c WHERE Id = :drawNote.Id]);

      //Create Redemption
      Redemption__c red = TestHelper.createRedemption(testCharterHolder.Id);
      insert red;
      /*
      Allocation__c all = TestHelper.createAllocation(fundRec1.Id, red.Id, 5000);
      insert all;
      */
      //Create PaymentStub
      Payment_Sub__c paymntStub = TestHelper.createPaymentSub(drawNote.Id, 100000);
      insert paymntStub;

      //Create Payment
      Payment__c paymnt = TestHelper.createPayment(drawNote.Id, 100000, paymntStub.Id);
      paymnt.Payment_Type__c = 'Allocation';
      System.debug('new payment: ' + paymnt);
      insert paymnt;

      PaymentTriggerManager.calculateDrawInterest([SELECT id, Draw_Note__c, Payment_Amount__c, Date_Paid__c FROM Payment__c WHERE id = :paymnt.ID], red.Id);

    }


  }
}