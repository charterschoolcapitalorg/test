({
	editTenant: function(component, event, helper) {

        var evt = $A.get("e.force:editRecord");
        evt.setParams({
         "recordId": component.get("v.Tenant").Id,
       });
        evt.fire();
    
    },
    viewTenant: function(component, event, helper) {    
        window.open("/lightning/r/Tenant__c/" + component.get("v.Tenant").Id+ "/view","_blank");

     },
    editTenantAcct: function(component, event, helper) {
		window.open("/lightning/r/Account/" + component.get("v.Tenant").Tenant__c+ "/view","_blank");
        /*
        var evt = $A.get("e.force:editRecord");
        evt.setParams({
         "recordId": component.get("v.Tenant").Tenant__c,
       });
        evt.fire();
    	*/
    },
})