@IsTest
private with sharing class ActionListOngoingDiligenceCreationTests {

    @TestSetup
    static void createData(){
       TestHelper.createSeedDataForTesting();
       Lease__c lease = new Lease__c();
       insert lease;

       Account acc = new Account();
       acc.name = 'Test account';
       insert acc;

       CSC_Action_List__c actionList = new CSC_Action_List__c();
       actionList.Action_List_Name__c = 'File Review';
       actionList.Account__c = acc.Id;
       actionList.Template__c = true;
       actionList.Action_List_Mapping__c = 'Audit/Financials';
       insert actionList;

       CSC_Action_Item__c actionItem = new CSC_Action_Item__c();
       actionItem.CSC_Action_List__c = actionList.Id;
       actionItem.Action_Item_Name__c = 'Test Item';
       insert actionItem;

    }

    @IsTest
    static void testNoInsertLeaseSchool(){
        Account school = [SELECT Id, Name, RecordTypeId FROM Account WHERE RecordType.DeveloperName = 'School' LIMIT 1];

        Lease_School__c ls = new Lease_School__c();
        ls.Account_School__c = school.Id; 
        ls.Lease__c = [SELECT Id, Name, RecordTypeId FROM Lease__c LIMIT 1].Id;
        insert ls;

        List<ActionListOngoingDiligenceCreation.CreateActionListsRequest> calrs = new List<ActionListOngoingDiligenceCreation.CreateActionListsRequest>();
        ActionListOngoingDiligenceCreation.CreateActionListsRequest calr = new ActionListOngoingDiligenceCreation.CreateActionListsRequest();
        calr.schoolId = school.Id;
        calr.audit_AL = false;
        calr.fam_AL = false;
        calr.fileCharter_AL = false;
        calr.fileSchool_AL = false;
        calrs.add(calr);

        Test.startTest();
        ActionListOngoingDiligenceCreation.createLists(calrs);
        System.assertEquals(0, [SELECT Id FROM CSC_Action_List__c WHERE Account__c = :school.Id].size(), 'Should not be any');
        Test.stopTest();
    }

    @IsTest
    static void testInsertAuditLeaseSchool(){
        Account school = [SELECT Id, Name, RecordTypeId FROM Account WHERE RecordType.DeveloperName = 'School' LIMIT 1];

        Lease_School__c ls = new Lease_School__c();
        ls.Account_School__c = school.Id; 
        ls.Lease__c = [SELECT Id, Name, RecordTypeId FROM Lease__c LIMIT 1].Id;
        insert ls;

        List<ActionListOngoingDiligenceCreation.CreateActionListsRequest> calrs = new List<ActionListOngoingDiligenceCreation.CreateActionListsRequest>();
        ActionListOngoingDiligenceCreation.CreateActionListsRequest calr = new ActionListOngoingDiligenceCreation.CreateActionListsRequest();
        calr.schoolId = school.Id;
        calr.audit_AL = true;
        calr.fam_AL = false;
        calr.fileCharter_AL = false;
        calr.fileSchool_AL = false;
        calrs.add(calr);

        Test.startTest();
        ActionListOngoingDiligenceCreation.createLists(calrs);
        List<CSC_Action_List__c> newActionList = [SELECT Id, Active_OD__c, Template__c FROM CSC_Action_List__c WHERE Account__c = :school.Id];
        System.assertEquals(1, newActionList.size(), 'Should be one');
        System.assertEquals(true, newActionList[0].Active_OD__c, 'Should be an Active OD');
        System.assertEquals(false, newActionList[0].Template__c, 'Should not be a template');
        Test.stopTest();
    }

    @IsTest
    static void testInsertFileReviewCharterLeaseSchool(){
        Account school = [SELECT Id, Name, RecordTypeId, Charter_Holder__r.Id FROM Account WHERE RecordType.DeveloperName = 'School' LIMIT 1];

        Lease_School__c ls = new Lease_School__c();
        ls.Account_School__c = school.Id; 
        ls.Lease__c = [SELECT Id, Name, RecordTypeId FROM Lease__c LIMIT 1].Id;
        insert ls;

        CSC_Action_List__c actionList = [SELECT Id, Action_List_Mapping__c FROM CSC_Action_List__c WHERE Template__c = true LIMIT 1];
        actionList.Action_List_Mapping__c = 'File Review - Charter Holder';
        update actionList;

        List<ActionListOngoingDiligenceCreation.CreateActionListsRequest> calrs = new List<ActionListOngoingDiligenceCreation.CreateActionListsRequest>();
        ActionListOngoingDiligenceCreation.CreateActionListsRequest calr = new ActionListOngoingDiligenceCreation.CreateActionListsRequest();
        calr.schoolId = school.Id;
        calr.audit_AL = false;
        calr.fam_AL = false;
        calr.fileCharter_AL = true;
        calr.fileSchool_AL = false;
        calrs.add(calr);

        Test.startTest();
        ActionListOngoingDiligenceCreation.createLists(calrs);
        System.assertEquals(1, [SELECT Id FROM CSC_Action_List__c WHERE Account__c = :school.Charter_Holder__r.Id].size(), 'Should be one');
        System.assertEquals(0, [SELECT Id FROM CSC_Action_List__c WHERE Account__c = :school.Id].size(), 'Should not be any');
        Test.stopTest();
    }

    @IsTest
    static void testInsertFacilitiesLeaseSchool(){
        Account school = [SELECT Id, Name, RecordTypeId, Charter_Holder__r.Id FROM Account WHERE RecordType.DeveloperName = 'School' LIMIT 1];

        Lease_School__c ls = new Lease_School__c();
        ls.Account_School__c = school.Id; 
        ls.Lease__c = [SELECT Id, Name, RecordTypeId FROM Lease__c LIMIT 1].Id;
        insert ls;

        CSC_Action_List__c actionList = [SELECT Id, Action_List_Mapping__c FROM CSC_Action_List__c WHERE Template__c = true LIMIT 1];
        actionList.Action_List_Mapping__c = 'Facilities - Asset Management';
        update actionList;

        List<ActionListOngoingDiligenceCreation.CreateActionListsRequest> calrs = new List<ActionListOngoingDiligenceCreation.CreateActionListsRequest>();
        ActionListOngoingDiligenceCreation.CreateActionListsRequest calr = new ActionListOngoingDiligenceCreation.CreateActionListsRequest();
        calr.schoolId = school.Id;
        calr.audit_AL = false;
        calr.fam_AL = true;
        calr.fileCharter_AL = false;
        calr.fileSchool_AL = false;
        calrs.add(calr);

        Test.startTest();
        ActionListOngoingDiligenceCreation.createLists(calrs);
        System.assertEquals(0, [SELECT Id FROM CSC_Action_List__c WHERE Account__c = :school.Charter_Holder__r.Id].size(), 'Should not be any');
        System.assertEquals(1, [SELECT Id FROM CSC_Action_List__c WHERE Account__c = :school.Id].size(), 'Should be one');
        Test.stopTest();
    }    

    @IsTest
    static void testInsertFileReviewLeaseSchool(){
        Account school = [SELECT Id, Name, RecordTypeId, Charter_Holder__r.Id FROM Account WHERE RecordType.DeveloperName = 'School' LIMIT 1];

        Lease_School__c ls = new Lease_School__c();
        ls.Account_School__c = school.Id; 
        ls.Lease__c = [SELECT Id, Name, RecordTypeId FROM Lease__c LIMIT 1].Id;
        insert ls;

        CSC_Action_List__c actionList = [SELECT Id, Action_List_Mapping__c FROM CSC_Action_List__c WHERE Template__c = true LIMIT 1];
        actionList.Action_List_Mapping__c = 'File Review - School';
        update actionList;

        List<ActionListOngoingDiligenceCreation.CreateActionListsRequest> calrs = new List<ActionListOngoingDiligenceCreation.CreateActionListsRequest>();
        ActionListOngoingDiligenceCreation.CreateActionListsRequest calr = new ActionListOngoingDiligenceCreation.CreateActionListsRequest();
        calr.schoolId = school.Id;
        calr.audit_AL = false;
        calr.fam_AL = false;
        calr.fileCharter_AL = false;
        calr.fileSchool_AL = true;
        calrs.add(calr);

        Test.startTest();
        ActionListOngoingDiligenceCreation.createLists(calrs);
        System.assertEquals(0, [SELECT Id FROM CSC_Action_List__c WHERE Account__c = :school.Charter_Holder__r.Id].size(), 'Should not be any');
        System.assertEquals(1, [SELECT Id FROM CSC_Action_List__c WHERE Account__c = :school.Id].size(), 'Should be one');
        Test.stopTest();
    }  
}