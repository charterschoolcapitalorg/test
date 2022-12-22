({
    doInit : function(component, event, helper){
             
        var action = component.get("c.getUrgentItems");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var items = response.getReturnValue();
                console.log(items.length);
                helper.handleHeaders(component, items);
            } else {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                } 
                console.error(message);
           }            
        });
        $A.enqueueAction(action); 
        
    }
})