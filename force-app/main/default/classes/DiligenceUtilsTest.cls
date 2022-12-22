@isTest
private class DiligenceUtilsTest {
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

        CSC_Action_List__c actionList = TestDiligenceUtils.getActionList(acct);
        insert actionList;

        CSC_Action_Item__c actionItem = TestDiligenceUtils.getActionItem(actionList);
        insert actionItem;

        Opportunity opp = TestDiligenceUtils.getOpportunity(acct);
        insert opp;

        Contact con = TestDiligenceUtils.getContact(acct);
        insert con;

        User u = TestDiligenceUtils.getUser(con, true);
    }

    @isTest
    private static void testSendCommunityEmailsForOpportunityDiligence() {
        Account charterHolder = [ SELECT Id FROM Account ];
        Contact con = [ SELECT Id FROM Contact ];

        Opportunity opp = TestDiligenceUtils.getOpportunity(charterHolder);
        insert opp;

        Intake_Item__c item = TestDiligenceUtils.getDiligenceItem(opp);
        insert item;

        Community_Contact_Role__c ccr = TestDiligenceUtils.getCCR(con, opp);
        insert ccr;

        EmailProviderMock mock = new EmailProviderMock();
        DiligenceUtils.emailSvc = mock;

        System.assertEquals(0, mock.emails.size());

        Test.startTest();
        DiligenceUtils.sendCommunityEmails([
            SELECT Id, Is_Ongoing__c, Account_Name__c, Opportunity__c, Status__c, Assigned_To__c
            FROM Intake_Item__c
        ], false);
        Test.stopTest();

        System.assertEquals(1, mock.emails.size());
        System.assertEquals(con.Id, mock.emails.get(0).getTargetObjectId());
        System.assertEquals(item.Id, mock.emails.get(0).getWhatId());
    }

    @isTest
    private static void testSendCommunityEmailsForOngoingDiligenceOnCharterHolder() {
        Account charterHolder = [ SELECT Id FROM Account ];
        Contact con = [ SELECT Id FROM Contact ];

        Intake_Item__c item = TestDiligenceUtils.getOngoingDiligenceItem(charterHolder);
        insert item;

        Community_Contact_Role__c ccr = TestDiligenceUtils.getCCR(con, charterHolder);
        insert ccr;

        EmailProviderMock mock = new EmailProviderMock();
        DiligenceUtils.emailSvc = mock;

        System.assertEquals(0, mock.emails.size());

        Test.startTest();
        DiligenceUtils.sendCommunityEmails([
            SELECT Id, Is_Ongoing__c, Account_Name__c, Opportunity__c, Status__c, Assigned_To__c
            FROM Intake_Item__c
        ], false);
        Test.stopTest();

        System.assertEquals(1, mock.emails.size());
        System.assertEquals(con.Id, mock.emails.get(0).getTargetObjectId());
        System.assertEquals(item.Id, mock.emails.get(0).getWhatId());
    }

    @isTest
    private static void testSendCommunityEmailsForOngoingDiligenceOnSchool() {
        Account charterHolder = [ SELECT Id FROM Account ];
        Contact con = [ SELECT Id FROM Contact ];

        Account school = TestDiligenceUtils.getSchool(charterHolder);
        insert school;

        Intake_Item__c item = TestDiligenceUtils.getOngoingDiligenceItem(school);
        insert item;

        Community_Contact_Role__c ccr = TestDiligenceUtils.getCCR(con, charterHolder);
        insert ccr;

        EmailProviderMock mock = new EmailProviderMock();
        DiligenceUtils.emailSvc = mock;

        System.assertEquals(0, mock.emails.size());

        Test.startTest();
        DiligenceUtils.sendCommunityEmails([
            SELECT Id, Is_Ongoing__c, Account_Name__c, Opportunity__c, Status__c, Assigned_To__c
            FROM Intake_Item__c
        ], false);
        Test.stopTest();

        System.assertEquals(1, mock.emails.size());
        System.assertEquals(con.Id, mock.emails.get(0).getTargetObjectId());
        System.assertEquals(item.Id, mock.emails.get(0).getWhatId());
    }

    @isTest
    private static void testCreateOngoingDiligence() {
        System.assertEquals(0, [ SELECT COUNT() FROM Intake_Item__c ]);
        Test.startTest();
        DiligenceUtils.createOngoingDiligence(new Map<Id,CSC_Action_Item__c>([ SELECT Id FROM CSC_Action_Item__c ]).keySet());
        Test.stopTest();
        System.assertEquals(2, [ SELECT COUNT() FROM Intake_Item__c ]);
        System.assertEquals(1, [ SELECT COUNT() FROM Intake_Item__c WHERE Parent_Intake_Item__c = null ]);
    }

    @isTest
    private static void testCreateOngoingDiligenceUpdateExisting() {
        Account acct = [ SELECT Id FROM Account ];

        Intake_Item__c item = TestDiligenceUtils.getOngoingDiligenceItem(acct);
        insert item;
        Intake_Item__c itemChild = TestDiligenceUtils.getOngoingDiligenceItem(acct, item);
        insert itemChild;

        Test.startTest();
        DiligenceUtils.createOngoingDiligence(new Map<Id,CSC_Action_Item__c>([ SELECT Id FROM CSC_Action_Item__c ]).keySet());
        Test.stopTest();

        System.assertEquals(2, [ SELECT COUNT() FROM Intake_Item__c ]);
        System.assertEquals(2, [ SELECT COUNT() FROM Intake_Item__c WHERE Id IN (:item.Id, :itemChild.Id) ]);
    }
}