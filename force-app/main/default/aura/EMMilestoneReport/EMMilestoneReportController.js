({
	doInit: function(component, event, helper) {
		console.log('calling doinit on enrollment marketing');
        let action = component.get("c.getEnrollmentMarketingMilestone");
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let items = response.getReturnValue();
                component.set("v.filteredOpportunities", items);
                component.set("v.originalOpportunities", items);
                component.set("v.today", Date.now());
                //component.set("v.oppsSignedContract", response.getsignedContractOpps(items));

                let returnUsers = helper.getUserList(component, items);
                component.set("v.userList", returnUsers);

                let returnStates = helper.getStateList(component, items);
                component.set("v.stateList", returnStates);

                // total records number
                let returnTotalRecordCount = helper.totalRecordCount(component, items);
                component.set("v.totalRecords", returnTotalRecordCount);

                // total contracted opps
                let returnTotalContracted = helper.totalContracted(component, items);
                component.set("v.oppsSignedContract", returnTotalContracted);
            }
        });
        $A.enqueueAction(action);
    },

    handleRefresh: function(component, event, helper){
        component.set("v.user", undefined);
        component.set("v.state", undefined);
        var init = component.get('c.doInit');
        $A.enqueueAction(init);
    },

    handleSearch: function(cmp, event, helper){
        let selectedState = cmp.get("v.state");
        let selectedUser = cmp.get("v.user");
        if(selectedState !== undefined || selectedUser !== undefined) {
            let filteredOpps = helper.filterOpps(cmp.get("v.originalOpportunities"), 
                                                selectedUser, 
                                                selectedState);
            cmp.set("v.filteredOpportunities", filteredOpps);
        }
    },

    openHelp: function(component, event, helper) {
        component.set("v.openHelp",true);
    },

    closeHelp: function(component, event, helper) {
        component.set("v.openHelp",false);
    },

    handleSort: function(component, event, helper) {
        let sortField = component.get('v.sortField'),
        sortDirection = component.get('v.sortDirection'),
        clickedField = event.currentTarget.dataset.sortfield;
        console.log('sort clicked');
        
        if (sortField === clickedField && sortDirection === 'ASC') {
            sortDirection = 'DESC';
        }else{
            sortDirection = 'ASC';
        }

        let data = component.get('v.filteredOpportunities');
        var cloneData = data.slice(0);
        console.log('*** clickedField = ' + clickedField);

        if (clickedField === 'estimatedCost' || clickedField === 'capRate') {
            if (sortDirection == "ASC") {
                cloneData.sort(function (a, b) {
                    return a[clickedField] - b[clickedField]
                });
            } else {
                cloneData.sort(function (a, b) {
                    return b[clickedField] - a[clickedField]
                });
            }
        } else {
            if (sortDirection == "ASC") {
                cloneData.sort(function (a, b) {
                    return (a[clickedField] || "|||").toUpperCase().localeCompare((b[clickedField] || "|||").toUpperCase())
                });
            } else {
                cloneData.sort(function (a, b) {
                    return (b[clickedField] || "!!!").toUpperCase().localeCompare((a[clickedField] || "!!!").toUpperCase())
                });
            }
        }

        console.log('cloneData after sort = '+ JSON.stringify(cloneData));

        component.set('v.filteredOpportunities', cloneData);
        component.set('v.sortField', clickedField);
        component.set('v.sortDirection', sortDirection);
    },

})