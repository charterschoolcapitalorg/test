({
	submitFeedback : function(component, event, helper) {      
        var action = component.get('c.postFeedItemWithRichTextRecordLink'); 
        let feedback = component.get("v.feedback");
        let groupId = component.get("v.groups");
        let recordId = component.get("v.recordId");
        // method name i.e. getEntity should be same as defined in apex class
        // params name i.e. entityType should be same as defined in getEntity method
        action.setParams({
            "communityId" : groupId,
            "subjectId" : groupId,
            "textWithMentionsAndRichText" : feedback,
            "linkedRecord" : recordId
        });
        
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                //component.set('v.sObjList', a.getReturnValue());
                helper.showConfirmToast();
        		component.set("v.feedback", '');
            } else {
                helper.showErrorToast();
            }
        });
        $A.enqueueAction(action);
        
        
        
	}
})