/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Funded_ReceivableTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Funded_ReceivableTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Funded_Receivable__c());
    }
}