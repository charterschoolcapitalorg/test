/**=====================================================================
 * Charter School Capital
 * Name: OperationsReporting
 * Test Class: OperationsReportingTest
 * Description: WC Milestone Report
 * Created Date: ???
 * Created By: ??? 
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 *  Oct 30, 2022                Slava Krel                   Data Export
 =====================================================================*/

public with sharing class OperationsReporting {

    public List<OpportunityWrapper> oppsToExport {get;set;}

    public OperationsReporting(){
        oppsToExport = getDailyUpdates();
    }

    @AuraEnabled
    public static Map<Opportunity, List<CSC_Action_Item__c>> getDailyUpdateOpps() {
        
        Map<Opportunity, List<CSC_Action_Item__c>> oppItemMap = new Map<Opportunity, List<CSC_Action_Item__c>>();
        
        Map<Id, Opportunity> opps = new Map<ID, Opportunity>([SELECT Id, Account.Name, Name, CloseDate, State__c, NET_Amount_Requested__c, Owner.LastName, Paralegal__r.LastName, Financial_Review__r.LastName, Legal_Assistant__r.User_Fullname__c, Paralegal__r.User_Fullname__c, Financial_Review__r.User_Fullname__c, Owner.User_Fullname__c, Client_Portal_Testing_Opp__c, RecordType.Name, Receivables_Purchased__c, Date_Submitted__c, RecordType.DeveloperName FROM Opportunity WHERE Whiteboard_Opportunity_WC__c = true ORDER BY CloseDate asc]);
        //System.debug('WB Opps: ' + opps);
        Set<Id> oppIds = opps.keySet();
        
        List<String> itemNames = new List<String>{
            '"Ready to Fund" Email Sent',
            '"Ready to Fund" email sent',
            // '*CLIENT PORTAL* - Financial Analyst Finalized List of Items',
            // '*CLIENT PORTAL* - Financial Analyst Reviewed and Made Items Visible',
            // '*CLIENT PORTAL* - Paralegal Finalized List of Items',
            // '*CLIENT PORTAL* - Paralegal Reviewed and Made Items Visible',
            // '*CLIENT PORTAL* CSR Marked Diligence Items visible and Opening Call as Accepted',
            // '5DF Packet sent to client',
            'Financial Analyst Finalized List of Items',
            'Paralegal Finalized List of Items',
            'CSR Marked Diligence Items visible and Opening Call as Accepted',
            'CS Added CP Users to Client Portal',
            'Client Services Writeup Complete',
            'Diligence Items Received',
            'FC Approval Email Sent',
            'Final Amortization Schedule Approved by Client',
            'Finance FC Form Complete',
            'Funding Committee Approval',
            'Funding Committee Approval received',
            'Funding Committee approvals',
            'Funding Committee Form (Financial Review Completed)',
            'Funding Committee Form (Underwriting Review Completed)',
            'Funding Committee form completed - FIN (Financial review completed)',
            'Funding Committee form completed -UW (Due diligence completed)',
            'Funding Estimate approved by Client',
            'Funding Estimate Approved by Client',
            'Funding Estimate Prepared',
            'Initial Amortization Schedule prepared',
            'OIL Docs Received (Finance)',
            'OIL Docs Received (Underwriting)',
            'OIL documents received - FIN',
            'OIL documents received – FIN',
            'OIL documents received - UW',
            'OIL documents received – UW',
            // 'OIL sent to Client',
            'Pre-Approval Provided - FIN',
            'Pre-approval Provided - Finance',
            'Pre-approval Provided - Underwriting',
            'Pre-approval provided - UW',
            'Pre-approval- Finance',
            'Pre-approval- Underwriting',
            'Ready to Fund Email Sent',
            'Received electronic signature pages',
            'Received Electronic Signature Pages',
            'Received signature pages (Client)',
            // 'Send Application Guide',
            'Servicing FC Form Submitted for Review',
            'Underwriting FC Form Complete'
            };
        //System.debug(itemNames);
        
        List<CSC_Action_Item__c> itemList = new List<CSC_Action_Item__c>();
        itemList = [SELECT id, Name, Action_Item_Name__c, Opportunity_Id__c, Status__c, Assigned_To__r.Name, Date_Completed__c, CSC_Action_List__r.Opportunity__r.CloseDate, Status_Value__c  FROM CSC_Action_Item__c WHERE RecordType.DeveloperName = 'Sales_Process' AND CSC_Action_List__r.Opportunity__c IN :oppIds and Action_Item_Name__c IN :itemNames ORDER BY CSC_Action_List__r.Opportunity__r.CloseDate asc, CSC_Action_List__r.Opportunity__r.Account.Name asc];
                
        for(CSC_Action_Item__c ai : itemList){
            if(oppItemMap.containsKey(opps.get(ai.Opportunity_Id__c))){
                (oppItemMap.get(opps.get(ai.Opportunity_Id__c))).add(ai);
            } else {
                oppItemMap.put(opps.get(ai.Opportunity_Id__c), new List<CSC_Action_Item__c>{ai});
            }
        }
        System.debug('Map' + oppItemMap);
        return oppItemMap;
    }

    @AuraEnabled
    public static List<OpportunityWrapper> getDailyUpdates() {
        Map<Opportunity, List<CSC_Action_Item__c>> dailyOpps = getDailyUpdateOpps();

        List<OpportunityWrapper> opps = new List<OpportunityWrapper>();
        for(Opportunity o : dailyOpps.keySet()){
            System.debug('Opp: ' + o);
            Map<String, List<CSC_Action_Item__c>> itemMap = new Map<String, List<CSC_Action_Item__c>>();
            itemMap.put('fePrepared', new List<CSC_Action_Item__c>());
            itemMap.put('cpOpen', new List<CSC_Action_Item__c>());
            itemMap.put('feApproved', new List<CSC_Action_Item__c>());
            itemMap.put('oilsReceived', new List<CSC_Action_Item__c>());
            itemMap.put('paSubmitted', new List<CSC_Action_Item__c>());
            itemMap.put('fcSent', new List<CSC_Action_Item__c>());
            itemMap.put('fcApproval', new List<CSC_Action_Item__c>());
            itemMap.put('sigPages', new List<CSC_Action_Item__c>());
            itemMap.put('emailSent', new List<CSC_Action_Item__c>());
            
            OpportunityWrapper ow = new OpportunityWrapper();
            ow.oppId = o.Id;
            ow.opp = o;
            // ow.businessDaysFromStart = DateUtilities.calculateBusinessDays(o.Date_Submitted__c, Date.today());
            ow.businessDaysToClose = DateUtilities.calculateBusinessDays(Date.today(), o.CloseDate);
            for(CSC_Action_Item__c item : dailyOpps.get(o)){
                if(item.Action_Item_Name__c.containsIgnoreCase('Funding Estimate Prepared') || item.Action_Item_Name__c.containsIgnoreCase('Initial Amortization Schedule prepared')){
                    itemMap.get('fePrepared').add(item);
                // } else if(item.Action_Item_Name__c.containsIgnoreCase('Client Portal') || item.Action_Item_Name__c.containsIgnoreCase('Send Application') || item.Action_Item_Name__c.containsIgnoreCase('OIL Sent') || item.Action_Item_Name__c.containsIgnoreCase('5DF Packet')){
                //     itemMap.get('oilSent').add(item);
                } else if(item.Action_Item_Name__c.containsIgnoreCase('Financial Analyst Finalized List of Items') || item.Action_Item_Name__c.containsIgnoreCase('Paralegal Finalized List of Items') || item.Action_Item_Name__c.containsIgnoreCase('CSR Marked Diligence Items visible and Opening Call as Accepted') || item.Action_Item_Name__c.containsIgnoreCase('CS Added CP Users to Client Portal')){
                    itemMap.get('cpOpen').add(item);
                } else if(item.Action_Item_Name__c.containsIgnoreCase('Funding Estimate Approved') || item.Action_Item_Name__c.containsIgnoreCase('Final Amortization Schedule Approved by Client')){
                    itemMap.get('feApproved').add(item);
                } else if(item.Action_Item_Name__c.containsIgnoreCase('OIL Doc') || item.Action_Item_Name__c.containsIgnoreCase('Diligence Items Received')){
                    itemMap.get('oilsReceived').add(item);
                } else if(item.Action_Item_Name__c.containsIgnoreCase('Funding Committee Form') || item.Action_Item_Name__c.containsIgnoreCase('Submitted for Review') || item.Action_Item_Name__c.containsIgnoreCase('Complete')){
                    itemMap.get('paSubmitted').add(item);
                } else if(item.Action_Item_Name__c.containsIgnoreCase('Funding Committee Approval')){
                    itemMap.get('fcApproval').add(item);
                } else if(item.Action_Item_Name__c.containsIgnoreCase('Signature Pages')){
                    itemMap.get('sigPages').add(item);
                } else if(item.Action_Item_Name__c.containsIgnoreCase('Ready to Fund')){
                    itemMap.get('emailSent').add(item);
                } else {
                    itemMap.get('fcSent').add(item);    //catch-all as any non-FC Sent should have been filtered out
                }
            }
            System.debug('fePrepared' + itemMap.get('fePrepared'));
            System.debug('cpOpen' + itemMap.get('cpOpen'));
            System.debug('feApproved' + itemMap.get('feApproved'));
            System.debug('oilsReceived' + itemMap.get('oilsReceived'));
            System.debug('paSubmitted' + itemMap.get('paSubmitted'));
            System.debug('fcSent' + itemMap.get('fcSent'));
            System.debug('fcApproval' + itemMap.get('fcApproval'));
            System.debug('sigPages' + itemMap.get('sigPages'));
            System.debug('emailSent' + itemMap.get('emailSent'));
            
            ow.fePrepared = calculateStatusFromStart(itemMap.get('fePrepared'), o.Date_Submitted__c, 2);
            if(o.RecordType.DeveloperName == 'Loan'){
                ow.cpOpen = 'Late';
            } else {
                ow.cpOpen = calculateStatusFromStart(itemMap.get('cpOpen'), o.Date_Submitted__c, 2);
            }
            // ow.cpOpen = calculateStatusFromStart(itemMap.get('cpOpen'), o.Date_Submitted__c, 2);
            ow.feApproved = calculateStatusToClose(itemMap.get('feApproved'), 8, ow.businessDaysToClose);
            ow.oilsReceived = calculateStatusToClose(itemMap.get('oilsReceived'), 7, ow.businessDaysToClose);
            ow.paSubmitted = calculateStatusToClose(itemMap.get('paSubmitted'), 6, ow.businessDaysToClose);
            ow.fcSent = calculateStatusToClose(itemMap.get('fcSent'), 5, ow.businessDaysToClose);
            ow.fcApproval = calculateStatusToClose(itemMap.get('fcApproval'), 4, ow.businessDaysToClose);
            ow.sigPages = calculateStatusToClose(itemMap.get('sigPages'), 3, ow.businessDaysToClose);
            ow.emailSent = calculateStatusToClose(itemMap.get('emailSent'), 3, ow.businessDaysToClose);
            
            opps.add(ow);
        }
        return opps;
    }

    private static string calculateStatusFromStart(List<CSC_Action_Item__c> items, Date startDate, Integer dueDays){
        //Completed || Late
        String status = '';
        Integer count = 0;
        Date submittedDate = (startDate == null ? Date.today().addDays(-50) : startDate);
        for(CSC_Action_Item__c item : items){
            System.debug('item' + item.Action_Item_Name__c);
            System.debug('item status' + item.Status__c);
            if(item.Status_Value__c == 1 && ((status == 'Completed' && count > 0) || count == 0)) {
                status = 'Completed';
            } else if (item.Status_Value__c != 1 && DateUtilities.calculateBusinessDays(submittedDate, Date.today()) > dueDays){
                status = 'Late';
            } else if (item.Status_Value__c != 1) {
                status = 'Incomplete';
            }
            count++;
        }
        return status;
    }

    private static string calculateStatusToClose(List<CSC_Action_Item__c> items, Integer days, Integer dueDays){
        //Completed || Late
        String status = '';
        Integer count = 0;
        for(CSC_Action_Item__c item : items){
            System.debug('item' + item.Action_Item_Name__c);
            System.debug('item status' + item.Status__c);
            if(item.Status_Value__c == 1 && ((status == 'Completed' && count > 0) || count == 0)) {
                status = 'Completed';
            } else if (item.Status_Value__c != 1 && dueDays < days){
                status = 'Late';
            } else if (item.Status_Value__c != 1) {
                status = 'Incomplete';
            }
            count++;
        }
        return status;
    }

    public class OpportunityWrapper{
        @AuraEnabled
        public String oppId {get;set;}
        @AuraEnabled
        public Opportunity opp {get;set;}
        @AuraEnabled
        public String fePrepared {get;set;}
        @AuraEnabled
        public String cpOpen {get;set;}
        @AuraEnabled
        public String feApproved {get;set;}
        @AuraEnabled
        public String oilsReceived {get;set;}
        @AuraEnabled
        public String paSubmitted {get;set;}
        @AuraEnabled
        public String fcSent {get;set;}
        @AuraEnabled
        public String fcApproval {get;set;}
        @AuraEnabled
        public String sigPages {get;set;}
        @AuraEnabled
        public String emailSent {get;set;}
        // @AuraEnabled
        // public Integer businessDaysFromStart {get;set;}
        @AuraEnabled
        public Integer businessDaysToClose {get;set;}
    }
}