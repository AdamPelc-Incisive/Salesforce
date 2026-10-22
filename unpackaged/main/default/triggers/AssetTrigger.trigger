trigger AssetTrigger on Asset (after insert, after update) {
    AssetTriggerHandler.handleStatusChange(Trigger.new, Trigger.oldMap);
}