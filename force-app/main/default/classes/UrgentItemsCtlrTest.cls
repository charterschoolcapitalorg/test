@isTest
public class UrgentItemsCtlrTest {
    @testSetup
    private static void setup() {
        Account acct = TestDiligenceUtils.getCharterHolder();
        insert acct;
        Opportunity opp = TestDiligenceUtils.getOpportunity(acct);
        insert opp;
        Contact con = TestDiligenceUtils.getContact(acct);
        insert con;
        TestDiligenceUtils.getUser(con, true);
        Community_Contact_Role__c ccr1 = TestDiligenceUtils.getCCR(con, acct);
        Community_Contact_Role__c ccr2 = TestDiligenceUtils.getCCR(con, opp);
        insert new List<Community_Contact_Role__c> { ccr1, ccr2 };

        Intake_Item__c acctItem = TestDiligenceUtils.getOngoingDiligenceItem(acct);
        Intake_Item__c oppItem = TestDiligenceUtils.getDiligenceItem(opp);
        acctItem.Due_Date__c = Date.today().addDays(-5);
        oppItem.Due_Date__c = Date.today().addDays(-4);
        insert new List<Intake_Item__c> { oppItem, acctItem };

        Intake_Item__c oppChildItem1 = TestDiligenceUtils.getDiligenceItem(opp, oppItem);
        Intake_Item__c oppChildItem2 = TestDiligenceUtils.getDiligenceItem(opp, oppItem);
        oppChildItem1.Due_Date__c = Date.today().addDays(-4);
        oppChildItem2.Due_Date__c = Date.today().addMonths(1);
        insert new List<Intake_Item__c> { oppChildItem1, oppChildItem2 };
    }

    @isTest
    public static void testGetUrgentItems(){
        Contact con = [ SELECT Id FROM Contact ];
        User u = [ SELECT Id FROM User WHERE ContactId = :con.Id ];

        Test.startTest();
        List<IntakeItemWrapper> wraps = null;
        System.runAs(u) {
            wraps = UrgentItemsCtlr.getUrgentItems();
        }
        Test.stopTest();

        System.assertEquals(3, [ SELECT COUNT() FROM Intake_Item__c WHERE Show_In_Urgent_Tab__c = true ]);
        System.assertEquals(2, wraps.size());
        System.assertEquals(null, wraps.get(0).children);
        System.assertEquals(null, wraps.get(1).children);
        System.assertEquals([ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = true ].Id, wraps.get(0).item.Id);
        System.assertEquals([ SELECT Id FROM Intake_Item__c WHERE Is_Ongoing__c = false AND Parent_Intake_Item__c != null AND Show_In_Urgent_Tab__c = true ].Id, wraps.get(1).item.Id);
    }

    @isTest
    public static void testGetUrgentItemsNoItems(){
        Contact con = [ SELECT Id FROM Contact ];
        User u = [ SELECT Id FROM User WHERE ContactId = :con.Id ];

        Test.startTest();
        List<Intake_Item__c> items = [ SELECT Id FROM Intake_Item__c ];
        for (Intake_Item__c item: items) {
            item.Status__c = 'Submitted';
        }
        update items;

        List<IntakeItemWrapper> wraps = null;
        System.runAs(u) {
            wraps = UrgentItemsCtlr.getUrgentItems();
        }
        Test.stopTest();

        System.assertEquals(0, [ SELECT COUNT() FROM Intake_Item__c WHERE Show_In_Urgent_Tab__c = true ]);
        System.assertEquals(0, wraps.size());
    }
}