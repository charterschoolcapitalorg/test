/**
 * Created by Ivan Garcia on 3/26/2018.
 */
({

    doInit: function(component, event, helper) {
          
        var action = component.get("c.getOpportunities");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('opp state '+state);
            if (state === "SUCCESS") {
                
                 var items = response.getReturnValue();
                 console.log('opps '+items);
                 component.set("v.opps", items);
                 console.log('set opps');
            }
            
        });
            $A.enqueueAction(action);
        
        
     },
                
     handleUploadFinished: function (cmp, event) {
         console.log('***** reinit');
        var a = component.get('c.doInit');
        $A.enqueueAction(a);
        console.log('***** end of reinit');
    },

     LoadOpenTxns : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/'
        });
        urlEvent.fire();
	},
    LoadBulkUpload : function(component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/bulkupload'
        });
        urlEvent.fire();
	},

	handleDocUploaded: function (component, event, helper) {
         console.log('&&&&& in handleDocUploaded of IntakeCommunity');
        action = component.get("c.getRecTypeItem");
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 component.set("v.rectypelist", item);
                console.log(item);
            }
         });
         
         $A.enqueueAction(action);
        console.log('***** end of handleDocUploaded of IntakeCommunity');
    },
})