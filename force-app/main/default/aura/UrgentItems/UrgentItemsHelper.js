({
    handleHeaders : function(component, items) {
        
        //set oppName (used as group header) so we can sort
        for(var x = 0; x < items.length; x++) {
            var currHeader;
            var currItem = items[x];
            try {
                if (currItem.oppName) {
                    currHeader = currItem.oppName;
                } else {
                    currHeader = currItem.item.Account_Name__r.Name;
                }
                currItem.oppName = currHeader;
            } catch(e) {
                console.error(e);
            }
        }

        //sort by oppName
        //items.sort((a,b) => (a.oppName > b.oppName) ? 1 : ((b.oppName > a.oppName) ? -1 : 0));

        //set flag to display new header
        var prevHeader;  
        for(var x = 0; x < items.length; x++) {
            var currItem = items[x];
            try {
                if (prevHeader == currItem.oppName) {
                    currItem.displayNewHeader = false;
                } else {
                    currItem.displayNewHeader = true;
                }
                prevHeader = currItem.oppName;
            } catch(e) {
                console.error(e);
            }
        }         
        component.set("v.intakeItems", items);
    }
})