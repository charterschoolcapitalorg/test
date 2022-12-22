/**=====================================================================
 * Appirio, Inc
 * Name: AllocationTriggerManagerTest
 * Description: Test funcitonality of AllocationTriggerManager.cls (T-286173)
 * Created Date: June 11th, 2014.
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * 06/16/2014 					Manisha Gupta					Modified to update code coverage and test failure fixes
 =====================================================================*/
@isTest
public with sharing class AllocationTriggerManagerTest {
  private static Funded_Receivable__c fundRec1;
  private static Funded_Receivable__c fundRec2;
  private static Redemption__c redemption;

  //Insert test for Allocation
  static testMethod void AddAllocationToFundedReceivableTest() {
  	List<ID> fundRecIdList = new List<ID>();
  	createTestData ();
  	Test.startTest();
    fundRecIdList.add(fundRec1.ID);
    fundRecIdList.add(fundRec2.ID);


  	List<Allocation__c> allocationList = new List<Allocation__c>();
  	//Insert allocation
  	Allocation__c testAllocation = new Allocation__c();
  	testAllocation.Funded_Receivable__c = fundRec1.ID;
  	testAllocation.Redemption__c = redemption.ID;
  	testAllocation.Face_Amount_Applied__c = 2000.00;
  	allocationList.add(testAllocation);

    testAllocation = new Allocation__c();
  	testAllocation.Funded_Receivable__c = fundRec2.ID;
  	testAllocation.Redemption__c = redemption.ID;
  	testAllocation.Face_Amount_Applied__c = 2000.00;

  	allocationList.add(testAllocation);

  	insert allocationList;

  	System.assert([SELECT ID FROM Commission__c WHERE Funded_Receivable__c IN: fundRecIdList].size() > 0);
  	System.assertNotEquals([SELECT ID, Final_Payment_Date__c FROM Funded_Receivable__c WHERE ID =: fundRec1.ID].Final_Payment_Date__c, null);

  	List<Draw_Note_TX__c> drawNoteTXList = [SELECT ID, Status__c, Funded_Receivable__c FROM Draw_Note_TX__c WHERE Funded_Receivable__c IN: fundRecIdList];

  	System.assertEquals(drawNoteTXList.get(0).Status__c, 'Paid');
  	System.assertEquals(drawNoteTXList.get(1).Status__c, 'Active');
  	Test.stopTest();
  	update allocationList;
  }

  //Create necessary test data.
  private static void createTestData () {
    User testUser = TestDataUtility.createUser('System Administrator');
    insert testUser;

    Map<String,Schema.RecordTypeInfo> rtMapByName = new Map<String,Schema.RecordTypeInfo>();

		Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
		rtMapByName = d.getRecordTypeInfosByName();
		String schoolRecTypeId = rtMapByName.get('School').getRecordTypeId();
		String charterRecTypeId = rtMapByName.get('Charter Holder').getRecordTypeId();

    State_Province__c operatingState = TestDataUtility.createOperatingState();

  	Account testSchool = TestDataUtility.createAccountForRecordType(schoolRecTypeId, 'SchoolTest', operatingState.ID, true);
  	testSchool.OwnerId = testUser.ID;
  	update testSchool;

  	Account testCharterHolder = TestDataUtility.createAccountForRecordType(charterRecTypeId, 'SchoolTest', operatingState.ID, true);

    Opportunity newOppty = TestHelper.createOpportunity(testSchool, 'testOppty');
    newOppty.OwnerID = testUser.ID;
    newOppty.Account_Owner__c = testUser.Id;
    insert newOppty;

    Funding_Estimates__c fundingEstimate = TestHelper.createFundingEstimate(newOppty.ID);
    insert fundingEstimate;

    Opp_School__c oppSchool = TestHelper.createOppSchool(newOppty, testSchool);
    System.debug('--->fundingEstimate.ID-->'+fundingEstimate.ID);
    Funding_Estimate_Receivable__c funEstRec = TestHelper.createFundingEstimateReceivable(fundingEstimate.ID, oppSchool.ID);
    funEstRec.Funding_Estimate__c = fundingEstimate.ID;
    insert funEstRec;


  	RPA__c testRPA = new RPA__c();
  	testRPA.Account__c = testCharterHolder.ID;
  	testRPA.RPA_Type__c = 'Original';
  	testRPA.Status__c = 'Draft';
  	testRPA.Library_Type__c = 'Underwriting';
  	insert testRPA;

  	fundRec1 = TestDataUtility.createFundedReceivable(1000, testCharterHolder.ID, testRPA.ID);
  	//fundRec1.Payments_Applied__c = 500;
  	fundRec1.Source_Funding_Estimate_Receivable__c = funEstRec.ID;
  	insert fundRec1;

  	fundRec2 = TestDataUtility.createFundedReceivable(2000, testCharterHolder.ID, testRPA.ID);
  	fundRec2.Final_Payment_Date__c = null;
  	//fundRec2.Payments_Applied__c = 500;
  	fundRec2.Source_Funding_Estimate_Receivable__c = funEstRec.ID;
  	insert fundRec2;

  	System.debug('---testSchool--'+testSchool);
  	redemption = new Redemption__c();
  	redemption.School__c = testSchool.ID;
  	redemption.Payee__c = testCharterHolder.ID;
  	redemption.Date_Cleared__c = Date.today();
  	redemption.Date_Received__c = Date.today();
  	redemption.Type__c = 'Refinance';
    insert redemption;

		Draw_Note__c drawNote = TestHelper.createDrawNote();
		drawNote.Status__c = 'Active';
		drawNote.Operating_State__c = operatingState.ID;
		insert drawNote;

		list<Draw_Note_TX__c> lstDrawTX = new list<Draw_Note_TX__c>();

		Draw_Note_TX__c drNoteTX;
		for(Integer i = 0; i<2; i++){
      drNoteTX = new Draw_Note_TX__c();
      drNoteTX.Status__c = 'Active';
      drNoteTX.Draw_Note__c = drawNote.Id;
      drNoteTX.Class__c = 're';
      //drNoteTX.Amount_Borrowed__c = 2001.00;
      if (i>=1){
        drNoteTX.Funded_Receivable__c = fundRec2.Id;
        drNoteTX.Amount_Borrowed__c = fundRec2.FV_Amount__c;
      }else{
        drNoteTX.Funded_Receivable__c = fundRec1.Id;
        drNoteTX.Amount_Borrowed__c = fundRec1.FV_Amount__c;
      }

      lstDrawTX.add(drNoteTX);
   }
   System.debug('DrTXs: ' + lstDrawTX);
   insert lstDrawTX;


  }
}