({
	 openComment: function (component, event, helper) {
        
        var commentval = component.get("v.commentval");
        component.set("v.showcommentval", true);
        console.log('showcommentval is true for : ' + commentval);
        
    },
    close: function (component, event, helper) {
        
        var commentval = component.get("v.commentval");
        component.set("v.showcommentval", false);
        console.log('showcommentval is false for : ' + commentval);
        
    },
    init: function (component, event, helper) {
        
        var rowdata = component.get("v.rowdata");
        var index = component.get("v.theindex");
        
        /*if (rowdata.Name=='Analysis Summary') {
            component.set("v.fieldvalue", rowdata.allVals[index]);
            commentval = component.get("v.val");
        } else { */
        component.set("v.fieldvalue", rowdata.allVals[index]); 
        
        
	    
    },
})