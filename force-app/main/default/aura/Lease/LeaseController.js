({
	editLease: function(component, event, helper) {

        var evt = $A.get("e.force:editRecord");
        evt.setParams({
         "recordId": component.get("v.Lease").Id,
       });
        evt.fire();
    
    },
    viewLease: function(component, event, helper) {    
        window.open("/lightning/r/Lease__c/" + component.get("v.Lease").Id+ "/view","_blank");

     },
    executeAction: function(component, event, helper) {
    	
        var act = component.find('actionl').get('v.value');
        console.log('act: ' + act);
        
        if (act=='leasesuite') {
            var action = component.get("c.newLeaseSuite");
            $A.enqueueAction(action); 
        } else if (act=='leaseschool'){
            var action = component.get("c.newLeaseSchool");
            $A.enqueueAction(action);
        
        } else if (act=='leasecompliance') {
            var lease = component.get("v.Lease");
			var header = "New Lease Compliance " + lease.Name;
            var modalBody;
            var modalHeader;
            console.log('creating new lease compliance for lease: ' + lease.Name);
            var propId = component.get("v.propertyId");
            
            $A.createComponents([ ["c:LeaseComplianceType", {Lease: lease, propertyId: propId}] ],
               function(components, status) {
                   if (status === "SUCCESS") {
                       console.log('success');
                       modalBody = components[0];
                       component.find('overlayLib').showCustomModal({
                           header: modalHeader,
                           body: modalBody, 
                           showCloseButton: true,
                           closeCallback: function() {
                              
                           }
                       });
                   } else {
                       console.log('status: ' + status);
                   }                               
               });
        }
    },
    
    newLeaseSuite: function(component, event, helper) {

        var evt = $A.get("e.force:createRecord");
        evt.setParams({
           'entityApiName':'Lease_Suite__c',
           'defaultFieldValues': {
              Lease__c: component.get("v.Lease").Id, 
               Name:  component.get("v.Lease").Name, 
           },
            "panelOnDestroyCallback": function(event) {
                
            },
            "navigationLocation":"LOOKUP",
           
        });
        
        evt.fire();
    
    },
    newLeaseSchool: function(component, event, helper) {

        var evt = $A.get("e.force:createRecord");
        evt.setParams({
           'entityApiName':'Lease_School__c',
           'defaultFieldValues': {
              Lease__c: component.get("v.Lease").Id, 
           },
            "panelOnDestroyCallback": function(event) {
                
            },
            "navigationLocation":"LOOKUP",
           
        });
        
        evt.fire();
    
    },
    newLeaseCompliance: function(component, event, helper) {

        var evt = $A.get("e.force:createRecord");
        evt.setParams({
           'entityApiName':'Lease_Suite__c',
           'defaultFieldValues': {
              Lease__c: component.get("v.Lease").Id, 
           },
            "panelOnDestroyCallback": function(event) {
                
            },
            "navigationLocation":"LOOKUP",
           
        });
        
        evt.fire();
    
    },
})