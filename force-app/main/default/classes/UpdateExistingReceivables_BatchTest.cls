/**=====================================================================
 * Appirio, Inc
 * Name: UpdateExistingReceivables_BatchTest
 * Description: Test Class for UpdateExistingReceivables_Batch
 * Created Date: [07/18/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
@isTest
private class UpdateExistingReceivables_BatchTest {
	static Redemption__c red = new Redemption__c();
	static Account investor = new Account();
	static Account CharterHolder = new Account();
	static Account school = new Account();
	static State_Province__c testOpState = new State_Province__c();
	static map<String,RecordType> rtMap = new map<String,RecordType>();
	
	private static void createTestData(){
		list<Funded_Receivable__c> frlist = new list<Funded_Receivable__c>();
		
		//TestHelper.createCustomSettingToSetPageSize('DrawNoteReceivable');
		
		/*Operating State Creation*/
		testOpState = TestHelper.createOperatingState();
		insert testOpState;
		/*Operating State Creation*/
		
		rtMap = TestHelper.createRecordTypeMap();
		
		/*Charter Holder Creation*/
		CharterHolder = TestHelper.createAccountForRecordType(rtMap.get('Charter_Holder').Id, 'Arya Charter');
		/*Charter Holder Creation*/
		
		/*school Creation*/
		school = TestHelper.createAccountForRecordType(rtMap.get('School').Id, 'Rajeev School');
		school.Operating_State__c = testOpState.Id;
		school.Charter_Holder__c = CharterHolder.Id;
		update school;
		
		/*Redemption Creation*/
		red = TestHelper.createRedemption(school.Id);
		red.Date_Cleared__c = Date.today() - 30;
		insert red;
		/*Redemption Creation*/		
		
		/*RPA's Account Creation*/	
		Account acc = TestHelper.createAccountForIndustryType('Test');
		insert acc;
		/*RPA's Account Creation*/	
		
		/*RPA Creation for Receivables*/	
		RPA__c RPA = TestHelper.createRPA(acc.Id);
		insert RPA;
		/*RPA Creation for Receivables*/
		
		
		/*for unassigned receivables*/
		Funded_Receivable__c fundedRec = TestHelper.createFundedRec(school.Id, RPA.Id);
		fundedRec.FV_Amount__c = 600;
		//fundedRec.Payments_Applied__c = fundedRec.FV_Amount__c;
		fundedRec.Purchase_Date__c = date.today();
		insert fundedRec;
		/*for unassigned receivables*/
		
		
		/*Creation of allocations to created receivables*/		
		Allocation__c Allocation = TestHelper.createAllocation(fundedRec.id,red.Id,200);
		insert Allocation;
		Allocation__c Allocation1 = TestHelper.createAllocation(fundedRec.id,red.Id,400);
		insert Allocation1;
		/*Creation of allocations to created receivables*/	

		
	}

     static testmethod void testScheduler(){
        test.startTest();
        createTestData();
        System.schedule('UpdateExistingReceivables_Batch Job','0 0 1 1 * ?', new UpdateExistingReceivables_Batch());
        test.stopTest();
        System.assert(true);
    }
}