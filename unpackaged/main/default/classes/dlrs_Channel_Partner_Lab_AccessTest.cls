/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Channel_Partner_Lab_AccessTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Channel_Partner_Lab_AccessTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Channel_Partner_Lab_Access__c());
    }
}