trigger CommunityContactRoleAfterInsert on Community_Contact_Role__c (after insert) {
    DiligenceUtils.shareIntakeItems(Trigger.new);
}