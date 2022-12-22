({
    doInit : function(component, event, helper) {
        
    },
	acceptItem : function(component, event, helper) {
		console.log('acceptItem');
        var theme = "{!$User.UITheme}";
        
    	console.log('uitheme - ' + theme);
        var recid = component.get("v.recordId");
        console.log('recid - ' + recid);
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
             componentDef : "c:AcceptClientPortalItem",
             componentAttributes: {
             	recordId :recid,
                theme : theme 
        	}
        });
        evt.fire();
        
	}
})