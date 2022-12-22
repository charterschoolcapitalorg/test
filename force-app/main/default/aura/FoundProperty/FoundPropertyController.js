({
    select: function(component, event, helper) {
        
        
      var action = component.get('c.savePropertyToOpp');
      action.setParams({o: component.get("v.OppId"), p : component.get("v.Property").Id});
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          	var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "message": "You selected: " + component.get("v.Property").Id,
            });
            toastEvent.fire();   
        }
      });
      $A.enqueueAction(action);
        
	},
    
	viewProperty: function(component, event, helper) {

        /*var evt = $A.get("e.force:viewRecord");
        evt.setParams({
         "recordId": component.get("v.Property").Id,
       });
        evt.fire();
    	
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": component.get("v.Property").Id,
          "slideDevName": "related"
        });
        navEvt.fire();
        */
        component.find("navigation")
        .navigate({
            "type" : "standard__recordPage",
            "attributes": {
                "recordId"      : component.get("v.Property").Id,
                "actionName"    :  "view"   
            }
        }, true);
        
    	},
})