({
    doInit :  function(component, event, helper)  {
    	var action = component.get("c.getFiles");
        var intakeItem = component.get("v.intakeItem");
        action.setParams({ theid : intakeItem.Id });
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

        var action2 = component.get("c.getItemDetail");
        action2.setParams({ itemId : intakeItem.Id });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = JSON.parse(response.getReturnValue());
                component.set("v.status", data.status);
                component.set("v.project", data.project);
            }
        });
        $A.enqueueAction(action2);    
    },
    
	close : function(component, event, helper) {
		var overlay = component.find("overlayLib");
        console.log('Overlay: '+ overlay);
        component.find("overlayLib").notifyClose();
    }
})