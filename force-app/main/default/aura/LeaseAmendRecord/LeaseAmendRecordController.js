({
	init : function(cmp, event, helper) {
        let leaseId = cmp.get("v.recordId");
        console.log('recordId: ' + leaseId)
       
        let action = cmp.get("c.getLease");
        action.setParams({"leaseId" : leaseId});
        action.setCallback(this, function(response) {
        let state = response.getState();
        if (state === "SUCCESS") {   
            cmp.set("v.lease", response.getReturnValue());
            console.log('lease:' + JSON.stringify(response.getReturnValue()));           
        } else {
            console.log('error');
            $A.get("e.force:closeQuickAction").fire();  
            let message = 'There was an error creating the lease amendment.';
            helper.showToast(message, 'error');
        }
      }); 
      $A.enqueueAction(action);
    },
    
    handleOnSubmit: function(cmp, event, helper) {
        event.preventDefault();
        cmp.set('v.disabled', true);
        cmp.set('v.showSpinner', true);
        //cmp.set('v.step', '3');

        let leaseId = cmp.get("v.recordId");
        let leaseRecord = JSON.stringify(cmp.get("v.lease"));
        let leaseAmendmentRecord = JSON.stringify(cmp.get("v.leaseAmendment"));

        let action = cmp.get("c.updateRecords");
        action.setParams({"leaseJSON" : leaseRecord, "leaseAmendmentJSON" : leaseAmendmentRecord, "leaseId" : leaseId});
        action.setCallback(this, function(response) {
        let state = response.getState();
        if (state === "SUCCESS") {   
            helper.showToast('Amendment created!', 'success');
            $A.get('e.force:refreshView').fire();
            $A.get("e.force:closeQuickAction").fire();         
        } else {
            console.log('error');
            $A.get("e.force:closeQuickAction").fire();  
            let message = 'There was an error creating the lease amendment.';
            helper.showToast(message, 'error');
        }
      }); 
      $A.enqueueAction(action);
    },

    handleOnNext: function(cmp, event, helper) {
        event.preventDefault();
        cmp.set('v.disabled', true);
        cmp.set('v.showSpinner', true);
        console.log('lease amendment: ' + JSON.stringify(cmp.get("v.leaseAmendment")));
        cmp.set('v.step', '2');
    },

    handleOnGoBack: function(cmp, event, helper) {
        event.preventDefault();
        cmp.set('v.disabled', true);
        cmp.set('v.showSpinner', true);
        console.log('lease amendment: ' + cmp.get("v.leaseAmendment"));
        cmp.set('v.step', '1');
    },

});