@isTest
public with sharing class TestCreateLeaseComplianceBatchable {

    @isTest 
    static void testLeaseBatchable(){
        TestDiligenceUtils.createStates();
		
		State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
		
		Account a = new Account(name='test ch', recordtypeid = RecordTypes.IDCharterAccount, operating_state__c=s.Id);
        insert a;
        Account prop = new Account(name='test property',recordtypeid = RecordTypes.IDPropAccount, operating_state__c=s.Id);
        insert prop;

        Lease__c lease = new Lease__c();
		lease.Property__c = prop.Id;
        lease.Account__c = a.Id;
        insert lease;

        ID pending = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Pending').getRecordTypeId();

        Lease_Compliance_Template__c t = new Lease_Compliance_Template__c();
		t.Due_Days__c = 2;
		t.Client_Alert_Days__c= 2;
		t.Expire_Days__c= 2;
		t.FAM_Alert_Days__c= 2;
		t.Period__c= 'Monthly';
        t.Type__c = 'Property Insurance';
        t.Action_Item_Mapping__c = 'Property Insurance';
		insert t;

        Lease_Compliance__c nl = new Lease_Compliance__c();
		nl.lease__c = lease.Id;
		nl.Received_Date__c = null;
		nl.Start_Date__c = date.today().adddays(-32);
		nl.End_Date__c = date.today().adddays(-31);
		nl.Client_Alert_Days__c = 1;
		nl.Expire_Days__c = 5;
		nl.FAM_Alert_Days__c = 1;
		nl.Due_Days__c = 1;
		nl.recordtypeid = pending;
        nl.type__c = 'Property Insurance';
        insert nl;
        
        System.debug('here is the date:' + nl.Next_Record_Trigger_Date__c);

        CSC_Action_List__c aList = new CSC_Action_List__c();
        aList.Action_List_Name__c = 'Test Action List';
        aList.Account__c = a.Id;
        aList.Library_Type__c = 'Underwriting';
        insert aList;

        CSC_Action_Item__c aItem = new CSC_Action_Item__c();
        aItem.Action_Item_Name__c = 'Test Action Item';
        aItem.CSC_Action_List__c = aList.Id;
        t.Action_Item_Mapping__c = 'Property Insurance';
        insert aItem;

        Test.startTest();

        CreateLeaseComplianceScheduable lcb = new CreateLeaseComplianceScheduable();
        String sch ='0 0 23 * * ?'; 
        System.schedule('Schedule to update csc action items in lease batch', sch,lcb);

        Test.stopTest();

        List<CSC_Action_Item__c> items = [SELECT Id, Account__c, CSC_Action_List__r.Account__c, CSC_Action_List__r.Account__r.RecordTypeId, Next_Action_Date__c, Expiration_Date__c, 	Status__c, Action_Item_Mapping__c
                                                FROM CSC_Action_Item__c WHERE Id =: aItem.Id];
        
        System.debug(items);

    }


}