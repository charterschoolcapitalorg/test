@isTest
private class ExpeditedDiligenceAlertControllerTest {
    private static final EmailProviderMock mock = new EmailProviderMock();

    static {
        QueueableEmails.emailSvc = mock;
    }

    @testSetup
    public static void setup() {
        Account charterHolderAcct = TestDiligenceUtils.getCharterHolder();
        insert charterHolderAcct;

        Account schoolAcct = TestDiligenceUtils.getSchool(charterHolderAcct);
        insert schoolAcct;

        Contact con = TestDiligenceUtils.getContact(schoolAcct);
        insert con;
    }

    private static Contact getContact() {
        return [
            SELECT Id, FirstName, LastName, Email
            FROM Contact
        ];
    }

    private static Account getCharterHolder() {
        return [ SELECT Id FROM Account WHERE RecordTypeId = :RecordTypes.IDCharterAccount ];
    }

    private static Account getSchool() {
        return [ SELECT Id FROM Account WHERE RecordTypeId = :RecordTypes.IDSchoolAccount ];
    }

    @isTest
    private static void testGetRelatedUsersEmpty() {
        Account charterHolderAcct = getCharterHolder();

        Test.startTest();
        List<Contact> usrs = ExpeditedDiligenceAlertController.getRelatedUsers(charterHolderAcct.Id);
        Test.stopTest();

        System.assert(usrs.isEmpty());
    }

    @isTest
    private static void testGetRelatedUsers() {
        Account charterHolderAcct = getCharterHolder();
        Account schoolAcct = getSchool();
        Contact con = getContact();
        User u = TestDiligenceUtils.getUser(con, true);
        Community_Contact_Role__c ccr = TestDiligenceUtils.getCCR(con, schoolAcct);
        insert ccr;

        Test.startTest();
        List<Contact> usrs = ExpeditedDiligenceAlertController.getRelatedUsers(charterHolderAcct.Id);
        Test.stopTest();

        System.assertEquals(1, usrs.size());
        System.assertEquals(con.Id, usrs.get(0).Id);
    }

    @isTest
    private static void testSendAlerts() {
        Account charterHolderAcct = getCharterHolder();
        Account schoolAcct = getSchool();
        Contact con = getContact();
        User u = TestDiligenceUtils.getUser(con, true);
        Community_Contact_Role__c ccr = TestDiligenceUtils.getCCR(con, charterHolderAcct);
        insert ccr;

        Intake_Item__c ii = TestDiligenceUtils.getOngoingDiligenceItem(schoolAcct);
        insert ii;

        System.assertEquals(false, [ SELECT Client_Alert_Sent__c FROM Intake_Item__c WHERE Id = :ii.Id ].Client_Alert_Sent__c);

        Test.startTest();
        Boolean result = ExpeditedDiligenceAlertController.sendAlerts(charterHolderAcct.Id, new List<Contact> { con });
        Test.stopTest();

        System.assertEquals(true, [ SELECT Client_Alert_Sent__c FROM Intake_Item__c WHERE Id = :ii.Id ].Client_Alert_Sent__c);
        System.assertEquals(true, result);

        System.assertEquals(1, mock.emails.size());
        System.assertEquals(con.Id, mock.emails.get(0).getTargetObjectId());
    }
}