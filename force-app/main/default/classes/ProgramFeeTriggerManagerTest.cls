/**=====================================================================
 * Appirio, Inc
 * Test Class Name: ProgramFeeTriggerManagerTest
 * Class Name: ProgramFeeTriggerManager
 * Description: To test functionality of ProgramFeeTriggerManager class.
 * Created Date: June 13th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest
private class ProgramFeeTriggerManagerTest {
  private static Program_Fee__c recentFee;	
  private static Program_Fee__c programFee;	
	private static RPA__c rpa1, rpa2;
	private static Terms_Letter__c tl1, tl2;
	
  static testMethod void myUnitTest() {
    createTestData();  	
  	recentFee = new Program_Fee__c();
    recentFee.Terms_Letter__c = tl1.ID;
    recentFee.Fee_Type__c = 'Fixed Fee';
    recentFee.Start_Date__c = Date.today().addMonths(-3);
    recentFee.End_Date__c = Date.today().addMonths(-1);
    insert recentFee;
  	
    programFee = new Program_Fee__c();
    programFee.Terms_Letter__c = tl1.ID;
    programFee.Fee_Type__c = 'Fixed Fee';
    programFee.Start_Date__c = Date.today();
    programFee.End_Date__c = Date.today().addMonths(2);
    insert programFee;
    
    RPA__c testAssert = [SELECT Current_Program_Fee_Value__c, Current_Program_Fee_Months__c FROM RPA__c WHERE ID =: rpa1.ID];
    
    System.assert(testAssert.Current_Program_Fee_Months__c == 2.00);
  }

	private static void createTestData() {
		Account acct = new Account(
			Name = 'Unit Test Charter Holder',
			RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id
		);
		insert acct;

		rpa1 = new RPA__c(
			Account__c = acct.Id,
			RPA_Date__c = System.today().toStartOfMonth(),
			RPA_Type__c = 'Original',
			Status__c = 'Active'
		);
		rpa2 = new RPA__c(
			Account__c = acct.Id,
			RPA_Date__c = System.today().toStartOfMonth(),
			RPA_Type__c = 'First Amended and Restated',
			Status__c = 'Draft'
		);
		insert new List<RPA__c> { rpa1, rpa2 };

		tl1 = new Terms_Letter__c(
			RPA__c = rpa1.Id,
			Account__c = acct.Id,
			TL_Type__c = 'Original',
			TL_Date__c = System.today(),
			Initial_Close_Date__c = System.today().toStartOfMonth().addMonths(1).addDays(-1),
			RPA_Face_Value__c = 100,
			RPA_Gross_Value__c = 100,
			Status__c = 'Active',
			Termination_Date__c = System.today().toStartOfMonth().addMonths(2)
		);

		insert tl1;

		Opportunity opp = new Opportunity(
			Name = 'Unit Test Opp',
			CloseDate = System.today(),
			StageName = 'Initial Funding',
			AccountId = acct.Id,
			Amount = 100,
			RPA__c = rpa1.Id,
			Terms_Letter__c = tl1.Id
		);
		insert opp;
	}


}