({
	newParcel: function(component, event, helper) {

        var evt = $A.get("e.force:createRecord");
        evt.setParams({
           'entityApiName':'Parcel__c',
           'defaultFieldValues': {
              Property__c: component.get("v.propertyId"),
              County__c: component.get("v.Property").County__c,
              Property_Address__c: component.get("v.Property").BillingStreet + ' ' + component.get("v.Property").BillingCity + ', ' + component.get("v.Property").BillingState + ' ' + component.get("v.Property").BillingPostalCode,
           },
            "panelOnDestroyCallback": function(event) {
                console.log('panelOnDestroyCallback');
            },
            "navigationLocation":"LOOKUP",
           
        });
        
        evt.fire();
    
    },
})