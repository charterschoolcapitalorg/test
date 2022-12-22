@isTest
private with sharing class DiligenceCheckListControllerTest {

  @testSetup
  private static void setup(){
      State_Province__c state = TestDiligenceUtils.getState('PA', 'Pennsylvania');
      insert state;

      Intake_Item_Template__c iiTpl = TestDiligenceUtils.getOngoingDiligenceTemplate();
      iiTpl.State__c = 'PENNSYLVANIA';
      insert iiTpl;

      Intake_Item_Template__c iiTplChild = TestDiligenceUtils.getOngoingDiligenceTemplate(iiTpl);
      iiTplChild.State__c = 'PENNSYLVANIA';
      insert iiTplChild;

      Account acct = TestDiligenceUtils.getCharterHolder();
      acct.Operating_State__c = state.Id;
      insert acct;

      Account school = TestDiligenceUtils.getSchool(acct);
      insert school;
      
      Account prop = TestDiligenceUtils.getProperty();
      insert prop;
      
      Contact con = TestDiligenceUtils.getContact(acct);
      insert con;

      User u = TestDiligenceUtils.getUser(con, true);
      Profile PROFILE = [ SELECT Id FROM Profile WHERE Name = 'CSC - System Administrator' ];
      User ud1 = new User(
            FirstName = 'test',
            LastName = 'Diligence',
            Alias = 'testD1',
            Email = 'testd1@test.com',
            Username = 'testd1@test.com',
            ContactId = null,
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'ISO-8859-1',
            LocaleSidKey = 'en_CA',
            IsActive = true,
            ProfileId = PROFILE.Id
        );
        insert ud1;

      Lease__c lease = TestDiligenceUtils.getLease(prop);
      lease.Lease_Status__c = 'Active';
      lease.Account__c = school.Id;
      insert lease;

      Lease_School__c leaseSchool = TestDiligenceUtils.getLeaseSchool(lease, school);
      insert leaseSchool;

      CSC_Action_List__c actionList = TestDiligenceUtils.getActionList(acct);
      actionList.Active_OD__c = true;
      insert actionList;
      
      CSC_Action_List__c actionList2 = TestDiligenceUtils.getActionList(school);
      actionList.Active_OD__c = true;
      insert actionList2;

      CSC_Action_Item__c actionItem = TestDiligenceUtils.getActionItem(actionList);
      actionItem.Ongoing_Diligence_Item__c = true;
      actionItem.Assigned_To__c = ud1.Id;
      actionItem.Must_have_CP_item__c = true;
      insert actionItem;
      
      CSC_Action_Item__c actionItem2 = TestDiligenceUtils.getActionItem(actionList2);
      actionItem.Ongoing_Diligence_Item__c = true;
      actionItem.Assigned_To__c = ud1.Id;
      actionItem.Must_have_CP_item__c = false;
      insert actionItem2;

      Opportunity opp = TestDiligenceUtils.getOpportunity(acct);
      insert opp;
      
      Opportunity opp2 = TestDiligenceUtils.getOpportunity(school);
      insert opp2;
      
      Intake_Item__c intake = TestDiligenceUtils.getDiligenceItem(opp);
      intake.CSC_Action_Item__c = actionItem.Id;
      intake.Status__c = 'Additional Input Needed';
      insert intake;
      
      Intake_Item__c intake2 = TestDiligenceUtils.getDiligenceItem(opp);
      intake.CSC_Action_Item__c = actionList2.Id;
      intake.Status__c = 'Additional Input Needed';
      insert intake2;
  }

  @isTest
  private static void testGetOngoingDiligence() {
      User u = [SELECT Id FROM User WHERE Alias = 'testD1'];
      Test.startTest();    
      List<DiligenceCheckListController.reportWrapper> testList = DiligenceCheckListController.getInitialData('Budget', null, null, null, null, null, null);
      List<DiligenceCheckListController.reportWrapper> testList1 = DiligenceCheckListController.getInitialData(null, 'CSC Owned', null, null, null, null, null);
      List<DiligenceCheckListController.reportWrapper> testList2 = DiligenceCheckListController.getInitialData(null, null, 'Additional Input Needed', null, null, null, null);
      List<DiligenceCheckListController.reportWrapper> testList3 = DiligenceCheckListController.getInitialData(null, null, null, Date.today(), null, null, null);
      List<DiligenceCheckListController.reportWrapper> testList4 = DiligenceCheckListController.getInitialData(null, null, null, null, Date.today(), null, null);
      List<DiligenceCheckListController.reportWrapper> testList5 = DiligenceCheckListController.getInitialData(null, null, null, null, null, u.Id, null);
      List<DiligenceCheckListController.reportWrapper> testList6 = DiligenceCheckListController.getInitialData(null, null, null, null, null, null, 'LISA');
      List<DiligenceCheckListController.reportWrapper> testList7 = DiligenceCheckListController.getInitialData('Budget', 'CSC Owned', 'Additional Input Needed', Date.today(), Date.today(), u.Id, null);

      Map<String, List<DiligenceCheckListController.PicklistOption>> testmap = DiligenceCheckListController.getPicklists();  
      Test.stopTest();
  }

}