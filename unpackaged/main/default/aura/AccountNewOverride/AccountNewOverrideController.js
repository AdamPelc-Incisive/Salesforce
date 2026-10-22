({
    doInit : function(component, event, helper) {
        var flow = component.find("flow");
        flow.startFlow("Account_New_Account_List_View");
    },

    handleCancel : function(component, event, helper) {
        // Stop the running flow interview (so it doesn't keep running in the background)
        var flow = component.find("flow");
        try {
            flow.destroy(); // works in many orgs/contexts
        } catch (e) {
            // ignore - not fatal
        }

        // Close modal
        component.set("v.isOpen", false);

        // Return to Accounts list view (Recently Viewed)
        window.setTimeout($A.getCallback(function() {
            window.location.href = "/lightning/o/Account/list?filterName=__Recent";
        }), 50);
    },

    handleStatusChange : function(component, event, helper) {
        var status = event.getParam("status");
        if (status !== "FINISHED" && status !== "FINISHED_SCREEN") return;

        if (component.get("v.hasFinished")) return;
        component.set("v.hasFinished", true);

        window.setTimeout($A.getCallback(function() {
            window.location.href = "/lightning/o/Account/list?filterName=__Recent";
        }), 80);
    }
})