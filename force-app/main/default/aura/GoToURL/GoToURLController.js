({
    init : function(component, event, helper) {
        let address = component.get( "v.urlId" );
        if (component.get("v.recId")){
            address += component.get("v.recId");
        }
        $A.get( "e.force:navigateToURL" ).setParams( {
            "url": address 
        } ).fire();
    }
})