({
	newTenant: function(component, event, helper) {

        var evt = $A.get("e.force:createRecord");
        evt.setParams({
           'entityApiName':'Tenant__c',
           'defaultFieldValues': {
              
           },
            
            "panelOnDestroyCallback": function(event) {
                console.log('panelOnDestroyCallback');
            },
            "navigationLocation":"LOOKUP",
           
        });
        
        evt.fire();
    
    },
})