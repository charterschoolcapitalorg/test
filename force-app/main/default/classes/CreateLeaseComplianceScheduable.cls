global with sharing class CreateLeaseComplianceScheduable implements Schedulable {
 
    global void execute(SchedulableContext sc) 
    {  
        CreateLeaseComplianceBatchable batch = new CreateLeaseComplianceBatchable(); 
        Database.executeBatch(batch, 10);
    }

}