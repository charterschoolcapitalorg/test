({
	doInit : function(component, event, helper) {
		var action = component.get("c.getRecTypes");
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 component.set("v.rectypes", item);
                console.log(item);
            }
         });
         
         $A.enqueueAction(action);
        
        action = component.get("c.getRecTypeItem");
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 component.set("v.rectypelist", item);
                console.log(item);
            }
         });
         
         $A.enqueueAction(action);
       
	},
    LoadOpenTxns : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/'
        });
        urlEvent.fire();
	},
    LoadClosedTxns : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/closedtxns'
        });
        urlEvent.fire();
	},
})