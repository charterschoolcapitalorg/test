({

    init: function (cmp, event, helper) {
        
        // console.log('init...');
        var recid = cmp.get("v.recordId");
		var action = cmp.get("c.getRecord");
		action.setParams({"recordId" : recid});
        action.setCallback(this, function(response){
            var state = response.getState();
			if (state === "SUCCESS") {
                var resp = response.getReturnValue();
                console.log('resp: ' + JSON.stringify(resp));
                cmp.set("v.clonedRecord", resp);
                cmp.set("v.recordTypeName", resp['Type__c']);
                if(resp['Type__c']=='Underwriting'){
                    cmp.set("v.disabled", true);
                    cmp.set("v.clonedRecord.Fiscal_Year__c", '');
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    getRatinginfo: function (cmp, event, helper) {
        cmp.set("v.clonedRecord.Historical_Ratings_Color__c", null);
        cmp.set("v.clonedRecord.Historical_Ratings_Actual__c", null);
        // console.log('init...');
        var accid = cmp.get("v.clonedRecord.Account__c");
        var fy = cmp.get("v.clonedRecord.Fiscal_Year__c");
		var action = cmp.get("c.getRatings");
		action.setParams({"accountId" : accid,
                          "fy" : fy
                         });
        action.setCallback(this, function(response){
            var state = response.getState();
			if (state === "SUCCESS") {
                var resp = response.getReturnValue();
                console.log('resp: ' + JSON.stringify(resp));
                if(resp){
                    cmp.set("v.clonedRecord.Historical_Ratings_Color__c", resp.Historical_Ratings_Color__c);
                	cmp.set("v.clonedRecord.Historical_Ratings_Actual__c", resp.Historical_Ratings__c);
                	cmp.set("v.disabled", false);
                }else{
                    cmp.set("v.isNoARModalOpen", true);
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    closeNoARModel: function(cmp, event, helper) {
        cmp.set('v.isNoARModalOpen', false);
        cmp.set("v.disabled", false);
        // console.log('record:' + cmp.get('v.recordId'));
    },
    
    handleLoad: function(cmp, event, helper) {
        cmp.set('v.showSpinner', false);
        // console.log('record:' + cmp.get('v.recordId'));
    },

    handleSubmit: function(cmp, event, helper) {
        // console.log('submitting...');
        cmp.set('v.disabled', true);
        cmp.set('v.showSpinner', true);
    },

    handleError: function(cmp, event, helper) {
        // errors are handled by lightning:inputField and lightning:messages
        // so this just hides the spinner
        cmp.set('v.showSpinner', false);
    },

    handleSuccess: function(cmp, event, helper) {
        // console.log('event: ' + event);
        var params = event.getParams();
        cmp.set('v.recordId', params.response.id);
        cmp.set('v.showSpinner', false);
        cmp.set('v.saved', true);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": params.response.id
        });
        navEvt.fire();
    }
    
});