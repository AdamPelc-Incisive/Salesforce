/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class TriggerTemplate {
    global TriggerTemplate() {

    }
global interface Handler {
    void handle(pandadoc.TriggerTemplate.TriggerAction param0);
    void setValues(List<SObject> param0, Map<Id,SObject> param1);
}
global interface HandlerEV2 {
    void handleEV2(pandadoc.TriggerTemplate.TriggerAction param0);
    void setValues(List<SObject> param0, Map<Id,SObject> param1);
}
global enum TriggerAction {afterdelete, afterinsert, afterundelete, afterupdate, beforedelete, beforeinsert, beforeupdate}
global class TriggerManager {
    global TriggerManager() {

    }
    global void addHandler(pandadoc.TriggerTemplate.Handler theHandler, pandadoc.TriggerTemplate.TriggerAction theAction) {

    }
    global void addHandler2(Object theHandler, List<pandadoc.TriggerTemplate.TriggerAction> theActions) {

    }
    global void addHandler(pandadoc.TriggerTemplate.Handler theHandler, List<pandadoc.TriggerTemplate.TriggerAction> theActions) {

    }
    global void runHandlers() {

    }
}
}
