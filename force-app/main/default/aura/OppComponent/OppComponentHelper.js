({
	getIFRecType : function(component, event){   
        var action = component.get("c.getIDIFOpp");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.IFOppType", response.getReturnValue());
            }            
        });
        $A.enqueueAction(action);  
	},
    getFOFRecType : function(component, event){   
        var action = component.get("c.getIDFOFOpp");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.FOFOppType", response.getReturnValue());
            }            
        });
        $A.enqueueAction(action);  
	},
    getFacRecType : function(component, event){   
        var action = component.get("c.getIDFacOpp");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.FacOppType", response.getReturnValue());
            }            
        });
        $A.enqueueAction(action);  
	},
    
})