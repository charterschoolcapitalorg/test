({
	deleteMember: function(component, member){
        var action = component.get("c.setDeleteIntake");
        action.setParams({
            toDelete : JSON.stringify(member)
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {

            }
        });
        $A.enqueueAction(action);
    },
})