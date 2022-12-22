({
    getFundRecType : function(component, event){   
        var action = component.get("c.getIDInitialFundingIntake");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {        
                component.set("v.fundRectType", response.getReturnValue());
            }            
        });
        $A.enqueueAction(action);  
	},

    get5DFRecType : function(component, event){   
        var action = component.get("c.getID5DFIntake");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {           
                component.set("v.five5DFRectType", response.getReturnValue());
            }            
        });
        $A.enqueueAction(action);  
    },
        
    getFacRecType : function(component, event){   
        var action = component.get("c.getIDFacilitiesIntakeItem");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.facRecType", response.getReturnValue());
            }            
        });
        $A.enqueueAction(action);  
	},
    
    showToast : function(title, message, duration, key, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        if(! toastEvent){
            confirm(title + ': ' + message);
            return;
        }
        toastEvent.setParams({
            title : title,
            message: message,
            duration: duration,
            key: key,
            type: type,
            mode: mode
        });
        toastEvent.fire();
    },
})