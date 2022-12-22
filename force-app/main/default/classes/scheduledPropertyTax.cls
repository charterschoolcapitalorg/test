/**=====================================================================
 * Charter School Capital
 * Name: scheduledPropertyTax
 * Test Class: scheduledPropertyTaxTest
 * Description: property tax status, scheduler
 * Created Date: [Sep 22, 2022]
 * Created By: [Slava Krel] 
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
 
global class scheduledPropertyTax implements Schedulable {

    public static String sched = '0 00 00 * * ?'; //Every Day at Midnight
    
    global void execute(SchedulableContext sc) {
        Id propTaxBatchJobId = Database.executeBatch(new PropertyTax(), 200);
    }
}