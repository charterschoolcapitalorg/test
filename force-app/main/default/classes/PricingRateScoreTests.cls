@IsTest
private class PricingRateScoreTests { 

    static Account testSchool;
    static Account testCharter;
    static List<Account> testSchools;
    static Pricing_Rate__c testPR;
    static List<Pricing_Rate__c> testPRs;

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
	static void negTest_RescoreSchool_NoMarketRate() {

    }

    @IsTest
	static void posTest_RescoreCharter_MixedStudentCounts() {

    }

    private static Pricing_Rate__c fetchPricingRateData(Id prId) {
        return [
            SELECT Id, Student_Count_Record__c, Student_Count_Current_FY__c, Student_Count_1_FY_Prior__c, Student_Count_2_FY_Prior__c
            FROM Pricing_Rate__c
            WHERE Id =: prId
        ];
    }

    private static List<Log__c> fetchLogs() {
        return [SELECT Id FROM Log__c];
    }
}