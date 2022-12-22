public with sharing class AllPropertyContactsCtrl {

    @AuraEnabled
    public static Map<Account, List<Related_Contact__c>> getAllPropertyRentContacts(){
        // Needed maps
        Map<Id, Set<Id>> propertyIdToAccountIdMap = new Map<Id, Set<Id>>();
        Map<Id, Set<Related_Contact__c>> accountIdToRelatedContactMap = new Map<Id, Set<Related_Contact__c>>();
        Map<Account, Set<Related_Contact__c>> propertyToRelatedContactMap = new Map<Account, Set<Related_Contact__c>>();

        // Get a list of properties
        List<Account> properties = [SELECT Id, Name, Nick_Name__c, BillingState, Equity_Investor__r.Nick_Name__c FROM Account WHERE RecordType.DeveloperName = 'Property' AND Sold__c = false];

        // Get a list of leases
        List<Lease__c> leases = new List<Lease__c>();
        leases = [SELECT Id, Name, Tenant__r.Tenant__r.Name, Tenant__c, Tenant__r.Tenant__r.Id, Base_Year_Rent__c,  Purchase_Option__c, Escalation_Date__c, Lease_Expiration_Date__c, Property__r.Id
                FROM Lease__c where Property__c=:properties AND Lease_Status__c = 'Active'];

        // Combine Tenant and Property Ids for Related Contacts search filter, and initialize maps
        Set<Id> accountIds = new Set<Id>();

        for(Account prop: properties){
            accountIds.add(prop.Id);
            Set<Id> accIds = new Set<Id>();
            accIds.add(prop.Id);
            propertyIdToAccountIdMap.put(prop.Id, accIds);
            accountIdToRelatedContactMap.put(prop.Id, new Set<Related_Contact__c>());
        }

        for(Lease__c lease: leases){
            accountIds.add(lease.Tenant__r.Tenant__r.Id);
            propertyIdToAccountIdMap.put(lease.Property__r.Id, propertyIdToAccountIdMap.get(lease.Property__r.Id)).add(lease.Tenant__r.Tenant__r.Id);
            accountIdToRelatedContactMap.put(lease.Tenant__r.Tenant__r.Id, new Set<Related_Contact__c>());
        }

        // Get a list or Related Contacts on the accounts with Rent Invoice checked
        List<Related_Contact__c> rentInvoiceRCs = new List<Related_Contact__c>();

        rentInvoiceRCs = [SELECT Id, Facilities_Contact__c, Financial_Contact__c, Rent_Invoice__c, Contact__r.FIrstName, Contact__r.LastName, Contact__r.Email, Contact__r.Account.Name,
                            Account__r.Name , Account__r.Id, Account__r.Nick_Name__c, Alt_Email__c
                            FROM Related_Contact__c WHERE Account__c IN:accountIds
                            // AND (Financial_Contact__c = True OR Facilities_Contact__c = True OR Rent_Invoice__c = True)];
                            AND Rent_Invoice__c = True];

        for(Related_Contact__c rc : rentInvoiceRCs){
            accountIdToRelatedContactMap.put(rc.Account__r.Id, accountIdToRelatedContactMap.get(rc.Account__r.Id)).add(rc);
        }

        for(Account prop: properties){
            Set<Related_Contact__c> rcs = new Set<Related_Contact__c>();
            for(Id accId : propertyIdToAccountIdMap.get(prop.Id)){
                rcs.addAll(accountIdToRelatedContactMap.get(accId));
                propertyToRelatedContactMap.put(prop, rcs);
            }
        }

        // @AuraEnabled does not work with Sets - convert to List
        Map<Account, List<Related_Contact__c>> propertyToRelatedContactListMap = new Map<Account, List<Related_Contact__c>>();
        for(Account acc: propertyToRelatedContactMap.keySet()) {
            System.debug(acc);
            System.debug(propertyToRelatedContactMap.get(acc));
            propertyToRelatedContactListMap.put(acc, new List<Related_Contact__c>(propertyToRelatedContactMap.get(acc)));
        }
        return propertyToRelatedContactListMap;

    }


}