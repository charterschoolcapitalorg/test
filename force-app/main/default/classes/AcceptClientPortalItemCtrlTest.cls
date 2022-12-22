@isTest
private class AcceptClientPortalItemCtrlTest {
    @testSetup
    private static void setup() {
        Account charterHolderAcct = TestDiligenceUtils.getCharterHolder();
        insert charterHolderAcct;

        Account schoolAcct = TestDiligenceUtils.getSchool(charterHolderAcct);
        insert schoolAcct;

        Intake_Item__c ii = TestDiligenceUtils.getOngoingDiligenceItem(schoolAcct);
        ii.Client_Comments__c = 'Test Client Comment';
        ii.Status__c = 'Submitted';
        insert ii;

        ContentVersion file = TestDiligenceUtils.getFile(ii);
        insert file;

        CSC_Action_List__c actionList = TestDiligenceUtils.getActionList(schoolAcct);
        insert actionList;

        CSC_Action_Item__c actionItem = TestDiligenceUtils.getActionItem(actionList);
        insert actionItem;

        Account prop = TestDiligenceUtils.getProperty();
        insert prop;

        Lease__c lease = TestDiligenceUtils.getLease(prop);
        lease.Lease_Status__c = 'Active';
        insert lease;

        Lease_School__c leaseSchool = TestDiligenceUtils.getLeaseSchool(lease, schoolAcct);
        insert leaseSchool;

        Lease_Compliance__c leaseCompliance = TestDiligenceUtils.getLeaseCompliance(lease);
        insert leaseCompliance;
    }

    @isTest
    private static void testGetLeaseComplianceItem() {
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];

        Test.startTest();
        List<Lease_Compliance__c> lcs = AcceptClientPortalItemCtrl.getLeaseComplianceItem(ii.Id);
        Test.stopTest();

        System.assertEquals(1, lcs.size());
    }

    @isTest
    private static void testSaveNoActionItems() {
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];

        Test.startTest();
        AcceptClientPortalItemCtrl.saveNoActionItems(ii.Id);
        Test.stopTest();

        ii = [ SELECT Id, Status__c, Status_Changed_from_UI__c FROM Intake_Item__c WHERE Is_Ongoing__c = true ];
        System.assertEquals('Accepted', ii.Status__c);
        System.assertEquals(true, ii.Status_Changed_from_UI__c);
    }

    @isTest
    private static void testSaveActionItem() {
        CSC_Action_Item__c ai = [ SELECT Id FROM CSC_Action_Item__c ];
        ContentDocument doc = [ SELECT Id FROM ContentDocument ];
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];

        Test.startTest();
        AcceptClientPortalItemCtrl.saveActionItem(
            String.valueOf(ii.Id),
            String.valueOf(ai.Id),
            'Completed',
            String.valueOf(doc.Id),
            'true',
            'Test CSC Comment',
            '2021-01-01',
            '2021-01-01',
            '2021-01-01',
            '2021-01-01',
            'true'
        );
        Test.stopTest();

        ii = [ SELECT Id, Status__c FROM Intake_Item__c ];
        ai = [ SELECT Id, CSC_Action_List__r.Account__c, Status__c, Action_Item_Mapping__c, CSC_Team_Comment__c, Comments__c, Date_Effective__c, Expiration_Date__c, Next_Action_Date__c FROM CSC_Action_Item__c ];

        Financial__c fin = [ SELECT Id, Action_Item__c, Account__c, Data_Source__c FROM Financial__c ];
        
        System.assertEquals('Accepted', ii.Status__c);
        System.assertEquals('Completed', ai.Status__c);

        System.assertEquals(1, [ SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :ai.Id ]);
        System.assertEquals(1, [ SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :fin.Id ]);

        System.assertEquals(ai.Id, fin.Action_Item__c);
        System.assertEquals(ai.CSC_Action_List__r.Account__c, fin.Account__c);
        System.assertEquals(ai.Action_Item_Mapping__c, fin.Data_Source__c);

        System.assertEquals(Date.newInstance(2021, 1, 1), ai.Date_Effective__c);
        System.assertEquals(Date.newInstance(2021, 1, 1), ai.Expiration_Date__c);
        System.assertEquals(Date.newInstance(2021, 1, 1), ai.Next_Action_Date__c);

        System.assertEquals('Test CSC Comment \n Per Client '+formatDate()+' - Test Client Comment', ai.Comments__c);
        System.assertEquals('Test CSC Comment', ai.CSC_Team_Comment__c);
    }

    @isTest
    private static void testSaveLeaseCompliance() {
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];
        Lease_Compliance__c lc = [ SELECT Id FROM Lease_Compliance__c ];
        ContentDocument doc = [ SELECT Id FROM ContentDocument ];

        Test.startTest();
        AcceptClientPortalItemCtrl.saveLeaseCompliance(
            String.valueOf(ii.Id),
            String.valueOf(lc.Id),
            doc.Id,
            'true',
            'Test CSC Comment'
        );
        Test.stopTest();

        ii = [ SELECT Id, Status__c FROM Intake_Item__c ];
        lc = [ SELECT Id, RecordType.DeveloperName, Received_Date__c, Action_Item_Mapping__c, Lease__r.Account__c, Comments__c FROM Lease_Compliance__c ];

        // Financial__c fin = [ SELECT Id, Lease__c, Account__c, Data_Source__c FROM Financial__c ];
        
        System.assertEquals('Accepted', ii.Status__c);
        // System.assertEquals('Current', lc.RecordType.DeveloperName);

        System.assertEquals(1, [ SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :lc.Id ]);
        // System.assertEquals(1, [ SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :fin.Id ]);

        // System.assertEquals(lc.Lease__c, fin.Lease__c);
        // System.assertEquals(lc.Lease__r.Account__c, fin.Account__c);
        // System.assertEquals(lc.Action_Item_Mapping__c, fin.Data_Source__c);

        System.assertEquals('Test CSC Comment \n Per Client '+formatDate()+' - Test Client Comment', lc.Comments__c);
    }

    @isTest
    private static void testGetMappedItems() {
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];

        Test.startTest();
        List<CSC_Action_Item__c> items = AcceptClientPortalItemCtrl.getMappedItems(ii.Id);
        Test.stopTest();

        Set<Id> allActionItemIds = new Set<Id>();
        for (CSC_Action_Item__c item: items) {
            allActionItemIds.add(item.Id);
        }

        System.assertEquals(1, allActionItemIds.size());
    }

    @isTest
    private static void testGetCharterACLItems() {
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];

        Test.startTest();
        List<CSC_Action_Item__c> items = AcceptClientPortalItemCtrl.getCharterACLItems(ii.Id);
        Test.stopTest();

        System.assertEquals(0, items.size());
    }

    @isTest
    private static void testGetSchoolACLItems() {
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];

        Test.startTest();
        List<CSC_Action_Item__c> items = AcceptClientPortalItemCtrl.getSchoolACLItems(ii.Id);
        Test.stopTest();

        System.assertEquals(1, items.size());
    }

    @isTest
    private static void testGetPCLItems() {
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];

        Test.startTest();
        List<CSC_Action_Item__c> items = AcceptClientPortalItemCtrl.getPCLItems(ii.Id);
        Test.stopTest();

        System.assertEquals(0, items.size());
    }

    @isTest
    public static void testGetters(){
        System.assertEquals(RecordType.getSObjectType(), AcceptClientPortalItemCtrl.getCharterALAcctType().getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), AcceptClientPortalItemCtrl.getSchoolALAcctType().getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), AcceptClientPortalItemCtrl.getPCLType().getSObjectType());
        System.assertEquals(UserInfo.getUiThemeDisplayed(), AcceptClientPortalItemCtrl.getUIThemeDescription());
        System.assertEquals(UserInfo.getUiTheme(), AcceptClientPortalItemCtrl.getUiTheme());
    }
    
    @isTest
    public static void testGetFiles(){
        Intake_Item__c ii = [ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ];

        Test.startTest();
        List<ContentDocument> docs = AcceptClientPortalItemCtrl.getFiles(ii.Id);
        Test.stopTest();

        System.assertEquals(1, docs.size());
    }

    private static String formatDate() {
        Date today = Date.today();
        return today.month()+'/'+today.day()+'/'+today.year();
    }
}