({
	loadIntakeItems : function(component, event, selectedOptionValue ) {
		console.log('***** MyItemByProduct.loadIntakeItems: acctIds - ' + component.get('v.cmoids'));
        var intakeName = component.get("v.iName");
        var recType = component.get("v.iRecType");
        var action = component.get("c.getIntakeItems");
        
        action.setParams({intakeName : intakeName, 
                          "statusFilter" : component.get('v.statusfilter'), 
                          "acctIds" : component.get('v.cmoids'), 
                          recType:recType});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {                
                 var results = response.getReturnValue();
                 component.set("v.intakeItems", results);
                var hasredflag = false;
            } else {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
            } 
        });
        $A.enqueueAction(action);
	},    
    showToast : function(title, message, duration, key, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        if(! toastEvent){
            confirm(title + ': ' + message);
            return;
        }
        toastEvent.setParams({
            title : title,
            message: message,
            duration: duration,
            key: key,
            type: type,
            mode: mode
        });
        toastEvent.fire();
    },
    showUploadInfoToast : function(component, event, fileNames) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Info Message',
            message: fileNames + ' sucessfully uploaded!',
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:'4000',
            key: 'info_alt',
            type: 'success',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
    getFundRecType : function(component, event){   
        var action = component.get("c.getIDInitialFundingIntake");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('Get Fund Rec Type ' + response.getReturnValue());
            if (state === "SUCCESS") {               
                component.set("v.fundRectType", response.getReturnValue());
            }            
        });
        $A.enqueueAction(action);  
	},
    
    getFacRecType : function(component, event){   
        var action = component.get("c.getIDFacilitiesIntakeItem");
        action.setCallback(this, function(response) {
            var state = response.getState();
            //console.log('Get Fund Rec Type ' + state);
            if (state === "SUCCESS") {               
                component.set("v.facRecType", response.getReturnValue());
            }            
        });
        $A.enqueueAction(action);  
	},
    
})