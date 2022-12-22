@isTest
private class CreateLeaseComplianceBatchableTest {
    @testSetup 
    private static void testLeaseBatchable(){
        Account a = TestDiligenceUtils.getCharterHolder();
        insert a;
        Account prop = TestDiligenceUtils.getProperty();
        insert prop;

        Lease__c lease = TestDiligenceUtils.getLease(prop);
        lease.Account__c = a.Id;
        insert lease;

        Lease_Compliance_Template__c t = TestDiligenceUtils.getLeaseComplianceTemplate();
        t.Type__c = 'Property Insurance';
        insert t;

        Lease_Compliance__c nl = TestDiligenceUtils.getLeaseCompliance(lease);
        nl.Type__c = 'Property Insurance';
        nl.Start_Date__c = date.today().addMonths(-3);
        nl.End_Date__c = date.today().addMonths(-2);
        insert nl;
        
        CSC_Action_List__c aList = TestDiligenceUtils.getActionList(a);
        insert aList;
        CSC_Action_Item__c aItem = TestDiligenceUtils.getActionItem(aList);
        insert aItem;
    }

    @isTest
    public static void testSchedulable() {
        Test.startTest();
        new CreateLeaseComplianceScheduable().execute(null);
        Test.stopTest();

        assertUpdated();
    }

    @isTest
    public static void testBatch() {
        Test.startTest();
        Database.executeBatch(new CreateLeaseComplianceBatchable());
        Test.stopTest();

        assertUpdated();
    }

    @isTest
    public static void testBatchCurrentLC() {
        Lease_Compliance__c lc = [ SELECT Id, RecordTypeId FROM Lease_Compliance__c ];
        System.assertEquals(CreateLeaseComplianceBatchable.pending, lc.RecordTypeId);
        lc.RecordTypeId = CreateLeaseComplianceBatchable.current;
        update lc;

        Test.startTest();
        Database.executeBatch(new CreateLeaseComplianceBatchable());
        Test.stopTest();

        assertUpdated();
    }

    private static void assertUpdated() {
        CSC_Action_Item__c item = [ SELECT Id, Next_Action_Date__c, Expiration_Date__c, CP_Item_Due_Date__c, Diligence_Notification_Sent__c, Status__c FROM CSC_Action_Item__c ];
        Lease_Compliance__c oldLC = [ SELECT Id FROM Lease_Compliance__c WHERE RecordType.DeveloperName = 'Expired' ];
        Lease_Compliance__c newLC = [ SELECT Id, Due_Date__c, Expiration_Date__c, Client_Alert_Date__c FROM Lease_Compliance__c WHERE RecordType.DeveloperName = 'Pending' ];

        System.assertEquals(newLC.Client_Alert_Date__c, item.Next_Action_Date__c);
        System.assertEquals(newLC.Due_Date__c, item.CP_Item_Due_Date__c);
        System.assertEquals(newLC.Expiration_Date__c, item.Expiration_Date__c);
        System.assertEquals(false, item.Diligence_Notification_Sent__c);
        System.assertEquals('New', item.Status__c);

    }
}