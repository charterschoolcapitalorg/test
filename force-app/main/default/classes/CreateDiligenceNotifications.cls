global class CreateDiligenceNotifications implements Schedulable {
    @testVisible private static Map<String, Id> groupMap = new Map<String,Id>();

    @testVisible
    private static ChatterProvider chatterSvc = new ChatterProviderStandard();

    public class ChatterProviderStandard implements ChatterProvider {
        public void postFeedItemWithMentions(Id networkId, Id accountId, String body) {
            ConnectApiHelper.postFeedItemWithMentions(networkId, accountId, body);
        }
    }

    public interface ChatterProvider {
        void postFeedItemWithMentions(Id networkId, Id accountId, String body);
    }
    

    global void execute(SchedulableContext SC) {
    	List<CSC_Action_Item__c> results = [Select CSC_Action_List__r.Account__c, Notification_Group__c, Assigned_To__c, List_Item_Name__c, Expiration_Date__c from CSC_Action_Item__c where Send_Diligence_Notification__c = true ORDER BY CSC_Action_List__r.Account__c];
        Map<Id, List<CSC_Action_Item__c>> accountMap = SObjectUtil.groupById(results, 'CSC_Action_List__r.Account__c');
        

        if(results.size() > 0) {
            Set<String> groupNames = new Set<String>();
            for(CSC_Action_Item__c cai : results) {
                groupNames.add(cai.Notification_Group__c);
            }
            groupNames.remove(null);

            //query for group ids based on notification group name
            List<CollaborationGroup> groups = [Select Id, Name from CollaborationGroup where Name in :groupNames];
            for(CollaborationGroup g : groups) {
                groupMap.put(g.Name, g.Id);
            }

            for(Id accountId : accountMap.keySet()) {
                List<CSC_Action_Item__c> actionItems = accountMap.get(accountId);
                chatterSvc.postFeedItemWithMentions(
                    Network.getNetworkId(), 
                    accountId, 
                    buildMentions(actionItems) 
                    + 'The following diligence items are expiring soon:'
                    + buildItemList(actionItems)
                    + 'Please check that these items are still needed and reach out to the client if needed.'
                );
            }
            
            for(CSC_Action_Item__c item : results) {
                item.Diligence_Notification_Sent__c = true;
            }
            update results;
        }
    }
    private String buildItemName(CSC_Action_Item__c item) {
        return '{record:'+item.Id+'} - ' + item.List_Item_Name__c + ' - ' + item.Expiration_Date__c.format();
    }
    
    private String buildItemList(List<CSC_Action_Item__c> actionItems) {
        String listContent = '<ul>';
        for(CSC_Action_Item__c item : actionItems) {
            listContent += '<li>' + buildItemName(item) + '</li>';
        }
        listContent += '</ul>';
        return listContent;
    }
    
    private String buildMentions(List<CSC_Action_Item__c> actionItems) {
        String mentions = '';
        Set<Id> uniqueUserIds = new Set<Id>();
        Set<Id> uniqueGroupIds = new Set<Id>();
        for(CSC_Action_Item__c item : actionItems) {
            if (item.Assigned_To__c != null && uniqueUserIds.add(item.Assigned_To__c)) {
                mentions += '{' + item.Assigned_To__c + '} ';
            }
            if(item.Notification_Group__c != null && uniqueGroupIds.add(groupMap.get(item.Notification_Group__c))) {
                mentions += '{' + groupMap.get(item.Notification_Group__c) + '} ';
            }
        }

        return mentions;
    }
}