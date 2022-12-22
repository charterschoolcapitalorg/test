({
	editParcel: function(component, event, helper) {

        var evt = $A.get("e.force:editRecord");
        evt.setParams({
            "recordId": component.get("v.Parcel").Id,
        });
        evt.fire();
    },
    
    viewParcel: function(component, event, helper) {    
        window.open("/lightning/r/Parcel__c/" + component.get("v.Parcel").Id+ "/view","_blank");
    },

    newPropertyTax: function(component, event, helper) {
        console.log('newpropertyTax');
		var act = component.find('actionl').get('v.value');
        console.log('action: ' + act);
        //console.log('act: ' + act);
        if (act === 'proptax') {  
            var evt = $A.get("e.force:createRecord");
            var status = 'Draft';
            var mapping = 'Property Taxes';
            evt.setParams({
               'entityApiName':'Property_Tax__c',
               'defaultFieldValues': {
                    Property__c: component.get("v.propertyId"),
                    Parcel__c: component.get("v.Parcel").Id,
                    Property_Tax_Status__c: status,
                    Action_Item_Mapping__c: mapping,
               },
                "panelOnDestroyCallback": function(event) {
                    
                },
                "navigationLocation":"LOOKUP",
            });
            evt.fire();
        }
    },
})