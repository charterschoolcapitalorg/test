public class UrgentItemsCtlr {
    @AuraEnabled
    public static List<IntakeItemWrapper> getUrgentItems(){
        List<Opportunity> openOpportunities = MyItemsCtlr.getOpenOpportunities();
        List<Account> accounts = MyAccountItemsCtlr.getAccounts();

        List<IntakeItemWrapper> items = new List<IntakeItemWrapper>();
        items.addAll(MyAccountItemCtlr.getIntakeItems(new Map<Id,Account>(accounts).keySet(), null));
        items.addAll(MyItemCtlr.getIntakeItems(new Map<Id,Opportunity>(openOpportunities).keySet(), null));

        List<IntakeItemWrapper> urgentItems = new List<IntakeItemWrapper>();
        for(IntakeItemWrapper i : flatten(items)) {
            if (i.item.Show_in_Urgent_Tab__c) {
                urgentItems.add(i);
            }
        }

        urgentItems.sort();

        return urgentItems;
    }

    private static List<IntakeItemWrapper> flatten(List<IntakeItemWrapper> items) {
        List<IntakeItemWrapper> flattened = new List<IntakeItemWrapper>();
        for (IntakeItemWrapper i: items) {
            if (i.hasChildren) {
                if (i.children != null) {
                    flattened.addAll(i.children);
                }
            } else {
                flattened.add(i);
            }
        }
        return flattened;
    }
}