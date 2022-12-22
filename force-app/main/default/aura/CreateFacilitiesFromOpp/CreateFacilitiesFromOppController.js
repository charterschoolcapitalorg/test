({
	 
    doInit: function(component, event, helper) {
        console.log("doInit CreateFacilitiesFromOpp ");
        var recid = component.get("v.recordId");
        console.log("rec id: " + recid);
        var action = component.get("c.getOpportunity");
		action.setParams({"oId": recid});
         
		action.setCallback(this, function(actionResult) {
			var state = actionResult.getState();
			if (state == "SUCCESS") {
				var retVal = actionResult.getReturnValue();
				component.set("v.Opp", retVal);
                console.log('Opp: ' + component.get("v.Opp"));
                if (retVal.Property__c) {
                    	console.log('Prop Id: ' + component.get("v.Opp.Property__c"));
                        var evt = $A.get("e.force:navigateToComponent");
                        evt.setParams({
                            componentDef : "c:CreateFacilitiesObjects",
                            componentAttributes: {
                                propertyId : component.get("v.Opp.Property__c"),
                                fromObjectId : component.get("v.Opp.Id"),
                            }
                        });
                        evt.fire();
                    	
                }
                            
			}else if (state == "ERROR") {
				var errors = actionResult.getError();
			}
		});
		$A.enqueueAction(action);  
        
        component.set('v.columns', [
            {label: 'Name', fieldName: 'Name', type: 'text'},
            {label: 'Id', fieldName: 'Id', type: 'text'},
        ]);

        
	},

    updateSelectedText: function (cmp, event) {
        var selectedRows = event.getParam('selectedRows');
        cmp.set('v.selectedRowsCount', selectedRows.length);
    },
            
    createProperty: function(component, event, helper) {
        
        component.set('v.createAccount', true);

        // var opp = component.get("v.Opp");
        // var editRecordEvent = $A.get("e.force:createRecord");                
        // editRecordEvent.setParams({
        //     'entityApiName':'Account',
        //     'defaultFieldValues': {
        //         Name: '',
        //         Purchase_Price__c: opp.Total_Price__c,
        //         Acquisition_Date__c: opp.CloseDate,
        //         Opportunity_That_Created_the_Property__c: opp.Id+'',
        //     },
        //     "recordTypeId": '0120g000000l48l',
        //     "recordId": component.get("v.Property.Id"),
        //     "panelOnDestroyCallback": function(event) {
        //         console.log('panelOnDestroyCallback: ' + window.location.href);
        //         var a = component.get('c.doInit');
        //         $A.enqueueAction(a);
        //     },
        //     "navigationLocation":"LOOKUP",
        // });
        // editRecordEvent.fire();
        
	},

    search : function(component, event, helper) {
        console.log('in search');
        var searchText = component.get('v.searchText');
        var action = component.get('c.searchProperties');
        console.log('in search2');
        action.setParams({searchText: searchText});
        action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
            var props = response.getReturnValue();
            console.log(props);
            component.set("v.FoundProps",props);
            var count = 0;
            for (var i=0; i<props.length; i++) {
                count++;
            }
            component.set("v.numFoundProps", count);  
        }
      });
      $A.enqueueAction(action);
    },

    insertProperty: function(component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        helper.toggleInsertButton(component,'true');
        component.set('v.showSpinner', true);
        let opp = component.get("v.Opp");
        let fields = event.getParam('fields');
        fields.Opportunity_That_Created_the_Property__c = opp.Id;
        fields.RecordTypeId = '0120g000000l48lAAA';     // Property Record Type
        component.find('propertyRecord').submit(fields);
    },

    handleSuccess: function(component, event, helper) {
        // var updatedRecord = JSON.parse(JSON.stringify(event.getParams()));
        helper.showToast('success','Success!', 'The property record has been created successfully.');
        let init = component.get('c.doInit');
        $A.enqueueAction(init);
    },

    handleError: function(component, event, helper) {
        component.set('v.showSpinner', false);
        helper.toggleInsertButton(component,'false');
    }
    
})