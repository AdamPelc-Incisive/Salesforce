/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Channel_Partner_Lab_AccessTrigger on Channel_Partner_Lab_Access__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Channel_Partner_Lab_Access__c.SObjectType);
}