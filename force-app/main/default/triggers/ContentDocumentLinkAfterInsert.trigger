trigger ContentDocumentLinkAfterInsert on ContentDocumentLink (after insert) {
    /*[02/10/20] - J Caughie - This custom setting is used to conditionally control for which users/profile or the entire org
    the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    if(ProfileCustomSettings.Trigger_Objects__c == null){
        ProfileCustomSettings.Trigger_Objects__c = '';
    }
    if(ProfileCustomSettings.Triggers_Disabled__c == null){
        ProfileCustomSettings.Triggers_Disabled__c = false;
    }
    if(!(ProfileCustomSettings.Trigger_Objects__c.containsIgnoreCase('ContentDocumentLink') && ProfileCustomSettings.Triggers_Disabled__c)){    
        //molinger - for PQ Intake Item Attachment, set the status to Submitted
        Set<Id> attids = new Set<Id>();
        transient Map<Id,Id> docIds = new Map<Id,Id>();
        transient Map<Id,Id> docLinkedIds = new Map<Id,Id>();
        Id uId = UserInfo.getUserId();
        User u = [Select Id, IsPortalEnabled from USer where id=:uId];
        
        if (u.IsPortalEnabled) {
            for(ContentDocumentLink c:Trigger.new){
                System.debug('****ContentDocumentLink upload: ' + c);
                if(c.LinkedEntityID != null) {
                    attids.add(c.LinkedEntityID);
                    docIds.put(c.ContentDocumentId,c.LinkedEntityID);
                    docLinkedIds.put(c.LinkedEntityID,c.ContentDocumentId);
                }
            }
        }
        /* 
            transient Map<STring,ContentVersion> docNameMap = new Map<String,ContentVersion>();
            
            //maps contentdocumentid to folder id
            transient Map<Id,String> folderMap = new Map<Id,String>();
            
            //get folder id to put docuements in
            for (Intake_Item__c i : [Select Id, Opportunity__r.Client_External_Box_Folder_Id__c from Intake_Item__c where Id IN: attids]) {
                if (i.Opportunity__r.Client_External_Box_Folder_Id__c!=null) {
                    folderMap.put(docLinkedIds.get(i.Id),i.Opportunity__r.Client_External_Box_Folder_Id__c);
                } else {
                    //send error email
                    DiligenceUtils.sendErrorEMail('Cannot upload document: ' + docLinkedIds.get(i.Id) + ' for item id ' + i.Id + ' to Box.  Opportuniy field Client External Box Folder Id does not exist', 'Error uploading document to Box');
                }
            }
            
            
            if (docIds.size()>0) {
                List<ContentVersion> files = new List<ContentVersion>();
                for (ContentVersion cd : [Select  Id, Title, FileExtension, VersionData, ContentDocumentId  From ContentVersion where ContentDocumentId IN:docIds.keyset()]) {
                    if (cd.Title!=null) {
                        //upload doc to Box
                        System.debug('***Limits.getHeapSize(): ' + Limits.getHeapSize());
                        System.debug('***Limits.getLimitHeapSize(): ' + Limits.getLimitHeapSize());
                        transient String encoded = EncodingUtil.base64Encode(cd.VersionData);
                        System.debug('***folderid: ' +folderMap.get(cd.ContentDOcumentId) );
                        if (folderMap.get(cd.ContentDOcumentId) !=null) {
                            BoxAPIUtils.uploadDocument(docIds.get(cd.ContentDOcumentId),folderMap.get(cd.ContentDOcumentId), cd.Title+'.'+cd.FileExtension,encoded);
                        }
                    }            
                }
            }
        */
    
        List<Intake_item__c>  ii = new List<Intake_Item__c>();
        for (Intake_Item__c i : [Select Id, Status__c, Opportunity__r.Client_External_Box_Folder_Id__c from Intake_Item__c where Id IN: attids]) {
            
            if (i.status__c==DiligenceVars.IntakePendingStatus||i.status__c==DiligenceVars.IntakeSubmittedStatus || i.status__c==DiligenceVars.IntakeInputNeededStatus || i.status__c==DiligenceVars.IntakeApprovedStatus) {
                i.status__c = DiligenceVars.IntakeSubmittedStatus;
                ii.add(i);
            } /*else if(i.status__c == DiligenceVars.IntakeApprovedStatus){
                continue;
            }*/ else {
                throw new BoxUtils.BoxAuthException('You cannot upload new documents after it has been Accepted');
            }
            
        }

        if (ii.size()>0) { update ii; }


        if(Trigger.isAfter && Trigger.isInsert){
            ContentDocumentLinkTriggerManager.OnAfterInsertUpdate(Trigger.new, Trigger.newMap);
        }

    }
}