({
    init : function(cmp, event, helper) {
        let fe = cmp.get("v.recordId");
        console.log('recordId: ' + fe)
       
        let action = cmp.get("c.getEstimate");
        action.setParams({"feId" : fe});
        action.setCallback(this, function(response) {
            let state = response.getState();
            let retVal = response.getReturnValue();
            if (state === "SUCCESS") {
                console.log('oppId: ' + retVal["Opportunity__c"]);
                if (retVal["Converted_to_FR__c"] === true){
                    $A.get("e.force:closeQuickAction").fire();
                    helper.showToast('Receivables already purchased.', 'warning', 'Warning');
                } else {
                    cmp.set("v.fundingEstimate", retVal); 
                    cmp.set("v.oppId", retVal["Opportunity__c"]); 
                    cmp.set("v.step", "1"); 
                }                               
            } else {
                console.log('error');
                let message = 'There has been an error getting the FE';
                helper.showToast(message, 'error', 'Error');
            }
      }); 
      $A.enqueueAction(action);
    },

    handleOnCancel : function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        helper.showToast('Process cancelled.', 'other', 'Info');
    },

    handleOnProceed : function (cmp, event, helper) {
        cmp.set("v.buttonDisabled", "true");
        // let oppId = cmp.get("v.oppId");
        let fe = cmp.get("v.recordId");
        let action = cmp.get("c.createReceivables");
        action.setParams({"feId" : fe});
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
                helper.showToast('Receivables purchased.', 'success', 'Success');
                $A.get('e.force:refreshView').fire();
                //var navEvt = $A.get("e.force:navigateToSObject");
                //navEvt.setParams({
                //    "recordId": oppId
                //});
                //navEvt.fire();
            } else {
                // console.log('error');
                let message = 'There has been an error creating the receivables. ';
                message += response.getError()[0].message;
                $A.get("e.force:closeQuickAction").fire();
                helper.showToast(message, 'error', 'Error');
            }
        });
        $A.enqueueAction(action);
    }
 });