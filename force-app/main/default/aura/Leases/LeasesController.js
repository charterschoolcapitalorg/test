({
    doInit: function(component, event, helper) {
        var action = component.get("c.getLeaseRecordType");
		action.setCallback(this, function(actionResult) {
			var state = actionResult.getState();
			if (state == "SUCCESS") {
				var recTypeId = actionResult.getReturnValue();
                component.set("v.recTypeId", recTypeId);    
            }
        });
        $A.enqueueAction(action);                   
        
    },
    
	newLease: function(component, event, helper) {
			var evt = $A.get("e.force:createRecord");
                evt.setParams({
                   'entityApiName':'Lease__c',
                   'defaultFieldValues': {
                      Property__c: component.get("v.propertyId"),
                   },
                    recordTypeId: component.get("v.recTypeId"),//'0120g000000l48p',
                    "panelOnDestroyCallback": function(event) {
                        console.log('panelOnDestroyCallback');
                    },
                    "navigationLocation":"LOOKUP",
                   
                });
                
                evt.fire();	
    },
})