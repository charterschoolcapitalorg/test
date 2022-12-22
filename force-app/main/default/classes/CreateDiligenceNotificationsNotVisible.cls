global with sharing class CreateDiligenceNotificationsNotVisible implements Schedulable{
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
        Date twoWeeks = Date.today().addDays(14);
        List<Intake_Item__c> results = [Select Account_Name__c, Name, Due_Date__c, Opportunity__r.Id, Department__c from Intake_Item__c 
                                        WHERE Sent_Created_Notification__c = false AND 
                                                Is_Visible_To_Community__c = false AND 
                                                Status__c = 'Pending' AND 
                                                Due_Date__c <=:twoWeeks AND
                                                Is_Ongoing__c = true
                                                ORDER BY Account_Name__c];

        results = ContentDocumentLinkTriggerManager.getItems(SObjectUtil.collectIds(results));

        Map<Id, List<Intake_Item__c>> accountMap = SObjectUtil.groupById(results, 'Account_Name__c');

        if(results.size() > 0) {
            for(Id accountId : accountMap.keySet()) {
                List<Intake_Item__c> intakeItems = accountMap.get(accountId);
                chatterSvc.postFeedItemWithMentions(
                    Network.getNetworkId(), 
                    accountId, 
                    buildMentions(intakeItems) 
                    + 'The following diligence are due soon, but have not been made visible to the client:'
                    + buildItemList(intakeItems)
                    + 'Please check that these items are still needed and make them visible to the client if needed.'
                );
            }
            
            for(Intake_Item__c item : results) {
                item.Sent_Created_Notification__c = true;
            }
            update results;
        }
    }

    private String buildItemName(Intake_Item__c item) {
        return '{record:'+item.Id+'} - ' + item.Due_Date__c.format();
    }
    
    private String buildItemList(List<Intake_Item__c> intakeItems) {
        String listContent = '<ul>';
        for(Intake_Item__c item : intakeItems) {
            listContent += '<li>' + buildItemName(item) + '</li>';
        }
        listContent += '</ul>';
        return listContent;
    }

    private String buildMentions(List<Intake_Item__c> iis) {
        Set<Id> mentionIds = new Set<Id>();
        for (Intake_Item__c ii: iis) {
            mentionIds.add(ContentDocumentLinkTriggerManager.getUserToNotify(ii));
        }
        mentionIds.remove(null);

        List<String> mentions = new List<String>();
        for (Id mentionId: mentionIds) {
            mentions.add('{'+mentionId+'}');
        }
        String m = String.join(mentions, ' ');
        return String.isBlank(m) ? '' : m + ' ';
    }

}