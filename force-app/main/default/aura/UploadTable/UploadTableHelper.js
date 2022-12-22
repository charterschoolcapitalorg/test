({
	loadIntakeItems : function(component, event, selectedOptionValue ) {
		var intakeName = component.get("v.intakeName");
        var action = component.get("c.getIntakeItems");
        console.log('loadIntakeItems ' + selectedOptionValue);
        action.setParams({intakeName : intakeName, dateRange : selectedOptionValue});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('^^^^^ Intake Item ' + state);
            if (state === "SUCCESS") {                
                 var results = response.getReturnValue();
                 component.set("v.intakeItems", results);
                var hasredflag = false;
                console.log('^^^^^ results' + results);
                for ( var r in results ) {
                    console.log('^^^^^ results ii: ' + r.Red_Flag_Instructions_For_Client__c);
                }
                //hasRedFlag
            }
            
        });
        $A.enqueueAction(action);
	},    
    
    showUploadInfoToast : function(component, event, fileNames) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Info Message',
            message: fileNames + ' sucessfully uploaded!',
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:'5000',
            key: 'info_alt',
            type: 'info',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },

})