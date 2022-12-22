/**=====================================================================
 * Trigger Name: DocuSignStatusTriggerManager
 * Description: Manager for DocuSignStatusTrigger
 * Created Date: [02/16/2018]
 * Created By: John Caughie
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
public class DocuSignStatusTriggerManager {

	public static void OnAfterInsertUpdate(Map<id, dsfs__DocuSign_Status__c> newStatusMap, Map<id, dsfs__DocuSign_Status__c> oldStatusMap) {
		//copyDocuSignStatusAttachmentsToOpportunity(newStatusMap, oldStatusMap);
		createDocumentLinksToOpportunity(newStatusMap, oldStatusMap);
	}

	public static void createDocumentLinksToOpportunity(Map<id, dsfs__DocuSign_Status__c> newStatusMap, Map<id, dsfs__DocuSign_Status__c> oldStatusMap){
		
		// get a list of updated DocuSign statuses
		Map<id, dsfs__DocuSign_Status__c> linkedDocuSignOpps = new Map<id, dsfs__DocuSign_Status__c>();
		for (Id i: newStatusMap.keySet()) {
			if(newStatusMap.get(i).dsfs__Opportunity__c != null && newStatusMap.get(i).dsfs__Opportunity__c != oldStatusMap.get(i).dsfs__Opportunity__c){
				linkedDocuSignOpps.put(i, newStatusMap.get(i));
			}
		}

		// get a list of attachments
		if(linkedDocuSignOpps.size() != 0){
			List<ContentDocumentLink> existingCDLs = new List<ContentDocumentLink>();
			existingCDLs = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = : linkedDocuSignOpps.keySet()];
	
			// create new ContentDocumentLinks
			List<ContentDocumentLink> newCDLs = new List<ContentDocumentLink>();
			for(ContentDocumentLink cdl : existingCDLs){
				newCDLs.add(newContentDocumentLink(cdl.ContentDocumentId, linkedDocuSignOpps.get(cdl.LinkedEntityId).dsfs__Opportunity__c, 'InternalUsers'));
			}
	
			// insert links
			Database.SaveResult[] srCDLsList = Database.insert(newCDLs, false);
		}
		
	}

	private static ContentDocumentLink newContentDocumentLink(Id docId, Id recordId, String visibility){
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.LinkedEntityId = recordId;
		cdl.ContentDocumentId = docId;
		cdl.Visibility = visibility;
		return cdl;
	}	

	// 2020.05.06 Transitioned to Lightning - Attachments be gone!

	// public static void copyDocuSignStatusAttachmentsToOpportunity(Map<id, dsfs__DocuSign_Status__c> newStatusMap, Map<id, dsfs__DocuSign_Status__c> oldStatusMap){
	// 	List<dsfs__DocuSign_Status__c> docuSignStatuses = getUpdatedDocuSignStatusOpportunities(newStatusMap, oldStatusMap);
	// 	List<Id> ids = getDocuSignStatuses(docuSignStatuses);
	// 	List<Attachment> oldAttachments = getAttachments(ids);
	// 	List<Attachment> newAttachments = copyAttachmentsToNewParent(oldAttachments, newStatusMap);
	// 	insert newAttachments;
	// }

	// public static List<dsfs__DocuSign_Status__c> getUpdatedDocuSignStatusOpportunities(Map<id, dsfs__DocuSign_Status__c> newStatusMap, Map<id, dsfs__DocuSign_Status__c> oldStatusMap){
	// 	List<dsfs__DocuSign_Status__c> docuSignStatuses = new List<dsfs__DocuSign_Status__c>();
	// 	for(dsfs__DocuSign_Status__c dsfs : newStatusMap.values()){
	// 		if(dsfs.dsfs__Opportunity__c <> oldStatusMap.get(dsfs.Id).dsfs__Opportunity__c && dsfs.dsfs__Opportunity__c != null){
	// 			docuSignStatuses.add(dsfs);
	// 		}
	// 	}
	// 	System.debug('Statuses: ' + docuSignStatuses);
	// 	return docuSignStatuses;
	// }

	// public static List<Id> getDocuSignStatuses(List<dsfs__DocuSign_Status__c> statuses){
	// 	List<Id> statusIds = new List<Id>();
	// 	for(dsfs__DocuSign_Status__c dsfs : statuses){
	// 		statusIds.add(dsfs.Id);
	// 	}
	// 	System.debug('Status Ids: ' + statusIds);
	// 	return statusIds;
	// }

 	// public static List<Attachment> getAttachments(List<Id> recordIds){
	// 	List<Attachment> attachments = new List<Attachment>();
	// 	attachments = [SELECT Id, ParentId, Name, Body, Description, ContentType FROM Attachment WHERE ParentId = :recordIds];
	// 	System.debug('Attachments: ' + attachments);
	// 	return attachments;
 	// }

 	// public static List<Attachment> copyAttachmentsToNewParent(List<Attachment> oldAttachments, Map<id, dsfs__DocuSign_Status__c> statusMap){
 	// 	List<Attachment> updatedAttachments = new List<Attachment>();
 	// 	updatedAttachments = oldAttachments.deepClone(false, false, false);
 	// 	for(Attachment att : updatedAttachments){
 	// 		att.ParentId = statusMap.get(att.ParentId).dsfs__Opportunity__c;
 	// 	}
 	// 	System.debug('Updated docs: ' + updatedAttachments);
 	// 	return updatedAttachments;
 	// }

}