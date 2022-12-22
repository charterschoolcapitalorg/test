global class DrawNoteInterestScheduler implements Database.Batchable<SObject>, Schedulable {

    /*** SCHEDULABLE INTERFACE Method ***/
    global void execute(SchedulableContext sc) {
        id batchId = Database.executeBatch(new DrawNoteInterestScheduler());
        System.debug('\n\n==> batchId = ' + batchId);
    }
    
    /*** BATCHABLE INTERFACE Methods ***/
    global Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'Select Id, Principal_Due__c, Note_Rate__c ';
        query += 'FROM Draw_Note__c ';
        query += 'WHERE Status__c = \'Active\' AND RecordType.DeveloperName = \'Credit_Line\'';
        System.debug(query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context, List<SOBject> objects) {
        List<Draw_Entry__c> entries = new List<Draw_Entry__c>();
        for (SObject sobj: objects){
            Draw_Note__c note = (Draw_Note__c)sobj;
            Draw_Entry__c de = new Draw_Entry__c();
            de.Activity_Date__c = Date.today();
            de.Activity_Type__c = 'Daily Interest';
            de.Draw_Note__c = note.Id;
            de.Principal_Paid__c = 0;
            de.Ending_Principal__c = note.Principal_Due__c;
            de.Principal__c = note.Principal_Due__c;
            de.Payment_Amount__c = 0;
            de.Interest_Paid__c = 0;
            de.Interest_Fwd__c = (note.Note_Rate__c * note.Principal_Due__c / 100.00 / 360.00).setScale(2);
            de.Draw_Rate__c = note.Note_Rate__c;
            System.debug(de);
            entries.add(de);
        }
        System.debug('entries: ' + entries);
        insert entries;
    }

    global void finish(Database.BatchableContext context) {
        List<String> recipients = new List<String>();
        recipients.add('jcaughie@charterschoolcapital.com');
        EmailUtils.sendTextEmail(recipients, 'Interest Posted', 'Draw entries created for today\'s interest.');
    }
}