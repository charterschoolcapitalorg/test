@isTest
public class FCFormHeaderControllerTest  {
   
   public static testMethod void controllerTest() {

        // Set up data
        Account a = new Account(Name='Test');
        insert a;
        
        Opportunity o = new Opportunity(Name='Test'
                                        , AccountId=a.Id
                                        , StageName='Stage 1 - Prospect'
                                        , CloseDate=system.today()
                                        , Facilities_Client_Type__c='Seller'
                                        , Deal_Structure__c='Purchase Existing Location');
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



        //FC_Details__c fcDetailsSummary = new FC_Details__c(FC_Form__c=fcFormFinance.Id, RecordTypeId=fcDetailsRTMap.get('Summary'), Opp_School__c=os.Id);
        //insert fcDetailsSummary;
        FC_Details__c fcDetailsFinance = new FC_Details__c(FC_Form__c=fcFormFinance.Id, RecordTypeId=fcDetailsRTMap.get('Finance'), Opp_School__c=os.Id);
        insert fcDetailsFinance;
        FC_Details__c fcDetailsUnderwriting = new FC_Details__c(FC_Form__c=fcFormUnderwriting.Id, RecordTypeId=fcDetailsRTMap.get('Underwriting'), Opp_School__c=os.Id);
        insert fcDetailsUnderwriting;
        FC_Details__c fcDetailsServicing = new FC_Details__c(FC_Form__c=fcFormServicing.Id, RecordTypeId=fcDetailsRTMap.get('Servicing'), Opp_School__c=os.Id);
        insert fcDetailsServicing;


        // Test Summary
        //ApexPages.currentPage().getParameters().put('id', fcDetailsSummary.Id);
        //ApexPages.StandardController sc = new ApexPages.StandardController(fcDetailsSummary);
        //FCFormHeaderController controller = new FCFormHeaderController(sc);        

        // Test Finance
        ApexPages.currentPage().getParameters().put('id', fcDetailsFinance.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(fcDetailsFinance);
        FCFormHeaderController controller = new FCFormHeaderController(sc);        

        // Test Underwriting
        ApexPages.currentPage().getParameters().put('id', fcDetailsUnderwriting.Id);
        sc = new ApexPages.StandardController(fcDetailsUnderwriting);
        controller = new FCFormHeaderController(sc);        
        
        // Test Servicing
        ApexPages.currentPage().getParameters().put('id', fcDetailsServicing.Id);
        sc = new ApexPages.StandardController(fcDetailsServicing);
        controller = new FCFormHeaderController(sc);        

        // Test Actions
        controller.redirectRecordType();
        controller.edit();
        controller.save();
        controller.cancel();
        
        
            
    }
}