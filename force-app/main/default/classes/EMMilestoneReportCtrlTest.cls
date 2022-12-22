@isTest
public with sharing class EMMilestoneReportCtrlTest {

    // testing for InternallySourced, BOP, Other School, Other, BioStar
    
    @isTest
    public static void testInternallySourcedOpp() {

        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');

		//create account
		Account acct = new Account();
		acct.name = 'Test Acct IS';
		insert acct;

        //create opportunity
        Opportunity opp = new Opportunity();
        opp.name = 'Test Opp IS';
        opp.StageName = 'Stage 3 - Review';
        opp.accountId = acct.id;
        opp.CloseDate = System.today();
        opp.Estimated_Project_Cost__c = 100;
        opp.RecordTypeId = '0120g000000gregAAA';
        opp.Referral_Source__c = 'Internally Sourced';
        insert opp;
        
        //create Action List
        CSC_Action_List__c actionList = new CSC_Action_List__c();
        actionList.Action_List_Name__c = 'Test List Name IS';
        actionList.Account__c = acct.Id;
        actionList.Opportunity__c = opp.Id;
        actionList.Library_Type__c = 'Underwriting';
        actionList.Status__c = 'New';
        actionList.Order__c = 1;
        actionList.Template__c = false;
        actionList.Opportunity_Record_Type__c = 'FOF';
        insert actionList;
        
        //create Action Items
        List<CSC_Action_Item__c> items = new List<CSC_Action_Item__c>();
        for(Integer i = 0; i < 4; i++){
            CSC_Action_Item__c item = CSCTestUtil.createActionItem(actionList.Id, i);
            switch on i{
                when 0 {item.Action_Item_Name__c = 'Collect pre-qualification information';}
                when 1 {item.Action_Item_Name__c = 'Present Enrollment Marketing pitch deck to Prospect';}
                when 2 {item.Action_Item_Name__c = 'Approve Enrollment Marketing client for contracting';}
                when else {item.Action_Item_Name__c = 'Receive signed contract';}
            }
            items.add(item);
        }
        insert items;
        
        Test.startTest();
        EnrollmentMarketingMilestoneReportCtrl.getEnrollmentMarketingMilestone();
        EnrollmentMarketingMilestoneReportCtrl controller = new EnrollmentMarketingMilestoneReportCtrl();
        Test.stopTest();
    }

    @isTest
    public static void testOSOpp() {

        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');

		//create account
		Account acct = new Account();
		acct.name = 'Test Acct Other School';
		insert acct;

        //create opportunity
        Opportunity opp = new Opportunity();
        opp.name = 'Test Opp Other School';
        opp.StageName = 'Stage 3 - Review';
        opp.accountId = acct.id;
        opp.CloseDate = System.today();
        opp.Estimated_Project_Cost__c = 100;
        opp.RecordTypeId = '0120g000000gregAAA';
        opp.Referral_Source__c = 'Other School';
        insert opp;
        
        //create Action List
        CSC_Action_List__c actionList = new CSC_Action_List__c();
        actionList.Action_List_Name__c = 'Test List Name Other School';
        actionList.Account__c = acct.Id;
        actionList.Opportunity__c = opp.Id;
        actionList.Library_Type__c = 'Underwriting';
        actionList.Status__c = 'New';
        actionList.Order__c = 1;
        actionList.Template__c = false;
        actionList.Opportunity_Record_Type__c = 'FOF';
        insert actionList;
        
        //create Action Items
        List<CSC_Action_Item__c> items = new List<CSC_Action_Item__c>();
        for(Integer i = 0; i < 4; i++){
            CSC_Action_Item__c item = CSCTestUtil.createActionItem(actionList.Id, i);
            switch on i{
                when 0 {item.Action_Item_Name__c = 'Collect pre-qualification information';}
                when 1 {item.Action_Item_Name__c = 'Present Enrollment Marketing pitch deck to Prospect';}
                when 2 {item.Action_Item_Name__c = 'Approve Enrollment Marketing client for contracting';}
                when else {item.Action_Item_Name__c = 'Receive signed contract';}
            }
            items.add(item);
        }
        insert items;
        
        Test.startTest();
        EnrollmentMarketingMilestoneReportCtrl.getEnrollmentMarketingMilestone();
        EnrollmentMarketingMilestoneReportCtrl controller = new EnrollmentMarketingMilestoneReportCtrl();
        Test.stopTest();
    }

    @isTest
    public static void testBOPOpp() {

        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');

		//create account
		Account acct = new Account();
		acct.name = 'Test Acct BOP';
		insert acct;

        //create opportunity
        Opportunity opp = new Opportunity();
        opp.name = 'Test Opp BOP';
        opp.StageName = 'Stage 3 - Review';
        opp.accountId = acct.id;
        opp.CloseDate = System.today();
        opp.Estimated_Project_Cost__c = 100;
        opp.RecordTypeId = '0120g000000gregAAA';
        opp.Referral_Source__c = 'BOP';
        insert opp;
        
        //create Action List
        CSC_Action_List__c actionList = new CSC_Action_List__c();
        actionList.Action_List_Name__c = 'Test List Name BOP';
        actionList.Account__c = acct.Id;
        actionList.Opportunity__c = opp.Id;
        actionList.Library_Type__c = 'Underwriting';
        actionList.Status__c = 'New';
        actionList.Order__c = 1;
        actionList.Template__c = false;
        actionList.Opportunity_Record_Type__c = 'FOF';
        insert actionList;
        
        //create Action Items
        List<CSC_Action_Item__c> items = new List<CSC_Action_Item__c>();
        for(Integer i = 0; i < 4; i++){
            CSC_Action_Item__c item = CSCTestUtil.createActionItem(actionList.Id, i);
            switch on i{
                when 0 {item.Action_Item_Name__c = 'Collect pre-qualification information';}
                when 1 {item.Action_Item_Name__c = 'Present Enrollment Marketing pitch deck to Prospect';}
                when 2 {item.Action_Item_Name__c = 'Approve Enrollment Marketing client for contracting';}
                when else {item.Action_Item_Name__c = 'Receive signed contract';}
            }
            items.add(item);
        }
        insert items;
        
        Test.startTest();
        EnrollmentMarketingMilestoneReportCtrl.getEnrollmentMarketingMilestone();
        EnrollmentMarketingMilestoneReportCtrl controller = new EnrollmentMarketingMilestoneReportCtrl();
        Test.stopTest();
    }

    @isTest
    public static void testBioStarOpp() {

        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');

		//create account
		Account acct = new Account();
		acct.name = 'Test Acct BioStar';
		insert acct;

        //create opportunity
        Opportunity opp = new Opportunity();
        opp.name = 'Test Opp BioStar';
        opp.StageName = 'Stage 3 - Review';
        opp.accountId = acct.id;
        opp.CloseDate = System.today();
        opp.Estimated_Project_Cost__c = 100;
        opp.RecordTypeId = '0120g000000gregAAA';
        opp.Referral_Source__c = 'BioStar';
        insert opp;
        
        //create Action List
        CSC_Action_List__c actionList = new CSC_Action_List__c();
        actionList.Action_List_Name__c = 'Test List Name BioStar';
        actionList.Account__c = acct.Id;
        actionList.Opportunity__c = opp.Id;
        actionList.Library_Type__c = 'Underwriting';
        actionList.Status__c = 'New';
        actionList.Order__c = 1;
        actionList.Template__c = false;
        actionList.Opportunity_Record_Type__c = 'FOF';
        insert actionList;
        
        //create Action Items
        List<CSC_Action_Item__c> items = new List<CSC_Action_Item__c>();
        for(Integer i = 0; i < 4; i++){
            CSC_Action_Item__c item = CSCTestUtil.createActionItem(actionList.Id, i);
            switch on i{
                when 0 {item.Action_Item_Name__c = 'Collect pre-qualification information';}
                when 1 {item.Action_Item_Name__c = 'Present Enrollment Marketing pitch deck to Prospect';}
                when 2 {item.Action_Item_Name__c = 'Approve Enrollment Marketing client for contracting';}
                when else {item.Action_Item_Name__c = 'Receive signed contract';}
            }
            items.add(item);
        }
        insert items;
        
        Test.startTest();
        EnrollmentMarketingMilestoneReportCtrl.getEnrollmentMarketingMilestone();
        EnrollmentMarketingMilestoneReportCtrl controller = new EnrollmentMarketingMilestoneReportCtrl();
        Test.stopTest();
    }

    @isTest
    public static void testOtherOpp() {

        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');

		//create account
		Account acct = new Account();
		acct.name = 'Test Acct Other';
		insert acct;

        //create opportunity
        Opportunity opp = new Opportunity();
        opp.name = 'Test Opp Other';
        opp.StageName = 'Stage 3 - Review';
        opp.accountId = acct.id;
        opp.CloseDate = System.today();
        opp.Estimated_Project_Cost__c = 100;
        opp.RecordTypeId = '0120g000000gregAAA';
        opp.Referral_Source__c = 'Other';
        insert opp;
        
        //create Action List
        CSC_Action_List__c actionList = new CSC_Action_List__c();
        actionList.Action_List_Name__c = 'Test List Name Other';
        actionList.Account__c = acct.Id;
        actionList.Opportunity__c = opp.Id;
        actionList.Library_Type__c = 'Underwriting';
        actionList.Status__c = 'New';
        actionList.Order__c = 1;
        actionList.Template__c = false;
        actionList.Opportunity_Record_Type__c = 'FOF';
        insert actionList;
        
        //create Action Items
        List<CSC_Action_Item__c> items = new List<CSC_Action_Item__c>();
        for(Integer i = 0; i < 4; i++){
            CSC_Action_Item__c item = CSCTestUtil.createActionItem(actionList.Id, i);
            switch on i{
                when 0 {item.Action_Item_Name__c = 'Collect pre-qualification information';}
                when 1 {item.Action_Item_Name__c = 'Present Enrollment Marketing pitch deck to Prospect';}
                when 2 {item.Action_Item_Name__c = 'Approve Enrollment Marketing client for contracting';}
                when else {item.Action_Item_Name__c = 'Receive signed contract';}
            }
            items.add(item);
        }
        insert items;
        
        Test.startTest();
        EnrollmentMarketingMilestoneReportCtrl.getEnrollmentMarketingMilestone();
        EnrollmentMarketingMilestoneReportCtrl controller = new EnrollmentMarketingMilestoneReportCtrl();
        Test.stopTest();
    }
}