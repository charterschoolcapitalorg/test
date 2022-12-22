public with sharing class FC_MasterComponent_Ctrl {

    @AuraEnabled
    public static string getDataWarnings(String recordId){
        String warning;
        Id recordTypeId = getRecordTypeId(recordId);
        
        if (FCFOrmUtils.UWFcRecType==recordTypeId) {
            warning = 'Charter Holder, State, Management Company, SOS Good Standing, Enrollment Cap By Site, Certified Articles Of Incorporation, UCC Search Results, County Level Lien Search Results';       
        } else if (FCFOrmUtils.FinanceFcRecType==recordTypeId) {
            warning = 'Current Year Surplus/Deficit, Net Assets, Indebtedness, Audit Findings, Transaction Fee, Current Funding Face Value, Maximum Deferred Purchase Price, Deferred Purchase Amount, Current Attendance, Attendance Trends, Annual Estimated Budget, GRV Left On Board, FV Left On Board, RPA Initial, RPA Remaining, RPA Expiration Date, Program Fee, Fee Collected (this transaction),  Initial Draw, Total Maximum Loan Amount, Interest Rate, Commitment Fee, Last Draw Date, Maturity Date';
        } else if (FCFOrmUtils.SummaryFcRecType==recordTypeId) {
            warning = 'Funding Date,Account Manager, Date CS Last Visited School, Account Strategy, Client Update';
        } else if (FCFOrmUtils.ServicingFcRecType==recordTypeId) {
            warning = 'Total Exposure, Number of Receivables Outstanding, Number Payments Outstanding Post Funding, Past Due Amounts';  
        } else if (FCFOrmUtils.UWFcDetailRecType==recordTypeId) {
            warning = 'School Name, Charter Term, School Open Date, Enrollment Cap By Site, First Day of School this Academic Year, Grades Served, Lease Term, Authorizer, Academic Performance, Academic Performance Comments, Charter Good Standing, EWS Level, Concerning Google Alert, Indication of Closure, Management Changes in the Last Year';
        } else if (FCFOrmUtils.FinanceFcDetailRecType==recordTypeId) {
            warning = 'Current Year Surplus/Deficit, Net Assets, Indebtedness, EWS Level, Pricing, Transaction Fee, Current Funding Face Value, Maximum Deferred Purchase Price, Deferred Purchase Amount, Current Attendance, Attendance Trends, Annual Estimated Budget, Receivables Description, Concerning Google Alert, Indication of Closure, Management Changes in the Last Year ';   
        } else if (FCFOrmUtils.ServicingFcDetailRecType==recordTypeId){
            warning = 'Intercept Type, FDA Status, Total Exposure, Number of Receivables Outstanding, Number Payments Outstanding Post Funding, Past Due Amounts';
        }

        warning = 'WARNING:  The following fields will be updated - ' + warning ;
        return warning;
    }

    @AuraEnabled
    public static string getCommentWarnings(String recordId){
        String warning;
        Id recordTypeId = getRecordTypeId(recordId);
        
        if (FCFOrmUtils.UWFcRecType==recordTypeId) {
            warning = 'Oustanding Info Needed For Funding - UW, Underwriting Risks and Mitigants, Underwriting Review Comments, Underwriting Recomendation';
        } else if (FCFOrmUtils.FinanceFcRecType==recordTypeId) {
            warning = 'Oustanding Info Needed For Funding - FIN, Current Funding Comments, Financial Review Comments, State Specific Finance Comments, Current Year Surplus/Deficit, Net Assets, Indebtedness, Funding Plan, Audit Findings';
        } else if (FCFOrmUtils.SummaryFcRecType==recordTypeId) {
            warning = '';
        } else if (FCFOrmUtils.ServicingFcRecType==recordTypeId) {
            warning = 'Oustanding Info Needed For Funding - SVC, Funding Exposure Comments';    
        } else if (FCFOrmUtils.UWFcDetailRecType==recordTypeId) {
            warning = 'School Profile Comments, State Specific Comments, Underwriting EWS Comments';
        } else if (FCFOrmUtils.FinanceFcDetailRecType==recordTypeId) {
            warning = 'Current Funding Comments, Financial Review Comments, Finance EWS Comments, Current Year Surplus/Deficit, Net Assets, Indebtedness';
        } else if (FCFOrmUtils.ServicingFcDetailRecType==recordTypeId){
            warning = 'Servicing Comments, Funding Exposure Comments';
        }

        warning = 'WARNING:  The following fields will be updated - ' + warning ;
        return warning;
    }

    @AuraEnabled
    public static void refreshData(String recordId){
        Id recordTypeId = (Id)recordId;

        if(recordTypeId.getSobjectType() == Schema.FC_Details__c.SObjectType) {
            refreshDetailsData(recordId);
        } else if(recordTypeId.getSobjectType() == Schema.FC_Form__c.SObjectType) {
            refreshFormData(recordId);
        }

    }
    
    @AuraEnabled
    public static void refreshComments(String recordId){
        Id recordTypeId = (Id)recordId;

        if(recordTypeId.getSobjectType() == Schema.FC_Details__c.SObjectType) {
            refreshDetailsComments(recordId);
        } else if(recordTypeId.getSobjectType() == Schema.FC_Form__c.SObjectType) {
            refreshFormComments(recordId);
        }        
    }

    private static void refreshFormData(String recordId){
        List<FC_Form__c> forms = new List<FC_Form__c>();
        forms.add([SELECT Id, opportunity__c, RecordTypeId, Total_Fund_Receiv_FV_Amount__c, Current_Attendance__c FROM FC_Form__c WHERE Id=:recordId]);

        try{ 
            FCFormUtils.populateHeaderFieldsFromSFData(forms);
        } catch (Exception e){
            throw new AuraHandledException('Error updating records.');
        }
    }

    private static void refreshDetailsData(String recordId){
        List<FC_Details__c> details = new List<FC_Details__c>();
        FC_Details__c record = [SELECT Id, 
                            FC_Form__c, 
                            RecordTypeId, 
                            Opp_School__c, 
                            Current_Attendance__c, 
                            Receivables_Description__c,
                            Lease_Term__c,
                            Grades_Served__c,
                            Past_Due_Amounts__c,
                            Number_Payments_Outstanding_Post_Funding__c,
                            Number_of_Receivables_Outstanding__c 
                            FROM FC_Details__c 
                            WHERE Id=:recordId];
        
        record.Current_Attendance__c = '';
        record.Receivables_Description__c = '';
        record.Lease_Term__c = '';
        record.Grades_Served__c = '';

        update record;

        details.add(record);

        try{ 
            FCFormUtils.populateDetailFieldsFromSFData(details);
        } catch (Exception e){
            throw new AuraHandledException('Error updating records.');
        } 
    }

    private static void refreshFormComments(String recordId){
        System.debug('**** Refresh form comments ****');
        List<FC_Form__c> forms = new List<FC_Form__c>();
        forms.add([SELECT Id, opportunity__c, RecordTypeId, Total_Fund_Receiv_FV_Amount__c FROM FC_Form__c WHERE Id=:recordId]);

        try{ 
            FCFormUtils.populateHeaderCommentFieldsFromSFData(forms);
        } catch (Exception e){
            throw new AuraHandledException('Error updating records.');
        } 
    }

    private static void refreshDetailsComments(String recordId){
        System.debug('**** Refresh detail comments ****');
        List<FC_Details__c> details = new List<FC_Details__c>();
        details.add([SELECT Id, FC_Form__c, RecordTypeId, Opp_School__c FROM FC_Details__c WHERE Id=:recordId]);

        try{ 
            FCFormUtils.populateDetailCommentFieldsFromSFData(details);
        } catch (Exception e){
            throw new AuraHandledException('Error updating records.');
        } 
    }

    private static Id getRecordTypeId(String recordId){
        Id convId = (Id)recordId;
        System.debug(convId.getSobjectType());
        Id recordTypeId;

        if(convId.getSobjectType() == Schema.FC_Details__c.SObjectType) {
            recordTypeId = [SELECT id, RecordTypeId FROM FC_Details__c WHERE ID =: recordId LIMIT 1].RecordTypeId;
        } else if(convId.getSobjectType() == Schema.FC_Form__c.SObjectType) {
            recordTypeId = [SELECT id, RecordTypeId FROM FC_Form__c WHERE ID =: recordId LIMIT 1].RecordTypeId;
        }
       
        return recordTypeId;
    }

}