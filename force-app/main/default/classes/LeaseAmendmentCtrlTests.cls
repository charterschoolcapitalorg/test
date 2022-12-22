@isTest
private class LeaseAmendmentCtrlTests {
    
    @TestSetup
    static void createData(){
        //create property
        Account acc = new Account();
        acc.Name = 'Test account';
        acc.RecordTypeId = RecordTypes.IDPropAccount;
        insert acc;

        //create Lease records
        List<Lease__c> leases = new List<Lease__c>();
        for (Integer i = 0; i < 10; i++) {
            Lease__c lease = new Lease__c();
            lease.Escalation_Date__c = 'Random text in here ' + i;
            lease.Lease_Owner__c = 'AEP Owned';
            lease.Rent_Concessions__c = 'Free Rent';
            lease.Property__c = acc.Id;
            leases.add(lease);
        }
        insert leases;
    }

    @isTest static void testGetLease(){
        Lease__c targetLease = [SELECT id, Escalation_Date__c FROM Lease__c LIMIT 1];
        Lease__c lease = LeaseAmendmentCtrl.getLease(targetLease.Id);
        System.assertEquals(lease.Escalation_Date__c, targetLease.Escalation_Date__c, 'incorrect escalation date text on lease');
    }

    @isTest static void testUpdateLeases(){
        //get a lease
        Lease__c targetLease = [SELECT id, Escalation_Date__c, Property__r.Name FROM Lease__c LIMIT 1];
        String origEscalationDateText = targetLease.Escalation_Date__c;
        
        //create lease amendment json
        Lease_Amendment__c la = new Lease_Amendment__c();
        la.Amendment_Name__c = 'Some random name';
        la.Amendment_Summary__c = 'More ranadom summary text';
        la.Lease__c = targetLease.Id;
        String amendmentJSON = JSON.serialize(la);
        System.debug('amendment json ' + amendmentJSON);

        //Verify no lease amendments in the system
        List<Lease_Amendment__c> las = new List<Lease_Amendment__c>();
        las = [SELECT id FROM Lease_Amendment__c];
        System.assertEquals(0, las.size(), 'Shouldn\'t be any Lease Amendments in there!');
        
        //update lease json
        targetLease.Escalation_Date__c = 'Completely different text!';
        targetLease.Lease_Owner__c = 'CSC Owned';
        String amendedLeaseJSON = JSON.serialize(targetLease);
        System.debug('lease json ' + amendedLeaseJSON);

        //pass json and id to method
        LeaseAmendmentCtrl.updateRecords(amendedLeaseJSON, amendmentJSON, targetLease.Id);

        //verify new lease amendment & updated lease
        las = [SELECT id, Lease__c, Amendment_Summary__c, Amended_Lease_Values__c FROM Lease_Amendment__c];
        System.assertEquals(1, las.size(), 'there ma be only one!');
        System.assertEquals(targetLease.Id, las[0].Lease__c, 'should be for the lease');
        System.debug('vals: ' + las);

        //field + ': ' + originalLease.get(field) + ' -> '+ updatedLease.get(field)
        String escalationText = 'Escalation_Date__c:'+ '\n' + origEscalationDateText + ' -> Completely different text!';
        String ownerText = 'Lease_Owner__c:' + '\n' + 'AEP Owned -> CSC Owned';
        String concessionText = 'Rent_Concessions__c:' + '\n' + 'Free Rent -> Free Rent';

        System.assertEquals(true, las[0].Amended_Lease_Values__c.contains(escalationText), 'escalation text update not included');
        System.assertEquals(true, las[0].Amended_Lease_Values__c.contains(ownerText), 'lease owner update not included');
        System.assertEquals(false, las[0].Amended_Lease_Values__c.contains(concessionText), 'lease concession was not up[dated');

    }
}