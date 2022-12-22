@isTest
private class CreateDiligenceNotificationsTest {
    @testSetup
    private static void setup() {
        Account acct = TestDiligenceUtils.getCharterHolder();
        insert acct;
        CSC_Action_List__c al = TestDiligenceUtils.getActionList(acct);
        al.Active_OD__c = true;
        insert al;
        CSC_Action_Item__c ai = TestDiligenceUtils.getActionItem(al);
        ai.Notification_Group__c = 'FAM - Facilities Asset Management Team';
        ai.Diligence_Notification_Days__c = 45;
        ai.Expiration_Date__c = Date.today().addDays(40);
        ai.Assigned_To__c = UserInfo.getUserId();
        ai.Ongoing_Diligence_Item__c = true;
        insert ai;
    }

    @isTest
    private static void testExecute() {
        Id groupId = TestDiligenceUtils.getFakeId(SObjectType.CollaborationGroup);
        ChatterProviderMock mock = new ChatterProviderMock();
        CreateDiligenceNotifications.chatterSvc = mock;
        CreateDiligenceNotifications.groupMap.put('FAM - Facilities Asset Management Team', groupId);

        CSC_Action_Item__c itemBefore = [ SELECT Send_Diligence_Notification__c FROM CSC_Action_Item__c ];

        Test.startTest();
        new CreateDiligenceNotifications().execute(null);
        Test.stopTest();

        CSC_Action_Item__c itemAfter = [ SELECT Send_Diligence_Notification__c, CSC_Action_List__r.Account__c FROM CSC_Action_Item__c ];

        System.assertEquals(true, itemBefore.Send_Diligence_Notification__c);
        System.assertEquals(false, itemAfter.Send_Diligence_Notification__c);
        System.assertEquals(1, mock.reqs.size());
        System.assertEquals(itemAfter.CSC_Action_List__r.Account__c, mock.reqs.get(0).accountId);
        System.assert(mock.reqs.get(0).body.contains(groupId));
        System.assert(mock.reqs.get(0).body.contains(UserInfo.getUserId()));
    }

    public class ChatterProviderMock implements CreateDiligenceNotifications.ChatterProvider {
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