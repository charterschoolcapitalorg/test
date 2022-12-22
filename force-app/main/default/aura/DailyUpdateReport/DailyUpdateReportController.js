({
	doInit: function(component, event, helper) {
		// console.log('calling doinit...');
        let action = component.get("c.getDailyUpdates");
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let items = response.getReturnValue();
                component.set("v.filteredOpportunities", items);
                component.set("v.originalOpportunities", items);
                component.set("v.today", Date.now());
                component.set("v.ShowSpinner", false);
                let returnedUsers = helper.parseUserList(component, items);
                component.set("v.userList", returnedUsers);
            }
        });
        $A.enqueueAction(action);
    },

    handleChange: function(cmp, event, helper){
        let selectedUser = event.getParam("value");
        let filteredOpps = helper.filterOpps(cmp.get("v.originalOpportunities"), selectedUser);
        cmp.set("v.filteredOpportunities", filteredOpps);
    },

    handleRefresh: function(component, event, helper){
        // console.log('clicked refresh...');
        component.set("v.ShowSpinner", true);
        var init = component.get('c.doInit');
        $A.enqueueAction(init);

    }

})