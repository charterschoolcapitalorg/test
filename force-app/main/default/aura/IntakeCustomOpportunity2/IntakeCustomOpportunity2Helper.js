({
    getFileAttachments : function(component, event) {
        //console.log('helper fired!');
        var action = component.get("c.getFiles");
        var res = component.get("v.res");
        action.setParams({ oppId : res });
        //alert('***getting opp in custom opp component');
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert('***response: ' + state);
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                //alert('***response item: ' + item);
                component.set("v.files", item);
                console.log(item);
            }
        });
        $A.enqueueAction(action);
    }
})