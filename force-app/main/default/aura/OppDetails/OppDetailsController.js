({
    doInit :  function(component, event, helper)  {
        
    	var action = component.get("c.getOppFiles");
        var oppId = component.get("v.opp.Id");
        
        action.setParams({ theid : oppId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                component.set("v.files", item);
                var count = 0;
                var i;
                for (i in item){
                     count++;
                }

                component.set("v.numFiles", count);
            }
        });
        $A.enqueueAction(action); 
        
    },
    
	close : function(component, event, helper) {
		var overlay = component.find("overlayLib");
        component.find("overlayLib").notifyClose();
    }
})