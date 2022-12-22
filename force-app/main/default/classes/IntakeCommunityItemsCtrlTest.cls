@isTest
private class IntakeCommunityItemsCtrlTest {
    
    private static void setup() {
        Account acc = TestHelper.createAccountForIndustryType('School');
        insert acc;
    
        Account RPAAccount = TestHelper.createRPAAccount(acc.Id);
        insert RPAAccount;
    
        RPA__c rpa = new RPA__c();
        rpa.Account__c = RPAAccount.Id;
        insert rpa;
    
        Opportunity opp = TestHelper.createOpportunity(acc, 'Test Opp');
        //opp.RPA__c = rpa.Id;
        opp.AccountId = acc.id;
        //opp.recordtypeid = [select name,sobjecttype from recordtype where name = 'Initial Funding' and sobjecttype = 'opportunity'].id;
        insert Opp;
        
        Intake_Item__c it = new Intake_Item__c();
        //it.recordtypeid = [select name,sobjecttype from recordtype WHERE name = 'Initial Funding' AND sobjecttype = 'Opportunity'].id;
        it.name = 'test';
        it.Visible_To__c = 'Seller';
        it.Opportunity__c = opp.id;
        it.status__c = DiligenceVars.IntakePendingStatus;
        insert it;
        
        Intake_Item__c it2 = new Intake_Item__c();
        //it.recordtypeid = [select name,sobjecttype from recordtype WHERE name = 'Initial Funding' AND sobjecttype = 'Opportunity'].id;
        it2.name = 'test';
        it2.Visible_To__c = 'Seller';
        it2.Opportunity__c = opp.id;
        it2.status__c = DiligenceVars.IntakePendingStatus;
        it2.Parent_Intake_Item__c = it.id;
        insert it2;
    }

    
    static testMethod void testItems(){
        setup();
        
        IntakeItem it = new IntakeItem();
        it.name = 'test';
        it.numPending = 1;
        it.numItems = 1;
        
        Intake_Item__c intakeItem = [select id,opportunity__c,Opportunity__r.Name,status__c,
        assigned_to__c, 
        Due__c ,
                                     Is_Visible_To_Community__c,Is_Document__c, 
                                      Opportunity__r.recordtypeid, Opportunity__r.recordtype.name, Action_URL__c ,
                                      Parent_Intake_Item__c 
                                     FROM intake_item__c LIMIT 1];
        
        IntakeItemWrapper itw = new IntakeItemWrapper();
        itw.item = intakeItem;
        itw.hasChildren = false;
        itw.hasParent = false;
        itw.isReadOnly = false;
        itw.isPQSubmitted = false;
        itw.numUnsubmittedDocs = 2;
        itw.numChildrenAccepted = 2;
        itw.numChildren = 2;
        itw.allChildrenAccepted = false;
        itw.assignedToName = 'test';
        itw.oppName = 'test';
        itw.assignedToCSC = true;
        itw.isOverdue = true;
        itw.hasOverdueChildren = true;
        itw.isPQ = true;
        itw.isInfoSheet = true;
        itw.isActionDetail = true;
        itw.isActionEditDetail = true;
        //itw.children;
        IntakeItemWrapper w = new IntakeItemWrapper(intakeItem,'Role');
        
        List<IntakeItemWrapper> items = IntakeCommunityItemsCtrl.acceptedStatus(intakeItem.id);
        List<Opportunity> opps = IntakeCommunityItemsCtrl.getClosedOpportunities('');
        List<String> filters = new List<String>();
        filters.add('');
        list<ItemsByOppRecType> types = IntakeCommunityItemsCtrl.getRecTypeItem('', filters);
        Map<String,List<IntakeItemWrapper>> maps = IntakeCommunityItemsCtrl.getMapOpportunity('[{"allChildrenAccepted":true,"assignedToCSC":false,"assignedToName":"blah","hasChildren":false,"hasOverdueChildren":false,"hasParent":false,"isActionDetail":false,"isActionEditDetail":false,"isInfoSheet":false,"isOverdue":false,"isPQ":true,"isPQSubmitted":false,"isReadOnly":false,"item":{"Id":"a2C0R0000001xxvUAA","RecordTypeId":"0120g000000EB1aAAG","Opportunity__c":"0060R000005iwBKQAY","Visible_To__c":"CSC;School","Comments__c":"Please complete the questions in the attached form to the best of your knowledge.","Is_Document__c":false,"Action_URL__c":"Custom Form","Name":"Submit Pre-Qualification Form","Status__c":"Pending","Is_Pre_Qual__c":true,"Assigned_To__c":"School","Due__c":false,"Processing_Order__c":1,"Opportunity__r":{"Target_Wire_Date__c":"2018-07-09","AccountId":"0010R00000MC0u3QAD","Name":"Initial Funding - blah8","Id":"0060R000005iwBKQAY","Account":{"Id":"0010R00000MC0u3QAD","Name":"blah"}}},"numChildren":0,"numChildrenAccepted":0,"numUnsubmittedDocs":0,"oppName":"Initial Funding - blah8"}]');
        
        
    }
    
    static testMethod void testItemWrappers(){
        ItemsByOppRecType it = new ItemsByOppRecType();
        it.recordtypename = null;
        it.itemList = null;
    }
    
    static testMethod void testCollapsibleSection(){
        Lightning_CollapsibleSection.getItems('test');
    }
    
    static testMethod void testUploadDocumentList(){
        Lightning_UploadDocumentList.getOpps('test');
    }
    
    static testMethod void testMyItems(){
            setup();
            
            //DiligenceRoleMap__mdt dm = new DiligenceRoleMap__mdt(Box_Folder_Name__c='test',Profile_Name__c='System Administrator',Role__c='School');
            //insert dm;
        
            Opportunity o = [SELECT id from opportunity limit 1];
            intake_item__c i = [select id from intake_item__c LIMIT 1];
            MyItemCtlr.getIntakeItems(o.id,i.id);
            MyItemRowCtlr.getIntakeItems(o.id,i.id);
            MyItemRowCtlr.getIntakeItem(i.id);
            MyItemRowCtlr.getUserRole(userInfo.getUserId());
            MyItemRowCtlr.getIDFacilitiesIntakeItem();
            MyItemRowCtlr.acceptedStatus(i.id);
            MyItemsCtlr.getOpenOpportunities();
            MyItemsCtlr.getUserRole(userInfo.getUserId());
            contact c = new contact();
            MyItemsCtlr.getOppsForContactRole(c.id, 'Test');
               
    }
    
    static testMethod void testPortalDocUpload(){
        setup();
        string before = 'Testing base 64 encode';            
        Blob beforeblob = Blob.valueOf(before);

         //Insert contentdocument data
         ContentVersion cv = new ContentVersion();
         cv.title = 'test content trigger';      
         cv.PathOnClient ='test';           
         cv.VersionData =beforeblob;          
         insert cv;         
        contentdocument ctd = [SELECT id FROM contentdocument LIMIT 1];
        
        Portal_Multi_Doc_Upload__c p = new Portal_Multi_Doc_Upload__c();
        p.Target_Object_Ids__c = [select id from intake_item__c limit 1].id;
        p.Content_Ids__c = ctd.id;
        p.Root_Object_Id__c = [select id from opportunity limit 1].id;
        insert p;
       
    }
    
    static testMethod void TestOppEditCtrlTests(){
        setup();
        opportunity opp = [select id from opportunity limit 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        TestOppEditCtrl testOpp = new TestOppEditCtrl(sc);
        
        PageReference pageRef = Page.TestOppEditPage ;
        pageRef.getParameters().put('id', opp.id);
        Test.setCurrentPage(pageRef);
        
        testOpp.back();
        testOpp.getLock();
        testOpp.save();
    }
    
    /*
    static testMethod void UploadTableCtlrTests(){
        setup();
        string before = 'Testing base 64 encode';            
        Blob beforeblob = Blob.valueOf(before);

         //Insert contentdocument data
         ContentVersion cv = new ContentVersion();
         cv.title = 'test content trigger';      
         cv.PathOnClient ='test';           
         cv.VersionData =beforeblob;          
         insert cv;         
        contentdocument ctd = [SELECT id FROM contentdocument LIMIT 1];
        
        opportunity o = [SELECT id from opportunity limit 1];
        intake_item__c i = [select id,name from intake_item__c LIMIT 1];
        
        List<Intake_Item__c> items = UploadTableCtlr.getIntakeItems(i.name,'30');
        UploadTableCtlr.insertUpload(i.id,ctd.id, '');
    }*/

    private static Map<String,SObject> setupItems() {
        Account cmo = TestDiligenceUtils.getCMO();
        insert cmo;
        Account charterHolder = TestDiligenceUtils.getCharterHolder(cmo);
        insert charterHolder;
        Account school = TestDiligenceUtils.getSchool(charterHolder);
        insert school;
        Contact con = TestDiligenceUtils.getContact(school);
        insert con;
        Opportunity opp = TestDiligenceUtils.getOpportunity(charterHolder);
        insert opp;
        Intake_Item__c acctItem = TestDiligenceUtils.getOngoingDiligenceItem(charterHolder);
        Intake_Item__c oppItem = TestDiligenceUtils.getDiligenceItem(opp);
        insert new List<Intake_Item__c> { acctItem, oppItem };
        User u = TestDiligenceUtils.getUser(con, true);
        insert new List<Community_Contact_Role__c> {
            TestDiligenceUtils.getCCR(con, charterHolder),
            TestDiligenceUtils.getCCR(con, opp)
        };
        Box_Read_Only_Shares__c folder = new Box_Read_Only_Shares__c(Opportunity__c = opp.Id, Role__c = 'School');
        insert folder;
        return new Map<String,SObject> {
            'folder' => folder,
            'oppItem' => oppItem,
            'acctItem' => acctItem,
            'opp' => opp,
            'user' => u,
            'cmo' => cmo
        };
    }

    @isTest
    public static void testGetRecTypes() {
        Test.startTest();
        IntakeCommunityItemsCtrl ctrl = IntakeCommunityItemsCtrl.getRecTypes();
        Test.stopTest();

        System.assertEquals(RecordType.getSObjectType(), ((Id)ctrl.fundRecType).getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), ((Id)ctrl.facRecType).getSObjectType());
        System.assertEquals(RecordType.getSObjectType(), ((Id)ctrl.fofRecType).getSObjectType());
    }

    @isTest
    public static void testGetOppName() {
        Map<String,SObject> data = setupItems();

        Test.startTest();
        Opportunity opp = IntakeCommunityItemsCtrl.getOppName(data.get('opp').Id);
        Test.stopTest();

        System.assertEquals(data.get('opp').Id, opp.Id);
    }

    @isTest
    public static void testSubmitStatus() {
        Map<String,SObject> data = setupItems();

        Test.startTest();
        System.runAs((User)data.get('user')) {
            IntakeCommunityItemsCtrl.submitStatus(data.get('oppItem').Id);
        }
        Test.stopTest();

        System.assertEquals('Submitted', [ SELECT Status__c FROM Intake_Item__c WHERE Id = :data.get('oppItem').Id ].Status__c);
    }

    @isTest
    public static void testGetRecTypeItemAllItems() {
        Map<String,SObject> data = setupItems();

        Test.startTest();
        System.runAs((User)data.get('user')) {
            List<ItemsByOppRecType> items = IntakeCommunityItemsCtrl.getRecTypeItem('All Items', new List<String>());
            List<ItemsByOppRecType> itemsCached = IntakeCommunityItemsCtrl.getRecTypeItem('All Items', new List<String>());
            List<String> cmoStrings = IntakeCommunityItemsCtrl.getCMOStrings(items);
            List<CMOAccounts> cmos = IntakeCommunityItemsCtrl.getCMOs(items, null);
        }
        Test.stopTest();

        //TBD
    }

    @isTest
    public static void testGetRecTypeItemAllItemsWithCMOFilter() {
        Map<String,SObject> data = setupItems();

        Test.startTest();
        System.runAs((User)data.get('user')) {
            List<ItemsByOppRecType> items = IntakeCommunityItemsCtrl.getRecTypeItem('All Items', new List<String> { data.get('cmo').Id });
            List<ItemsByOppRecType> itemsCached = IntakeCommunityItemsCtrl.getRecTypeItem('All Items', new List<String> { data.get('cmo').Id });
            List<String> cmoStrings = IntakeCommunityItemsCtrl.getCMOStrings(items);
            List<CMOAccounts> cmos = IntakeCommunityItemsCtrl.getCMOs(items, new List<String> { data.get('cmo').Id });
        }
        Test.stopTest();

        //TBD
    }

    @isTest
    public static void testFolders() {
        Map<String,SObject> data = setupItems();

        Test.startTest();
        List<Box_Read_Only_Shares__c> folders = null;
        System.runAs((User)data.get('user')) {
            folders = IntakeCommunityItemsCtrl.getFolders();
        }
        Test.stopTest();

        System.assertEquals(1, folders.size());
        System.assertEquals(data.get('folder').Id, folders.get(0).Id);
    }

    @isTest
    public static void testMapOpportunity() {
        Id oppty1Id = TestDiligenceUtils.getFakeId(SObjectType.Opportunity);
        Id ii1Id = TestDiligenceUtils.getFakeId(SObjectType.Intake_Item__c);
        Id ii2Id = TestDiligenceUtils.getFakeId(SObjectType.Intake_Item__c);
        IntakeItemWrapper childWrapper1 = new IntakeItemWrapper();
        childWrapper1.item = new Intake_Item__c(Id = ii1Id, Opportunity__c = oppty1Id, Opportunity__r = new Opportunity(Name = 'Test Opp 1'));
        IntakeItemWrapper parentWrapper1 = new IntakeItemWrapper();
        parentWrapper1.item = new Intake_Item__c(Id = ii2Id, Opportunity__c = oppty1Id, Opportunity__r = new Opportunity(Name = 'Test Opp 1'));
        parentWrapper1.children = new List<IntakeItemWrapper>();
        parentWrapper1.children.add(childWrapper1);

        Test.startTest();
        Map<String,List<IntakeItemWrapper>> result = IntakeCommunityItemsCtrl.getMapOpportunity(JSON.serialize(new List<IntakeItemWrapper> {
            parentWrapper1
        }));
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(1, result.values().get(0).size());
        System.assertEquals(ii2Id, result.values().get(0).get(0).item.Id);
        System.assertEquals(1, result.values().get(0).get(0).children.size());
        System.assertEquals(ii1Id, result.values().get(0).get(0).children.get(0).item.Id);
    }
}