({
	
     init: function (component, event, helper) {
        
        var recid = component.get("v.finObjId");
        var action = component.get("c.getFiles");
        action.setParams({"objId" : recid});
        action.setCallback(this, function(response){
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var files = response.getReturnValue();
                component.set("v.files", files);
                //component.set("v.hasfiles",)
            }
        });
        $A.enqueueAction(action);
    },
    
    
    close: function(component, event, helper) {
        console.log('close');
        component.set("v.showfiles", false);
        
    },
    
    viewFiles: function(component, event, helper) {
         console.log('viewFiles');
        component.set("v.showfiles", true);
    },
    formPress: function(component, event, helper) {
        if (event.keyCode === 27) {
            console.log("formPress");
            console.log('close');
        	component.set("v.showfiles", false);
        }
    },
})