({
    handleReturn: function(component, event, helper){
        var evt = $A.get("e.c:NavigateToHomePage");
        evt.fire();
    },
})