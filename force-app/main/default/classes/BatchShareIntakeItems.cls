global class BatchShareIntakeItems implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Intake_Item__c
            WHERE Is_Visible_To_Community__c = true
        ]);
    }

    global void execute(Database.BatchableContext context, List<SObject> scope) {
        DiligenceUtils.shareIntakeItems((List<Intake_Item__c>)scope);
    }

    global void finish(Database.BatchableContext context) { }
}