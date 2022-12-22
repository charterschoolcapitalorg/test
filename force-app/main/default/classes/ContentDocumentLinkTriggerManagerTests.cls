@isTest
private class ContentDocumentLinkTriggerManagerTests {
    @testSetup static void recordsSetup() {  
        User u = [SELECT Name, UserType FROM User WHERE UserType = 'PowerPartner' AND IsActive = true LIMIT 1];
        Account a;
        a = new Account(name='Test Account', RecordTypeId = RecordTypes.IDCharterAccount);
        insert a;
        Contact con = new Contact(LastName = 'Smith', FirstName = 'John', AccountId = a.Id, email='jsmith_example@charterschoolcapital.com');
        insert con;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];


        RPA__c newRPA = new RPA__c(Account__c = a.Id, Status__c = 'Draft', Library_Type__c = 'Underwriting', RPA_Type__c = 'Original', RPA_Date__c = Date.today());
        insert newRPA;

        Terms_Letter__c newTL = new Terms_Letter__c(RPA__c = newRPA.Id, TL_Type__c = 'Original', TL_Date__c = Date.today(), Initial_Close_Date__c = Date.today(), Termination_Date__c = Date.today(),
                                Account__c = a.Id, Status__c = 'Draft', Library_Type__c = 'Underwriting');
        insert newTL;

        Opportunity o = new Opportunity(name = 'Test Opp', AccountId = a.Id, Paralegal__c = u.Id, Amount = 0, CloseDate = Date.today(), StageName = 'Stage 1', Library_Type__c = 'Underwriting',
                                RPA__c = newRPA.Id, Terms_Letter__c = newTL.Id);
        insert o;
        Intake_Item__c ii = new Intake_Item__c(name = 'Test Item', Opportunity__c = o.Id, Department__c = 'Underwriting - PL', Status__c = Diligencevars.IntakePendingStatus);
        insert ii;
		// Insert portal as current user
        System.runAs (thisUser) {
            Profile p = [SELECT Id FROM Profile WHERE Name='Partner Community User School/Tenant'];
            UserRole r = [SELECT Id FROM UserRole WHERE PortalType ='Partner' LIMIT 1];
            System.debug('r' + r);
            u = new User(alias = 'jsmith', email='jsmith_example@charterschoolcapital.com', 
                emailencodingkey='UTF-8', lastname='Smith', 
                languagelocalekey='en_US', ContactId = con.Id,
                localesidkey='en_US', profileid = p.Id, PortalRole='Worker',
                timezonesidkey='America/Los_Angeles', UserPermissionsSFContentUser = true,
                username='jsmith_example@charterschoolcapital.com+portal');
            insert u;
            System.debug(u);

        }
        OpportunityShare os = new OpportunityShare();
        os.UserOrGroupId = u.Id;
        os.OpportunityAccessLevel = 'Edit';
        os.OpportunityId = o.Id;
        insert os;

        CSC_Action_List__c actionList = new CSC_Action_List__c(Account__c = a.Id, Library_Type__c = 'Underwriting', Action_List_Name__c = 'Test Action List');
        insert actionList;

        CSC_Action_Item__c actionItem = new CSC_Action_Item__c(Action_Item_Name__c = 'Test Action Item', CSC_Action_List__c = actionList.Id);
        insert actionItem;

        Resolution__c reso = new Resolution__c(School__c = a.Id, GRV__c = 1000000, FV__c = 750000, Status__c = 'Pending', Library_Type__c = 'Underwriting');
        insert reso;

    }


    @isTest static void testInternal(){
    	Intake_Item__c ii = [SELECT id FROM Intake_Item__c LIMIT 1];
    	Integer emails = 0;
    	ContentVersion contentVersion = new ContentVersion(
		  Title = 'Cashflow',
		  PathOnClient = 'Cashflow.txt',
		  VersionData = Blob.valueOf('Test Content'),
		  IsMajorVersion = true
		);
		insert contentVersion;    
		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

		//create ContentDocumentLink record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = ii.id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.shareType = 'V';
		emails = Limits.getEmailInvocations();
		Test.startTest();
			insert cdl;
			emails = -Limits.getEmailInvocations();
		Test.stopTest();
		System.assertEquals(0, emails, 'No emails should have been sent');
    }


    @isTest static void testExternal(){
    	User u = [SELECT Name, UserType FROM User WHERE email='jsmith_example@charterschoolcapital.com'];
    	System.debug('u: ' + u);
        Intake_Item__c ii = [SELECT id FROM Intake_Item__c LIMIT 1];
    	Integer emails = 0;
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Cashflow',
            PathOnClient = 'Cashflow.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            SharingOption = 'A'
        );
        insert contentVersion;
        ContentDocument cd = [SELECT ID, OwnerId FROM ContentDocument WHERE Title = 'Cashflow' LIMIT 1];
        cd.OwnerId = u.Id;
        update cd;
        //create ContentDocumentLink record 
		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = ii.id;
		cdl.ContentDocumentId = documents[0].Id;
		cdl.shareType = 'V';
		emails = Limits.getEmailInvocations();
		Test.startTest();
			insert cdl;
			emails += Limits.getEmailInvocations();
		Test.stopTest();
        System.assertEquals(1, emails, 'One email should have been sent');
    }

    @isTest static void testActionItem(){
        CSC_Action_Item__c actionItem = [SELECT id FROM CSC_Action_Item__c LIMIT 1];
        Integer emails = 0;
    	ContentVersion contentVersion = new ContentVersion(
		  Title = 'Cashflow',
		  PathOnClient = 'Cashflow.txt',
		  VersionData = Blob.valueOf('Test Content'),
		  IsMajorVersion = true
		);
		insert contentVersion;    
		ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

		//create ContentDocumentLink record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = actionItem.id;
		cdl.ContentDocumentId = document.Id;
		cdl.shareType = 'V';
        emails = Limits.getEmailInvocations();
        
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
		Test.startTest();
			insert cdl;
            emails = -Limits.getEmailInvocations();
            cdls = [SELECT id FROM ContentDocumentLink WHERE ContentDocumentId = :document.Id];
		Test.stopTest();
        System.assertEquals(0, emails, 'No emails should have been sent');
        System.assertEquals(5, cdls.size(), 'Should be linked to the Acc/AL/AI/User/Library');
    }

    @isTest static void testResolution(){
        Resolution__c resolution = [SELECT id FROM Resolution__c LIMIT 1];
        Integer emails = 0;
    	ContentVersion contentVersion = new ContentVersion(
		  Title = 'Cashflow',
		  PathOnClient = 'Cashflow.txt',
		  VersionData = Blob.valueOf('Test Content'),
		  IsMajorVersion = true
		);
		insert contentVersion;    
		ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

		//create ContentDocumentLink record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = resolution.id;
		cdl.ContentDocumentId = document.Id;
		cdl.shareType = 'V';
        emails = Limits.getEmailInvocations();
        
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
		Test.startTest();
			insert cdl;
            emails = -Limits.getEmailInvocations();
            cdls = [SELECT id FROM ContentDocumentLink WHERE ContentDocumentId = :document.Id];
		Test.stopTest();
        System.assertEquals(0, emails, 'No emails should have been sent');
        System.assertEquals(4, cdls.size(), 'Should be linked to the Acc/Res/User/Library');
    }    

    @isTest static void testOpportunity(){
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        Integer emails = 0;
    	ContentVersion contentVersion = new ContentVersion(
		  Title = 'Cashflow',
		  PathOnClient = 'Cashflow.txt',
		  VersionData = Blob.valueOf('Test Content'),
		  IsMajorVersion = true
		);
		insert contentVersion;    
		ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

		//create ContentDocumentLink record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = opp.id;
		cdl.ContentDocumentId = document.Id;
		cdl.shareType = 'V';
        emails = Limits.getEmailInvocations();
        
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
		Test.startTest();
			insert cdl;
            emails = -Limits.getEmailInvocations();
            cdls = [SELECT id FROM ContentDocumentLink WHERE ContentDocumentId = :document.Id];
		Test.stopTest();
        System.assertEquals(0, emails, 'No emails should have been sent');
        System.assertEquals(3, cdls.size(), 'Should be linked to the Opp/User/Library');
    } 

    @isTest static void testOpportunityTL(){
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        Integer emails = 0;
    	ContentVersion contentVersion = new ContentVersion(
		  Title = 'A&R_TL.pdf',
		  PathOnClient = 'AR_TL.pdf',
		  VersionData = Blob.valueOf('Test Content'),
		  IsMajorVersion = true
		);
		insert contentVersion;    
		ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

		//create ContentDocumentLink record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = opp.id;
		cdl.ContentDocumentId = document.Id;
		cdl.shareType = 'V';
        emails = Limits.getEmailInvocations();
        
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
		Test.startTest();
			insert cdl;
            emails = -Limits.getEmailInvocations();
            cdls = [SELECT id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :document.Id];
        Test.stopTest();
                
        System.assertEquals(0, emails, 'No emails should have been sent');
        System.assertEquals(4, cdls.size(), 'Should be linked to the Opp/User/Library/TL');
    } 

    @isTest static void testOpportunityNoTL(){
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        opp.Terms_Letter__c = null;
        opp.RPA__c = null;
        update opp;
        Integer emails = 0;
    	ContentVersion contentVersion = new ContentVersion(
		  Title = 'A&R TL',
		  PathOnClient = 'AR TL.pdf',
		  VersionData = Blob.valueOf('Test Content'),
		  IsMajorVersion = true
		);
		insert contentVersion;    
		ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

		//create ContentDocumentLink record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = opp.id;
		cdl.ContentDocumentId = document.Id;
		cdl.shareType = 'V';
        emails = Limits.getEmailInvocations();
        
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
		Test.startTest();
			insert cdl;
            emails = -Limits.getEmailInvocations();
            cdls = [SELECT id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :document.Id];
        Test.stopTest();
                
        System.assertEquals(0, emails, 'No emails should have been sent');
        System.assertEquals(3, cdls.size(), 'Should be linked to the Opp/User/Library');
    } 

    @isTest static void testOpportunityRPA(){
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        Integer emails = 0;
    	ContentVersion contentVersion = new ContentVersion(
		  Title = 'A&R RPA.pdf',
		  PathOnClient = 'AR_RPA.pdf',
		  VersionData = Blob.valueOf('Test Content'),
		  IsMajorVersion = true
		);
		insert contentVersion;    
		ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

		//create ContentDocumentLink record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = opp.id;
		cdl.ContentDocumentId = document.Id;
		cdl.shareType = 'V';
        emails = Limits.getEmailInvocations();
        
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
		Test.startTest();
			insert cdl;
            emails = -Limits.getEmailInvocations();
            cdls = [SELECT id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :document.Id];
        Test.stopTest();
                
        System.assertEquals(0, emails, 'No emails should have been sent');
        System.assertEquals(4, cdls.size(), 'Should be linked to the Opp/User/Library/RPA');
    } 

    @isTest static void testOpportunityNoRPA(){
        Opportunity opp = [SELECT id FROM Opportunity LIMIT 1];
        opp.Terms_Letter__c = null;
        opp.RPA__c = null;
        update opp;
        Integer emails = 0;
    	ContentVersion contentVersion = new ContentVersion(
		  Title = 'A&R RPA',
		  PathOnClient = 'AR RPA.pdf',
		  VersionData = Blob.valueOf('Test Content'),
		  IsMajorVersion = true
		);
		insert contentVersion;    
		ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

		//create ContentDocumentLink record 
		ContentDocumentLink cdl = New ContentDocumentLink();
		cdl.LinkedEntityId = opp.id;
		cdl.ContentDocumentId = document.Id;
		cdl.shareType = 'V';
        emails = Limits.getEmailInvocations();
        
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
		Test.startTest();
			insert cdl;
            emails = -Limits.getEmailInvocations();
            cdls = [SELECT id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :document.Id];
        Test.stopTest();
                
        System.assertEquals(0, emails, 'No emails should have been sent');
        System.assertEquals(3, cdls.size(), 'Should be linked to the Opp/User/Library');
    } 

}