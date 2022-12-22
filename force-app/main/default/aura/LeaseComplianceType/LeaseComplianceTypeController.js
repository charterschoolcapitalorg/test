({
    doInit: function(component, event, helper) {
        console.log('init of LeaseComplianceType');
        var action = component.get("c.getLeaseComplianceRecordType");
		action.setCallback(this, function(actionResult) {
			var state = actionResult.getState();
			if (state == "SUCCESS") {
				var recTypeId = actionResult.getReturnValue();
                console.log('recTypeId: ' + recTypeId);
                component.set("v.recTypeId", recTypeId);    
            }
        });
        $A.enqueueAction(action);                   
        
    },
    
	newLeaseCompliance: function(component, event, helper) {
		var action = component.get("c.getLeaseComplianceTemplate");
		var type = component.get("v.LeaseCompliance.Type__c");
        var lease = component.get("v.Lease");
        console.log('type: ' + type);
        action.setParams({"tType": type});
		action.setCallback(this, function(actionResult) {
			var state = actionResult.getState();
			if (state == "SUCCESS") {
				var retVal = actionResult.getReturnValue();
                var dueDays = null;
                var expireDays = null;
                var famDays = null;
                var clientDays = null;
                var actionItemMapping = null;
                var period = null;
                if (retVal) {
                    dueDays = retVal.Due_Days__c;
                    expireDays = retVal.Expire_Days__c;
                    famDays = retVal.FAM_Alert_Days__c;
                    clientDays = retVal.Client_Alert_Days__c;
                    actionItemMapping = retVal.Action_Item_Mapping__c;
                    period = retVal.Period__c;
                }
				//component.set("v.LCT", retVal);
                console.log('getLeaseComplianceTemplate: ' + retVal);
                
                //create lease compliance with default values
                var evt = $A.get("e.force:createRecord");
                evt.setParams({
                   'entityApiName':'Lease_Compliance__c',
                   'defaultFieldValues': {
                       Due_Days__c: dueDays,
                       Expire_Days__c: expireDays,
                       FAM_Alert_Days__c: famDays,
                       Client_Alert_Days__c: clientDays,
                       Action_Item_Mapping__c: actionItemMapping,
                       Type__c: type,
                       Period__c: period,
                       Lease__c: lease.Id
                   },
                    recordTypeId: component.get("v.recTypeId"),//'0120g000000l48p',
                    "panelOnDestroyCallback": function(event) {
                        console.log('panelOnDestroyCallback');
                    },
                    "navigationLocation":"LOOKUP",
                   
                });
                evt.fire();
            
            }
        });
		$A.enqueueAction(action);
        
    },
})