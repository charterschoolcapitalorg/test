({
	doInit: function(component, event, helper) {
		// console.log('calling doinit...');
        helper.loadPicklists(component);
    },

    handleSearch: function(component, event, helper) {
        helper.performSearch(component);
    },

    handleRefresh: function(component, event, helper){
        // console.log('clicked refresh...');
        component.set("v.ShowSpinner", true);
        helper.performSearch(component);
    },

    handleSort: function(component, event, helper) {
        component.set("v.loading", true);
        try {
            let sortField = component.get('v.sortField'),
                sortDirection = component.get('v.sortDirection'),
                clickedField = event.currentTarget.dataset.sortfield;
            console.log('clickedField = '+clickedField);
            console.log('sortField = '+sortField);
            console.log('sortDirection = '+sortDirection);
            if (sortField === clickedField && sortDirection === 'ASC') {
                sortDirection = 'DESC';
            }else{
                sortDirection = 'ASC';
            }
            let data = component.get('v.filteredRecords');
            var cloneData = data.slice(0);
            //console.log('cloneData = '+JSON.stringify(cloneData));
            if (sortDirection == "ASC") {
                cloneData.sort(function (a, b) {
                    return (a[clickedField] || "|||").toUpperCase().localeCompare((b[clickedField] || "|||").toUpperCase())
                });
            } else {
                cloneData.sort(function (a, b) {
                    return (b[clickedField] || "!!!").toUpperCase().localeCompare((a[clickedField] || "!!!").toUpperCase())
                });
            }
            //cloneData.sort((helper.sortBy(clickedField, sortDirection === 'ASC' ? 1 : -1))); 
            //console.log('cloneData after sort = '+JSON.stringify(cloneData));       
            component.set('v.filteredRecords', cloneData);
                component.set('v.sortField', clickedField);
                component.set('v.sortDirection', sortDirection);
            
            window.setTimeout($A.getCallback(function(){
                // Your async code here
                component.set("v.loading", false);
            }), 1);
        } catch (e) {
            console.log(e);
            component.set("v.loading", false);
        }
    },

    handleClear: function(component){
        component.set("v.showClear", false);
		component.set('v.aiMapping', null);
        component.set('v.owner', null);
        component.set('v.status', null);
        component.set('v.startDate', null);
        component.set('v.endDate', null);
        component.set('v.assignedTo', null);
        component.set('v.property', null);
        component.set("v.filteredRecords", null);
        },

    getHelp: function(component, event, helper) {
        component.set("v.openmodel",true);
    },

    closeHelp: function(component, event, helper) {
        component.set("v.openmodel",false);
    },

})