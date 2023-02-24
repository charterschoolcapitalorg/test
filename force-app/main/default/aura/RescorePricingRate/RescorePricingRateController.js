({
    doInit : function(component, event, helper) {
        helper.clearAllErrorMessages(component, event);
        helper.setColumns(component, event);
        helper.setup(component, event);
    },

    rescore : function(component, event, helper) {
        helper.rescore(component, event);
        location.reload();
    },
})