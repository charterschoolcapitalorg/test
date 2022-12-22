@isTest
private class CreateWeeklyClientStatusEmailTest {
    private static EmailProviderMock mock = new EmailProviderMock();
    private static Pattern TOKEN_PATTERN = Pattern.compile('[{][A-Za-z]+[}]');

    static {
        QueueableEmails.emailSvc = mock;
    }

    @testSetup
    private static void setup() {
        Account charterHolderAcct = TestDiligenceUtils.getCharterHolder();
        insert charterHolderAcct;

        Account schoolAcct = TestDiligenceUtils.getSchool(charterHolderAcct);
        insert schoolAcct;

        Contact con = TestDiligenceUtils.getContact(schoolAcct);
        insert con;

        Opportunity opp = TestDiligenceUtils.getOpportunity(charterHolderAcct);
        insert opp;

        User u = TestDiligenceUtils.getUser(con, true);

        Community_Contact_Role__c ccrAcct = TestDiligenceUtils.getCCR(con, charterHolderAcct);
        Community_Contact_Role__c ccrOpp = TestDiligenceUtils.getCCR(con, opp);
        insert new List<Community_Contact_Role__c> { ccrAcct, ccrOpp };

        Intake_Item__c ii1 = TestDiligenceUtils.getOngoingDiligenceItem(schoolAcct);
        Intake_Item__c ii2 = TestDiligenceUtils.getOngoingDiligenceItem(schoolAcct);
        Intake_Item__c ii3 = TestDiligenceUtils.getDiligenceItem(opp);
        ii1.Client_Facing_Item_Name__c = 'Ongoing Item 1';
        ii2.Client_Facing_Item_Name__c = 'Ongoing Item 2';
        ii3.Client_Facing_Item_Name__c = 'Parent Opp Item';
        insert new List<Intake_Item__c> { ii1, ii2, ii3 };

        Intake_Item__c ii4 = TestDiligenceUtils.getDiligenceItem(opp, ii3);
        Intake_Item__c ii5 = TestDiligenceUtils.getDiligenceItem(opp, ii3);
        ii4.Client_Facing_Item_Name__c = 'Opp Item 1';
        ii5.Client_Facing_Item_Name__c = 'Opp Item 2';
        insert new List<Intake_Item__c> { ii4, ii5 };

        System.assertEquals(4, [
            SELECT COUNT()
            FROM Intake_Item__c
            WHERE Send_Weekly_Reminder__c = true
            AND (Is_Ongoing__c = true OR Parent_Intake_Item__c != null)
        ]);
    }

    @isTest
    private static void testRegex() {
        System.assert(TOKEN_PATTERN.matcher('String contains a {TestToken}').find());
        System.assert(!TOKEN_PATTERN.matcher('String does not contain a Test Token').find());
    }

    @isTest
    public static void testBatch() {
        Test.startTest();
        Database.executeBatch(new CreateWeeklyClientStatusEmail());
        Test.stopTest();

        System.assertEquals(1, mock.emails.size());

        System.assert(!TOKEN_PATTERN.matcher(mock.emails.get(0).getHtmlBody()).find(), mock.emails.get(0).getHtmlBody());
        System.assert(!TOKEN_PATTERN.matcher(mock.emails.get(0).getPlainTextBody()).find(), mock.emails.get(0).getPlainTextBody());
        System.assert(mock.emails.get(0).getHtmlBody().contains('2 Outstanding Diligence Item(s)'), mock.emails.get(0).getHtmlBody());
        System.assert(mock.emails.get(0).getPlainTextBody().contains('2 Outstanding Diligence Item(s)'), mock.emails.get(0).getPlainTextBody());
    }

    @isTest
    public static void testSchedulable() {
        Test.startTest();
        new CreateWeeklyClientStatusEmailSched().execute(null);
        Test.stopTest();

        System.assertEquals(1, mock.emails.size());

        System.assert(!TOKEN_PATTERN.matcher(mock.emails.get(0).getHtmlBody()).find(), mock.emails.get(0).getHtmlBody());
        System.assert(!TOKEN_PATTERN.matcher(mock.emails.get(0).getPlainTextBody()).find(), mock.emails.get(0).getPlainTextBody());
        System.assert(mock.emails.get(0).getHtmlBody().contains('2 Outstanding Diligence Item(s)'), mock.emails.get(0).getHtmlBody());
        System.assert(mock.emails.get(0).getPlainTextBody().contains('2 Outstanding Diligence Item(s)'), mock.emails.get(0).getPlainTextBody());
    }

    @isTest
    public static void testEmailContent() {
        CreateWeeklyClientStatusEmail batch = new CreateWeeklyClientStatusEmail();

        Test.startTest();
        simulateBatch(batch);
        Test.stopTest();

        System.assertEquals(1, batch.queuedEmails.size());

        List<String> oppItems = batch.queuedEmails.get(0).renderOpps();
        List<String> acctItems = batch.queuedEmails.get(0).renderAccts();
        List<String> upcomingItems = batch.queuedEmails.get(0).renderUpcoming();
        List<String> pastDueItems = batch.queuedEmails.get(0).renderPastDue();

        System.assertEquals(1, oppItems.size(), String.join(oppItems, ', '));
        System.assertEquals(1, acctItems.size(), String.join(acctItems, ', '));
        System.assertEquals(0, upcomingItems.size());
        System.assertEquals(0, pastDueItems.size());

        Opportunity opp = [ SELECT Id, Name FROM Opportunity ];
        Account acct = [ SELECT Id, Name FROM Account WHERE RecordTypeId = :RecordTypes.IDSchoolAccount ];

        System.assertEquals(acct.Name+': 2 Outstanding Diligence Item(s) (as of this email), due by '+Date.today().format(), acctItems.get(0));
        System.assertEquals(opp.Name+': 2 Outstanding Diligence Item(s) (as of this email), due by '+Date.today().format(), oppItems.get(0));
    }

    @isTest
    public static void testEmailContentUpcomingClientAlertDays() {
        Test.startTest();
        Date newDueDate = Date.today().addDays(14);
        List<Intake_Item__c> items = [ SELECT Id FROM Intake_Item__c ];
        for (Intake_Item__c item: items) {
            item.Due_Date__c = newDueDate;
            item.Client_Alert_Days__c = 14;
        }
        update items;

        CreateWeeklyClientStatusEmail batch = new CreateWeeklyClientStatusEmail();
        simulateBatch(batch);
        Test.stopTest();

        System.assertEquals(1, batch.queuedEmails.size());

        List<String> oppItems = batch.queuedEmails.get(0).renderOpps();
        List<String> acctItems = batch.queuedEmails.get(0).renderAccts();
        List<String> upcomingItems = batch.queuedEmails.get(0).renderUpcoming();
        List<String> pastDueItems = batch.queuedEmails.get(0).renderPastDue();

        System.assertEquals(0, oppItems.size());
        System.assertEquals(0, acctItems.size());
        System.assertEquals(4, upcomingItems.size());
        System.assertEquals(0, pastDueItems.size());

        Opportunity opp = [ SELECT Id, Name FROM Opportunity ];
        Account acct = [ SELECT Id, Name FROM Account WHERE RecordTypeId = :RecordTypes.IDSchoolAccount ];

        System.assert(upcomingItems.contains('Ongoing Item 1 is due on '+newDueDate.format()));
        System.assert(upcomingItems.contains('Ongoing Item 2 is due on '+newDueDate.format()));
        System.assert(upcomingItems.contains('Opp Item 1 is due on '+newDueDate.format()));
        System.assert(upcomingItems.contains('Opp Item 2 is due on '+newDueDate.format()));
    }

    @isTest
    public static void testEmailContentUpcomingNoClientAlertDays() {
        Test.startTest();
        Date newDueDate = Date.today().addDays(14);
        List<Intake_Item__c> items = [ SELECT Id FROM Intake_Item__c ];
        for (Intake_Item__c item: items) {
            item.Due_Date__c = newDueDate;
        }
        update items;

        CreateWeeklyClientStatusEmail batch = new CreateWeeklyClientStatusEmail();
        simulateBatch(batch);
        Test.stopTest();

        System.assertEquals(0, batch.queuedEmails.size());
    }

    @isTest
    public static void testEmailContentPastDue() {
        Test.startTest();
        Date newDueDate = Date.today().addDays(-1);
        List<Intake_Item__c> items = [ SELECT Id FROM Intake_Item__c ];
        for (Intake_Item__c item: items) {
            item.Due_Date__c = newDueDate;
        }
        update items;

        CreateWeeklyClientStatusEmail batch = new CreateWeeklyClientStatusEmail();
        simulateBatch(batch);
        Test.stopTest();

        System.assertEquals(1, batch.queuedEmails.size());

        List<String> oppItems = batch.queuedEmails.get(0).renderOpps();
        List<String> acctItems = batch.queuedEmails.get(0).renderAccts();
        List<String> upcomingItems = batch.queuedEmails.get(0).renderUpcoming();
        List<String> pastDueItems = batch.queuedEmails.get(0).renderPastDue();

        System.assertEquals(0, oppItems.size());
        System.assertEquals(0, acctItems.size());
        System.assertEquals(0, upcomingItems.size());
        System.assertEquals(2, pastDueItems.size());

        Opportunity opp = [ SELECT Id, Name FROM Opportunity ];
        Account acct = [ SELECT Id, Name FROM Account WHERE RecordTypeId = :RecordTypes.IDSchoolAccount ];

        System.assert(pastDueItems.contains('Ongoing Item 1 was due on '+newDueDate.format()));
        System.assert(pastDueItems.contains('Ongoing Item 2 was due on '+newDueDate.format()));
    }

    @isTest
    public static void testFormatting() {
        System.assertEquals('<h3 style="padding-left: 20px">Test Heading</h3><ul><li>Item 1</li><li>Item 2</li></ul>', CreateWeeklyClientStatusEmail.formatSectionHtml('Test Heading', new List<String> { 'Item 1', 'Item 2' }));
        System.assertEquals('<h3 style="padding-left: 20px">Test Heading</h3><ul><li>Item 1</li></ul>', CreateWeeklyClientStatusEmail.formatSectionHtml('Test Heading', new List<String> { 'Item 1' }));
        System.assertEquals('', CreateWeeklyClientStatusEmail.formatSectionHtml('Test Heading', new List<String> { }));

        System.assertEquals('Test Heading:\n * Item 1\n * Item 2\n\n', CreateWeeklyClientStatusEmail.formatSectionText('Test Heading', new List<String> { 'Item 1', 'Item 2' }));
        System.assertEquals('Test Heading:\n * Item 1\n\n', CreateWeeklyClientStatusEmail.formatSectionText('Test Heading', new List<String> { 'Item 1' }));
        System.assertEquals('', CreateWeeklyClientStatusEmail.formatSectionText('Test Heading', new List<String> { }));
    }

    private static void simulateBatch(CreateWeeklyClientStatusEmail b) {
        Database.QueryLocator ql = b.start(null);
        List<CustomPortalEmailsToSend__mdt> scope = Database.query(ql.getQuery());
        b.execute(null, scope);
        b.finish(null);
    }
}