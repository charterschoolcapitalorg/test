/**=====================================================================
 * Appirio, Inc
 * Name: ReceivableTypeDeepCloneControllerTest
 * Description: T-278593 : Receivable Type "Full Clone" tool
 * Created Date: [05/15/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
@isTest
private class ReceivableTypeDeepCloneControllerTest {

	private static testmethod void testDeepClone(){

		// trst data
		Payor__c payor = TestHelper.createPayor('payorName');

		Receivable_Type__c testRecType = TestHelper.createReceivableType(payor, 'typeName');

		List<Calculation__c> listCalculation = new list<Calculation__c>();
		for(Integer i = 0 ; i < 10 ; i++){
			listCalculation.add(TestHelper.createCalculationNoInsert(testRecType, 'ReceivableTypeDeepCloneControllerTest'));
		}

		insert listCalculation;

		list<Payout_Date__c> listPayoutToInsert = new list<Payout_Date__c>();
		for(Calculation__c calc : listCalculation){
			for(Integer i = 0 ; i < 10 ; i++){
				listPayoutToInsert.add(TestHelper.createPayoutDateNoInsert(10, calc, Date.today(), 'outName'));
			}
		}

		insert listPayoutToInsert;
		Test.StartTest();

		Test.setCurrentPage(Page.ReceivableTypeDeepClone);
		ApexPages.Standardcontroller std = new ApexPages.Standardcontroller(testRecType);

		ReceivableTypeDeepCloneController controller = new ReceivableTypeDeepCloneController(std);

		system.assertEquals(testRecType.Name, controller.clonedReceivableType.Name);

		controller.clonedReceivableType.Name = 'New Cloned Rec';
		controller.clonedReceivableType.Fiscal_Year__c = '15-16';
		controller.incrementPayoutDateYears = 4;

		controller.executeDeepClone();

		system.assert(controller.clonedReceivableType.Id <> Null);
		system.assert(controller.clonedReceivableType.Name == 'New Cloned Rec');
		system.assert(controller.clonedReceivableType.Fiscal_Year__c == '15-16');

		List<Calculation__c> listClonedCalculation = [Select Id from Calculation__c where Receivable_Type__c = :controller.clonedReceivableType.Id];
		system.assert(listCalculation.size() == listClonedCalculation.size());

		list<Payout_Date__c> listClonedPayoutDate = [Select Default_Payout_Date__c from Payout_Date__c where Calculation__c in :listClonedCalculation];
		system.assert(listPayoutToInsert.size() ==  listClonedPayoutDate.size());

		for(Integer i = 0 ; i < listPayoutToInsert.size() ; i++){
			system.assert(listPayoutToInsert[i].Default_Payout_Date__c.addYears(controller.incrementPayoutDateYears) == listClonedPayoutDate[i].Default_Payout_Date__c);
		}


		Test.StopTest();


	}
}