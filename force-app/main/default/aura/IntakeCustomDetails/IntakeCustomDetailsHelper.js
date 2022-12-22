({
	getFileAttachments : function(component, event) {
        //console.log('helper fired!');
		var action = component.get("c.getFiles");
        var res = component.get("v.res");
        action.setParams({ iId : res });
        //alert('***getting opp in custom opp component');
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('files state: ' + state);
            if (state === "SUCCESS") {
                 var items = response.getReturnValue();
                //alert('***response item: ' + item);
                 component.set("v.files", items);
                console.log('files: ' + items);
            }
         });
        $A.enqueueAction(action);
	}
})