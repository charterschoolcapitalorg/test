/**=====================================================================
 * Name: TestFacilitiesPortalItemMapping
 * Created By: RelationEdge
 *
 * Date Modified                Modified By                  Description of the update
 * [May 22, 2020]               [John Caughie]              [updated for lead facilities type being disabled]
 * [May 22, 2020]               [John Caughie]              [TODO - RE didn't add any system asserts. Add system asserts]
 =====================================================================*/

@isTest 
 private class TestFacilitiesPortalItemMapping {

    @TestSetup
    static void makeData(){
        State_Province__c state1 = new State_Province__c(
            Name = 'CA',
            Active__c = true
        );
        insert state1;

        State_Province__c s = [Select Id from State_Province__c where Name = 'CA' limit 1];
		
		Account a = new Account(name='test ch', recordtypeid = RecordTypes.IDCharterAccount, operating_state__c=s.Id);
        insert a;
        Account a2 = new Account(name='test school', ParentId=a.Id,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
        insert a2;    
		Account prop = new Account(name='test property',recordtypeid = RecordTypes.IDPropAccount, operating_state__c=s.Id);
        insert prop; 

        Id ongoingId = RecordTypes.IDOngoingIntakeItem;
        Intake_Item__c ii = new Intake_Item__c(Name = 'testing', RecordTypeId = ongoingId, Client_Comments__c = 'this is a test intake item for saving lease compliance', Submitted_Date__c = Date.today(), Status__c = DiligenceVars.IntakePendingStatus, Account_Name__c = a.Id, Action_Item_Mapping__c = 'Budget');
        insert ii;
        System.debug(ii.Id);
         
        Tenant__c te = new Tenant__c();
		te.tenant__c = a.Id;
        insert te;
		
		Lease__c leaseWithTenantMatchesCP = new Lease__c();
		leaseWithTenantMatchesCP.Property__c = prop.Id;
        leaseWithTenantMatchesCP.Tenant__c = te.Id;
        leaseWithTenantMatchesCP.Lease_Status__c = 'Active'; 
        insert leaseWithTenantMatchesCP; 
        

        Lease__c leaseWithAccountMatchingCP = new Lease__c();
        leaseWithAccountMatchingCP.Property__c = prop.Id;
        leaseWithAccountMatchingCP.Account__c = a.Id;
        leaseWithAccountMatchingCP.Lease_Status__c = 'Active'; 
        insert leaseWithAccountMatchingCP;

        Lease__c leaseForLeaseSchool1 = new Lease__c();
        leaseForLeaseSchool1.Property__c = prop.Id;
        leaseForLeaseSchool1.Account__c = prop.Id;
        leaseForLeaseSchool1.Lease_Status__c = 'Active'; 
        insert leaseForLeaseSchool1;

        Lease_School__c matchesCP = new Lease_School__c();
        matchesCP.lease__c = leaseForLeaseSchool1.Id;
        matchesCP.Account_School__c = a2.Id;
        insert matchesCP;

        
        ID pending = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Pending').getRecordTypeId();

        Lease_Compliance__c nl = new Lease_Compliance__c();
        nl.Lease__c = leaseWithTenantMatchesCP.Id;
        nl.Lease_Compliance_Name__c = 'lease compliance testing';
        nl.Action_Item_Mapping__c = 'Budget';
		nl.Received_Date__c = null;
		nl.recordtypeid = pending;
        insert nl;
        
        
        Lease_Compliance__c nl3 = new Lease_Compliance__c();
        nl3.Lease__c = leaseWithAccountMatchingCP.Id;
        nl3.Action_Item_Mapping__c = 'Budget';
		nl3.Received_Date__c = null;
		nl3.recordtypeid = pending;
        insert nl3;
        
        Lease_Compliance__c nl4 = new Lease_Compliance__c();
        nl4.Lease__c = leaseForLeaseSchool1.Id;
        nl4.Action_Item_Mapping__c = 'Budget';
		nl4.Received_Date__c = null;
		nl4.recordtypeid = pending;
        insert nl4;
        
    }
     static testMethod void mapPortalItems() {
            TestDIligenceUtils.createCOnfig();
            TestDiligenceUTils.createFacilitiesIntakeTemplates();
            
            // LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
            // cntr.back();
            // cntr.doNotCreateOpp = false;
            
            // //positive test
            // LEad l = TestDiligenceUtils.createFacLead();
            // insert l;
            // cntr.setLEad(l);
            // cntr.execute();

            //2020.05.22 J caughie - removed lead conversion and created opp directly. Lead facilities types was disabled.
            Account charter = new Account();
            charter.Name = 'Test Charter';
            insert charter;

            Opportunity opp = new Opportunity();
            opp.AccountId = charter.Id;
            opp.Name = 'FA - Test Charter';
            opp.CloseDate = Date.today().addDays(30);
            opp.StageName = 'Stage 1 - Prospect​​';
            opp.RecordTypeId= RecordTypes.IDFacilitiesOpp;
            opp.Facilities_Client_Type__c = 'Seller';
            insert opp;
            
            // String oppName = 'FA - '+l.company;
            Opportunity o;
            // try {
            //     o = [Select Id from Opportunity where Name=:oppName];
            //     //o = [Select Id from Opportunity LIMIT 1];
            // } catch (Exception e) {
            //     oppName = l.company;
            //     o = [Select Id from Opportunity where Name=:oppName];
            //  }
            o = [Select Id from Opportunity where Name=:opp.Name];
            //update opp to Stage 2 to create Stop 1 items
            o.StageName = Diligencevars.facStageToTriggerIntakeItemCreation;
            update o;
            
         List<Intake_Item__c> ii = [Select Id, Action_Item_Mapping__c from Intake_Item__c where Opportunity__c=:o.Id];
         System.debug('test ii ' + ii);
         
         AcceptClientPortalItemCtrl.getUIThemeDescription();
         AcceptClientPortalItemCtrl.getUITheme();         
         AcceptClientPortalItemCtrl.getMappedItems(ii[0].Id);
         
         AcceptClientPortalItemCtrl.getIntakeItem(ii[0].Id);
         
         List<CSC_Action_Item__c> acl = AcceptClientPortalItemCtrl.getCharterACLItems(ii[0].Id);
         List<CSC_Action_Item__c> sacl = AcceptClientPortalItemCtrl.getSchoolACLItems(ii[0].Id);
         List<CSC_Action_Item__c> pcl = AcceptClientPortalItemCtrl.getPCLItems(ii[0].Id);
        
         if (acl!=null&&acl.size()>0) {
             
             AcceptClientPortalItemCtrl.saveActionItem(ii[0].Id, acl[0].Id, 'Completed', '', 'blah', 
                                      'blah', Date.today().format(), Date.today().format(), Date.today().format(), Date.today().format(), 'true');
         }
         if (sacl!=null&&sacl.size()>0) {
             
             AcceptClientPortalItemCtrl.saveActionItem(ii[0].Id, sacl[0].Id, 'Completed', '', 'blah', 
                                      'blah', Date.today().format(), Date.today().format(), Date.today().format(), Date.today().format(), 'true');
         }
         if (pcl!=null&&pcl.size()>0) {
             
             AcceptClientPortalItemCtrl.saveActionItem(ii[0].Id, pcl[0].Id, 'Completed', '', 'blah', 
                                      'blah', Date.today().format(), Date.today().format(), Date.today().format(), Date.today().format(), 'true');
         }
         AcceptClientPortalItemCtrl.saveNoActionItems(ii[0].Id);
        
        
        AcceptClientPortalItemCtrl.getCharterALAcctType();
        AcceptClientPortalItemCtrl.getPCLType();
        AcceptClientPortalItemCtrl.getFiles(ii[0].Id);                          
     }

     @IsTest
     static void testSaveLeaseCompliance(){

        String iiId = [SELECT Id FROM Intake_Item__c WHERE Name = 'testing'].Id;
        Lease_Compliance__c lcId = [SELECT Id, Lease_Compliance_Name__c, Received_Date__c, RecordType.Name FROM Lease_Compliance__c WHERE Lease_Compliance_Name__c = 'lease compliance testing'];
        System.debug(lcId);
         
        Test.startTest();
        AcceptClientPortalItemCtrl.saveLeaseCompliance(iiId, String.valueOf(lcId.Id), '', 'tue', 'testing method');
        Test.stopTest();

        Lease_Compliance__c newLc = [SELECT Id, Lease_Compliance_Name__c, Received_Date__c, RecordType.Name, Comments__c FROM Lease_Compliance__c WHERE Id =: lcId.Id];
        System.debug(newLc);

        // System.assertEquals(lcId.RecordType.Name, newLc.RecordType.Name); //Jen added a flow whichbreaks this
        System.assertEquals(Date.today(), newLc.Received_Date__c);

         
     }

     @IsTest 
     static void testGetLeaseCompliance(){
        Account parent = [SELECT Id, Name FROM Account WHERE Name = 'test ch'];
        Account a = [SELECT Id, Name, ParentId FROM Account WHERE Name = 'test school'];
        a.ParentId = parent.Id;
        update a;
        System.debug(a);
        Intake_Item__c ii = [SELECT Id, Account_Name__c, Action_Item_Mapping__c FROM Intake_Item__c WHERE Name = 'testing'];
        System.debug(ii);
        ii.Account_Name__c = parent.Id;
        update ii;

        Test.startTest();
        List<Lease_Compliance__c> myList = AcceptClientPortalItemCtrl.getLeaseComplianceItem(ii.Id);
        Test.stopTest();

        System.debug(myList);

     }
 }