/**=====================================================================
 * Created Date: [09/21/2016]
 * Created By: John Caughie
 * Send annual email re MFA notification
 * Date Modified                Modified By                  Description of the update
 * 
  =====================================================================*/
global class FundedReceivableMFABatch implements Database.Batchable<sObject>, Schedulable {

    String template;
    String contact;
    
    global FundedReceivableMFABatch() {
        MFA_Loan_Notification__c mfa = MFA_Loan_Notification__c.getOrgDefaults();
        template = mfa.Template__c;
        contact = mfa.Contact__c;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'Select Id, School__c, Name FROM Funded_Receivable__c WHERE RecordType.Name = \'Loan\' AND Status__c = \'Active\' '; 
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Funded_Receivable__c> scope) {
        sendMultipleEmailSingleUserNotifications(contact, template, scope);
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }

    //+++ SCHEDULEABLE INTERFACE Methods +++//
    global void execute(SchedulableContext sc) {
        //Anonymous code used to invoke annual email
        //FundedReceivableMFABatch f = new FundedReceivableMFABatch();
        //String sch = '0 0 12 20 7 ? *';
        //String jobID = system.schedule('MFA Alert', sch, f);

        id batchId = Database.executeBatch(new FundedReceivableMFABatch(), 100);
        System.debug('\n\n==> batchId = ' + batchId);
    }


    private static void sendMultipleEmailSingleUserNotifications(Id contactId, Id templateId, List<Funded_Receivable__c> records) {

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        //Contruct & send the actual message
        for(Funded_Receivable__c i :records){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(templateId);
            mail.setTargetObjectId(contactId);
            mail.setSaveAsActivity(false);
            mail.setUseSignature(false);
            mail.setWhatId(i.Id);
            mails.add(mail);
        }

        Messaging.sendEmail(mails);

    }
    
}