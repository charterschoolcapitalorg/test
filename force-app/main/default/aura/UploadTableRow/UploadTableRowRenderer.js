({
    afterRender : function(component, helper){
        this.superAfterRender();        
        var intakeItem = component.get("v.intakeItem");
        var today = new Date();
        var monthDigit = today.getMonth() + 1;
        if (monthDigit <= 9) {
            monthDigit = '0' + monthDigit;
        }
        var dateColumn = component.find("dateColumn");
        console.log(dateColumn.get("v.value"));
        var currentDate = new Date(today.getFullYear() + "-" + monthDigit + "-" + today.getDate());
        var dueDate = new Date(intakeItem.Due_Date__c);
        console.log('Intake Item Due Date: ' + dueDate);
        console.log('Today: ' + currentDate);
        if(dueDate < currentDate){
            $A.util.addClass(dateColumn, "overdue");
        } else {
            $A.util.addClass(dateColumn, "notoverdue");
        }

    }
})