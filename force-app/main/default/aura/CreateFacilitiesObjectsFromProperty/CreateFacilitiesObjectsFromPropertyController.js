({
	doInit : function(component, event, helper) {
        var recid = component.get("v.recordId");
        console.log('doInit from prop page recid: ' + recid);        
		var evt = $A.get("e.force:navigateToComponent");
                        evt.setParams({
                            componentDef : "c:CreateFacilitiesObjects",
                            componentAttributes: {
                                propertyId : recid,
                                fromObjectId : recid,
                            }
        });
        evt.fire();
	}
})