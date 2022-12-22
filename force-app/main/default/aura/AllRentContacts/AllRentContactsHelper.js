({
    getColumnDefinitions: function () {
        var columns = [

            { label: 'Property', fieldName: 'accUrl', type: 'url', sortable: true, initialWidth: 300, typeAttributes: {
                label: { fieldName: 'Property' },
                      target: '_blank'
                  }, hideDefaultActions: true},
            {label: 'State', fieldName: 'StateName', type: 'text', sortable: true, initialWidth: 90},
            {label: 'Owner', fieldName: 'Owner', type: 'text', sortable: true, initialWidth: 120},
            {label: 'Nick Name', fieldName: 'NickName', type: 'text', sortable: true, initialWidth: 150},
            {label: 'First Name', fieldName: 'FirstName', type: 'text', initialWidth: 150},
            { label: 'Last Name', fieldName: 'rcUrl', type: 'url', sortable: true, initialWidth: 180, typeAttributes: {
                label: { fieldName: 'LastName' },
                      target: '_blank'
                  }, hideDefaultActions: true},
            {label: 'Email', fieldName: 'email', type: 'email', initialWidth: 350},
            {label: 'Alt Email', fieldName: 'altEmail', type: 'text', initialWidth: 250},
            {label: 'Tenant', fieldName: 'Account', type: 'text', sortable: true}           
        ];

        return columns;
    },

    // Used to sort the 'Age' column
    sortBy: function(field, reverse, primer) {
        var key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },

    handleSort: function(cmp, event) {
        let sortedBy = event.getParam('fieldName');
        let sortDirection = event.getParam('sortDirection');
        this.sortData(cmp, sortedBy,sortDirection);
    },

    sortData: function(cmp, sortedBy, sortDirection){
        let cloneData = cmp.get("v.data");

        if (sortedBy === "accUrl") {
            cloneData.sort(this.sortBy("Property", sortDirection === 'asc' ? 1 : -1));
          } else if(sortedBy === "rcUrl"){
            cloneData.sort(this.sortBy("LastName", sortDirection === 'asc' ? 1 : -1));
          } else {
            cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
          }
        
        cmp.set('v.data', cloneData);
        cmp.set('v.sortDirection', sortDirection);
        cmp.set('v.sortedBy', sortedBy);
    },

})