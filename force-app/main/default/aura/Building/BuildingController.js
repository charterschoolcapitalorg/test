({
	newSuite: function(component, event, helper) {
		
        var act = component.find('actionl').get('v.value');
        console.log('act: ' + act);
        
        if (act=='newsuite') {
            var evt = $A.get("e.force:createRecord");
            evt.setParams({
               'entityApiName':'Suite__c',
               'defaultFieldValues': {
                  Property__c: component.get("v.propertyId"),
                  Building__c: component.get("v.Building").Id, 
               },
                "panelOnDestroyCallback": function(event) {
                    
                },
                "navigationLocation":"LOOKUP",
               
            });
            
            evt.fire();
        }
    
    },
    editBuilding: function(component, event, helper) {

        var evt = $A.get("e.force:editRecord");
        evt.setParams({
         "recordId": component.get("v.Building").Id,
       });
        evt.fire();
    
    },
    viewBuilding: function(component, event, helper) {    
        window.open("/lightning/r/Building__c/" + component.get("v.Building").Id+ "/view","_blank");

     },
})