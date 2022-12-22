@isTest
private class Send_Community_Invite_ControllerTest {
    @TestSetup
    private static void setup(){
        Account cmoAcct = TestDiligenceUtils.getCMO();
        insert cmoAcct;
        Account charterHolderAcct = TestDiligenceUtils.getCharterHolder(cmoAcct);
        insert charterHolderAcct;
        Account schoolAcct = TestDiligenceUtils.getSchool(charterHolderAcct);
        insert schoolAcct;
        Opportunity opp = TestDiligenceUtils.getOpportunity(schoolAcct);
        insert opp;
        Contact con = TestDiligenceUtils.getContact(schoolAcct);
        insert con;
    }

    @isTest
    private static void testAccountControllerCMOContact() {
        Account school = [ SELECT Id FROM Account WHERE RecordTypeId = :RecordTypes.IDSchoolAccount ];
        Account cmo = [ SELECT Id FROM Account WHERE RecordTypeId = :RecordTypes.IDBusAccount ];
        Contact con = TestDiligenceUtils.getContact(cmo);
        insert con;

        Test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(school);
        Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(ctrl);
        Test.stopTest();

        System.assertEquals(2, sc.consWrapper.size());
        System.assert((new Set<Id> {sc.consWrapper.get(0).con.Id, sc.consWrapper.get(1).con.Id}).contains(con.Id));
    }

    @isTest
    private static void testAccountController() {
        Account charterHolderAcct = [ SELECT Id FROM Account WHERE RecordTypeId = :RecordTypes.IDCharterAccount ];
        Contact con = [ SELECT Id FROM Contact ];

        System.assertEquals(0, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Contact__c = :con.Id AND Account__c = :charterHolderAcct.Id AND Opportunity__c = null ]);
        System.assertEquals(0, [ SELECT COUNT() FROM User WHERE ContactId = :con.Id ]);

        Test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(charterHolderAcct);
        Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(ctrl);

        System.assertEquals(true, sc.isFromAccount());
        System.assertEquals(false, sc.isFromOpportunity());

        System.assertEquals(1, sc.consWrapper.size());
        System.assertNotEquals(true, sc.consWrapper.get(0).selected);
        System.assertEquals(con.Id, sc.consWrapper.get(0).con.Id);

        sc.consWrapper.get(0).selected = true;

        ApexPages.PageReference ref = sc.save();
        Test.stopTest();

        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assertEquals(1, msgs.size());
        System.assertEquals(ApexPages.Severity.CONFIRM, msgs.get(0).getSeverity());

        System.assertEquals(null, ref);

        User u = [ SELECT Id FROM User WHERE ContactId = :con.Id ];

        System.assertEquals(1, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Contact__c = :con.Id AND Account__c = :charterHolderAcct.Id AND Opportunity__c = null ]);
        System.assertEquals(1, [ SELECT COUNT() FROM AccountShare WHERE AccountId = :charterHolderAcct.Id AND UserOrGroupId = :u.Id AND RowCause = 'Manual' ]);
    }

    @isTest
    private static void testOpportunityController() {
        Opportunity opp = [ SELECT Id FROM Opportunity ];
        Contact con = [ SELECT Id FROM Contact ];

        System.assertEquals(0, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Contact__c = :con.Id AND Account__c = null AND Opportunity__c = :opp.Id ]);
        System.assertEquals(0, [ SELECT COUNT() FROM User WHERE ContactId = :con.Id ]);

        Test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(opp);
        Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(ctrl);

        System.assertEquals(false, sc.isFromAccount());
        System.assertEquals(true, sc.isFromOpportunity());

        System.assertEquals(1, sc.consWrapper.size());
        System.assertNotEquals(true, sc.consWrapper.get(0).selected);
        System.assertEquals(con.Id, sc.consWrapper.get(0).con.Id);

        sc.consWrapper.get(0).selected = true;

        ApexPages.PageReference ref = sc.save();
        Test.stopTest();

        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assertEquals(1, msgs.size());
        System.assertEquals(ApexPages.Severity.CONFIRM, msgs.get(0).getSeverity());

        System.assertEquals(null, ref);

        User u = [ SELECT Id FROM User WHERE ContactId = :con.Id ];

        System.assertEquals(1, [ SELECT COUNT() FROM Community_Contact_Role__c WHERE Contact__c = :con.Id AND Account__c = null AND Opportunity__c = :opp.Id ]);
        System.assertEquals(1, [ SELECT COUNT() FROM OpportunityShare WHERE OpportunityId = :opp.Id AND UserOrGroupId = :u.Id AND RowCause = 'Manual' ]);
    }
}