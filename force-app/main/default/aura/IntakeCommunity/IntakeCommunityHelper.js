({
    
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

    loadValue: function(component, actionName, cb) {
        var action = component.get(actionName);
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                cb(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    loadSections: function(component) {
        this.loadValue(component, 'c.hasOpportunities', function(show) {
            if (show) {
                component.set('v.hasOpportunities', true);
                var sections = Array.from(component.get('v.activeSections'));
                sections.push('opportunities');
                component.set('v.activeSections', sections);
            }
        });
        this.loadValue(component, 'c.hasAccounts', function(show) {
            if (show) {
                component.set('v.hasAccounts', true);
                var sections = Array.from(component.get('v.activeSections'));
                sections.push('accounts');
                component.set('v.activeSections', sections);
            }
        });
        this.loadValue(component, 'c.hasUrgentItems', function(show) {
            if (show) {
                component.set('v.hasUrgentItems', true);
                component.set('v.selectedTabId', 'urgentTab');
            }
        });
    }
})