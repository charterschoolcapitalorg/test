@isTest
private class SObjectUtilTest {
    @isTest
    private static void testGetIdFieldForReference() {
        System.assertEquals('AccountId', SObjectUtil.getIdFieldForReference('Account'));
        System.assertEquals('Account__c', SObjectUtil.getIdFieldForReference('Account__r'));
    }

    @isTest
    private static void testGetReferenceFieldForId() {
        System.assertEquals('Account', SObjectUtil.getReferenceFieldForId('AccountId'));
        System.assertEquals('Account__r', SObjectUtil.getReferenceFieldForId('Account__c'));
    }

    @isTest
    private static void testGetFakeId() {
        Id fakeId1 = SObjectUtil.getFakeId(SObjectType.Account);
        Id fakeId2 = SObjectUtil.getFakeId(SObjectType.Account);
        System.assertEquals(Account.SObjectType, fakeId1.getSObjectType());
        System.assertEquals(Account.SObjectType, fakeId2.getSObjectType());
        System.assertEquals(0, [ SELECT COUNT() FROM Account WHERE Id IN (:fakeId1, :fakeId2) ]);
        System.assertNotEquals(fakeId1, fakeId2);
    }

    @isTest
    private static void testSObjectKeyFromObject() {
        Lead l1 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'Id', 'FirstName', 'LastName' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(new List<Object> { l1.Id, l1.FirstName, l1.LastName });

        System.assert(key1.equals(key2));
        System.assert(key2.equals(key1));
    }

    @isTest
    private static void testSObjectKeysNotEqual() {
        Lead l1 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));
        Lead l2 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'Id', 'FirstName', 'LastName' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(l2, new List<String> { 'Id', 'FirstName', 'LastName' });

        System.assert(!key1.equals(key2));
        System.assert(key1.equals(key1));
        System.assert(!key2.equals(key1));
        System.assert(key2.equals(key2));
    }

    @isTest
    private static void testSObjectKeysEqual_PropertySubset() {
        Lead l1 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));
        Lead l2 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'FirstName', 'LastName' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(l2, new List<String> { 'FirstName', 'LastName' });

        System.assertEquals(key1.hashCode(), key2.hashCode());
        System.assert(key1.equals(key2));
        System.assert(key1.equals(key1));
        System.assert(key2.equals(key1));
        System.assert(key2.equals(key2));
    }

    @isTest
    private static void testSObjectKeysNotEqual_DifferentLists() {
        Lead l1 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));
        Lead l2 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'FirstName', 'LastName' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(l2, new List<String> { 'FirstName' });

        System.assertNotEquals(key1.hashCode(), key2.hashCode());
        System.assert(!key1.equals(key2));
        System.assert(key1.equals(key1));
        System.assert(!key2.equals(key1));
        System.assert(key2.equals(key2));
    }

    @isTest
    private static void testSObjectKeysNotEqual_DifferentOrders() {
        Lead l1 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));
        Lead l2 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = SObjectUtil.getFakeId(SObjectType.Lead));

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'FirstName', 'LastName' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(l2, new List<String> { 'LastName', 'FirstName' });

        System.assertNotEquals(key1.hashCode(), key2.hashCode());
        System.assert(!key1.equals(key2));
        System.assert(key1.equals(key1));
        System.assert(!key2.equals(key1));
        System.assert(key2.equals(key2));
    }

    @isTest
    private static void testSObjectKeysEqual_DifferentObjectTypes() {
        String accountId = String.valueOf(SObjectUtil.getFakeId(SObjectType.Account));

        Account acc = new Account(Name = 'Bob', Id = accountId);
        Contact con = new Contact(FirstName = 'Bob', AccountId = accountId);

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(acc, new List<String> { 'Id', 'Name' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(con, new List<String> { 'AccountId', 'FirstName' });

        System.assertEquals(key1.hashCode(), key2.hashCode());
        System.assert(key1.equals(key2));
        System.assert(key1.equals(key1));
        System.assert(key2.equals(key1));
        System.assert(key2.equals(key2));
    }

    @isTest
    private static void testSObjectKeysEqual_DifferentIdInstances() {
        String leadId = String.valueOf(SObjectUtil.getFakeId(SObjectType.Lead));

        Id idInstance1 = Id.valueOf(leadId);
        Id idInstance2 = Id.valueOf(leadId);

        // there used to be a bug in SFDC where two separate ID instance do not return the same hashcode
        // we should expect that our tool works fine in this case by working around this bug
        System.assert(idInstance1.equals(idInstance2));

        Lead l1 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = idInstance1);
        Lead l2 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = idInstance2);

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'Id', 'FirstName', 'LastName' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(l2, new List<String> { 'Id', 'FirstName', 'LastName' });

        System.assertEquals(key1.hashCode(), key2.hashCode());
        System.assert(key1.equals(key2));
        System.assert(key1.equals(key1));
        System.assert(key2.equals(key1));
        System.assert(key2.equals(key2));
    }

    @isTest
    private static void testSObjectKeysEqual_NullValues() {
        String leadId = String.valueOf(SObjectUtil.getFakeId(SObjectType.Lead));

        Lead l1 = new Lead(FirstName = 'Bob', LastName = null, Id = leadId);
        Lead l2 = new Lead(FirstName = 'Bob', LastName = null, Id = leadId);

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'Id', 'FirstName', 'LastName' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(l2, new List<String> { 'Id', 'FirstName', 'LastName' });

        System.assertEquals(key1.hashCode(), key2.hashCode());
        System.assert(key1.equals(key2));
        System.assert(key1.equals(key1));
        System.assert(key2.equals(key1));
        System.assert(key2.equals(key2));
    }

    @isTest
    private static void testSObjectKeysNotEqual_OneNullValue() {
        String leadId = String.valueOf(SObjectUtil.getFakeId(SObjectType.Lead));

        Lead l1 = new Lead(FirstName = 'Bob', LastName = 'Test', Id = leadId);
        Lead l2 = new Lead(FirstName = 'Bob', LastName = null, Id = leadId);

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'Id', 'FirstName', 'LastName' });
        SObjectUtil.SObjectKey key2 = SObjectUtil.keyFrom(l2, new List<String> { 'Id', 'FirstName', 'LastName' });

        System.assert(!key1.equals(key2));
        System.assert(key1.equals(key1));
        System.assert(!key2.equals(key1));
        System.assert(key2.equals(key2));
    }

    @isTest
    private static void testSObjectKeysNotEqual_NotSObjectKey() {
        Lead l1 = new Lead(FirstName = 'Bob');

        SObjectUtil.SObjectKey key1 = SObjectUtil.keyFrom(l1, new List<String> { 'Id', 'FirstName', 'LastName' });

        System.assert(!key1.equals('ABC'));
    }

    @isTest
    private static void testGroupAndCollect() {
        Id acctId1 = SObjectUtil.getFakeId(SObjectType.Account);
        Id acctId2 = SObjectUtil.getFakeId(SObjectType.Account);

        List<Contact> cons = new List<Contact> {
            new Contact(Id = SObjectUtil.getFakeId(SObjectType.Contact), AccountId = acctId1, FirstName = 'Joe'),
            new Contact(Id = SObjectUtil.getFakeId(SObjectType.Contact), AccountId = acctId1, FirstName = 'Joe'),
            new Contact(Id = SObjectUtil.getFakeId(SObjectType.Contact), AccountId = acctId1, FirstName = 'Bob'),
            new Contact(Id = SObjectUtil.getFakeId(SObjectType.Contact), AccountId = acctId2, FirstName = 'Tom')
        };

        Map<Id,List<Contact>> conMap1 = SObjectUtil.groupById(cons, 'AccountId');
        System.assertEquals(2, conMap1.size());
        System.assertEquals(3, conMap1.get(acctId1).size());
        System.assertEquals(1, conMap1.get(acctId2).size());

        Set<Id> acctIds1 = SObjectUtil.collectIds(cons, Contact.AccountId);
        Set<Id> acctIds2 = SObjectUtil.collectIds(cons, 'AccountId');
        System.assertEquals(new Set<Id> { acctId1, acctId2 }, acctIds1);
        System.assertEquals(new Set<Id> { acctId1, acctId2 }, acctIds2);

        Map<SObjectUtil.SObjectKey,List<Contact>> conMap3 = SObjectUtil.groupByKeys(cons, new List<String> { 'AccountId', 'FirstName' });
        System.assertEquals(3, conMap3.size());

        System.assertEquals(2, conMap3.get(SObjectUtil.keyFrom(cons.get(0), new List<String> { 'AccountId', 'FirstName' })).size());
        System.assertEquals(1, conMap3.get(SObjectUtil.keyFrom(cons.get(2), new List<String> { 'AccountId', 'FirstName' })).size());
        System.assertEquals(1, conMap3.get(SObjectUtil.keyFrom(cons.get(3), new List<String> { 'AccountId', 'FirstName' })).size());
    }

    @isTest
    private static void testGroupAndCollect2() {
        Id acctId1 = SObjectUtil.getFakeId(SObjectType.Account);
        Id acctId2 = SObjectUtil.getFakeId(SObjectType.Account);

        List<Contact> cons = new List<Contact> {
            new Contact(Id = SObjectUtil.getFakeId(SObjectType.Contact), AccountId = acctId1, FirstName = 'Joe'),
            new Contact(Id = SObjectUtil.getFakeId(SObjectType.Contact), AccountId = acctId1, FirstName = 'Joe'),
            new Contact(Id = SObjectUtil.getFakeId(SObjectType.Contact), AccountId = acctId1, FirstName = 'Bob'),
            new Contact(Id = SObjectUtil.getFakeId(SObjectType.Contact), AccountId = acctId2, FirstName = 'Tom')
        };

        Map<Id,List<Contact>> conMap1 = SObjectUtil.groupById(cons, 'AccountId');
        System.assertEquals(2, conMap1.size());
        System.assertEquals(3, conMap1.get(acctId1).size());
        System.assertEquals(1, conMap1.get(acctId2).size());

        Set<Id> conIds = SObjectUtil.collectIds(cons);
        System.assertEquals(new Set<Id> { cons[0].Id, cons[1].Id, cons[2].Id, cons[3].Id }, conIds);

        Map<SObjectUtil.SObjectKey,List<Contact>> conMap3 = SObjectUtil.groupByKeys(cons, new List<String> { 'AccountId', 'FirstName' });
        System.assertEquals(3, conMap3.size());

        System.assertEquals(2, conMap3.get(SObjectUtil.keyFrom(cons.get(0), new List<String> { 'AccountId', 'FirstName' })).size());
        System.assertEquals(1, conMap3.get(SObjectUtil.keyFrom(cons.get(2), new List<String> { 'AccountId', 'FirstName' })).size());
        System.assertEquals(1, conMap3.get(SObjectUtil.keyFrom(cons.get(3), new List<String> { 'AccountId', 'FirstName' })).size());
    }

    @isTest
    private static void testSetField() {
        Contact con = new Contact();
        SObjectUtil.setField(con, 'Account.AccountNumber', '1234');
        System.assertEquals('1234', con.Account.AccountNumber);
        System.assertEquals('1234', SObjectUtil.getField(con, 'Account.AccountNumber'));
    }

    @isTest
    private static void testGetChanged() {
        Id con1Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con2Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con3Id = SObjectUtil.getFakeId(SObjectType.Contact);

        Test.startTest();
        List<Contact> changed = SObjectUtil.getChanged(
            new List<Contact> {
                new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                new Contact(Id = con2Id, FirstName = 'Test2', LastName = 'Person2'),
                new Contact(Id = con3Id, FirstName = 'Test3', LastName = 'Person3')
            },
            new List<Contact> {
                new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                new Contact(Id = con2Id, FirstName = 'Test2_Changed', LastName = 'Person2'),
                new Contact(Id = con3Id, FirstName = 'Test3', LastName = 'Person3')
            },
            new Set<String> {
                'FirstName',
                'LastName'
            }
        );
        Test.stopTest();

        System.assertEquals(1, changed.size());
        System.assertEquals(con2Id, changed.get(0).Id);
        System.assertEquals('Test2_Changed', changed.get(0).FirstName);
        System.assertEquals('Person2', changed.get(0).LastName);
    }

    @isTest
    private static void testGetRecordsFromMap() {
        Id con1Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con2Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con3Id = SObjectUtil.getFakeId(SObjectType.Contact);

        Test.startTest();
        List<SObject> records = SObjectUtil.getRecordsFromMap(
            new Map<Id,Contact> {
                con1Id => new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                con2Id => new Contact(Id = con2Id, FirstName = 'Test2', LastName = 'Person2'),
                con3Id => new Contact(Id = con3Id, FirstName = 'Test3', LastName = 'Person3')
            },
            new Set<Id> { con1Id, con2Id }
        );
        Test.stopTest();

        System.assertEquals(new Set<Id> { con1Id, con2Id }, new Map<Id,SObject>(records).keySet());
    }

    @isTest
    private static void testGetChangedIds() {
        Id con1Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con2Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con3Id = SObjectUtil.getFakeId(SObjectType.Contact);

        Test.startTest();
        Set<Id> changedIds = SObjectUtil.getChangedIds(
            new Map<Id,Contact> {
                con1Id => new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                con2Id => new Contact(Id = con2Id, FirstName = 'Test2', LastName = 'Person2'),
                con3Id => new Contact(Id = con3Id, FirstName = 'Test3', LastName = 'Person3')
            },
            new Map<Id,Contact> {
                con1Id => new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                con2Id => new Contact(Id = con2Id, FirstName = 'Test2_Changed', LastName = 'Person2'),
                con3Id => new Contact(Id = con3Id, FirstName = 'Test3', LastName = 'Person3')
            },
            new Set<String> {
                'FirstName',
                'LastName'
            }
        );
        Test.stopTest();

        System.assertEquals(new Set<Id> { con2Id }, changedIds);
    }

    @isTest
    private static void testGetChangedIds_missingNewMap() {
        Id con1Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con2Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con3Id = SObjectUtil.getFakeId(SObjectType.Contact);

        Test.startTest();
        Set<Id> changedIds = SObjectUtil.getChangedIds(
            new Map<Id,Contact> {
                con1Id => new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                con2Id => new Contact(Id = con2Id, FirstName = 'Test2', LastName = 'Person2'),
                con3Id => new Contact(Id = con3Id, FirstName = 'Test3', LastName = 'Person3')
            },
            null,
            new Set<String> {
                'FirstName',
                'LastName'
            }
        );
        Test.stopTest();

        System.assertEquals(new Set<Id> { con1Id, con2Id, con3Id }, changedIds);
    }

    @isTest
    private static void testGetChangedIds_missingOldMap() {
        Id con1Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con2Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con3Id = SObjectUtil.getFakeId(SObjectType.Contact);

        Test.startTest();
        Set<Id> changedIds = SObjectUtil.getChangedIds(
            null,
            new Map<Id,Contact> {
                con1Id => new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                con2Id => new Contact(Id = con2Id, FirstName = 'Test2', LastName = 'Person2'),
                con3Id => new Contact(Id = con3Id, FirstName = 'Test3', LastName = 'Person3')
            },
            new Set<String> {
                'FirstName',
                'LastName'
            }
        );
        Test.stopTest();

        System.assertEquals(new Set<Id> { con1Id, con2Id, con3Id }, changedIds);
    }

    @isTest
    private static void testGetChangedIds_missingIdsInMaps() {
        Id con1Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con2Id = SObjectUtil.getFakeId(SObjectType.Contact);
        Id con3Id = SObjectUtil.getFakeId(SObjectType.Contact);

        Test.startTest();
        Set<Id> changedIds = SObjectUtil.getChangedIds(
            new Map<Id,Contact> {
                con1Id => new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                con2Id => new Contact(Id = con2Id, FirstName = 'Test2', LastName = 'Person2')
            },
            new Map<Id,Contact> {
                con1Id => new Contact(Id = con1Id, FirstName = 'Test1', LastName = 'Person1'),
                con3Id => new Contact(Id = con3Id, FirstName = 'Test3', LastName = 'Person3')
            },
            new Set<String> {
                'FirstName',
                'LastName'
            }
        );
        Test.stopTest();

        System.assertEquals(new Set<Id> { con2Id, con3Id }, changedIds);
    }

    @isTest
    private static void testFilterLists() {
        List<Account> accts = new List<Account> {
            new Account(Id = SObjectUtil.getFakeId(SObjectType.Account), AccountNumber = '123'),
            new Account(Id = SObjectUtil.getFakeId(SObjectType.Account), AccountNumber = '456'),
            new Account(Id = SObjectUtil.getFakeId(SObjectType.Account), AccountNumber = '123')
        };

        Test.startTest();
        List<Account> matches1 = SObjectUtil.filterList(accts, SObjectUtil.whereFieldEquals(Account.AccountNumber, '123'));
        List<Account> matches2 = SObjectUtil.filterList(accts, SObjectUtil.whereFieldEquals(Account.AccountNumber, '456'));
        List<Account> matches3 = SObjectUtil.filterList(accts, SObjectUtil.whereFieldIn(Account.Id, new Set<Id> { accts.get(0).Id, accts.get(1).Id }));
        List<Account> matches4 = SObjectUtil.filterList(accts, new Set<Id> { accts.get(0).Id, accts.get(1).Id });
        List<Account> matches5 = SObjectUtil.filterList(accts, SObjectUtil.whereFieldIn(Account.AccountNumber, new Set<String> { '123' }));
        Test.stopTest();

        System.assertEquals(new List<Account> { accts.get(0), accts.get(2) }, matches1);
        System.assertEquals(new List<Account> { accts.get(1) }, matches2);
        System.assertEquals(new List<Account> { accts.get(0), accts.get(1) }, matches3);
        System.assertEquals(new List<Account> { accts.get(0), accts.get(1) }, matches4);
        System.assertEquals(new List<Account> { accts.get(0), accts.get(2) }, matches5);
    }

    @isTest
    private static void testGetSObjectType() {
        System.assertEquals(Account.SObjectType, SObjectUtil.getSObjectType('Account'));
    }

    @isTest
    private static void testFilterIds() {
        Id accountId1 = SObjectUtil.getFakeId(SObjectType.Account);
        Id accountId2 = SObjectUtil.getFakeId(SObjectType.Account);

        Set<Id> allIds = new Set<Id> {
            accountId1,
            accountId2,
            SObjectUtil.getFakeId(SObjectType.Contact),
            SObjectUtil.getFakeId(SObjectType.Contact),
            SObjectUtil.getFakeId(SObjectType.Lead),
            SObjectUtil.getFakeId(SObjectType.Lead)
        };

        System.assertEquals(6, allIds.size());

        Test.startTest();
        Set<Id> accountIds = SObjectUtil.filterIdsToType(allIds, Account.SObjectType);
        Test.stopTest();

        System.assertEquals(2, accountIds.size());
        System.assertEquals(new Set<Id> { accountId1, accountId2 }, accountIds);
    }

    @isTest
    private static void testApplyFields() {
        Contact con = new Contact(FirstName = 'First');

        Test.startTest();
        SObjectUtil.applyFields(con, new Contact(LastName = 'Last'));
        Test.stopTest();

        System.assertEquals('First', con.FirstName);
        System.assertEquals('Last', con.LastName);
    }

    @isTest
    private static void testPrefixFieldsWithoutDot() {
        System.assertEquals(new Set<String> {
            'Test.One',
            'Test.Two',
            'Test.Three'
        }, SObjectUtil.prefixFields('Test', new Set<String> {
            'One',
            'Two',
            'Three'
        }));
    }

    @isTest
    private static void testPrefixFieldsWithDot() {
        System.assertEquals(new Set<String> {
            'Test.One',
            'Test.Two',
            'Test.Three'
        }, SObjectUtil.prefixFields('Test.', new Set<String> {
            'One',
            'Two',
            'Three'
        }));
    }

    @isTest
    private static void testPrefixFieldsEmptyString() {
        System.assertEquals(new Set<String> {
            'One',
            'Two',
            'Three'
        }, SObjectUtil.prefixFields('', new Set<String> {
            'One',
            'Two',
            'Three'
        }));
    }

    @isTest
    private static void testPrefixFieldsNull() {
        System.assertEquals(new Set<String> {
            'One',
            'Two',
            'Three'
        }, SObjectUtil.prefixFields(null, new Set<String> {
            'One',
            'Two',
            'Three'
        }));
    }
}