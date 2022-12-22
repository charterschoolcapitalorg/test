/**=====================================================================
 * Appirio, Inc
 * Trigger Name: ProgramFeeTrigger_Test
 * Description: T-278354 : Test Class for Trigger ProgramFeetrigger
 * Created Date: [05/23/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
@isTest
private class ProgramFeeTrigger_Test {
	static Boolean activeDraw;
	static testMethod void myUnitTest() {
        Test.StartTest();
   
        TestHelper.createCustomSettingToByPassTriggersAndRules('Program_Fee__c');
  
        Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;
        
        RPA__c rpa = TestHelper.createRPA(acc.id);
		insert rpa;
		
		Terms_Letter__c tmsLttr = TestHelper.createTermsLetter(acc.id, rpa.id);
		insert tmsLttr;
		
		Program_Fee__c pgmFees = TestHelper.createProgramFee (tmsLttr.Id);
		pgmFees.Program_Fee__c = 432.00;
		
		pgmFees.Start_Date__c = Date.Today();
		pgmFees.End_Date__c = Date.today() + 20;
		insert pgmFees;
		
		Date a = pgmFees.Start_Date__c;
		Date b = pgmFees.End_Date__c;
		Integer monthDiff = a.monthsBetween(b);
		
		RPA__c test_rpa = [select Current_Program_Fee_Value__c, Current_Program_Fee_Months__c from RPA__c where id =: rpa.Id];
		System.assertEquals(pgmFees.Program_Fee__c, test_rpa.Current_Program_Fee_Value__c);
		System.assertEquals(monthDiff, test_rpa.Current_Program_Fee_Months__c);
		
		system.debug('--------------------' );
		Program_Fee__c pgmFees1 = TestHelper.createProgramFee (tmsLttr.Id);
		pgmFees1.Program_Fee__c = 1000.00;
		pgmFees1.Start_Date__c = Date.Today();
		pgmFees1.End_Date__c = Date.today() + 120;
		insert pgmFees1;
		
		Date c = pgmFees1.Start_Date__c;
		Date d = pgmFees1.End_Date__c;
		Integer monthDiff1 = c.monthsBetween(d);
		
		RPA__c test_rpa1 = [select Current_Program_Fee_Value__c, Current_Program_Fee_Months__c from RPA__c where id =: rpa.Id];
		System.assertEquals(pgmFees1.Program_Fee__c, test_rpa1.Current_Program_Fee_Value__c);
		System.assertEquals(monthDiff1, test_rpa1.Current_Program_Fee_Months__c);
		Test.StopTest();
	}
}