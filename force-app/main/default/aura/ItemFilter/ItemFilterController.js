({
    scriptsLoaded : function(component, event, helper) {
        $(".select2Class").select2({
            placeholder: "Select Portfolio(s)",
            allowClear: false,
            selectOnClose: false,
        }).on('change', $A.getCallback(function(e) {
            if (component.isValid()) {
                var selectedIds = new Set(Array.from(e.target.selectedOptions).map(function(opt) {
                    return opt.value;
                }));

                var newAccts = component.get('v.cmoaccounts').map(function(it) {
                    return Object.assign({}, it, { Checked: selectedIds.has(it.Id) });
                });

                console.log(JSON.stringify(newAccts));

                component.set('v.cmoaccounts', newAccts);

                component.getEvent('filterChange').fire();
            }
        }));
    },

    applyFilters : function(component, event, helper) {
        component.getEvent('filterChange').fire();
    },

})