/******************************************************************************************
 *  Purpose : Test Class for FundedReceivableManager
 *  Author  : Rahul Agrawal (Appirio)
 *  Date    : 06/10/2014
 *  Story  : T-285924
*******************************************************************************************/
@isTest
private class FundedReceivableManagerTest {
	static Account school;
	static list<Funded_Receivable__c> lstFR;
	static User u1;

	static void createData(boolean ferRequired){



		TestHelper.createCustomSettingToByPassTriggersAndRules('Account, RPA__c, Opportunity, '+
    															'Funding_Estimate_Receivable__c, Funding_Estimates__c, '+
																'Opp_School__c');

		Financial_Calc_Settings__c finCalc = Financial_Calc_Settings__c.getOrgDefaults();
        finCalc.NameSpacePrefix__c = '';
        upsert finCalc;

		Account acc = TestHelper.createAccountForIndustryType('School');
		insert acc;

		Account RPAAccount = TestHelper.createRPAAccount(acc.Id);
		//RPAAccount.first_purchase_date__c =
		insert RPAAccount;

		RPA__c rpa = new RPA__c();
		rpa.Account__c = RPAAccount.Id;
		insert rpa;

		//Initialize Record Type.
     	Map<String,RecordType> rtMap = TestHelper.createRecordTypeMap();

		//Create School
        school = TestHelper.createAccountForRecordType((rtMap.get('School')).Id,'ABC School 1');

		Funding_Estimate_Receivable__c fer;
		if(ferRequired){
			Opportunity opp = TestHelper.createOpportunity(acc, 'Test Opp');
			opp.Account_Owner__c = u1.Id;
			insert opp;

			Opp_School__c oppSchool = testHelper.createOppSchool(opp, acc);

			Funding_Estimates__c fundingEst = Testhelper.createFundingEstimate(opp.Id);
			insert fundingEst;

			fer = TestHelper.createFundingEstimateReceivable(fundingEst.Id, oppSchool.Id);
			insert fer;
		}
		//Create Payor
  		Payor__c statePayor = testHelper.createPayor('California');

		//Create Receivable Types.
  		Receivable_Type__c type1 = testHelper.createReceivableType(statePayor,'CA-In Lieu');

		//Create Calculations.
  		Calculation__c c1 = testHelper.createCalculation(type1,'calc_CA_InLieu');

  		//Create Payout Dates for both calculations.
  		Payout_Date__c   payout  = testHelper.createPayoutDate(50,c1,Date.newInstance(2014,6,1),'June');
  		Profile test_Profile = new Profile (Name = 'test value');

		// Create funded Receivable
		lstFR = new list<Funded_Receivable__c>();
		for(integer i=0; i < 5; i++){
			Funded_Receivable__c fundedReceivable = TestHelper.createFundedReceivable( payout.Id, 2, school.Id,  rpa.Id);
			fundedReceivable.Program_Fees_Collected__c = 77;
			fundedReceivable.School__c = school.Id;
			fundedReceivable.Transaction_Fee_Collected__c = 10;
			fundedReceivable.Expected_Pay_Date__c = Date.today().addDays(i);
			if(ferRequired){
				fundedReceivable.Source_Funding_Estimate_Receivable__c = fer.Id;
			}
			lstFR.add(fundedReceivable);
		}
		insert lstFR;
	}

    static testMethod void frmAccountUpdateAfterTest() {
		createData(false);
		Test.startTest();
		FundedReceivableManager.AccountUpdateAfter(lstFR);
		Account acc = [select name, id, ownerid, first_purchase_date__c, last_purchase_date__c, account_status__c, Max_Expected_Pay_Date__c from account where id = :school.Id];
		system.assertEquals(acc.first_purchase_date__c, date.today());
		system.assertEquals(acc.last_purchase_date__c, date.today());
		system.assertEquals(acc.Max_Expected_Pay_Date__c, date.today().addDays(4));											//2016.09.09 J Caughie - Added extra assert
		Test.stopTest();
    }

    static testMethod void frmCommissionCaculation() {
    	Profile prof = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    	UserRole rol = [SELECT Id FROM UserRole WHERE DeveloperName = 'CSC_Internal' LIMIT 1];
    	u1 = TestHelper.createUser('Unit1', 'Test1', 'unittest1@unittest.com', 'UT1', prof.Id);
    	u1.UserRoleId = rol.Id;
		u1.NewAcctCommission__c = 10.0;
		u1.ExistingAcctCommission__c = 1.0;
		u1.IsActive = true;
		insert u1;
    	system.runAs(u1){
			createData(true);
			Test.startTest();
			Map<ID, Funded_Receivable__c> oldValueMap = new Map<ID, Funded_Receivable__c>(lstFR);
			FundedReceivableManager.CommissionCaculation(lstFR, oldValueMap, true);
			list<RPA_Redemption__c> lstRPARedemption = [select id from RPA_Redemption__c where Funded_Receivable__c in: lstFR];
			// CommissionCaculation method call twice time, one from Trigger and one from above.
			// Because of this double RPA Redemption records created and compared below
			system.assertEquals(lstRPARedemption.size(), lstFR.size() * 2);

			list<Commission__c> lstCommision = [select id from Commission__c where Funded_Receivable__c in: lstFR];
			system.assertEquals(lstCommision.size(), lstFR.size());
			Test.stopTest();
    	}
    }
}