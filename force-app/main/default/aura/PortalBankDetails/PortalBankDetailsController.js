({
	doInit : function(component, event, helper) {
		//component.set("v.oppRecord.Id", "v.oppId");
		var iId = component.get("v.oppId");

		var action = component.get("c.getBankDetails");
		 action.setParams({
		        oppId : component.get("v.oppId")
		    });
		action.setCallback(this, function(response) {
		    var state = response.getState();
		    if (state === "SUCCESS") {
		        var accountResponse = response.getReturnValue();
		        component.set("v.oppRecord", accountResponse);
		    }
		});
		$A.enqueueAction(action);
	},

	handleSaveAndSubmit : function(component, event, helper){
        var action = component.get("c.updateOpportunityBank");
        action.setParams({
                opp : component.get("v.oppRecord")
            });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.isOpen", true);
                component.set("v.modalMessage", "Bank details submitted. Thank you!");
            }else{
                component.set("v.isOpen", true);
                component.set("v.modalMessage", "There was an error submitting please try again.");
            }
        });
        $A.enqueueAction(action);
	},

    handleReturn: function(component, event, helper){
        var evt = $A.get("e.c:NavigateToHomePage");
        evt.fire();
    },

    closeModal: function(component, event, helper) {
    	component.set("v.isOpen", false);
    },

})