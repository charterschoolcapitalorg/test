({
	editSuite: function(component, event, helper) {

        var evt = $A.get("e.force:editRecord");
        evt.setParams({
         "recordId": component.get("v.Suite").Id,
       });
        evt.fire();
    
    },
    viewSuite: function(component, event, helper) {    
        window.open("/lightning/r/Suite__c/" + component.get("v.Suite").Id+ "/view","_blank");

     },
})