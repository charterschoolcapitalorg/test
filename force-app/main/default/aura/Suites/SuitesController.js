({
	newSuite: function(component, event, helper) {

        var evt = $A.get("e.force:createRecord");
        evt.setParams({
           'entityApiName':'Suite__c',
           'defaultFieldValues': {
              Property__c: component.get("v.propertyId"),
           },
            "panelOnDestroyCallback": function(event) {
                console.log('panelOnDestroyCallback');
                var refreshEvent = component.getEvent("refreshEvent");
                refreshEvent.fire();
                
            },
            "navigationLocation":"LOOKUP",
           
        });
        
        evt.fire();
    
    },
})