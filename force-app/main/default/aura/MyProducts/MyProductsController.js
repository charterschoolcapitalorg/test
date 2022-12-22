({
    doInit : function(component, event, helper) {
        component.set("v.didchange", false);

        helper.loadCMOs(component);
        helper.loadItems(component, []);
    },
    
    handleFilterChange: function(component, event, helper) {
        var cmoIds = component.get('v.cmoaccounts')
                .filter(function(acct) { return acct.Checked; })
                .map(function(acct) { return acct.Id; });

        component.set('v.cmoIdsSelected', cmoIds);
        helper.loadItems(component, cmoIds);
    }
})