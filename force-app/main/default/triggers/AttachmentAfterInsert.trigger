/**=====================================================================
 * Manager Class Name: AttachmentAfterInsert
 * Description: Attachment triggers
 * Created Date: 
 * Created By: C-Level, modified by Appirio and John Caughie
 * Date Modified                Modified By                  Description of the update
 * 2017.09.01                   John Caughie                Opportunity attachments - NOTE THAT THIS CLASS NEEDS TO BE REFACTORED
 =====================================================================*/
trigger AttachmentAfterInsert on Attachment (after insert) {
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
    // 05/06/2014 : Manisha Gupta : Add null check (T-276525)
    if(ProfileCustomSettings.Trigger_Objects__c == null){
        ProfileCustomSettings.Trigger_Objects__c = '';
    }
    if(ProfileCustomSettings.Triggers_Disabled__c == null){
        ProfileCustomSettings.Triggers_Disabled__c = false;
    }
    if(!true){
    //if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('attachment') && ProfileCustomSettings.Triggers_Disabled__c)){
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
        Set<Id> itemIds = new Set<Id>();
        Set<Id> legalDocIds = new Set<Id>();
        Set<Id> resIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();                                                //2019.01.25 J Caughie - Move attachments from opp to Opp Content
        List<Attachment> moveAttachments = new List<Attachment>();

        for(Attachment attach : trigger.new) {
            Schema.sObjectType sobjType = attach.ParentId.getSObjectType();

            if(sobjType == CSC_Action_Item__c.sObjectType) {
                itemIds.add(attach.ParentId);
                moveAttachments.add(attach);
            } else if(sobjType == Legal_Doc__c.sObjectType) {
                legalDocIds.add(attach.ParentId);
                moveAttachments.add(attach);
            } else if(sobjType == Resolution__c.sObjectType) {
                resIds.add(attach.ParentId);
                moveAttachments.add(attach);
            } else if(sobjType == Opportunity.sObjectType && attach.Name.toUpperCase().contains('_COMPLETED')){                 //2019.01.25 J Caughie - Move attachments from opp to Opp Content
                oppIds.add(attach.ParentId);
                moveAttachments.add(attach);
            }
        }

        if(!moveAttachments.isEmpty()) {
            Set<String> libraryTypes = new Set<String>();
            Map<Id, String> objLibTypeMap = new Map<Id, String>();
            Map<Id, CSC_Action_Item__c> actionItemMap = new Map<Id, CSC_Action_Item__c>();
            Map<Id, Legal_Doc__c> legalDocMap = new Map<Id, Legal_Doc__c>();
            Map<Id, Resolution__c> resolutionMap = new Map<Id, Resolution__c>();
            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();                //2019.01.25 J Caughie - Move attachments from opp to Opp Content

            if(!itemIds.isEmpty()) {
                for(CSC_Action_Item__c actionItem : [SELECT Id, CSC_Action_List__c, CSC_Action_List__r.Account__c, Library_Type__c FROM CSC_Action_Item__c WHERE Id IN :itemIds]) {
                    if(String.isNotBlank(actionItem.Library_Type__c)) {
                        actionItemMap.put(actionItem.Id, actionItem);
                        String libType = actionItem.Library_Type__c.toLowerCase();
                        libraryTypes.add(libType);
                        objLibTypeMap.put(actionItem.Id, libType);
                    }
                }
            }

            if(!legalDocIds.isEmpty()) {
                for(Legal_Doc__c doc : [SELECT Id, Account__c, Library_Type__c FROM Legal_Doc__c WHERE Id IN :legalDocIds]) {
                    if(String.isNotBlank(doc.Library_Type__c)) {
                        legalDocMap.put(doc.Id, doc);
                        String libType = doc.Library_Type__c.toLowerCase();
                        libraryTypes.add(libType);
                        objLibTypeMap.put(doc.Id, libType);
                    }
                }
            }

            if(!resIds.isEmpty()) {
                for(Resolution__c res : [SELECT Id, School__c, Library_Type__c FROM Resolution__c WHERE Id IN :resIds]) {
                    if(String.isNotBlank(res.Library_Type__c)) {
                        resolutionMap.put(res.Id, res);
                        String libType = res.Library_Type__c.toLowerCase();
                        libraryTypes.add(libType);
                        objLibTypeMap.put(res.Id, libType);
                    }
                }
            }

            //2019.01.25 J Caughie - Move attachments from opp to Opp Content
            if(!oppIds.isEmpty()) {
                for(Opportunity opp : [SELECT Id, RPA__c, Terms_Letter__c, Library_Type__c FROM Opportunity WHERE Id IN :oppIds]) {
                    if(String.isNotBlank(opp.Library_Type__c)) {
                        opportunityMap.put(opp.Id, opp);
                        String libType = opp.Library_Type__c.toLowerCase();
                        libraryTypes.add(libType);
                        objLibTypeMap.put(opp.Id, libType);
                    }
                }  
            }
            //2019.01.25 J Caughie - Move attachments from opp to Opp Content

            if(!libraryTypes.isEmpty()) {
                Map<String, ContentWorkspace> libraryMap = new Map<String, ContentWorkspace>();
                Map<Id, ContentVersion> contentVerMap = new Map<Id, ContentVersion>();

                for(ContentWorkspace workspace : [SELECT Id, Name FROM ContentWorkspace WHERE Name IN :libraryTypes]) {
                    libraryMap.put(workspace.Name.toLowerCase(), workspace);
                }

                for(Attachment attach : moveAttachments) {
                    if(objLibTypeMap.containsKey(attach.ParentId)) {
                        String libType = objLibTypeMap.get(attach.ParentId);

                        if(String.isNotBlank(libType) && libraryMap.containsKey(libType)) {
                            ContentWorkspace workspace = libraryMap.get(libType);

                            ContentVersion contentVer = new ContentVersion(
                                Title = attach.Name,
                                PathOnClient = attach.Name,
                                VersionData = attach.Body,
                                FirstPublishLocationId = workspace.Id
                            );

                            if(actionItemMap.containsKey(attach.ParentId)) {
                                CSC_Action_Item__c item = actionItemMap.get(attach.ParentId);
                                contentVer.CSC_Action_Item__c = item.Id;
                                contentVer.CSC_Action_List__c = item.CSC_Action_List__c;
                                contentVer.Account__c = item.CSC_Action_List__r.Account__c;
                            }

                            if(legalDocMap.containsKey(attach.ParentId)) {
                                Legal_Doc__c doc = legalDocMap.get(attach.ParentId);
                                contentVer.Legal_Doc__c = doc.Id;
                                contentVer.Account__c = doc.Account__c;
                            }

                            if(resolutionMap.containsKey(attach.ParentId)) {
                                Resolution__c res = resolutionMap.get(attach.ParentId);
                                contentVer.Resolution__c = res.Id;
                                contentVer.Account__c = res.School__c;
                            }
                            
                            //2019.01.25 J Caughie - Move attachments from opp to Opp Content
                            if(opportunityMap.containsKey(attach.ParentId)) {
                                Opportunity opp = opportunityMap.get(attach.ParentId);
                                contentVer.Opportunity__c = opp.Id;
                                //if name contains Terms Letter link to RPA
                                Pattern termsLetter = Pattern.compile('(.+[^a-zA-Z]TL[^a-zA-Z].+)');
                                Matcher tlMatch = termsLetter.matcher(attach.name.toUpperCase());
                                Boolean includesTL = tlMatch.matches();
                                if (includesTL){
                                    contentVer.Terms_Letter__c = opp.Terms_Letter__c;
                                }
                                //if name contains RPA link to Terms Letter
                                Pattern rpa = Pattern.compile('(.+[^a-zA-Z]RPA[^a-zA-Z].+)');
                                Matcher rpaMatch = rpa.matcher(attach.name.toUpperCase());
                                Boolean includesRPA = rpaMatch.matches();
                                if (includesRPA){
                                    contentVer.RPA__c = opp.RPA__c;
                                }
                                //contentVer.Account__c = res.School__c;
                            }
                            //2019.01.25 J Caughie - Move attachments from opp to Opp Content

                            contentVerMap.put(attach.Id, contentVer);
                        }
                    }
                }

                if(!contentVerMap.isEmpty()) {
                    insert contentVerMap.values();
                    CSCUtils.deleteAttachments(contentVerMap.keySet());
                }
            }
        }
    }
}