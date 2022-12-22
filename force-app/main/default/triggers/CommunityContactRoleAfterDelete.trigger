trigger CommunityContactRoleAfterDelete on Community_Contact_Role__c (after delete) {
    DiligenceUtils.shareIntakeItems(Trigger.old);
}