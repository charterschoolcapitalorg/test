({
    loadCMOs: function(component) {
        var action2 = component.get("c.getCMOs");

        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {  
                var cmo = response.getReturnValue();
                component.set("v.cmoaccounts", cmo);
                
            } else {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
            } 
        });
             
        $A.enqueueAction(action2);
    },

    loadItems: function(component, cmoIds) {
        var action = component.get("c.getRecTypeItem");
        action.setParams({ "statusFilter" : component.get('v.statusfilter'), "cmos" : cmoIds });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                    var item = response.getReturnValue();
                    component.set("v.rectypelist", item);
                    console.log('***** rectypelist' + component.get("v.rectypelist"));
            } else {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                if(message == null) {
                    console.error('Unknown error getting items');
                } else {
                    console.error(message);
                }
            }
        });

        $A.enqueueAction(action);
    }
})