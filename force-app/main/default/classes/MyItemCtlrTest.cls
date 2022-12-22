@isTest
private class MyItemCtlrTest {
    @testSetup
    private static void setup() {
        Account acct = TestDiligenceUtils.getCharterHolder();
        insert acct;
        Opportunity opp = TestDiligenceUtils.getOpportunity(acct);
        insert opp;
        Intake_Item__c parentItem = TestDiligenceUtils.getDiligenceItem(opp);
        insert parentItem;
        Intake_Item__c item = TestDiligenceUtils.getDiligenceItem(opp, parentItem);
        insert item;
    }

    @isTest
    public static void testGetIntakeItemsWithParentId(){
        Opportunity opp = [ SELECT Id FROM Opportunity ];
        Intake_Item__c parentItem = [ SELECT Id FROM Intake_Item__c WHERE Parent_Intake_Item__c = null ];
        Intake_Item__c childItem = [ SELECT Id FROM Intake_Item__c WHERE Parent_Intake_Item__c = :parentItem.Id ];

        Test.startTest();
        List<IntakeItemWrapper> items = MyItemCtlr.getIntakeItems(opp.Id, parentItem.Id);
        Test.stopTest();

        System.assertEquals(1, items.size());
        System.assertEquals(childItem.Id, items.get(0).item.Id);
        System.assertEquals(false, items.get(0).hasChildren);
        System.assertEquals(true, items.get(0).hasParent);
    }

    @isTest
    public static void testGetIntakeItemsWithoutParentId(){
        Opportunity opp = [ SELECT Id FROM Opportunity ];
        Intake_Item__c parentItem = [ SELECT Id FROM Intake_Item__c WHERE Parent_Intake_Item__c = null ];
        Intake_Item__c childItem = [ SELECT Id FROM Intake_Item__c WHERE Parent_Intake_Item__c = :parentItem.Id ];

        Test.startTest();
        List<IntakeItemWrapper> items = MyItemCtlr.getIntakeItems(opp.Id, null);
        Test.stopTest();

        System.assertEquals(1, items.size());
        System.assertEquals(parentItem.Id, items.get(0).item.Id);
        System.assertEquals(true, items.get(0).hasChildren);
        System.assertEquals(false, items.get(0).hasParent);
        System.assertEquals(1, items.get(0).children.size());
        System.assertEquals(childItem.Id, items.get(0).children.get(0).item.Id);
    }
}