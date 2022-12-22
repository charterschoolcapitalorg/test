({
    doInit : function(component, action, helper) {
        component.set('v.columns', [
            {label: 'Name', fieldName: 'Name', type: 'text'},
            {label: 'Email', fieldName: 'Email', type: 'email'}
        ]);
        var action = component.get("c.getRelatedUsers");
        action.setParams({ accountId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var users = response.getReturnValue();
                if (users != null && users.length > 0) {
                    $A.util.removeClass(component.find("success"), "slds-hide");
                    component.set("v.data", users);
                	component.set("v.users", users);                 	
                    component.set("v.confirm", true);
                } else {
                    $A.util.removeClass(component.find("failure"), "slds-hide");
                }
            }
            else {
                console.error("Expedited Diligence Alert Failed with state: " + state + ': returned: ' + response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    handleSelect : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows'); 
        for ( var i = 0; i < selectedRows.length; i++ ) {
            console.log('selected row: ' + selectedRows[i].Id);
        }
        component.set("v.selectedUsers", selectedRows);
        
    },
    handleSend : function(component, event, helper) {
        component.set("v.sending", true);
        var action = component.get("c.sendAlerts");
        action.setParams({ accountId : component.get("v.recordId"), users : component.get("v.selectedUsers") });
        console.log(component.get("v.contacts"));
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var status = response.getReturnValue();
                if (status) {
                    component.set("v.confirm", false);
                    component.set("v.success", true);
                }
            }
            else {
                console.log("Expedited Diligence Alert Failed with state: " + state + ': returned: ' + response.getReturnValue());
            }
            component.set("v.sending", false);
        });
        $A.enqueueAction(action);
        
    },
    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    showSpinner: function(component, event, helper) { 
        if (component.get("v.sending")) {
        	component.set("v.spinner", true); 
        }
   	},
    hideSpinner : function(component,event,helper){   
       component.set("v.spinner", false);
    }
})