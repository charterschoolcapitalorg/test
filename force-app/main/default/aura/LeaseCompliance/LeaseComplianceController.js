({
	editLC: function(component, event, helper) {

        var evt = $A.get("e.force:editRecord");
        evt.setParams({
         "recordId": component.get("v.LC").Id,
       });
        evt.fire();
    
    },
    viewLC: function(component, event, helper) {    
        window.open("/lightning/r/Lease_Compliance__c/" + component.get("v.LC").Id+ "/view","_blank");

     },
})