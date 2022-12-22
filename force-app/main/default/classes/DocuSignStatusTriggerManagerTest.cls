/**=====================================================================
 * Trigger Name: DocuSignStatusTriggerManagerTest
 * Description: Test for DocuSignStatusTriggerManager
 * Created Date: [02/16/2018]
 * Created By: John Caughie
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
@isTest
private class DocuSignStatusTriggerManagerTest {

	@testSetup static void recordsSetup(){
		Integer numRecords = 10;
		BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
				Triggers_Disabled__c = false,
				Validation_Rules_Disabled__c = false,
				Workflow_Rules_Disabled__c = false);
			insert ProfileCustomSettings;

			Account charter = new Account();
			charter.Name = 'Test Charter';
			insert charter;

			List<Opportunity> opps = new List<Opportunity>();
			for(Integer i = 0; i < numRecords; i++){
			Opportunity opp = new Opportunity();
			opp.AccountId = charter.Id;
			opp.Name = 'Test Opp ' + i;
			opp.CloseDate = Date.today();
			opp.StageName = 'Stage 1';
			opps.add(opp);
		}
		insert opps;

		List<Id> oppIds = new List<Id>();
		for(Opportunity o : opps){
			oppIds.add(o.Id);
		}

		List<dsfs__DocuSign_Status__c> dsfs = new List<dsfs__DocuSign_Status__c>();
		for(Integer i = 0; i < numRecords; i++){
			dsfs__DocuSign_Status__c docuSign = new dsfs__DocuSign_Status__c();
			dsfs.add(docuSign);
		}	
		insert dsfs;

		List<String> filenames = new List<String>{'TL.pdf', 'RPA.pdf', 'BOS.pdf', 'OC.pdf', 'IC.pdf'};
		// create files content
		List<ContentVersion> listCV = new List<ContentVersion>();
		for(String s: filenames){
			ContentVersion contentVersion = new ContentVersion(
				Title = s,
				PathOnClient = s,
				VersionData = Blob.valueOf('Test Content'),
				IsMajorVersion = true
			);
			listCV.add(contentVersion);
		}
		insert listCV;

		// link to DocuSign status
		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
		List<ContentDocumentLink> existingCDLs = new List<ContentDocumentLink>(); 
		for(ContentDocument cd : documents){
			for(Integer i = 0; i < numRecords; i++){
				ContentDocumentLink cdl = New ContentDocumentLink();
				cdl.LinkedEntityId = dsfs[i].id;
				cdl.ContentDocumentId = cd.Id;
				cdl.shareType = 'V';
				existingCDLs.add(cdl);
			}
		}
		insert existingCDLs;
		
	}

	@isTest static void testDocuSignStatusUpdate(){
		List<Opportunity> opps = new List<Opportunity>();
		opps = [SELECT Id FROM Opportunity];
		List<Id> oppIds = new List<Id>();
		List<dsfs__DocuSign_Status__c> docuSigns = new List<dsfs__DocuSign_Status__c>();
		docuSigns = [SELECT id FROM dsfs__DocuSign_Status__c];

		for (Integer i = 0; i < 10; i++) {
			docuSigns[i].dsfs__Opportunity__c = opps[i].Id;
			oppIds.add(opps[i].Id);
		}

		Integer docsBefore = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :oppIds].size();
		Test.startTest();
			update docuSigns;
		Test.stopTest();
		Integer docsAfter = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :oppIds].size();
		System.assertEquals(10 * 0, docsBefore, 'DocuSign Statuses not linked');
		System.assertEquals(10 * 5, docsAfter, '5 created for each opportunity');

	}

	// private static List<dsfs__DocuSign_Status__c> dsfs;
	// private static List<Opportunity> opps;
	// private static List<Id> oppIds;
	// private static Integer docCount = 20;

	// static testMethod void testStatusAssignment(){
	// 	Integer numDocuSigns = 10;
	// 	createTestData(numDocuSigns);
	// 	for(Integer i = 0; i < numDocuSigns; i++){
	// 		dsfs[i].dsfs__Opportunity__c = opps[i].Id;
	// 	}
	// 	Test.startTest();
	// 	update dsfs;
	// 	Test.stopTest();

	// 	List<AggregateResult> numberOppAtts = [SELECT count(id) numDocs FROM Attachment WHERE parentId IN :oppIds GROUP BY parentId];
	// 	System.debug(numberOppAtts);

	// 	for(AggregateResult ar : numberOppAtts){
	// 		System.assertEquals(docCount, ar.get('numDocs'), 'Incorrect number of docs');
	// 	}
	// }

	// static testMethod void testUnchangedStatusAssignment(){
	// 	Integer numDocuSigns = 1;
	// 	createTestData(numDocuSigns);
	// 	for(Integer i = 0; i < numDocuSigns; i++){
	// 		dsfs[i].dsfs__Opportunity__c = null;
	// 	}
	// 	Test.startTest();
	// 	update dsfs;
	// 	Test.stopTest();

	// 	List<AggregateResult> numberOppAtts = [SELECT count(id) numDocs FROM Attachment WHERE parentId IN :oppIds GROUP BY parentId];
	// 	System.debug(numberOppAtts);

	// 	for(AggregateResult ar : numberOppAtts){
	// 		System.assertEquals(0, ar.get('numDocs'), 'Incorrect number of docs');
	// 	}
	// }

	// private static void createTestData(Integer numDocuSigns){
		
	//     BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
	//                                             Triggers_Disabled__c = false,
	//                                             Validation_Rules_Disabled__c = false,
	//                                             Workflow_Rules_Disabled__c = false);
	//     insert ProfileCustomSettings;

	// 	Account charter = new Account();
	// 	charter.Name = 'Test Charter';
	// 	insert charter;

	// 	opps = new List<Opportunity>();
	// 	for(Integer i = 0; i < numDocuSigns; i++){
	// 		Opportunity opp = new Opportunity();
	// 		opp.AccountId = charter.Id;
	// 		opp.Name = 'Test Opp ' + i;
	// 		opp.CloseDate = Date.today();
	// 		opp.StageName = 'Stage 1';
	// 		opps.add(opp);
	// 	}
	// 	insert opps;

	// 	oppIds = new List<Id>();
	// 	for(Opportunity o : opps){
	// 		oppIds.add(o.Id);
	// 	}

	// 	dsfs = new List<dsfs__DocuSign_Status__c>();
	// 	for(Integer i = 0; i < numDocuSigns; i++){
	// 		dsfs__DocuSign_Status__c docuSign = new dsfs__DocuSign_Status__c();
	// 		dsfs.add(docuSign);
	// 	}	
	// 	insert dsfs;

	// 	List<Attachment> atts = new List<Attachment>();
	// 	for(dsfs__DocuSign_Status__c d : dsfs){
	// 		for(Integer i = 0; i < docCount; i++){
	// 			Attachment att = new Attachment();
	// 			att.ParentId = d.Id;
	// 			att.Name = 'Test file';
	// 			Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
	// 	        att.body = bodyBlob;
	// 	        atts.add(att);
	// 		}
	// 	}
	// 	insert atts;

	// }
}