@isTest
private class TestFC {
 	public static String oppName = 'Initial Funding - COmpanyt';
 	
 	public static User createNewUser(Id profileId, String lastName, String email){
        User u = new user();
        u.lastName = lastName;
        u.Email = email;
        u.Alias = lastName;
        u.Username = 'Test'+lastName+ + DateTime.now().getTime()+'@t.com';
        u.CommunityNickname = lastName;
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'GMT';
        u.ProfileID = profileId;
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.IsActive = true;
        return u;
    }
    
    @future public static void fcCreateGroups() {
    	Id profileID = [SELECT Id from PROFILE WHERE NAME = 'System Administrator' limit 1].Id;
            User u = createNewUser(profileID, 'test', 't@t.com');
            User u2 = createNewUser(profileID, 'test2', 't2@t.com');
            USer u3 = [Select id from User Where Id=:UserInfo.getUserId()];
	        insert u;
	 		insert u2;
	 		
	 		try {
            Group test = new Group();
			//test.Name = 'Working Capital FC Approval Tier1';
			test.name = 'FC Approvers WC';
			test.developername = 'FC_Approvers_WC';
			insert test;
			
			
			List<GrouPMember> gms = new List<GroupMember>();
			GroupMember gm = new GroupMember(USerOrGroupId=u.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u2.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u3.Id, GroupId=test.id);
			gms.add(gm);
			insert gms;
			
			test = new Group();
			//test.Name = 'Working Capital FC Approval Tier1';
			test.name = 'FC Pre Approvers FAC';
			test.developername = 'FC_Pre_Approvers_FAC';
			insert test;
			
			test = new Group();
			test.Name = 'FC Pre Approvers UW';
			test.developername = 'FC_Pre_Approvers_UW';
			insert test;
			gms = new List<GroupMember>();
			gm = new GroupMember(USerOrGroupId=u.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u2.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u3.Id, GroupId=test.id);
			gms.add(gm);
			insert gms;
			
			
			test = new Group();
			test.Name = 'FC Pre Approvers FIN';
			test.developername = 'FC_Pre_Approvers_FIN';
			insert test;
			gms = new List<GroupMember>();
			gm = new GroupMember(USerOrGroupId=u.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u2.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u3.Id, GroupId=test.id);
			gms.add(gm);
			insert gms;
			
						
			test = new Group();
			test.Name = 'FC Pre Approvers SVC';
			test.developername = 'FC_Pre_Approvers_SVC';
			insert test;
			gms = new List<GroupMember>();
			gm = new GroupMember(USerOrGroupId=u.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u2.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u3.Id, GroupId=test.id);
			gms.add(gm);
			insert gms;
			
			test = new Group();
			test.Name = 'FC Pre FC Notifications WC';
			test.developername = 'FC_Pre_FC_Notifications_WC';
			insert test;
            gms = new List<GroupMember>();
			gm = new GroupMember(USerOrGroupId=u.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u2.Id, GroupId=test.id);
			gms.add(gm);
			gm = new GroupMember(USerOrGroupId=u3.Id, GroupId=test.id);
			gms.add(gm);
			insert gms;
			
	 	} catch (EXception e) {}
	 		
    }
     
     
    @testSetup 
    public static void fcSetup() {
 			
        fcCreateGroups();
        
        FC_Email_Templates__c fe = new FC_Email_Templates__c();
        fe.Dept_Head_Approved_Template__c = 'Test Dept Head Approved';
        fe.Dept_Head_Ready_For_Review_Template__c = 'Test Dept Head Ready For Review';
        fe.Final_Approval_Not_Approved_Template__c = 'Test Final Approval Not Approved';
        fe.Final_Approval_Rejected_Template__c = 'Test Final Approval Rejected';
        fe.Final_Approval_Template__c = 'Test Final Approval';
        fe.PreFC_Approved_Template__c = 'Test PreFC Approved';
        fe.PreFC_Ready_Template__c = 'Test PreFC Ready';
        fe.PreFC_Rejected_Template__c = 'Test PreFC Rejected';
        insert fe;
        
        
        TestDIligenceUtils.createCOnfig();
        TestDiligenceUTils.createFUndingIntakeTemplates();
        
        Opportunity o;
        
        LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
        cntr.back();
        cntr.doNotCreateOpp = false;
        
        //create Lead and Opp and Intake Items tests
        LEad l = TestDiligenceUtils.createIFLead();
        l.Industry = 'Charter Holder';
        l.Lead_Type__c = 'Charter Holder'; 
        //l.company = 'COmpanyx';
        insert l;
        cntr.setLEad(l);
        cntr.execute();
        
        String oName = 'Initial Funding - '+l.company;
        List<Opportunity> opps = [Select id, Name from Opportunity];
        o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oName];
        
        List<FC_FOrm__c> forms = FCFormUtils.createFCForms(o);
         
        o.recordtypeid=recordtypes.IDFacilitiesOpp;
        List<FC_FOrm__c> forms2 = FCFormUtils.createFCForms(o);
			
 	}

    static testMethod void testupdateCSCActioNItem() {
        //Create Action List records
        Account testAccount = CSCTestUtil.createAccount('Test Account 1');
        
        insert testAccount;
        
        CSC_Action_List__c actionList1 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 1 - Projected' ,'Finance', 1, true, true);
        
        Flags.SkipActionListOrderResequencing = true;
        insert actionList1;
        Flags.reset();
        
        
        //create Action List Items
        CSC_Action_Item__c item1 = CSCTestUtil.createActionItem(actionList1.Id, 1);
        item1.Department__c='Finance - Director of Finance and Risk Analysis';
        Flags.SkipActionItemOrderResequencing = true;
        insert item1;
        Flags.reset();
        
        USer u3 = [Select id from User Where Id=:UserInfo.getUserId()];
        
        CSC_Action_Item__c test = FCFormUtils.updateCSCActioNItem(item1, u3.Id);
        
        //create Action List Items
        CSC_Action_Item__c item2 = CSCTestUtil.createActionItem(actionList1.Id, 1);
        item2.Department__c='Director of Underwriting';
        Flags.SkipActionItemOrderResequencing = true;
        insert item2;
        Flags.reset();
        
        CSC_Action_Item__c test2 = FCFormUtils.updateCSCActioNItem(item2, u3.Id);
        
        //create Action List Items
        CSC_Action_Item__c item3 = CSCTestUtil.createActionItem(actionList1.Id, 1);
        item3.Department__c='Financial Analyst';
        Flags.SkipActionItemOrderResequencing = true;
        insert item3;
        Flags.reset();
        
        CSC_Action_Item__c test3 = FCFormUtils.updateCSCActioNItem(item3, u3.Id);
        
    }
    
    static testMethod void testupdateActionItem() {
        //Create Action List records
        Account testAccount = CSCTestUtil.createAccount('Test Account 1');
        
        insert testAccount;
        
        CSC_Action_List__c actionList1 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 1 - Projected' ,'Finance', 1, true, true);
        
        Flags.SkipActionListOrderResequencing = true;
        insert actionList1;
        Flags.reset();
        
        
        //create Action List Items
        CSC_Action_Item__c item1 = CSCTestUtil.createActionItem(actionList1.Id, 1);
        
        Flags.SkipActionItemOrderResequencing = true;
        insert item1;
        Flags.reset();
        
        USer u3 = [Select id from User Where Id=:UserInfo.getUserId()];
        
        CSC_Action_Item__c test = FCFormUtils.updateActionItem(item1, u3.Id);
        
        String Year = '2021';
            Integer fy = FCFormUtils.fyToYear(Year);
        
        String valAmount = FCFormUtils.formatDOllarAmount('2.00');
        
        Date dt = date.today();
        String dateString = FCFormUtils.dateToString(dt);
    }
    
    static testMethod void testnullCSCActioNItem() {
        //Create Action List records
        Account testAccount = CSCTestUtil.createAccount('Test Account 1');
        
        insert testAccount;
        
        CSC_Action_List__c actionList1 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 1 - Projected' ,'Finance', 1, true, true);
        
        Flags.SkipActionListOrderResequencing = true;
        insert actionList1;
        Flags.reset();
        
        
        //create Action List Items
        CSC_Action_Item__c item1 = CSCTestUtil.createActionItem(actionList1.Id, 1);
        
        Flags.SkipActionItemOrderResequencing = true;
        insert item1;
        Flags.reset();
        
        USer u3 = [Select id from User Where Id=:UserInfo.getUserId()];
        
        CSC_Action_Item__c test = FCFormUtils.nullCSCActioNItem(item1, u3.Id);
    }
    
 	static testMethod void testFCSetup() {
 			
        List<Opportunity> opps = [SELECT Id, OwnerId, Name, Terms_Letter__c, recordtypeid, AccountId FROM Opportunity LIMIT 1];
        Opportunity o = opps[0];
        
        RPA__c testRPA = new RPA__c(
        	RPA_Type__c = 'Original',
            Status__c = 'Draft',
            Account__c = o.AccountId,
            Library_Type__c = 'Underwriting'
        );
        insert testRPA;

        Terms_Letter__c testTL = new Terms_Letter__c(
        	RPA__c = testRPA.Id,
            TL_Type__c = 'Original',
            TL_Date__c = date.today(),
            Initial_Close_Date__c = date.today(),
            Termination_Date__c = date.today(),
            Account__c = o.AccountId,
            Status__c = 'Draft',
            Library_Type__c = 'Underwriting',
            RPA_Face_Value__c = 1000.00,
            RPA_Gross_Value__c = 1000.00
        );
        insert testTL;
        
        Account testAccount = CSCTestUtil.createAccount('Test Account 1');
        insert testAccount;
        
        CSC_Action_List__c actionList1 = CSCTestUtil.createActionList(testAccount.Id, 'Stage 1 - Projected' ,'Finance', 1, true, true);
        insert actionList1;
        
        CSC_ACtion_Item__c aiAcct = new CSC_ACtion_Item__c(
            Action_Item_Name__c = 'test', 
            CSC_Action_List__c = actionList1.Id, 
            Order__c = 1,
            Status__c ='New'
        );
        aiAcct.Action_Item_Name__c = 'SOS GOOD STANDING CERTIFICATE';
        aiAcct.Date_Effective__c = date.Today();
        insert aiAcct;
                
        Account testAccount2 = new Account(
        	Id = o.AccountId,
            CMO__c =aiAcct.Account_Id__c
        );
        update testAccount2;

        o.rpa__c = testRPA.Id;
        o.Terms_Letter__c = testTL.Id;
        update o;
            
        test.starttest();
            List<FC_FOrm__c> forms = FCFormUtils.createFCForms(o);
            FCFOrmUtils.populateHeaderFieldsFromSFData(forms);
            FCFOrmUtils.populateHeaderCommentFieldsFromSFData(forms);
    
            Id ServicingFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Servicing').getRecordTypeId();
            Id FinanceFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Finance').getRecordTypeId();
            forms[0].Recordtypeid = FinanceFcRecType;
            update forms;
            FCFOrmUtils.populateHeaderCommentFieldsFromSFData(forms);
            
            forms[0].Recordtypeid = ServicingFcRecType;
            update forms;
            FCFOrmUtils.populateHeaderCommentFieldsFromSFData(forms);
        test.stoptest();
	}

    //slava create a new test for the ucc search changes
    @isTest
    static void myNewTest() {
        
        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, Opportunity, CSC_Action_List__c, CSC_Action_Item__c');

        Set<String> oppIds = new Set<String>();

		//create account
		Account acctWon = new Account();
		acctWon.name = 'Test Acct Won';
		insert acctWon;
        
        //create opportunity Tenant/School Won
        Opportunity oppTenantWon = new Opportunity();
        oppTenantWon.name = 'Test OppTenantWon';
        oppTenantWon.StageName = 'Stage 3 - Review';
        oppTenantWon.accountId = acctWon.id;
        oppTenantWon.CloseDate = System.today();
        oppTenantWon.Facilities_Channel__c = 'Tenant/School';
        oppTenantWon.Estimated_Project_Cost__c = 100;
        insert oppTenantWon;

        oppIds.add(oppTenantWon.id);

        //create Action Lists 
        CSC_Action_List__c actionListTenantWon = new CSC_Action_List__c();
        actionListTenantWon.Action_List_Name__c = 'List Name Tenant Won';
        actionListTenantWon.Account__c = acctWon.Id;
        actionListTenantWon.Opportunity__c = oppTenantWon.Id;
        actionListTenantWon.Library_Type__c = 'Underwriting';
        actionListTenantWon.Status__c = 'New';
        actionListTenantWon.Order__c = 1;
        actionListTenantWon.Template__c = false;
        actionListTenantWon.Opportunity_Record_Type__c = 'FOF';
        insert actionListTenantWon;
        
        //create Action Items Tenant Won
        CSC_Action_Item__c item = CSCTestUtil.createActionItem(actionListTenantWon.Id, 1);
        item.Action_Item_Name__c = 'CERTIFIED ARTICLES OF INCORPORATION';
        item.action_item_mapping__c = 'UCC SEARCH';
        item.Date_Effective__c = Date.today();
        insert item;
            
        //Test.starttest();
        List<FC_FOrm__c> forms = FCFormUtils.createFCForms(oppTenantWon);
        FCFOrmUtils.populateHeaderFieldsFromSFData(forms);
        //Test.stoptest();
    }
    //slava create a new test for the ucc search changes
	    
 	static testMethod void testFCCreation() {
			
			test.starttest();
			
            Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
            
			System.debug('**** in testFCCreation opportunity: ' + o);
            
            /*LEad l = [Select id, company from Lead where email='t@t.com'];
			String oppName = 'Initial Funding - '+l.company;
			
			Opportunity o;
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }*/
            
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
            //create Opp School and FC Details
            System.debug('***** fcSetup creating account');
            Account a2 = new Account(name='test school', ParentId=o.AccountId,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
            insert a2;
            
            
            
            System.debug('***** fcSetup creating oppschool');
            Opp_School__c os = new Opp_School__c(Opportunity__c=o.Id, School__c=a2.Id);
            insert os;
            
            
            List<Opp_School__c> oss = new List<Opp_School__c>();
            oss.add(os);
            List<FC_Details__c> details = FCFormUtils.createFCDetails(oss);
			FCFOrmUtils.populateDetailFieldsFromSFData(details);
			FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);	
            
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            system.assert(summForm!=null);
            
            List<FC_Details__c> det = [Select Id from FC_Details__c where FC_Form__c=:uwFOrm.Id];
            system.assertEquals(1, det.size());
            
            test.stoptest();
 	}   
 	
 	static testMethod void testFCCreateFCCntrl() {
			
			
            
			System.debug('**** in testFCCreation');
            LEad l = [Select id, company from Lead where email='t@t.com'];
			String oppName = 'Initial Funding - '+l.company;
			
			Opportunity o;
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            test.starttest();
			
			ApexPages.StandardController thecontroller = new ApexPages.StandardController(o);
            Create_FC_Forms_Ctrl fc = new Create_FC_Forms_Ctrl(thecontroller);
            fc.back();
            fc.create();
            
                    
            test.stoptest();
 	}
 	
 	static testMethod void testFCRefresh7() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
 			
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(svcform);
            FC_Refresh_Ctrl fc = new FC_Refresh_Ctrl(thecontroller);
            fc.back();
            fc.refresh();
            
            
 	}
 	
 	static testMethod void testFCRefreshHeaderComments() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(uwFOrm);
            FC_Refresh_Comments_Ctrl fc = new FC_Refresh_Comments_Ctrl(thecontroller);
            fc.back();
            fc.refreshcomments();
            
            
 	}
 	
 	static testMethod void testFCRefresh2() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(uwFOrm);
            FC_Refresh_Ctrl fc = new FC_Refresh_Ctrl(thecontroller);
            fc.back();
            fc.refresh();
            
            
 	}
 	
 	
 	static testMethod void testFCRefresh3() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			 
            
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            //create Opp School and FC Details
            System.debug('***** fcSetup creating account');
            Account a2 = new Account(name='test school', ParentId=o.AccountId,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
            insert a2;
            
            test.starttest();
            System.debug('***** fcSetup creating oppschool');
            Opp_School__c os = new Opp_School__c(Opportunity__c=o.Id, School__c=a2.Id);
            insert os;
            List<Opp_School__c> oss = new List<Opp_School__c>();
            oss.add(os);
            List<FC_Details__c> details = FCFormUtils.createFCDetails(oss);
			FCFOrmUtils.populateDetailFieldsFromSFData(details);
			FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);		
            	
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            List<FC_Details__c> uwdet = [Select Id from FC_Details__c where FC_Form__c=:uwFOrm.Id];
           
            
 			//FC DEtails
            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(uwdet[0]);
            FC_Refresh_Details_Ctrl fdc = new FC_Refresh_Details_Ctrl(thecontroller2);
            fdc.back();
            fdc.refresh(); 
            test.stoptest();
            
 	}
 	
 	static testMethod void testFCRefresh4() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			
            
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            //create Opp School and FC Details
            System.debug('***** fcSetup creating account');
            Account a2 = new Account(name='test school', ParentId=o.AccountId,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
            insert a2;
            
            test.starttest();	
            System.debug('***** fcSetup creating oppschool');
            Opp_School__c os = new Opp_School__c(Opportunity__c=o.Id, School__c=a2.Id);
            insert os;
            List<Opp_School__c> oss = new List<Opp_School__c>();
            oss.add(os);
            List<FC_Details__c> details = FCFormUtils.createFCDetails(oss);
			FCFOrmUtils.populateDetailFieldsFromSFData(details);
			FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);		
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            List<FC_Details__c> uwsvc = [Select Id from FC_Details__c where FC_Form__c=:svcFOrm.Id];
            
            
 			//FC Details
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(uwsvc[0]);
            FC_Refresh_Details_Ctrl fdc = new FC_Refresh_Details_Ctrl(thecontroller2);
            fdc.back();
            fdc.refresh();  
            
            test.stoptest();
 	}
 	
 	static testMethod void testFCRefresh5() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
            //create Opp School and FC Details
            System.debug('***** fcSetup creating account');
            Account a2 = new Account(name='test school', ParentId=o.AccountId,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
            insert a2;
            
            test.starttest();
            System.debug('***** fcSetup creating oppschool');
            Opp_School__c os = new Opp_School__c(Opportunity__c=o.Id, School__c=a2.Id);
            insert os;
            List<Opp_School__c> oss = new List<Opp_School__c>();
            oss.add(os);
            List<FC_Details__c> details = FCFormUtils.createFCDetails(oss);
			FCFOrmUtils.populateDetailFieldsFromSFData(details);
			FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);		
            	
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            List<FC_Details__c> uwfin = [Select Id from FC_Details__c where FC_Form__c=:finnFOrm.Id];
            
            
 			//FC Details
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(uwfin[0]);
            FC_Refresh_Details_Ctrl fdc = new FC_Refresh_Details_Ctrl(thecontroller2);
            //fdc.back();
            fdc.refresh(); 
            
            test.stoptest(); 
 	}
    
    static testMethod void testFCRefresh8() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
            //create Opp School and FC Details
            System.debug('***** fcSetup creating account');
            Account a2 = new Account(name='test school', ParentId=o.AccountId,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
            insert a2;
            
            test.starttest();
            System.debug('***** fcSetup creating oppschool');
            Opp_School__c os = new Opp_School__c(Opportunity__c=o.Id, School__c=a2.Id);
            insert os;
            List<Opp_School__c> oss = new List<Opp_School__c>();
            oss.add(os);
            List<FC_Details__c> details = FCFormUtils.createFCDetails(oss);
            ID ServicingFcDetailRecType = Schema.SObjectType.FC_Details__c.getRecordTypeInfosByDeveloperName().get('Servicing').getRecordTypeId();
            details[0].Recordtypeid=ServicingFcDetailRecType;
            update details;
        
			FCFOrmUtils.populateDetailFieldsFromSFData(details);
			FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);		
            	
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            List<FC_Details__c> uwfin = [Select Id from FC_Details__c where FC_Form__c=:finnFOrm.Id];
            
            
 			//FC Details
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(uwfin[0]);
            FC_Refresh_Details_Ctrl fdc = new FC_Refresh_Details_Ctrl(thecontroller2);
            //fdc.back();
            fdc.refresh(); 
            
            test.stoptest(); 
 	}
 	
 	static testMethod void testFCRefreshDetailComments() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
            //create Opp School and FC Details
            System.debug('***** fcSetup creating account');
            Account a2 = new Account(name='test school', ParentId=o.AccountId,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
            insert a2;
            
            test.starttest();
            System.debug('***** fcSetup creating oppschool');
            Opp_School__c os = new Opp_School__c(Opportunity__c=o.Id, School__c=a2.Id);
            insert os;
            System.debug('***** fcSetup created oppschool'); 	
            List<Opp_School__c> oss = new List<Opp_School__c>();
            oss.add(os);
            List<FC_Details__c> details = FCFormUtils.createFCDetails(oss);
			FCFOrmUtils.populateDetailFieldsFromSFData(details);
			FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);	
				
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            List<FC_Details__c> uwfin = [Select Id from FC_Details__c where FC_Form__c=:finnFOrm.Id];
            
            
 			//FC Details
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(uwfin[0]);
            FC_Refresh_Details_Comments_Ctrl fdc = new FC_Refresh_Details_Comments_Ctrl(thecontroller2);
            fdc.back();
            fdc.refreshComments(); 
            
            test.stoptest(); 
 	}
 	
 	
 	static testMethod void testFCRefresh() {
			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(summForm);
            FC_Refresh_Ctrl fc = new FC_Refresh_Ctrl(thecontroller);
            fc.back();
            fc.refresh();
            
            
 	}   
 	
 	static testMethod void testFCRefresh6() {
			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(finnFOrm);
            FC_Refresh_Ctrl fc = new FC_Refresh_Ctrl(thecontroller);
            fc.back();
            fc.refresh();
            
            
 	}
 	
 	static testMethod void testFCPreFC() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            test.starttest();
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Working Capital';
            update summform;
            
            
 			//FC Summary
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
            fdc.back();
            
            //negative tests
            fdc.approve();
            
            summform.status__c='Waiting For Pre Approval';
            update summform;
			fdc.approve();            
            
            //positive tests
            summform.status__c='In Progress';
            update summform;
            fdc.create();
            fdc.confirmation = true;
            fdc.create();
            
            //get FC APprovals
            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id];
            //system.assertequals(fa.size(), 5);
            
            fdc.approve();
            fdc.reject();  
            fdc.confirmation = true;
            fdc.reject();
            test.stoptest();
            
 	}
 	
 	static testMethod void testFCPreFC2() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Working Capital';
            update summform;
            
            
            test.starttest();
 			//FC Summary
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
            fdc.back();
            
            //positive tests
            fdc.confirmation = true;
            fdc.create();
            
            //get FC APprovals
            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id];
            //system.assertequals(fa.size(), 5);
            
            
            //submit all approvals
            /*for (FC_Approval__c f : fa) {
            	f.status__c = 'Approved';
            }
            update fa;
            */
            
            test.stoptest();
            
 	}
 	
 	static testMethod void testFCApprovalCtrl() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            test.starttest();
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Working Capital';
            update summform;
            
            //FC Summary
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
            fdc.confirmation = true;
            fdc.create();
            
            //get FC APprovals
            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id];
            //system.assertequals(fa.size(), 5);
            
 			ApexPages.StandardController thecontroller3 = new ApexPages.StandardController(fa[0]);
            FC_Approval_Update_Ctrl fac = new FC_Approval_Update_Ctrl(thecontroller3);
            fac.back();
            fac.getStatusOptions();
            fac.selectedStatus = 'Approved';
            fac.submit();
            
            test.stoptest();
            /*fac.selectedStatus = 'Approved With Contingencies';
            fac.submit();
            fac.selectedStatus = 'Not Approved';
            fac.submit();
            */
            
 	}
 	
 	static testMethod void testFCApprovalCtrl2() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            test.starttest();
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Working Capital';
            update summform;
            
            //FC Summary
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
            fdc.confirmation = true;
            fdc.create();
            
            //get FC APprovals
            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id];
            //system.assertequals(fa.size(), 5);
            
            for (FC_Approval__c f : fa) {
	 			ApexPages.StandardController thecontroller3 = new ApexPages.StandardController(f);
	            FC_Approval_Update_Ctrl fac = new FC_Approval_Update_Ctrl(thecontroller3);
	            fac.back();
	            fac.getStatusOptions();
	            fac.selectedStatus = 'Approved With Contingencies';
	            fac.submit();
            }
            
            test.stoptest();
            
            
            
 	}
 	
 	static testMethod void testFCApprovalCtrl3() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            test.starttest();
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Working Capital';
            update summform;
            
            //FC Summary
 			ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
            fdc.confirmation = true;
            fdc.create();
            
            //get FC APprovals
            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id];
            //system.assertequals(fa.size(), 5);
            
 			ApexPages.StandardController thecontroller3 = new ApexPages.StandardController(fa[0]);
            FC_Approval_Update_Ctrl fac = new FC_Approval_Update_Ctrl(thecontroller3);
            fac.back();
            fac.getStatusOptions();
            fac.selectedStatus = 'Not Approved';
            fac.submit();
            test.stoptest();
            /*fac.selectedStatus = 'Approved With Contingencies';
            fac.submit();
            
            */
            
 	}
 	
 	
 	static testMethod void testFCReview() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			           
			
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
            
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            test.starttest();
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Working Capital';
            summform.status__c = 'In Progress';
            update summform;
            
            
            //submit forms for reivew
            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(uwFOrm);
            FC_Form_Review_Ctrl fr = new FC_Form_Review_Ctrl(thecontroller2);
            fr.init();
            fr.back();
            fr.submitForReview();
            
            
            thecontroller2 = new ApexPages.StandardController(svcFOrm);
            fr.init();
            fr.back();
            fr = new FC_Form_Review_Ctrl(thecontroller2);
            fr.submitForReview();
            
            thecontroller2 = new ApexPages.StandardController(finnFOrm);
            fr.init();
            fr.back();
            fr = new FC_Form_Review_Ctrl(thecontroller2);
            fr.submitForReview();
            
            //approve dept head approvals
            //get FC APprovals
            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
            	type__c='Dept Head Review'];
            
            //submit all approvals
            for (FC_Approval__c f : fa) {
            	f.status__c = 'Approved';
            }
            update fa;
            
            test.stoptest();
            
 	}
 	
 	
 	@isTest static void testFCFinalApproval() {
 			
 			
		    Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
		    
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Working Capital';
            summform.status__c = 'Waiting FOr Final Approval';
            summform.status__c ='Final Approval Not Approved';
            update summform;
            
            System.debug('&&&&&& starting test');
            Test.startTest();
		    
	            //create final approvals
	            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
	            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
	            System.debug('&&&&&& submitting form');
	            fdc.resubmitfinal();
	            
	            //get FC APprovals
	            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
	            	type__c='Final FC Approval'];
	            System.debug('****final approvals: ' + fa);
	            
	            //submit all approvals
	            for (FC_Approval__c f : fa) {
	            	f.status__c = 'Approved';
	            	//update f;
	            }
	            System.debug('&&&&&& updating approval');
	            update fa;
            
            Test.stopTest();
 	}
    
    @isTest static void testFCApproveWithCOntingencies() {
 			
		    Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
		    
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            System.debug('&&&&&& starting test');
            Test.startTest();
	            summform.approval_tier__c = 'Working Capital';
	            summform.status__c ='Approved With Contingencies';
	            update summform;
           
	            //create final approvals
	            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
	            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
	            System.debug('&&&&&& submitting form');
	            fdc.resubmitfinal();
	            
	            //get FC APprovals
	            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
	            	type__c='Final FC Approval'];
	            System.debug('****final approvals: ' + fa);
	            
	            //submit all approvals
	            for (FC_Approval__c f : fa) {
	            	f.status__c = 'Approved With Contingencies';
	            }
	            System.debug('&&&&&& updating approval with contingencies');
	            update fa;
            
            Test.stopTest();
 	}
 	
 	@isTest static void testPreFCApproval() {
 			
		    Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
		    
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            System.debug('&&&&&& starting test');
            Test.startTest();
	            summform.approval_tier__c = 'Working Capital';
	            summform.status__c ='Waiting For Pre Approval';
	            update summform;
           
	            //create pre-fc approvals
	            //ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
	            //FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
	           // System.debug('&&&&&& submitting form');
	            //fdc.resubmitfinal();
	            
	            //get FC APprovals
	            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
	            	type__c='Pre-FC Approval'];
	            System.debug('****Pre-FC Approval approvals: ' + fa);
	            
	            //submit all approvals
	            for (FC_Approval__c f : fa) {
	            	f.status__c = 'Approved';
	            }
	            System.debug('&&&&&& updating pre-fc');
	            update fa;
            
            Test.stopTest();
 	}
 	
 	@isTest static void testPreFCNotApproved() {
 			
		    Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
		    
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            System.debug('&&&&&& starting test');
            Test.startTest();
	            summform.approval_tier__c = 'Working Capital';
	            summform.status__c ='Waiting For Pre Approval';
	            update summform;
           
	            //create pre-fc approvals
	            //ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
	            //FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
	           // System.debug('&&&&&& submitting form');
	            //fdc.resubmitfinal();
	            
	            //get FC APprovals
	            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
	            	type__c='Pre-FC Approval'];
	            System.debug('****Pre-FC Approval approvals: ' + fa);
	            
	            //submit all approvals
	            for (FC_Approval__c f : fa) {
	            	f.status__c = 'Not Approved';
	            }
	            System.debug('&&&&&& updating pre-fc');
	            update fa;
            
            Test.stopTest();
 	}
 	
 	@isTest static void testFCNotApproved() {
 			
		    Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
		    
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            System.debug('&&&&&& starting test');
            Test.startTest();
	            summform.approval_tier__c = 'Working Capital';
	            summform.status__c ='Final Approval Not Approved';
	            update summform;
           
	            //create final approvals
	            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
	            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
	            System.debug('&&&&&& submitting form');
	            fdc.resubmitfinal();
	            
	            //get FC APprovals
	            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
	            	type__c='Final FC Approval'];
	            System.debug('****final approvals: ' + fa);
	            
	            //submit all approvals
	            for (FC_Approval__c f : fa) {
	            	f.status__c = 'Not Approved';
	            }
	            System.debug('&&&&&& updating not approved');
	            update fa;
            
            Test.stopTest();
 	}
 	
    @isTest static void testFCFinalApprovalRejection() {
 			
 			
		    Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
		    
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Working Capital';
            summform.status__c ='Rejected';
            update summform;
            
            System.debug('&&&&&& starting test');
            Test.startTest();
		    
	            //create final approvals
	            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
	            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
	            System.debug('&&&&&& submitting form');
	            fdc.resubmitfinal();
	            
	            //get FC APprovals
	            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
	            	type__c='Final FC Approval'];
	            System.debug('****final approvals: ' + fa);
	            
	            //submit all approvals
	            for (FC_Approval__c f : fa) {
	            	f.status__c = 'Approved';
	            	//update f;
	            }
	            System.debug('&&&&&& updating approval');
	            update fa;
            
            Test.stopTest();
 	}
    
    
    
    @isTest static void testFCFinalApprovalFacilities() {
 			
 			
		    Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
		    
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            summform.approval_tier__c = 'Facilities';
            summform.status__c ='Final Approval Not Approved';
            update summform;
            
            System.debug('&&&&&& starting test');
            Test.startTest();
		    
	            //create final approvals
	            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
	            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
	            System.debug('&&&&&& submitting form');
	            fdc.resubmitfinal();
	            
	            //get FC APprovals
	            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
	            	type__c='Final FC Approval'];
	            System.debug('****final approvals: ' + fa);
	            
	            //submit all approvals
	            for (FC_Approval__c f : fa) {
	            	f.status__c = 'Approved';
	            	//update f;
	            }
	            System.debug('&&&&&& updating approval');
	            update fa;
            
            Test.stopTest();
 	}
    
     @isTest static void testFCSubmittedForREview() {
 			
 			
		    Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
		    
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            Test.startTest();
            //finnFOrm.Submitted_For_Review__c = true;
            //update finNFOrm;
            svcFOrm.Submitted_For_Review__c = true;
            update svcFOrm;
            uwFOrm.Submitted_For_Review__c = true;
            update uwFOrm;
            
            Test.stopTest();
            
            /*
            summform.approval_tier__c = 'Facilities';
            summform.status__c ='Final Approval Not Approved';
            update summform;
            
            System.debug('&&&&&& starting test');
            
		    
	            //create final approvals
	            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(summForm);
	            FC_Submit_Pre_Approval_Ctrl fdc = new FC_Submit_Pre_Approval_Ctrl(thecontroller2);
	            System.debug('&&&&&& submitting form');
	            fdc.resubmitfinal();
	            
	            //get FC APprovals
	            List<FC_Approval__c> fa = [Select id from FC_Approval__c where FC_Form__c=:summFOrm.Id and 
	            	type__c='Final FC Approval'];
	            System.debug('****final approvals: ' + fa);
	            
	            //submit all approvals
	            for (FC_Approval__c f : fa) {
	            	f.status__c = 'Approved';
	            	//update f;
	            }
	            System.debug('&&&&&& updating approval');
	            update fa;
            
            Test.stopTest();
            */
 	}
 	
     static testMethod void testHEaderData() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			Opportunity o = [Select Id,OwnerId, Name, recordtypeid,  AccountId from Opportunity where Name=:oppName];
            
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            //create other objects and then refresh the data
            Funding_Estimates__c fundingEstimate = new Funding_Estimates__c();
            	fundingEstimate.Opportunity__c = o.Id;
		      fundingEstimate.Discount__c = 7;
		      fundingEstimate.Program_Fees_Collected__c = 12;
		      fundingEstimate.Unpaid_Balance_Receivables_Collected__c = 50;
		      fundingEstimate.Description_of_Unpaid_Balance_Receivable__c = 'description ';
		      fundingEstimate.Application_Fee_Credit__c = 78;
		      fundingEstimate.Penalty_Interest__c = 15;
		      fundingEstimate.Blocked_Account_Fee_Collected__c = 100;
		      fundingEstimate.Bond_or_Other_Payment__c = 123;
		      fundingEstimate.Refund_Reimbursements__c = 20;
		      fundingEstimate.Transaction_Fee__c = 10;
		      fundingEstimate.Net_to_School__c = 200;
		
		      insert fundingEstimate;
            	
            
            
            RPA__c rpa1 = new RPA__c(
			Account__c = o.AccountId,
			RPA_Date__c = System.today().toStartOfMonth(),
			RPA_Type__c = 'Original',
			Status__c = 'Active'
			);
			insert rpa1;
			
			o.rpa__c = rpa1.Id;
			
            //School_Attendance__c - for schools
            
            Account_Snapshot__c a = new Account_Snapshot__c();
            a.account__c = o.accountid; 
            
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(finnForm);
            FC_Refresh_Ctrl fc = new FC_Refresh_Ctrl(thecontroller);
            fc.back();
            fc.refresh();
 	}
 	       
 	static testMethod void testDetailData() {
 			LEad l = [Select id, company from Lead where email='t@t.com'];
			
			 
            
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
			Opportunity o;
			String oppName = 'Initial Funding - '+l.company;
			
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            } catch (Exception e) {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
            }
            
            //create Opp School and FC Details
            System.debug('***** fcSetup creating account');
            Account a2 = new Account(name='test school', ParentId=o.AccountId,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
            insert a2;
            
            test.starttest();
            System.debug('***** fcSetup creating oppschool');
            Opp_School__c os = new Opp_School__c(Opportunity__c=o.Id, School__c=a2.Id);
            insert os;
            List<Opp_School__c> oss = new List<Opp_School__c>();
            oss.add(os);
            List<FC_Details__c> details = FCFormUtils.createFCDetails(oss);
			FCFOrmUtils.populateDetailFieldsFromSFData(details);
			FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);		
            	
            //see if FC Forms were created
            LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
            //system.assertEquals(4, forms.size());
            FC_FOrm__c summForm;
            FC_FOrm__c finnFOrm;
            FC_FOrm__c uwFOrm;
            FC_FOrm__c svcFOrm;
            
            for (FC_FOrm__c f : forms) {
            	if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
            	if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
            	if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
            }
            
            List<FC_Details__c> uwdet = [Select Id from FC_Details__c where FC_Form__c=:uwFOrm.Id];
            
            //create other objects and then refresh the data
            
            
            Funding_Estimates__c fundingEstimate = new Funding_Estimates__c();
            	fundingEstimate.Opportunity__c = o.Id;
		      fundingEstimate.Discount__c = 7;
		      fundingEstimate.Program_Fees_Collected__c = 12;
		      fundingEstimate.Unpaid_Balance_Receivables_Collected__c = 50;
		      fundingEstimate.Description_of_Unpaid_Balance_Receivable__c = 'description ';
		      fundingEstimate.Application_Fee_Credit__c = 78;
		      fundingEstimate.Penalty_Interest__c = 15;
		      fundingEstimate.Blocked_Account_Fee_Collected__c = 100;
		      fundingEstimate.Bond_or_Other_Payment__c = 123;
		      fundingEstimate.Refund_Reimbursements__c = 20;
		      fundingEstimate.Transaction_Fee__c = 10;
		      fundingEstimate.Net_to_School__c = 200;
		
		      insert fundingEstimate;
            	
            School_Attendance__c attendance = new School_Attendance__c();
            attendance.School__c = a2.Id;
            attendance.Report_Date__c = date.today();
            attendance.Active__c = true;
            insert attendance;
			
			School_year__c sy = new School_year__c();
            sy.school__c = a2.Id;
            sy.End_Date__c = date.today();
            sy.Start_Date__c = date.today();
            insert sy;
            
            Lease__c lea = new Lease__c();
            lea.Active__c = true;
            lea.account__c = a2.Id;
            insert lea;
            
            EWS__c e = new EWS__c();
		
		e.Account__c = a2.Id;
		e.Review_Date__c = Date.today();
		e.Fiscal_Year__c = '16-17';
		e.Quarter_Ending_FY__c = 'Q1';
		e.Active__c = true;
		e.FDA_County__c = 'Yes';
		e.FDA_District__c = 'Yes';
		e.Date_Opened__c = Date.today();
		e.Num_of_Shortfalls_Current_FY__c = 0;
		e.Audit_Information__c = 'Minor Issues';
		e.Net_Assets__c = 0;
		e.Non_Facilities_Liabilities__c = 0;
		e.Annual_Rent_Expense__c = 0;
		e.Prior_Year_Surplus_Deficit__c = 0;
		e.Budgeted_Revenue__c = 100000;
		e.Budgeted_Donations__c = 0;
		e.Budgeted_Surplus_Deficit__c = 0;
		e.Budgeted_Attendance__c = 100;
		e.Attendance_Current__c = 200;
		e.Attendance_Prior__c = 150;
		e.Year_1_Latest__c = 200;
		e.Year_2__c = 200;
		e.Year_3_Oldest__c = 150;
		e.Number_of_Months_Outstanding__c = 0;
		e.Number_of_Fundings_per_Year__c = 3;
		e.Avg_percentage_of_Face_Funded__c = 85;
		e.Cross_Year_Funding_Amount__c = 0;
		e.Avg_Days_Notice_given__c = 40;
		insert e;
		
			/*
			Charter_Term__c charterTerm1 = new Charter_Term__c(
			School__c = a2.Id,
			Start_Date__c = System.today(),
			End_Date__c = System.today().addYears(5),
			Term__c = 'five',
			Frequency__c = 'year',
			Type__c = 'Initial',
			No_Cap_Limit__c = true
			);
			insert charterTerm1;
			
            
            
        
            
            //Funded_Receivable__c
            //Funding_Estimate_Receivable__c
            
            */
            
            
 			//FC DEtails
            ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(uwdet[0]);
            FC_Refresh_Details_Ctrl fdc = new FC_Refresh_Details_Ctrl(thecontroller2);
            fdc.back();
            fdc.refresh(); 
            
            test.stoptest();
            
            
            
            
            
 	}

     static testMethod void testRefactoring() {
        Lead l = [Select id, company from Lead where email='t@t.com'];
       
       Opportunity o;
       String oppName = 'Initial Funding - '+l.company;
       
       try {
           o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
       } catch (Exception e) {
               oppName = l.company;
               o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
       }
       
       State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
       
       //create Opp School and FC Details
       System.debug('***** fcSetup creating account');
       Account a2 = new Account(name='test school', ParentId=o.AccountId,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
       insert a2;
       
       test.starttest();
       System.debug('***** fcSetup creating oppschool');
       Opp_School__c os = new Opp_School__c(Opportunity__c=o.Id, School__c=a2.Id);
       insert os;
       List<Opp_School__c> oss = new List<Opp_School__c>();
       oss.add(os);

       EWS__c e = new EWS__c();
       e.Account__c = a2.Id;
       e.RecordTypeId = '01270000000l2adAAA';
       e.Review_Date__c = Date.today();
       e.Fiscal_Year__c = '16-17';
       e.Quarter_Ending_FY__c = 'Q1';
       //e.Active__c = true;
       e.FDA_County__c = 'Yes';
       e.FDA_District__c = 'Yes';
       e.Date_Opened__c = Date.today();
       e.Num_of_Shortfalls_Current_FY__c = 0;
       e.Audit_Information__c = 'Minor Issues';
       e.Net_Assets__c = 0;
       e.Non_Facilities_Liabilities__c = 0;
       e.Annual_Rent_Expense__c = 0;
       e.Prior_Year_Surplus_Deficit__c = 0;
       e.Budgeted_Revenue__c = 100000;
       e.Budgeted_Donations__c = 0;
       e.Budgeted_Surplus_Deficit__c = 0;
       e.Budgeted_Attendance__c = 100;
       e.Attendance_Current__c = 200;
       e.Attendance_Prior__c = 150;
       e.Year_1_Latest__c = 200;
       e.Year_2__c = 200;
       e.Year_3_Oldest__c = 150;
       e.Number_of_Months_Outstanding__c = 0;
       e.Number_of_Fundings_per_Year__c = 3;
       e.Avg_percentage_of_Face_Funded__c = 85;
       e.Cross_Year_Funding_Amount__c = 0;
       e.Avg_Days_Notice_given__c = 40;
       insert e;


       system.debug('*** Active? = ' + e.Active__c);
       system.debug('*** record type = ' + e.recordtypeid);
       
       e.Active__c = true;
       e.recordtypeid = '01270000000l2aeAAA';
       update e;

       system.debug('*** Active? = ' + e.Active__c);
       system.debug('*** record type = ' + e.recordtypeid);

       List<FC_Details__c> details = FCFormUtils.createFCDetails(oss);
       FCFOrmUtils.populateDetailFieldsFromSFData(details);
       FCFOrmUtils.populateDetailCommentFieldsFromSFData(details);		
           
       //see if FC Forms were created
       LIst<FC_FOrm__c> forms = [Select Id, Recordtypeid, Opportunity__c from FC_Form__C where OPportunity__c=:o.Id];
       //system.assertEquals(4, forms.size());
       FC_FOrm__c summForm;
       FC_FOrm__c finnFOrm;
       FC_FOrm__c uwFOrm;
       FC_FOrm__c svcFOrm;
       
       for (FC_FOrm__c f : forms) {
           if (f.recordtypeid==FCFOrmUtils.UWFcRecType) uwFOrm=f;
           if (f.recordtypeid==FCFOrmUtils.FinanceFcRecType) finnFOrm=f;
           if (f.recordtypeid==FCFOrmUtils.SummaryFcRecType) summForm=f;
           if (f.recordtypeid==FCFOrmUtils.ServicingFcRecType) svcFOrm=f;
       }
       
       List<FC_Details__c> uwfin = [Select Id from FC_Details__c where FC_Form__c=:finnFOrm.Id];
       
       
        //FC Details
        ApexPages.StandardController thecontroller2 = new ApexPages.StandardController(uwfin[0]);
       FC_Refresh_Details_Ctrl fdc = new FC_Refresh_Details_Ctrl(thecontroller2);
       //fdc.back();
       fdc.refresh(); 
       
       test.stoptest(); 
}
 	       
}