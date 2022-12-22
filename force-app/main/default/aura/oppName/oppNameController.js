/**
 * Created by Ivan Garcia on 4/18/2018.
 */
({
    doInit: function(component, event, helper) {
                		var action = component.get("c.getOppName");

                		action.setParams({
            	 		   oppId : component.get("v.idOpp")
            	 		   });
                        action.setCallback(this, function(response) {
                        	var state = response.getState();
                        	if (state === "SUCCESS") {
                               var items = response.getReturnValue();
                               component.set("v.nameOpp", items);
                            }
                        });
                     $A.enqueueAction(action);
         }
})