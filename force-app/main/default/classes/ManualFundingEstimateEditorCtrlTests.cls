@isTest
private class ManualFundingEstimateEditorCtrlTests {

    @testSetup
    static void dataSetUp() {
        TestHelper.createSeedDataForTesting();
        String oppId = [SELECT Id from Opportunity LIMIT 1].Id;
        Funding_Estimates__c fe = TestHelper.createFundingEstimate(oppId);
        fe.Manual_FE__c = true;
        insert fe;

        String oppSchoolId = [SELECT Id FROM Opp_School__c Where Opportunity__c = :oppId].Id;

        Funding_Estimate_Receivable__c fer = TestHelper.createFundingEstimateReceivable(fe.Id, oppSchoolId);
        fer.Statutory_Expected_Pay_Date__c = Date.newInstance(2021, 01, 01);
        insert fer;

    }

    @isTest
    static void testGetter(){
        String feId = [SELECT Id FROM Funding_Estimates__c LIMIT 1].Id;
        Test.startTest();
        List<Funding_Estimate_Receivable__c> fers = ManualFundingEstimateEditorCtrl.getFundingEstimateReceivables(feId);
        Test.stopTest();
        System.assertEquals(1, fers.size(), 'there should only be one');
        System.assertEquals(Date.newInstance(2021, 01, 01), fers[0].Statutory_Expected_Pay_Date__c, 'the date is incorrect');
    }

    @isTest
    static void testUpdate(){
        String feId = [SELECT Id FROM Funding_Estimates__c LIMIT 1].Id;
        List<Funding_Estimate_Receivable__c> fers = ManualFundingEstimateEditorCtrl.getFundingEstimateReceivables(feId);
        System.assertEquals(Date.newInstance(2021, 01, 01), fers[0].Statutory_Expected_Pay_Date__c, 'the date is incorrect');
        fers[0].Statutory_Expected_Pay_Date__c = Date.newInstance(2021, 01, 02);
        Test.startTest();
        ManualFundingEstimateEditorCtrl.updateReceivables(fers);
        Test.stopTest();
        System.assertEquals(Date.newInstance(2021, 01, 02), fers[0].Statutory_Expected_Pay_Date__c, 'the date is incorrect');
    }

    @isTest
    static void testError(){
        String feId = [SELECT Id FROM Funding_Estimates__c LIMIT 1].Id;
        List<Funding_Estimate_Receivable__c> fers = ManualFundingEstimateEditorCtrl.getFundingEstimateReceivables(feId);
        System.assertEquals(Date.newInstance(2021, 01, 01), fers[0].Statutory_Expected_Pay_Date__c, 'the date is incorrect');
        fers[0].Opp_School__c = null;
        Test.startTest();
        String returnValue = ManualFundingEstimateEditorCtrl.updateReceivables(fers);
        Test.stopTest();
        System.assertEquals(Date.newInstance(2021, 01, 01), fers[0].Statutory_Expected_Pay_Date__c, 'the date is incorrect');
        System.assertEquals('The following exception has occurred: ', returnValue.left('The following exception has occurred: '.length()), 'the returned value is wrong');
    }    
}