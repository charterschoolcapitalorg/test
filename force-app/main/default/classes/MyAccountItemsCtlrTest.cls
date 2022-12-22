@isTest
private class MyAccountItemsCtlrTest {
    @testSetup
    private static void setup() {
        Account charterHolderAcct = TestDiligenceUtils.getCharterHolder();
        insert charterHolderAcct;
        Account schoolAcct = TestDiligenceUtils.getSchool(charterHolderAcct);
        insert schoolAcct;
        Contact con = TestDiligenceUtils.getContact(schoolAcct);
        insert con;
        TestDiligenceUtils.getUser(con, true);
        Community_Contact_Role__c ccr = TestDiligenceUtils.getCCR(con, schoolAcct);
        insert ccr;
        Intake_Item__c item = TestDiligenceUtils.getOngoingDiligenceItem(schoolAcct);
        insert item;
    }
    
    @isTest
    public static void testGetAccounts(){
        Contact con = [ SELECT Id FROM Contact ];
        User u = [ SELECT Id FROM User WHERE ContactId = :con.Id ];
        Account schoolAcct = [ SELECT Id FROM Account WHERE RecordTypeId = :RecordTypes.IDSchoolAccount ];

        Test.startTest();
        List<Account> accts = null;
        System.runAs(u) {
            accts = MyAccountItemsCtlr.getAccounts();
        }
        Test.stopTest();

        System.assertEquals(1, accts.size());
        System.assertEquals(schoolAcct.Id, accts.get(0).Id);
    }
}