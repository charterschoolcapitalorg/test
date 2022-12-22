({
    doInit : function(component, event, helper) {
        var action = component.get("c.getAccounts");
        action.setParams({
            cmos: component.get('v.cmos') || [],
            statusfilter: component.get('v.statusfilter') || null
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            console.log(state);
            if (state === "SUCCESS") {               
                var accts = response.getReturnValue();
                component.set("v.accts", accts);
                if (accts && accts.length) {
                    component.getEvent('showAccountItems').fire();
                }
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