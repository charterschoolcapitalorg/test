({
	editLeaseSuite: function(component, event, helper) {

        var evt = $A.get("e.force:editRecord");
        evt.setParams({
         "recordId": component.get("v.LeaseSuite").Id,
       });
        evt.fire();
    
    },
    viewLeaseSuite: function(component, event, helper) {    
        window.open("/lightning/r/Lease_Suite__c/" + component.get("v.LeaseSuite").Id+ "/view","_blank");

     },
})