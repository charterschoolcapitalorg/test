({
    init : function(component, event, helper) {
        let id = component.get("v.recordId");
        console.log('init Id: ' + id);
        let action = component.get("c.getCommentWarnings");
        action.setParams({ "recordId" : id });
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                let returned = response.getReturnValue();
                console.log('returned ' + returned);
                component.set('v.body', returned);
            } else if (state === "ERROR") {
                component.set("v.error", true);
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },

    handleRefresh : function(cmp, event, helper){
        console.log('you clicked!');

        let id = cmp.get("v.recordId");
        let action = cmp.get("c.refreshComments");
        action.setParams({ "recordId" : id });
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                console.log('success!');
                helper.showToast('Comments updated.', 'success', 'Success');
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else if (state === "ERROR") {
                cmp.set("v.error", true);
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);


    },

    handleExit : function(cmp, event, helper){
        console.log('clicked exit!');
        $A.get("e.force:closeQuickAction").fire();
    },

});