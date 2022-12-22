({
    invoke : function(component, event, helper) {
        var redirectToNewRecord = $A.get( "e.force:navigateToSObject" );
        
        redirectToNewRecord.setParams({
        "recordId": component.get( "v.leadId" ),
        "slideDevName": "detail",
        "isredirect": "true"
        });
        console.log('@@@ = ' + component.get( "v.leadId" ));
        redirectToNewRecord.fire();
    }
})