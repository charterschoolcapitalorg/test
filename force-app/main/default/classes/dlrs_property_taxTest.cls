/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_property_taxTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_property_taxTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new property_tax__c());
    }
}