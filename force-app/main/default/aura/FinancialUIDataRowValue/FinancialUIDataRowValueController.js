({
    init: function (component, event, helper) {
        
        var rowdata = component.get("v.rowdata");
        var index = component.get("v.theindex");
	    component.set("v.val", rowdata.allVals[index]);
        component.set("v.isNegativeFormula", rowdata.allIsNegativeFormula[index]);
        component.set("v.commentval", rowdata.allComments[index]);
        component.set("v.showcommentval", "false");
    },
    formPress: function(component, event, helper) {
        if (event.keyCode === 27) {
            console.log("closecomment");
            var commentval = component.get("v.commentval");
            component.set("v.showcommentval", "False");
            console.log('showcommentval is false for : ' + commentval);
            var a = component.get('c.init');
       	    $A.enqueueAction(a);
        }
    },
    openComment: function (component, event, helper) {
        console.log("opencomment");
        var commentval;
        var rowdata = component.get("v.rowdata");
        /*if (rowdata.Name=='Analysis Summary') {
            commentval = component.get("v.val");
        } else { */
        commentval = component.get("v.commentval");
        
        component.set("v.showcommentval", "True");
        console.log('showcommentval is true for : ' + commentval);
        
    }
});