@isTest
private class MyItemRowCtlrTest {
    @testSetup
    private static void setup() {
        Account acct = TestDiligenceUtils.getCharterHolder();
        insert acct;
        Opportunity opp = TestDiligenceUtils.getOpportunity(acct);
        insert opp;
        Intake_Item__c item = TestDiligenceUtils.getDiligenceItem(opp);
        item.Client_Comments__c = 'Test Comment';
        item.Status__c = 'Pending';
        insert item;
        ContentVersion cv = TestDiligenceUtils.getFile(item);
        cv.Title = 'Closing_Statement - TEST';
        insert cv;
    }

    @isTest
    private static void testGetItemDetails() {
        Intake_Item__c it = [ SELECT Id, Opportunity__r.Client_Facing_Opportunity_Name__c FROM Intake_Item__c ];

        Test.startTest();
        Map<String,Object> data = (Map<String,Object>)JSON.deserializeUntyped(MyItemRowCtlr.getItemDetail(it.Id));
        Test.stopTest();

        System.assertEquals('Action Required', data.get('status'));
        System.assertEquals(it.Opportunity__r.Client_Facing_Opportunity_Name__c, data.get('project'));
    }

    @isTest
    private static void testGetIntakeItem() {
        Intake_Item__c it = [ SELECT Id, Opportunity__r.Client_Facing_Opportunity_Name__c FROM Intake_Item__c ];

        Test.startTest();
        Intake_Item__c item = MyItemRowCtlr.getIntakeItem(it.Id);
        Test.stopTest();

        System.assertEquals(it.Id, item.Id);
    }

    private static void testGetOpportunity() {
        Opportunity it = [ SELECT Id FROM Opportunity ];

        Test.startTest();
        Opportunity item = MyItemRowCtlr.getOpportunity(it.Id);
        Test.stopTest();

        System.assertEquals(it.Id, item.Id);
    }

    @isTest
    private static void testGetIntakeItemWrapper() {
        Intake_Item__c it = [ SELECT Id, Opportunity__r.Client_Facing_Opportunity_Name__c FROM Intake_Item__c ];

        Test.startTest();
        IntakeItemWrapper wrap = MyItemRowCtlr.getIntakeItemWrapper(it.Id);
        Test.stopTest();

        System.assertEquals(it.Id, wrap.item.Id);
    }

    @isTest
    private static void testGetIntakeItemClientComments() {
        Intake_Item__c it = [ SELECT Id, Opportunity__r.Client_Facing_Opportunity_Name__c FROM Intake_Item__c ];

        Test.startTest();
        String comment = MyItemRowCtlr.getIntakeItemClientComments(it.Id);
        Test.stopTest();

        System.assertEquals('Test Comment', comment);
    }

    @isTest
    private static void getFiles() {
        Intake_Item__c it = [ SELECT Id, Opportunity__r.Client_Facing_Opportunity_Name__c FROM Intake_Item__c ];

        Test.startTest();
        List<ContentDocument> docs = MyItemRowCtlr.getFiles(it.Id);
        Test.stopTest();

        System.assertEquals(1, docs.size());
        System.assertEquals('Closing_Statement - TEST', docs.get(0).Title);
    }

    @isTest
    private static void getOppFiles() {
        Intake_Item__c it = [ SELECT Id, Opportunity__r.Client_Facing_Opportunity_Name__c FROM Intake_Item__c ];

        Test.startTest();
        List<ContentDocument> docs = MyItemRowCtlr.getOppFiles(it.Id);
        Test.stopTest();

        System.assertEquals(1, docs.size());
        System.assertEquals('Closing_Statement - TEST', docs.get(0).Title);
    }

    @isTest
    public static void testRecordTypes(){
        System.assertEquals(RecordType.getSObjectType(), MyItemRowCtlr.getIDFOFOpp().getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), MyItemRowCtlr.getIDIFOpp().getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), MyItemRowCtlr.getIDFacOpp().getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), MyItemRowCtlr.getIDInitialFundingIntake().getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), MyItemRowCtlr.getID5DFIntake().getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), MyItemRowCtlr.getIDFacilitiesIntakeItem().getSObjectType());
    }

    @isTest
    public static void testAcceptedStatus(){
        Intake_Item__c ii = [SELECT Id from Intake_Item__c ];
        Test.startTest();
        IntakeItemWrapper wrap = MyItemRowCtlr.acceptedStatus(ii.Id);
        Test.stopTest();

        System.assertEquals(ii.Id, wrap.item.Id);
        System.assertEquals(DiligenceVars.IntakeApprovedStatus, [ SELECT Status__c FROM Intake_Item__c ].Status__c);
    }

    @isTest
    private static void testGetDownloadFileURL() {
        Intake_Item__c ii = [ SELECT Id from Intake_Item__c ];

        Test.startTest();
        String ids = MyItemRowCtlr.getDownloadFileURL(ii.Id);
        Test.stopTest();

        System.assertEquals([SELECT Id FROM ContentVersion].Id, Id.valueOf(ids.replaceAll(',$', '')));
    }

    @isTest
    private static void testGetNumDocs() {
        Intake_Item__c ii = [ SELECT Id from Intake_Item__c ];

        Test.startTest();
        Integer docs = MyItemRowCtlr.getNumDocs(ii.Id);
        Test.stopTest();

        System.assertEquals(1, docs);
    }

    @isTest
    private static void testGetNextDocId() {
        Intake_Item__c ii = [ SELECT Id from Intake_Item__c ];

        Test.startTest();
        String docId = MyItemRowCtlr.getNextDocId(ii.Id, '');
        Test.stopTest();

        System.assertEquals('', docId);
    }

    @isTest
    private static void testGetPrevDocId() {
        Intake_Item__c ii = [ SELECT Id from Intake_Item__c ];

        Test.startTest();
        String docId = MyItemRowCtlr.getPrevDocId(ii.Id, '');
        Test.stopTest();

        System.assertEquals('', docId);
    }

    @isTest
    private static void testAddComment() {
        Intake_Item__c it = [ SELECT Id, Opportunity__r.Client_Facing_Opportunity_Name__c FROM Intake_Item__c ];

        Test.startTest();
        MyItemRowCtlr.addComment(it.Id, 'New Comment');
        Test.stopTest();

        it = [ SELECT Status__c, Client_Comments__c FROM Intake_Item__c ];
        System.assertEquals('New Comment', it.Client_Comments__c);
        System.assertEquals(DiligenceVars.IntakeSubmittedStatus, it.Status__c);
    }

    @isTest
    private static void testNoChanges() {
        Intake_Item__c it = [ SELECT Id, Opportunity__r.Client_Facing_Opportunity_Name__c FROM Intake_Item__c ];

        Test.startTest();
        MyItemRowCtlr.noChanges(it.Id);
        Test.stopTest();

        it = [ SELECT Status__c, Client_Comments__c FROM Intake_Item__c ];
        System.assert(it.Client_Comments__c.contains('No Changes as of'));
        System.assertEquals(DiligenceVars.IntakeSubmittedStatus, it.Status__c);
    }
}