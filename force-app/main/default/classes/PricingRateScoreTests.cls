@IsTest
private class PricingRateScoreTests { 

    static Account testSchool;
    static List<Account> testSchools;
    static Pricing_Rate__c testPR;
    static List<Pricing_Rate__c> testPRs;

	static Account cmo, charterHolder, school1;
    static Pricing_Rate__c testPortfolioPR;
    static School_Attendance__c sa;

    static void setupSingle(Boolean stdCnts) {
        State_Province__c state = TestObjectFactory.getState();
        insert state;

        testSchool = TestObjectFactory.getSchool();
        insert testSchool;

        if (stdCnts) {
            List<School_Attendance__c> countsToIns = new List<School_Attendance__c>();
            School_Attendance__c sCount0 = TestObjectFactory.getStudentCount(testSchool);
            sCount0.Report_Date__c = Date.newInstance(2022, 9, 25);
            sCount0.Fiscal_Year__c = '22-23';
            sCount0.Active__c = true;
            sCount0.Total_Attendance_manual__c = 1512;
            countsToIns.add(sCount0);

            School_Attendance__c sCount1 = TestObjectFactory.getStudentCount(testSchool);
            sCount1.Report_Date__c = Date.newInstance(2021, 9, 25);
            sCount1.Fiscal_Year__c = '21-22';
            sCount1.Active__c = false;
            sCount1.Total_Attendance_manual__c = 1389;
            countsToIns.add(sCount1);

            School_Attendance__c sCount2 = TestObjectFactory.getStudentCount(testSchool);
            sCount2.Report_Date__c = Date.newInstance(2020, 9, 25);
            sCount2.Fiscal_Year__c = '20-21';
            sCount2.Active__c = false;
            sCount2.Total_Attendance_manual__c = 1365;
            countsToIns.add(sCount2);

            insert countsToIns;
        }
        
        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        insert mr;

        testPR = TestObjectFactory.getPricingRate(testSchool); 
        testPR.Market_Rate__c = mr.Id; 
        testPR.Reporting_Month__c = 'Sep';
        testPR.Reporting_Date__c = Date.newInstance(2022, 9, 25);
        insert testPR;
    }

    static void setupPortfolio() {

		charterHolder = new Account(Name = 'Charter Holder', RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id);
		insert charterHolder;

		school1 = new Account(Name = 'School',Charter_Holder__c = charterHolder.Id, ParentId = charterHolder.Id, RecordTypeId = RecordTypeUtils.AccountSchool.Id, Pricing_Rate_Inclusion_Override__c = true);
		insert school1;

        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        insert mr;

        testPortfolioPR = new Pricing_Rate__c( 
            Account__c = charterHolder.id,
            Market_Rate__c = mr.Id,
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('Portfolio').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert testPortfolioPR;

        Id facilitiesTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'School_Attendance__c' AND DeveloperName = 'Facilities' LIMIT 1].Id;
        sa = new School_Attendance__c(
            School__c = school1.Id,
            RecordTypeId = facilitiesTypeId,
            Attendance_Type__c = 'Q4',
            Report_Date__c = Date.today().addDays(-1 * 365),
            Fiscal_Year__c = '19-20',
            Total_Attendance_manual__c = 200 - (1 * 50));
        insert sa;
    }

    @IsTest
	static void posTest_RescoreSchool_WithStudentCounts() { 
        setupSingle(true);

        System.assertEquals(0, fetchLogs().size());

        testPR = fetchPricingRateData(testPR.Id);

        System.assertEquals(null, testPr.Student_Count_Record__c);
        System.assertEquals(null, testPr.Student_Count_Current_FY__c);
        System.assertEquals(null, testPr.Student_Count_1_FY_Prior__c);
        System.assertEquals(null, testPr.Student_Count_2_FY_Prior__c);

        PricingRateScore score = new PricingRateScore(testPR.Id);
        score.rescore();

        testPR = fetchPricingRateData(testPR.Id);

        System.assertEquals(0, fetchLogs().size());
        System.assertNotEquals(null, testPr.Student_Count_Record__c);
        System.assertEquals(1512, testPr.Student_Count_Current_FY__c);
        System.assertEquals(1389, testPr.Student_Count_1_FY_Prior__c);
        System.assertEquals(1365, testPr.Student_Count_2_FY_Prior__c);
    }

    @IsTest
	static void posTest_RescoreSchool_WithoutStudentCounts() {
        setupSingle(false);

        System.assertEquals(0, fetchLogs().size());

        testPR = fetchPricingRateData(testPR.Id);

        System.assertEquals(null, testPr.Student_Count_Record__c);
        System.assertEquals(null, testPr.Student_Count_Current_FY__c);
        System.assertEquals(null, testPr.Student_Count_1_FY_Prior__c);
        System.assertEquals(null, testPr.Student_Count_2_FY_Prior__c);

        PricingRateScore score = new PricingRateScore(testPR.Id);
        score.rescore();

        testPR = fetchPricingRateData(testPR.Id);

        System.assertEquals(0, fetchLogs().size());
        System.assertEquals(null, testPr.Student_Count_Record__c);
        System.assertEquals(null, testPr.Student_Count_Current_FY__c);
        System.assertEquals(null, testPr.Student_Count_1_FY_Prior__c);
        System.assertEquals(null, testPr.Student_Count_2_FY_Prior__c);
    }

    @IsTest
	static void posTest_RescorePortfolio_WithStudentCounts() { 
        setupPortfolio();
        Account sch1 = [SELECT Id, Name, Top_Level_Parent_Account_Id__c, WC_Client_Pricing_School__c, ParentId FROM Account WHERE Id = :school1.id];
        Account ch = [SELECT Id, Name FROM Account WHERE Id = :charterHolder.id];
        Pricing_Rate__c runningPR = [SELECT Id, Name, Account__c FROM Pricing_Rate__c WHERE Id = :testPortfolioPR.id];

        // check variables 
        // running PR
        system.debug('@@@ runningPR = ' + testPortfolioPR);
        // account on the running PR
        system.debug('@@@ ch = ' + ch);
        // Additional school
        system.debug('@@@ sch1 = ' + sch1.id + '; top level parent = ' + sch1.Top_Level_Parent_Account_Id__c + '; WC = ' + sch1.WC_Client_Pricing_School__c);

        PricingRateScore score = new PricingRateScore(testPortfolioPR.Id);
        score.rescore();

    }

    @IsTest
	static void rescoreController() {
        setupPortfolio();
        Test.startTest();
        RescorePricingRateController.whatToRescore(testPortfolioPR.id);
        RescorePricingRateController.getFieldSets();
        RescorePricingRateController.rescoreRate(testPortfolioPR.id);
        Test.stopTest();
    }

    private static Pricing_Rate__c fetchPricingRateData(Id prId) {
        return [
            SELECT Id, Student_Count_Record__c, Student_Count_Current_FY__c, Student_Count_1_FY_Prior__c, Student_Count_2_FY_Prior__c, RecordType.DeveloperName, Account__c, RecordTypeId
            FROM Pricing_Rate__c
            WHERE Id =: prId
        ];
    }

    private static List<Log__c> fetchLogs() {
        return [SELECT Id FROM Log__c];
    }
}