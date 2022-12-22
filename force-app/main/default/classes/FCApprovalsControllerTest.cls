@isTest
public class FCApprovalsControllerTest  {
   
   public static testMethod void controllerTest() {

        // Set up data
        Account a = new Account(Name='Test');
        insert a;
        
        Id ort = [Select id from recordtype where sobjecttype='Opportunity' and name='FOF'].Id;
        
        Opportunity o = new Opportunity(Name='Test'
                                        , AccountId=a.Id
                                        , StageName='Stage 1 - Prospect'
                                        , CloseDate=system.today()
                                        , Facilities_Client_Type__c='Seller'
                                        , Deal_Structure__c='Purchase Existing Location'
                                        , RecordTypeId=ort);
        insert o;
        
        Opp_School__c os = new Opp_School__c(School__c=a.Id, Opportunity__c=o.Id);
        insert os;
        
        
        Map<String, Id> fcFormRTMap = new Map<String, Id>(); 
        for (RecordType rt : [Select Id, Name From RecordType Where SObjectType = 'FC_Form__c']) {
            fcFormRTMap.put(rt.Name, rt.Id);
        }
        
        
        FC_Form__c fcFormSummary = new FC_Form__c(Name='Test', Opportunity__c=o.Id, RecordTypeId=fcFormRTMap.get('Summary'));
        insert fcFormSummary;
        FC_Form__c fcFormFinance = new FC_Form__c(Name='Test', Opportunity__c=o.Id, RecordTypeId=fcFormRTMap.get('Finance'));
        insert fcFormFinance;
        FC_Form__c fcFormUnderwriting = new FC_Form__c(Name='Test', Opportunity__c=o.Id, RecordTypeId=fcFormRTMap.get('Underwriting'));
        insert fcFormUnderwriting;
        FC_Form__c fcFormServicing = new FC_Form__c(Name='Test', Opportunity__c=o.Id, RecordTypeId=fcFormRTMap.get('Servicing'));
        insert fcFormServicing;                

        FC_Approval__c fcApproval = new FC_Approval__c(FC_Form__c=fcFormSummary.Id, Status__c='Pending', Type__c='Pre-FC Approval', Approver__c = UserInfo.getUserId());
        insert fcApproval;

        Map<String, Id> fcDetailsRTMap = new Map<String, Id>(); 
        for (RecordType rt : [Select Id, Name From RecordType Where SObjectType = 'FC_Details__c']) {
            fcDetailsRTMap.put(rt.Name, rt.Id);
        }


        FC_Details__c fcDetailsFinance = new FC_Details__c(FC_Form__c=fcFormFinance.Id, RecordTypeId=fcDetailsRTMap.get('Finance'), Opp_School__c=os.Id);
        insert fcDetailsFinance;
        FC_Details__c fcDetailsUnderwriting = new FC_Details__c(FC_Form__c=fcFormUnderwriting.Id, RecordTypeId=fcDetailsRTMap.get('Underwriting'), Opp_School__c=os.Id);
        insert fcDetailsUnderwriting;
        FC_Details__c fcDetailsServicing = new FC_Details__c(FC_Form__c=fcFormServicing.Id, RecordTypeId=fcDetailsRTMap.get('Servicing'), Opp_School__c=os.Id);
        insert fcDetailsServicing;


        // Test
        Test.startTest(); 
        ApexPages.currentPage().getParameters().put('id', fcFormSummary.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(fcFormSummary);
        FCApprovalsController controller = new FCApprovalsController(sc);        
        controller.refreshApprovals();
        controller.updateStatus();        
        controller.currentIndex = -1;
        controller.next();   
        controller.currentIndex = 1;
        controller.previous();
        controller.back();             
        Test.stopTest(); 
   
           
    }
}