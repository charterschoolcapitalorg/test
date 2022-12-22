public class ContentDocumentLinkTriggerManager {
	
	static Map<String, Diligence_Upload_Notification__mdt> departmentMap = getDepartments();
	
	static Map<String, ContentWorkspace> libraryMap{
		get{
			if(libraryMap == null){
				libraryMap = new Map<String, ContentWorkspace>();
				for(ContentWorkspace cw : [SELECT Id, Name FROM ContentWorkspace]){
					libraryMap.put(cw.Name, cw);
				}
			}
			return libraryMap;
		}
			set;
		}

	public static Map<String, Diligence_Upload_Notification__mdt> getDepartments(){
		List<Diligence_Upload_Notification__mdt> oppUser = new List<Diligence_Upload_Notification__mdt>();
		oppUser = [SELECT Department_Picklist__c, Opportunity_Users__c, Account_Users__c, Default_User_ID__c FROM Diligence_Upload_Notification__mdt];
		Map<String, Diligence_Upload_Notification__mdt> departmentMap = new Map<String, Diligence_Upload_Notification__mdt>();
		for(Diligence_Upload_Notification__mdt dun : oppUser){
			departmentMap.put(dun.Department_Picklist__c, dun);
		}
		System.debug(departmentMap);
		return departmentMap;
	}

	public static String getUserToNotify(Intake_Item__c ii) {
		Id userId = null;

		SObject parentObj = ii.Opportunity__r == null ? (SObject)ii.Account_Name__r : (SObject)ii.Opportunity__r;
		SObjectField userField = ii.Opportunity__r == null ? Diligence_Upload_Notification__mdt.Account_Users__c : Diligence_Upload_Notification__mdt.Opportunity_Users__c;

		if(departmentMap.get(ii.Department__c) != null && departmentMap.get(ii.Department__c).get(userField) != null){
			System.debug(parentObj.get((String)departmentMap.get(ii.Department__c).get(userField)));
			userId = (Id) parentObj.get((String)departmentMap.get(ii.Department__c).get(userField));
		} else if(departmentMap.get(ii.Department__c) != null){
			System.debug(departmentMap.get(ii.Department__c).Default_User_ID__c);
			userId = departmentMap.get(ii.Department__c).Default_User_ID__c;
		}

		return userId;
	}

	public static void OnAfterInsertUpdate(List<ContentDocumentLink> documentLinks, Map<Id, ContentDocumentLink> idToMapCDL) {
		System.debug('Doc Links: ' + documentLinks);
		sendExternalUploadNotifications(documentLinks, idToMapCDL);
		// 2020.03.27 J Caughie - toggle the following to link opportunity WC docs to related records, eg RPA & Terms Letter
		insertRelatedContentDocLinks(idToMapCDL);
	}

	public static void sendExternalUploadNotifications(List<ContentDocumentLink> documentLinks, Map<Id, ContentDocumentLink> idToDocLinks){

		Set<Id> docIds = new Set<Id>();
		Set<Id> itemIds = new Set<Id>();
		
		//Parse through ContentDocumentLinks for Document Ids
		for(ContentDocumentLink cdl : documentLinks){
			docIds.add(cdl.ContentDocumentId);
		}

		//Get list of documents created by external users
		List<ContentDocument> cd = new List<ContentDocument>();
		cd = [SELECT Id FROM ContentDocument WHERE Id IN : docIds AND Owner.UserType = 'PowerPartner'];
		System.debug('Docs: ' + cd);
		//Convert to set of Document Ids
		Set<Id> cdlIds = (new Map<Id,SObject>(cd)).keySet();
		System.debug('cdlIds' + cdlIds);

		//proceed if docs uploaded by external users
		List<ContentDocumentLink> externalCDL = new List<ContentDocumentLink>();
		if(cd != null){

			//Filter ContentDocumentLinks for uploads by external users
			for(ContentDocumentLink cdl : documentLinks){
				if(cdlIds.contains(cdl.ContentDocumentId)){
					externalCDL.add(cdl);
				}
			}
			System.debug('externalCDL: ' + externalCDL);

			//list of intake items uploaded by external users
			for(ContentDocumentLink cdl : externalCDL){
				switch on String.valueOf(cdl.LinkedEntityId.getSObjectType()){
					when 'Intake_Item__c'{
						itemIds.add(cdl.LinkedEntityId);
					}
				}
			}
			System.debug('Items: ' + itemIds);

			//Only send alerts for item files uploaded by external users
			if(itemIds.size() != 0){
				System.debug('Items uploaded');
				sendNotifications(itemIds, idToDocLinks);
			}
		}

	}


	public static void insertRelatedContentDocLinks(Map<Id, ContentDocumentLink> idToCDLMap){
		List<ContentDocumentLink> newCDLs = new List<ContentDocumentLink>();
		List<ContentWorkspaceDoc> newCWDs = new List<ContentWorkspaceDoc>();
		
		List<Id> opportunityIds = new List<Id>();
		List<Id> resolutionIds = new List<Id>();
		List<Id> actionItemIds = new List<Id>();
		List<String> libraryNames = new List<String>();
	
		//loop through docs to get list of original objects - looking for Opportunity, Resolutions or Action Items
		for(ContentDocumentLink cdl : idToCDLMap.values()){
			if(cdl.LinkedEntityId.getSobjectType() == Schema.Opportunity.SObjectType){
				opportunityIds.add(cdl.LinkedEntityId);
			} else if(cdl.LinkedEntityId.getSobjectType() == Schema.Resolution__c.SObjectType){
				resolutionIds.add(cdl.LinkedEntityId);
			} else if(cdl.LinkedEntityId.getSobjectType() == Schema.CSC_Action_Item__c.SObjectType){
				actionItemIds.add(cdl.LinkedEntityId);
			}
		}
		
		//
		System.debug('# of opportunities: ' + opportunityIds.size());
		System.debug('# of resolutionIds: ' + resolutionIds.size());
		System.debug('# of actionItemIds: ' + actionItemIds.size());


		//query for related records - fields needed to create links
		Map<ID, Opportunity> idOpportunityMap;
		if(opportunityIds.size() > 0) idOpportunityMap = new Map<ID, Opportunity>([SELECT Id, RPA__c, Terms_Letter__c, Library_Type__c FROM Opportunity WHERE Id IN :opportunityIds]);
		Map<ID, Resolution__c> idResolutionMap;
		if(resolutionIds.size() > 0) idResolutionMap = new Map<ID, Resolution__c>([SELECT Id, School__c, Library_Type__c FROM Resolution__c WHERE Id IN :resolutionIds]);
		Map<ID, CSC_Action_Item__c> idActionItemMap;
		if(actionItemIds.size() > 0) idActionItemMap = new Map<ID, CSC_Action_Item__c>([SELECT Id, CSC_Action_List__c, CSC_Action_List__r.Account__c, Library_Type__c FROM CSC_Action_Item__c WHERE Id IN :actionItemIds]);

		//Re-query CDLs to get Title - needed to check for RPA & TL documents
		Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocument.FileType FROM ContentDocumentLink WHERE Id IN :idToCDLMap.keySet()]);
		System.debug('cdlMap: ' + cdlMap);		
		
		//loop again creating new CDL records
		for(ContentDocumentLink cdl : cdlMap.values()){
			System.debug('cdl ' + cdl);
			if(cdl.ContentDocument.FileType != 'SNOTE'){
				if(cdl.LinkedEntityId.getSobjectType() == Schema.Opportunity.SObjectType){
					if(nameContainsTermsLetterLegalIdentifier(cdl.ContentDocument.Title) && idOpportunityMap.get(cdl.LinkedEntityId).Terms_Letter__c != null){
						newCDLs.add(newContentDocumentLink(cdl.ContentDocumentId, idOpportunityMap.get(cdl.LinkedEntityId).Terms_Letter__c, 'InternalUsers'));
					}
					if(nameContainsRPALegalIdentifier(cdl.ContentDocument.Title) && idOpportunityMap.get(cdl.LinkedEntityId).RPA__c != null){
						newCDLs.add(newContentDocumentLink(cdl.ContentDocumentId, idOpportunityMap.get(cdl.LinkedEntityId).RPA__c, 'InternalUsers'));
					}
					newCWDs.add(newContentWorkspaceDoc(cdl.ContentDocumentId, idOpportunityMap.get(cdl.LinkedEntityId).Library_Type__c));
				} else if(cdl.LinkedEntityId.getSobjectType() == Schema.Resolution__c.SObjectType){
					newCDLs.add(newContentDocumentLink(cdl.ContentDocumentId, idResolutionMap.get(cdl.LinkedEntityId).School__c, 'InternalUsers'));
					newCWDs.add(newContentWorkspaceDoc(cdl.ContentDocumentId, idResolutionMap.get(cdl.LinkedEntityId).Library_Type__c));
				} else if(cdl.LinkedEntityId.getSobjectType() == Schema.CSC_Action_Item__c.SObjectType){
					newCDLs.add(newContentDocumentLink(cdl.ContentDocumentId, idActionItemMap.get(cdl.LinkedEntityId).CSC_Action_List__c, 'InternalUsers'));
					newCDLs.add(newContentDocumentLink(cdl.ContentDocumentId, idActionItemMap.get(cdl.LinkedEntityId).CSC_Action_List__r.Account__c, 'InternalUsers'));
					newCWDs.add(newContentWorkspaceDoc(cdl.ContentDocumentId, idActionItemMap.get(cdl.LinkedEntityId).Library_Type__c));
				}
			}
		}

		Database.insert(newCDLs, false);
		Database.insert(newCWDs, false);

		/* Removed as errors are always already linked/shared 
		//consolidate error messages
		String uploadErrors = '';

		Database.SaveResult[] srCDLsList = Database.insert(newCDLs, false);
		// Iterate through each returned result
		for (Database.SaveResult sr : srCDLsList) {
			if (!sr.isSuccess()) {
				uploadErrors += 'Content Document List errors: \n';
				// Operation failed, so get all errors                
				for(Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.' + err);
					uploadErrors += (err.getStatusCode() + ': ' + err.getMessage());
					uploadErrors += '\n';
					uploadErrors += err.getFields();
					uploadErrors += '\n============\n';
					System.debug('The following error has occurred.');                    
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Content Document fields that affected this error: ' + err.getFields());
				}
			}
		}

		Database.SaveResult[] srCWDsList = Database.insert(newCWDs, false);
		// Iterate through each returned result
		for (Database.SaveResult sr : srCWDsList) {
			System.debug('srCDLsList ' + sr);
			if (!sr.isSuccess()) {
				uploadErrors += 'Content Workspace List errors: \n';
				// Operation failed, so get all errors                
				for(Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.' + err);
					uploadErrors += (err.getStatusCode() + ': ' + err.getMessage());
					uploadErrors += '\n';
					uploadErrors += err.getFields();
					uploadErrors += '\n============\n';
					System.debug('The following error has occurred.');                    
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Content Workspace fields that affected this error: ' + err.getFields());
				}
			}
		}

		if(String.isNotEmpty(uploadErrors)){
			List<String> emailContacts = new List<String>{'jcaughie@charterschoolcapital.com'};
			EmailUtils.sendTextEmail(emailContacts, 'Upload errors', uploadErrors);
		}
		*/
	}

	private static Boolean nameContainsTermsLetterLegalIdentifier(String fileName){
		Boolean containsTL = false;
		Pattern termsLetter = Pattern.compile('(.+[^a-zA-Z0-9]TL[^a-zA-Z0-9].+)');
		Matcher tlMatch = termsLetter.matcher(fileName.toUpperCase());
		Boolean includesTL = tlMatch.matches();
		if (includesTL){
			containsTL = true;
		}
		return containsTL;
	}

	private static Boolean nameContainsRPALegalIdentifier(String fileName){
		Boolean containsRPA = false;
		Pattern rpa = Pattern.compile('(.+[^a-zA-Z0-9]RPA[^a-zA-Z0-9].+)');
		Matcher rpaMatch = rpa.matcher(fileName.toUpperCase());
		Boolean includesRPA = rpaMatch.matches();
		if (includesRPA){
			containsRPA = true;
		}
		return containsRPA;
	}

	private static ContentDocumentLink newContentDocumentLink(Id docId, Id recordId, String visibility){
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.LinkedEntityId = recordId;
		cdl.ContentDocumentId = docId;
		cdl.Visibility = visibility;
		return cdl;
	}

	private static ContentWorkspaceDoc newContentWorkspaceDoc(Id docId, String libraryName){
		ContentWorkspaceDoc cwdRecord = new ContentWorkspaceDoc();
		cwdRecord.ContentDocumentId = docId;
		cwdRecord.ContentWorkspaceId = libraryMap.get(libraryName).Id;
		return cwdRecord;
	}

	public static List<Intake_Item__c> getItems(Set<Id> itemIds){
		//Get a list of Intake Items plus opportunity users
		List<String> fields = new List<String> {
			'Id',
			'Name',
			'Department__c',
			'Opportunity__c',
			'Opportunity__r.Name',
			'Opportunity__r.Id',
			'Account_Name__c',
			'Account_Name__r.Name',
			'Account_Name__r.Id',
			'Due_Date__c'
		};

		for (PicklistEntry ple: Diligence_Upload_Notification__mdt.Account_Users__c.getDescribe().getPicklistValues()) {
			if (ple.isActive()) {
				fields.add('Account_Name__r.'+ple.getValue());
			}
		}

		for (PicklistEntry ple: Diligence_Upload_Notification__mdt.Opportunity_Users__c.getDescribe().getPicklistValues()) {
			if (ple.isActive()) {
				fields.add('Opportunity__r.'+ple.getValue());
			}
		}

		List<Intake_Item__c> items = Database.query(
			QueryUtil.getSelect(fields, 'Intake_Item__c')
				.withCondition(QueryUtil.getIn('Id', itemIds))
				.toString()
		);

		System.debug('items: ' + items);
		return items;
	}


	private static void sendNotifications(Set<Id> itemIds, Map<Id, ContentDocumentLink> idToDocLinks){

		List<Intake_Item__c> items = getItems(itemIds);
		Map<Id, Intake_Item__c> idToIntakeItemMap = new Map<Id, Intake_Item__c>(items);

		//Map of intake item to set of content document links 
		List<ContentDocumentLink> cdls = [SELECT Id, ContentDocument.Title, ContentDocumentId, LinkedEntity.Name, LinkedEntityId FROM ContentDocumentLink WHERE Id IN : idToDocLinks.keySet() AND LinkedEntityId IN :items];
		System.debug(cdls);
		Map<Id, Set<ContentDocumentLink>> entityToDocLinks = new Map<Id, Set<ContentDocumentLink>>();
		Set<ContentDocumentLink> tempCDL = new Set<ContentDocumentLink>();
		for(ContentDocumentLink cdl : cdls){
			if(entityToDocLinks.containsKey(cdl.LinkedEntityId)){
				tempCDL = entityToDocLinks.get(cdl.LinkedEntityId);
				tempCDL.add(cdl);
			} else {
				tempCDL.add(cdl);
			}
			entityToDocLinks.put(cdl.LinkedEntityId, tempCDL);
		}
		System.debug('entityToDocLinks: ' + entityToDocLinks);

		//Map of user Id to content doc links
		Map<Id, Set<ContentDocumentLink>> userIdToContentDocLink = new Map<Id, Set<ContentDocumentLink>>();
		for(Intake_Item__c ii : items){
			Id userId = getUserToNotify(ii);
			if(userId != null){
				userIdToContentDocLink.put(userId, entityToDocLinks.get(ii.Id));
			}
		}

		//Send emails for docs
		if(userIdToContentDocLink.size() > 0){
			for(Id u : userIdToContentDocLink.keySet()){
				System.debug('Gotcha');
				String htmlBody = '';
				for(ContentDocumentLink cdl : userIdToContentDocLink.get(u)){
					Intake_Item__c ii = idToIntakeItemMap.get(cdl.LinkedEntityId);
					SObject parentObj = ii.Opportunity__r == null ? (SObject)ii.Account_Name__r : (SObject)ii.Opportunity__r;
					String label = parentObj.getSObjectType().getDescribe().getLabel();
					htmlBody += ('<p>' + '<a href="'+ URL.getOrgDomainUrl().toExternalForm() + '/' + cdl.ContentDocumentId + '">' + cdl.ContentDocument.Title + '</a>' + ' was uploaded to:</p>');
					htmlBody += ('<ul><li>' + label + ' <a href="'+ URL.getOrgDomainUrl().toExternalForm() + '/' + parentObj.Id + '">' + (String)parentObj.get('Name') + '</a>');
					htmlBody += (' - Intake item <a href="'+ URL.getOrgDomainUrl().toExternalForm() + '/' + cdl.LinkedEntityId + '">' + cdl.LinkedEntity.Name + '</a>' + '</li></ul>');
				}
				EmailUtils.sendNoReplyHTMLEmail(u, null, 'Client Portal documents uploaded', htmlBody, 'salesforce@charterschoolcapital.com');
			}

		}
		

	}

}