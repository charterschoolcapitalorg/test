({
    
    newBuilding: function(component, event, helper) {

        var evt = $A.get("e.force:createRecord");
        evt.setParams({
           'entityApiName':'Building__c',
           'defaultFieldValues': {
              Property__c: component.get("v.propertyId"),
               Address__c: component.get("v.Property").BillingStreet + ' ' + component.get("v.Property").BillingCity + ', ' + component.get("v.Property").BillingState + ' ' + component.get("v.Property").BillingPostalCode, 
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