global class DrawNotePaymentScheduler implements Database.Batchable<SObject>, Schedulable {

    /*** SCHEDULABLE INTERFACE Method ***/
    global void execute(SchedulableContext sc) {
        id batchId = Database.executeBatch(new DrawNotePaymentScheduler());
        System.debug('\n\n==> batchId = ' + batchId);
    }
    
    /*** BATCHABLE INTERFACE Methods ***/
    global Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'SELECT Id, Amount_Requested__c, Status__c, Disbursement_Date__c, Draw_Note__c, Draw_Note__r.Principal_Due__c, Draw_Note__r.Note_Rate__c ';
        query += 'FROM Drawdown__c ';
        query += 'WHERE Status__c = \'Pending\' AND Disbursement_Date__c = Today ';
        query += 'ORDER BY Draw_Note__c';
        System.debug(query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context, List<SOBject> objects) {
        List<Draw_Entry__c> entries = new List<Draw_Entry__c>();
        List<Drawdown__c> drawn = new List<Drawdown__c>();
        System.debug('obj: ' + objects);
        //loop through payments
        //DrawID used to create multiple draw entries on same draw
        String drawId = '';
        Decimal previousPrincipal = 0.0;
        for (SObject sobj: objects){
            Drawdown__c drawdown = (Drawdown__c)sobj;
            Draw_Entry__c de = new Draw_Entry__c();
            de.Activity_Date__c = Date.today();
            de.Activity_Type__c = 'Drawdown';
            de.Draw_Note__c = drawdown.Draw_Note__c;
            de.Principal_Paid__c = drawdown.Amount_Requested__c;
            de.Payment_Amount__c = 0;
            de.Interest_Paid__c = 0;
            de.Interest_Fwd__c = 0;
            de.Draw_Rate__c = drawdown.Draw_Note__r.Note_Rate__c;
            if(String.isNotBlank(drawId) && drawdown.Draw_Note__r.Id == drawId){
                de.Ending_Principal__c = drawdown.Amount_Requested__c + previousPrincipal;
                de.Principal__c = previousPrincipal;
                previousPrincipal = drawdown.Draw_Note__r.Principal_Due__c;
            } else {
                de.Ending_Principal__c = drawdown.Amount_Requested__c + drawdown.Draw_Note__r.Principal_Due__c;
                de.Principal__c = drawdown.Draw_Note__r.Principal_Due__c;
                previousPrincipal = drawdown.Amount_Requested__c + drawdown.Draw_Note__r.Principal_Due__c;
            }
            System.debug(de);
            entries.add(de);
            drawdown.Status__c = 'Completed';
            drawn.add(drawdown);
            drawId = drawdown.Draw_Note__c;
        }
        System.debug('drawn: ' + drawn);
        update drawn;
        System.debug('entries: ' + entries);
        insert entries;
    }

    global void finish(Database.BatchableContext context) {
        AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                    FROM AsyncApexJob WHERE Id =: context.getJobId()];
		System.debug(aaj);
        
        List<String> recipients = new List<String>();
        recipients.add('jcaughie@charterschoolcapital.com');
        EmailUtils.sendTextEmail(recipients, 'Payments Posted', aaj.JobItemsProcessed + ' of ' + aaj.TotalJobItems + ' draw entries created for today\'s payments.');
    }
}