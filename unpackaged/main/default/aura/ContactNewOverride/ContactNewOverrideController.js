({
    doInit : function(component, event, helper) {
        var flow = component.find("flow");
        flow.startFlow("Contact_New_Contact_List_View");
    },

    handleCancel : function(component, event, helper) {
        component.set("v.isOpen", false);

        // Return to Contacts → Recently Viewed
        window.setTimeout($A.getCallback(function() {
            window.location.href = "/lightning/o/Contact/list?filterName=__Recent";
        }), 50);
    },

    handleStatusChange : function(component, event, helper) {
        var status = event.getParam("status");

        // Only act when the flow finishes (Create or Cancel)
        if (status !== "FINISHED" && status !== "FINISHED_SCREEN") {
            return;
        }

        // Prevent double execution
        if (component.get("v.hasFinished")) {
            return;
        }
        component.set("v.hasFinished", true);

        // Return to Contacts → Recently Viewed
        window.setTimeout($A.getCallback(function() {
            window.location.href = "/lightning/o/Contact/list?filterName=__Recent";
        }), 80);
    }
})