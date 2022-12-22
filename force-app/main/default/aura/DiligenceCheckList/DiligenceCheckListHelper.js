({
	loadPicklists: function(component) {
        try {
            let action = component.get('c.getPicklists');
            action.setCallback(this, function(result) {
                try {
                    let state = result.getState();
                    if (state === 'SUCCESS') {
                        let picklistMap = result.getReturnValue();
                        let aiMappingList = picklistMap['mapping'];
                        aiMappingList.sort(function (a, b) {
                            return (a['label'] || "|||").toUpperCase().localeCompare((b['label'] || "|||").toUpperCase())
                        });
                        component.set('v.aiMappingList', aiMappingList);
                        
                        let statusList = picklistMap['status'];
                        component.set('v.statusList', statusList);

                        let ownerList = picklistMap['owners'];
                        component.set('v.ownerList', ownerList);

                        let propertyList = picklistMap['property'];
                        component.set('v.propertyList', propertyList);

                        let assignedToList = picklistMap['assignedTo'];
                        assignedToList.sort(function (a, b) {
                            return (a['label'] || "|||").toUpperCase().localeCompare((b['label'] || "|||").toUpperCase())
                        });
						component.set('v.assignedToList', assignedToList);
                        component.set("v.ShowSpinner", false);
                    } else if (state === 'ERROR') {
                        component.set("v.ShowSpinner", false);
                        let error = result.getError();
                        if (error && error[0] && error[0].message) {
                            this.showError(error[0].message);
                        } else {
                            this.showError('An Unknown Error Occurred.');
                        }
                    }
                } catch (e) {
                    console.log(e);
                }
            });
            $A.enqueueAction(action);
        } catch (e) {
            console.log(e);
        }
    },

	showError : function(errorMessage) {
        var errorToastEvent = $A.get("e.force:showToast");
        errorToastEvent.setParams({
            type : "error",
            message : errorMessage
        });
        errorToastEvent.fire();
    },

	performSearch: function(component){
        component.set("v.ShowSpinner", true);
        component.set("v.showClear", true);
        //add search validation
        //at least one of the filters from step 1 and both start and end dates have to be selected
		var endDatevalidity = component.get('v.endDate');
        var startDatevalidity = component.get('v.startDate');
        var diligenceItemValidity = component.get('v.aiMapping');
        var statusValidity = component.get('v.status');
        var assignToValidity = component.get('v.assignedTo');
        var ownerPortfolioValidity = component.get('v.owner');
        var propertyValidity = component.get('v.property');
        //if(startDatevalidity != null && endDatevalidity != null){
        if((startDatevalidity != null && endDatevalidity != null) && 
            (diligenceItemValidity != null || statusValidity != null || assignToValidity != null || ownerPortfolioValidity != null || propertyValidity != null)){
            let action = component.get("c.getInitialData"),
                aiMapping = component.get('v.aiMapping'),
                owner = component.get('v.owner'),
                status = component.get('v.status'),
                startDate = component.get('v.startDate'),
                endDate = component.get('v.endDate'),
                assignedTo = component.get('v.assignedTo'),
                property = component.get('v.property')
            action.setParams({
                mappingToSearch: aiMapping,
                ownerToSearch: owner,
                statusToSearch: status,
                startDateToSearch: startDate,
                endDateToSearch: endDate,
                assignedToSearch: assignedTo,
                propertyToSearch: property,
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    let items = response.getReturnValue();
                    items.sort(function (a, b) {
                        return (a['AccName'] || "|||").toUpperCase().localeCompare((b['AccName'] || "|||").toUpperCase())
                    });
                    component.set("v.today", Date.now());
                    component.set("v.ShowSpinner", false);
                    component.set("v.filteredRecords", items);
                } else {
                    component.set("v.ShowSpinner", false);
                    let error = response.getError();
                    if (error && error[0] && error[0].message) {
                        this.showError(error[0].message);
                        console.log('error: '+error[0].message);
                    } else {
                        this.showError('An Unknown Error Occurred.');
                        console.log('error: An Unknown Error Occurred.');
                    }
                    
                } 
            });
            $A.enqueueAction(action);
        }else{
            component.set("v.ShowSpinner", false);
            this.showError('Make sure Step 1 and Step 2 are complete');
            console.log('ERROR: Make sure Step 1 and Step 2 are complete');
        }
	},

    sortBy: function(field, reverse, primer) {
        console.log('performing sort now');
        console.log('field == '+field);
        console.log('reverse sort == '+reverse);
        //console.log('primer== '+primer);
        var key = primer
        ? function(x) {
            return primer(x[field]);
        }
        : function(x) {
            return x[field];
        };
        console.log('key == '+primer);
        return function(a, b) {
            //console.log('key(a) == '+key(a));
            //console.log('key(b) == '+key(b));
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        }
    }

})