({
	showConfirmToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : "success",
            "title": "Success!",
            "message": "Feedback has been submitted. Your Salesforce Team will review it and get back to you. Many thanks for your feedback!"
    	});
    toastEvent.fire();
	},
    
	showErrorToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : "error",
            "title": "Error!",
            "message": "There has been an issue, please contact you Salesforce Admin."
    	});
    toastEvent.fire();
	},    
})