@isTest
private class AttachmentTriggerManagerTest {
	
	/* CSC Icons test
		static testMethod void testInsertFiles() {
			Test.startTest();
			createTestData();
			Test.stopTest();

			List<Attachment> afterInsertAttachments = [SELECT Id, Name FROM Attachment];
			System.assertEquals(100, afterInsertAttachments.size(), 'Should be 50 for contacts and accounts totalling 100.');
			System.assertEquals('csc_icon.png', afterInsertAttachments[0].Name, 'csc_icons.png shouldn\'t exist');
		}
		
		private static void createTestData (){
			Account acc = new Account(Name = 'Test Account');
			insert acc;

			Contact con = new Contact(FirstName = 'Jack', LastName = 'Jones', AccountId = acc.Id);
			insert con;

			List<Attachment> accAttachments = new List<Attachment>();
			for(Integer i = 0; i < 50; i++){
				Attachment att = new Attachment();
				att.Body = Blob.valueOf('Some value here');
				att.Name = String.valueOf('csc_icon.png');
				att.ParentId = acc.Id;
				accAttachments.add(att); 
			}

			for(Integer i = 0; i < 50; i++){
				Attachment att = new Attachment();
				att.Body = Blob.valueOf('Some value here');
				att.Name = String.valueOf('csc_icons.png');
				att.ParentId = acc.Id;
				accAttachments.add(att); 
			}

			for(Integer i = 0; i < 50; i++){
				Attachment att = new Attachment();
				att.Body = Blob.valueOf('Some value here');
				att.Name = String.valueOf('csc_icons.png');
				att.ParentId = con.Id;
				accAttachments.add(att); 
			}

			for(Integer i = 0; i < 50; i++){
				Attachment att = new Attachment();
				att.Body = Blob.valueOf('Some value here');
				att.Name = String.valueOf('csc_icon.png');
				att.ParentId = con.Id;
				accAttachments.add(att); 
			}		

			insert accAttachments;

		}
	*/
	
    // static testMethod void testOpportunityAttachments() {
    //     Account acct = new Account(
    //         Name = 'Test Account'
    //     );
    //     insert acct;

    //     RPA__c rpa = new RPA__c(
    //     	Account__c = acct.Id
    //     );
    //     insert rpa;

    //     Terms_Letter__c tl = new Terms_Letter__c(
    //     	RPA__c = rpa.Id
    //     );
    //     insert tl;

    //     Opportunity opp = new Opportunity(
    //     	Name = 'Test Opportunity',
    //     	StageName = 'Stage 1',
    //     	CloseDate = Date.today(),
    //     	AccountId = acct.Id,
    //     	RPA__c = rpa.Id,
    //     	Terms_Letter__c = tl.Id
    //     );
    //     insert opp;

    //     List<Attachment> atts = new List<Attachment>();
        
    //     Attachment attach1 = new Attachment(
    //         Name = 'TO - TL_Completed.pdf',
    //         ParentId = acct.Id,
    //         Body = Blob.valueOf(
    //             'Chapter 1.\n\n'
    //             + 'The Basics:\n\n'
    //         ),
    //         ContentType = 'text/plain'
    //     );
    //     Attachment attach2 = new Attachment(
    //         Name = 'TO - ARTL_Completed.pdf',
    //         ParentId = opp.Id,
    //         Body = Blob.valueOf(
    //             'Chapter 1.\n\n'
    //             + 'The Basics:\n\n'
    //         ),
    //         ContentType = 'text/plain'
    //     );
    //     Attachment attach3 = new Attachment(
    //         Name = 'TO - TL_Completed.pdf',
    //         ParentId = opp.Id,
    //         Body = Blob.valueOf(
    //             'Chapter 1.\n\n'
    //             + 'The Basics:\n\n'
    //         ),
    //         ContentType = 'text/plain'
    //     );
    //     Attachment attach4 = new Attachment(
    //         Name = 'TO -RPA-OH1_Completed.pdf',
    //         ParentId = opp.Id,
    //         Body = Blob.valueOf(
    //             'Chapter 1.\n\n'
    //             + 'The Basics:\n\n'
    //         ),
    //         ContentType = 'text/plain'
    //     );
    //     atts.add(attach1);
    //     atts.add(attach2);
    //     atts.add(attach3);
    //     atts.add(attach4);

    //     Test.startTest();
    //     insert atts;
    //     Test.stopTest();

    //     List<Attachment> attachments = [SELECT Id FROM Attachment];
    //     System.assertEquals(1, attachments.size(), 'Should be one here');

    //     List<ContentVersion> contentVersRPA = [SELECT Id FROM ContentVersion WHERE RPA__c = :rpa.Id];
    //     System.assertEquals(1, contentVersRPA.size(), 'Should only be one');
    //     List<ContentVersion> contentVersTL = [SELECT Id FROM ContentVersion WHERE Terms_Letter__c = :tl.Id];
    //     System.assertEquals(1, contentVersTL.size(), 'Should only be one');
    //     List<ContentVersion> contentVers = [SELECT Id FROM ContentVersion WHERE Opportunity__c = :opp.Id];
    //     System.assertEquals(3, contentVers.size(), 'Should be two docs transferred');
    //  }

}