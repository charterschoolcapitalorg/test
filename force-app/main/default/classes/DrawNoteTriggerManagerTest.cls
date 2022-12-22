/**=====================================================================
 * Appirio, Inc
 * Test Class Name: DrawNoteTriggerManagerTest
 * Class Name: DrawNoteTriggerManager.cls
 * Description: (T-286173: To test functionality of main class mentioned above.
 * Created Date: June 12, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest
private class DrawNoteTriggerManagerTest {
  private static Draw_Note__c drawNote;
  private static Draw_Entry__c oldDrawEntry;
  
  static testMethod void myUnitTest() {
    createTestData ();

    drawNote.Note_Rate__c = 4;
    update drawNote;
    Draw_Entry__c newDrawEntry = [SELECT ID, Activity_Type__c FROM Draw_Entry__c WHERE Draw_Note__c =: drawNote.ID AND ID !=: oldDrawEntry.ID];
    
    //Newely created draw entry and its activity type updated.
    System.assert(newDrawEntry.ID != null);
    System.assertEquals(newDrawEntry.Activity_Type__c, 'Draw Rate Change');
  }

  //Test method for draw residual calculation
  private static testMethod void ResidualCalculationTest() {
    
    Draw_Note__c newDrawNote = residualTestData(1);

    Test.startTest();
    newDrawNote.Status__c = 'Active';
    update newDrawNote;
    Test.stopTest();

    Draw_Note__c afterAct = ([Select Id, Excess_Cash_Collateral__c from Draw_Note__c WHERE id =: newDrawNote.Id]);
    System.debug(afterAct);

    System.assertEquals(afterAct.Excess_Cash_Collateral__c, 97638.89);      //Calculated offline
  }

  private static testMethod void multipleResidualCalculationTest() {
    
    Draw_Note__c newDrawNote = residualTestData(2);

    Test.startTest();
    newDrawNote.Status__c = 'Active';
    update newDrawNote;
    Test.stopTest();

    Draw_Note__c afterAct = ([Select Id, Excess_Cash_Collateral__c from Draw_Note__c WHERE id =: newDrawNote.Id]);
    System.debug(afterAct);

    System.assertEquals(afterAct.Excess_Cash_Collateral__c, 195264.66);      //Calculated offline
  }

  //Create necessary test data.
  private static void createTestData () {

    State_Province__c operatingState = TestDataUtility.createOperatingState();

		drawNote = TestHelper.createDrawNote();
		drawNote.Status__c = 'Active';
		drawNote.Operating_State__c = operatingState.ID;
		drawNote.Borrow_Date__c = date.parse('1/12/2013');
		drawNote.Note_Rate__c = 2;
		insert drawNote;
    
    oldDrawEntry = new Draw_Entry__c();
    oldDrawEntry.Principal__c = 2.00;
    oldDrawEntry.Activity_Date__c = date.parse('1/12/2014');
    oldDrawEntry.Draw_Note__c = drawNote.Id;
    oldDrawEntry.Ending_Principal__c= 1000.00;
    oldDrawEntry.Interest_Fwd__c = 8.00;
    insert oldDrawEntry;
  }

  private static Draw_Note__c residualTestData(Integer numReceivables) {

    Account newAccount = new Account(name = 'Test Charter');
    insert newAccount;

    RPA__c newRPA = TestHelper.createRPA(newAccount.Id);
    insert newRPA;

    State_Province__c operatingState = TestDataUtility.createOperatingState();
    
    Draw_Note__c newDrawNote = TestHelper.createDrawNote();
    newDrawNote.Operating_State__c = operatingState.ID;
    insert newDrawNote;

    for(Integer i = 0; i < numReceivables; i++){
      Funded_Receivable__c newFR = TestHelper.createFundedRec(newAccount.Id, newRPA.Id);
      newFR.Expected_Pay_Date__c = date.Today() + 25 + (10 * i);
      newFR.FV_Amount__c = 200000;
      insert newFr;

      Draw_Note_TX__c newDrawNoteTX = TestHelper.createDrawNoteTx(newDrawNote.Id, newFR.Id, 100000);
      newDrawNoteTX.FV_Amount_TX__c = 200000;
      insert newDrawNoteTX;
      System.debug(newDrawNoteTX);

    }

    return newDrawNote;

  }



}