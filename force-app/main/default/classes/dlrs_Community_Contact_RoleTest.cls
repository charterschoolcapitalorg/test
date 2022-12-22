/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Community_Contact_RoleTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Community_Contact_RoleTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Community_Contact_Role__c());
    }
}