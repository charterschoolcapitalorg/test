@isTest
private class AllPropertyContactsCtrlTests {


    @testSetup static void dataSetup() {
        //get map of record types
        Map<String,RecordType> accRecordTypes = TestHelper.createRecordTypeMap();

        //create a property & business
        List<Account> newAccounts = new List<Account>();
        Account business = TestHelper.createAccountForRecordTypeNoInsert(accRecordTypes.get('Business').Id, 'Business account');
        newAccounts.add(business);
        Account property = TestHelper.createAccountForRecordTypeNoInsert(accRecordTypes.get('Property').Id, 'Property account');
        newAccounts.add(property);

        insert newAccounts;

        //create tenant
        Tenant__c tenant = new Tenant__c();
        tenant.Tenant__c = business.Id;
        insert tenant;

        //create a lease
        Lease__c lease = new Lease__c();
        lease.Property__c = property.Id;
        lease.Tenant__c = tenant.Id;
        lease.Lease_Status__c = 'Active';
        insert lease;

        //create contacts
        List<Contact> cons = new List<Contact>();
        for(Integer i = 0; i<10; i++){
            Contact c = new Contact();
            c.FirstName = 'First ' + i;
            c.LastName = 'Last ' + i;
            cons.add(c);
        }
        insert cons;

        //create related contacts, two with rent invoice checked
        List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>();
        for(Integer i = 0; i<10; i++){
            Related_Contact__c rc = new Related_Contact__c();
            rc.Account__c = business.Id;
            rc.Contact__c = cons[0].Id;
            relatedContacts.add(rc);
        }
        insert relatedContacts;

    }

    @isTest
    static void testGetter(){

        //update one RC to a rent invocie RC
        Related_Contact__c rc = [SELECT Id FROM Related_Contact__c LIMIT 1];
        rc.Rent_Invoice__c = true;
        update rc;

        Map<Account, List<Related_Contact__c>> rentContacts = AllPropertyContactsCtrl.getAllPropertyRentContacts();
        for(Account acc : rentContacts.keySet()){
            System.assertEquals(1, rentContacts.get(acc).size(), 'There may only be one!');
        }
    }

}