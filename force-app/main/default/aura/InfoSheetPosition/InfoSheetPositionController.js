({
	doInit : function(component, event, helper) {
		if(component.get("v.person.Vacant_Position__c") === true){
            helper.isVacantChecked(component);
        }
	},

    deleteMember : function(component, event, helper){
        const del = component.get("v.row");
        const delEvent = component.getEvent("removeRecordEvent");
        delEvent.setParams({
          "record": del
        });
        delEvent.fire();
    },

    handleClick: function(component, event, helper){
        let isVacant = component.get("v.person.Vacant_Position__c");
        if(isVacant){
            helper.isVacantChecked(component);
        } else {
            helper.isVacantUnchecked(component);
        }
    },

})