@isTest
private class CreateConsolidatedAccessEmailTest {
    private static EmailProviderMock mock = new EmailProviderMock();
    private static Pattern TOKEN_PATTERN = Pattern.compile('[{][A-Za-z]+[}]');

    static {
        QueueableEmails.emailSvc = mock;
    }

    @isTest
    private static void testRegex() {
        System.assert(TOKEN_PATTERN.matcher('String contains a {TestToken}').find());
        System.assert(!TOKEN_PATTERN.matcher('String does not contain a Test Token').find());
    }

    @testSetup
    private static void setup(){
        Account acct = TestDiligenceUtils.getCharterHolder();
        insert acct;
        Contact con = TestDiligenceUtils.getContact(acct);
        insert con;
        TestDiligenceUtils.getUser(con, true);
        Opportunity opp = TestDiligenceUtils.getOpportunity(acct);
        insert opp;
        Community_Contact_Role__c ccr1 = TestDiligenceUtils.getCCR(con, acct);
        Community_Contact_Role__c ccr2 = TestDiligenceUtils.getCCR(con, opp);
        insert new List<Community_Contact_Role__c> { ccr1, ccr2 };
    }

    @isTest
    private static void testSchedulable() {
        Contact con = [ SELECT Id FROM Contact ];

        System.assertEquals(0, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Client_Notifications_Sent__c = true ]);
        System.assertEquals(2, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Client_Notifications_Sent__c = false ]);

        Test.startTest();
        new CreateConsolidatedAccessEmailSched().execute(null);
        Test.stopTest();

        System.assertEquals(1, mock.emails.size());
        System.assertEquals(con.Id, mock.emails.get(0).getTargetObjectId());
        System.assertEquals(2, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Client_Notifications_Sent__c = true ]);
        System.assertEquals(0, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Client_Notifications_Sent__c = false ]);

        Account acct = [ SELECT Id, Name FROM Account ];
        Opportunity opp = [ SELECT Id, Name FROM Opportunity ];

        System.assert(!TOKEN_PATTERN.matcher(mock.emails.get(0).getHtmlBody()).find(), mock.emails.get(0).getHtmlBody());
        System.assert(!TOKEN_PATTERN.matcher(mock.emails.get(0).getPlainTextBody()).find(), mock.emails.get(0).getPlainTextBody());
        System.assert(mock.emails.get(0).getHtmlBody().contains(acct.Name), mock.emails.get(0).getHtmlBody());
        System.assert(mock.emails.get(0).getHtmlBody().contains(opp.Name), mock.emails.get(0).getHtmlBody());
        System.assert(mock.emails.get(0).getPlainTextBody().contains(acct.Name), mock.emails.get(0).getPlainTextBody());
        System.assert(mock.emails.get(0).getPlainTextBody().contains(opp.Name), mock.emails.get(0).getPlainTextBody());
    }

    @isTest
    private static void testBatch() {
        Contact con = [ SELECT Id FROM Contact ];

        System.assertEquals(0, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Client_Notifications_Sent__c = true ]);
        System.assertEquals(2, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Client_Notifications_Sent__c = false ]);

        Test.startTest();
        Database.executeBatch(new CreateConsolidatedAccessEmail());
        Test.stopTest();

        System.assertEquals(1, mock.emails.size());
        System.assertEquals(con.Id, mock.emails.get(0).getTargetObjectId());
        System.assertEquals(2, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Client_Notifications_Sent__c = true ]);
        System.assertEquals(0, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Client_Notifications_Sent__c = false ]);

        Account acct = [ SELECT Id, Name FROM Account ];
        Opportunity opp = [ SELECT Id, Name FROM Opportunity ];

        System.assert(!TOKEN_PATTERN.matcher(mock.emails.get(0).getHtmlBody()).find(), mock.emails.get(0).getHtmlBody());
        System.assert(!TOKEN_PATTERN.matcher(mock.emails.get(0).getPlainTextBody()).find(), mock.emails.get(0).getPlainTextBody());
        System.assert(mock.emails.get(0).getHtmlBody().contains(acct.Name), mock.emails.get(0).getHtmlBody());
        System.assert(mock.emails.get(0).getHtmlBody().contains(opp.Name), mock.emails.get(0).getHtmlBody());
        System.assert(mock.emails.get(0).getPlainTextBody().contains(acct.Name), mock.emails.get(0).getPlainTextBody());
        System.assert(mock.emails.get(0).getPlainTextBody().contains(opp.Name), mock.emails.get(0).getPlainTextBody());
    }

    @isTest
    private static void testBatchAlreadySent() {
        List<Community_Contact_Role__c> ccrs = [ SELECT Id FROM Community_Contact_Role__c ];
        for (Community_Contact_Role__c ccr: ccrs) {
            ccr.Client_Notifications_Sent__c = true;
        }
        update ccrs;

        Contact con = [ SELECT Id FROM Contact ];

        Test.startTest();
        Database.executeBatch(new CreateConsolidatedAccessEmail());
        Test.stopTest();

        System.assertEquals(0, mock.emails.size());
    }

    @isTest
    private static void testEmailContent() {
        CreateConsolidatedAccessEmail batch = new CreateConsolidatedAccessEmail();

        Test.startTest();
        simulateBatch(batch);
        Test.stopTest();

        System.assertEquals(1, batch.queuedEmails.size());

        List<String> oppItems = batch.queuedEmails.values().get(0).renderOpps();
        List<String> acctItems = batch.queuedEmails.values().get(0).renderAccts();

        System.assertEquals(1, oppItems.size());
        System.assertEquals(1, acctItems.size());

        Opportunity opp = [ SELECT Id, Name FROM Opportunity ];
        Account acct = [ SELECT Id, Name FROM Account ];

        System.assertEquals(acct.Name, acctItems.get(0));
        System.assertEquals(opp.Name, oppItems.get(0));
    }

    private static void simulateBatch(CreateConsolidatedAccessEmail b) {
        Database.QueryLocator ql = b.start(null);
        List<Community_Contact_Role__c> scope = Database.query(ql.getQuery());
        b.execute(null, scope);
        b.finish(null);
    }
}