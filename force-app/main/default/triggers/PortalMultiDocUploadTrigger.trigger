trigger PortalMultiDocUploadTrigger on Portal_Multi_Doc_Upload__c (before insert, after insert, before update, after update, before delete, after delete) {

    if(Trigger.isInsert && Trigger.isAfter){
        PortalMultiDocUploadTriggerHandler.CopyDocToSelectedRecords(Trigger.New);
    }
}