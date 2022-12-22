trigger CommunityContactRoleAfterUpdate on Community_Contact_Role__c (after update) {
    List<Community_Contact_Role__c> changed = new List<Community_Contact_Role__c>();

    for (Community_Contact_Role__c oldCCR: Trigger.old) {
        Community_Contact_Role__c newCCR = Trigger.newMap.get(oldCCR.Id);

        if (
            oldCCR.Opportunity__c != newCCR.Opportunity__c ||
            oldCCR.Account__c != newCCR.Account__c ||
            oldCCR.Contact__c != newCCR.Contact__c
        ) {
            changed.add(newCCR);
        }
    }

    DiligenceUtils.shareIntakeItems(changed);
}