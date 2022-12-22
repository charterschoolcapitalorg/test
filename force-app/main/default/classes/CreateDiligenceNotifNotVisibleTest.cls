@isTest
private class CreateDiligenceNotifNotVisibleTest  {
    @testSetup
    private static void setup() {
        Account acct = TestDiligenceUtils.getCharterHolder();
        insert acct;
        Intake_Item__c ii = TestDiligenceUtils.getOngoingDiligenceItem(acct);
        ii.Is_Visible_To_Community__c = false;
        ii.Due_Date__c = Date.today().addDays(7);
        ii.Status__c = 'Pending';
        insert ii;
    }

    @isTest
    private static void testExecute() {
        Id groupId = TestDiligenceUtils.getFakeId(SObjectType.CollaborationGroup);
        ChatterProviderMock mock = new ChatterProviderMock();
        CreateDiligenceNotificationsNotVisible.chatterSvc = mock;

        Intake_Item__c itemBefore = [ SELECT Sent_Created_Notification__c FROM Intake_Item__c ];

        Test.startTest();
        new CreateDiligenceNotificationsNotVisible().execute(null);
        Test.stopTest();

        Intake_Item__c itemAfter = [ SELECT Sent_Created_Notification__c, Account_Name__c FROM Intake_Item__c ];

        System.assertEquals(false, itemBefore.Sent_Created_Notification__c);
        System.assertEquals(true, itemAfter.Sent_Created_Notification__c);
        System.assertEquals(1, mock.reqs.size());
        System.assertEquals(itemAfter.Account_Name__c , mock.reqs.get(0).accountId);
        //System.assert(mock.reqs.get(0).body.contains(UserInfo.getUserId()));
    }

    public class ChatterProviderMock implements CreateDiligenceNotificationsNotVisible.ChatterProvider {
        public List<ChatterRequest> reqs = new List<ChatterRequest>();

        public void postFeedItemWithMentions(Id networkId, Id accountId, String body) {
            ChatterRequest req = new ChatterRequest();
            req.networkId = networkId;
            req.accountId = accountId;
            req.body = body;
            reqs.add(req);
        }
    }

    private class ChatterRequest {
        Id networkId { get; set; }
        Id accountId { get; set; }
        String body { get; set; }
    }

}