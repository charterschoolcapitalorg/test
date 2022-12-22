({
	editLS: function(component, event, helper) {

      var evt = $A.get("e.force:editRecord");
      evt.setParams({
        "recordId": component.get("v.LS").Id,
      });
      evt.fire();
    
  },
    
  viewLS: function(component, event, helper) {    
      // window.open("/lightning/r/Lease_School__c/" + component.get("v.LS").Id+ "/view","_blank");
      helper.viewAccount('Lease_School__c', component.get("v.LS").Id);
  },
     
  viewSchool: function(component, event, helper) {
      helper.viewAccount('Account', component.get("v.LS").Account_School__r.Id);
  },

})