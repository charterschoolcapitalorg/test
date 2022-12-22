({
    afterRender : function(component, helper){
        this.superAfterRender();        
        var index = component.get("v.idx");
        var isChild = component.get("v.isChild");
        var evenRow = (isChild) ? 'childEvenRow' : 'evenRow';
        var oddRow = (isChild) ? 'childOddRow' : 'oddRow';
        var remainder = index % 2;
        console.log('Remainder: ' + remainder);
        var rws = component.find("myRow");
        if ($A.util.isArray(rws)) {
            rws.forEach(rw => {
                if(rw && remainder == 0){
                    $A.util.addClass(rw, evenRow);
                } else {
                    $A.util.addClass(rw, oddRow);
                }     
            })
    	}
 		var subrows = component.find("subrows");
        console.log('Subrows: ' + subrows);
		$A.util.addClass(subrows, "isExpanded");
    }
})