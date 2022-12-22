@IsTest
private class CloneAllActivePricingRatesBatchTests {
    
    static void dataSetup(Integer prCt) {
        MarketRateTriggerHandler.triggerActive = false;
        List<Account> schools = new List<Account>();
        List<Pricing_Rate__c> pRates = new List<Pricing_Rate__c>();

        State_Province__c state = TestObjectFactory.getState();
        insert state;
        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        insert mr;
        
        for (Integer i = 0; i < prCt; i++) {
            schools.add(
                TestObjectFactory.getSchool()
            );
        }
        insert schools;

        for (Integer i = 0; i < prCt; i++) {
            Pricing_Rate__c testPR = TestObjectFactory.getPricingRate(schools[i]); 
            testPR.Market_Rate__c = mr.Id; 
            testPR.Reporting_Month__c = 'Sep';
            testPR.Reporting_Date__c = Date.newInstance(2022, 9, 25);
            testPR.Active__c = false;
            pRates.add(
                testPR
            );
        }

        for (Integer i = 0; i < prCt; i++) {
            Pricing_Rate__c testPR = TestObjectFactory.getPricingRate(schools[i]); 
            testPR.Market_Rate__c = mr.Id; 
            testPR.Reporting_Month__c = 'Oct';
            testPR.Reporting_Date__c = Date.newInstance(2022, 10, 25);
            testPR.Active__c = true;
            pRates.add(
                testPR
            );
        }

        insert pRates;
        MarketRateTriggerHandler.triggerActive = true;
    }

    @IsTest
	static void posTest_ActivateMarketRate() { 
        dataSetup(10);

        System.assertEquals(0, fetchAllLogs().size());
        System.assertEquals(20, fetchAllRates().size());
        System.assertEquals(10, fetchActiveRates().size());

        Test.startTest();
        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        insert mr;
        Test.stopTest();

        System.assertEquals(0, fetchAllLogs().size());
        System.assertEquals(30, fetchAllRates().size());
        System.assertEquals(10, fetchActiveRates().size());
    }

    @IsTest
	static void posTest_ActivateJulyMarketRate() { 
        dataSetup(10);

        System.assertEquals(0, fetchAllLogs().size());
        System.assertEquals(20, fetchAllRates().size());
        System.assertEquals(10, fetchActiveRates().size());

        Test.startTest();
        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        mr.Reporting_Date__c = Date.newInstance(2022, 7, 25);
        insert mr;
        Test.stopTest();

        System.assertEquals(0, fetchAllLogs().size());
        System.assertEquals(30, fetchAllRates().size());
        System.assertEquals(10, fetchActiveRates().size());
    }

    @IsTest
	static void negTest_RunWithNoActiveMarketRate() { 
        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        mr.Current_Monthly_Rate__c = false;
        insert mr;
        Account school = TestObjectFactory.getSchool();
        insert school;
        Pricing_Rate__c testPR = TestObjectFactory.getPricingRate(school); 
        testPR.Reporting_Date__c = Date.newInstance(2022, 9, 25);
        testPR.Market_Rate__c = mr.Id; 
        testPR.Active__c = true;
        insert testPR;

        System.assertEquals(0, fetchAllLogs().size());

        Test.startTest();
        CloneAllActivePricingRatesBatch b = new CloneAllActivePricingRatesBatch();
        Database.executeBatch(b);
        Test.stopTest();

        System.assertEquals(1, fetchAllLogs().size());
    }

    @IsTest
	static void negTest_HandleErrors() { 
        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        mr.Current_Monthly_Rate__c = false;
        insert mr;
        Account school = TestObjectFactory.getSchool();
        insert school;
        Pricing_Rate__c testPR = TestObjectFactory.getPricingRate(school); 
        testPR.Reporting_Date__c = Date.newInstance(2022, 9, 25);
        testPR.Market_Rate__c = mr.Id; 
        testPR.Active__c = true;
        insert testPR;

        Database.SaveResult oldRes = Database.insert(testPR, false);

        Database.SaveResult newRes = Database.insert(new Pricing_Rate__c(), false);
        CloneAllActivePricingRatesBatch.PricingRateConnection con = new CloneAllActivePricingRatesBatch.PricingRateConnection(testPR, new Pricing_Rate__c());
        con.oldSR = oldRes;
        con.newSR = newRes;

        System.assertEquals(0, fetchAllLogs().size());

        Test.startTest();
        
        CloneAllActivePricingRatesBatch.handleErrors(new Map<Id, CloneAllActivePricingRatesBatch.PricingRateConnection> {testPR.Id => con});
        Test.stopTest();

        System.assertEquals(1, fetchAllLogs().size());
    }

    private static List<Log__c> fetchAllLogs() {
        return [SELECT Id FROM Log__c];
    }

    private static List<Pricing_Rate__c> fetchAllRates() {
        return [SELECT Id FROM Pricing_Rate__c];
    }

    private static List<Pricing_Rate__c> fetchActiveRates() {
        return [SELECT Id FROM Pricing_Rate__c WHERE Active__c = true];
    }
}