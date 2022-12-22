({
    init : function(component, event, helper) {
      var intakeItem = component.get("v.intakeItem");  
      var action = component.get("c.getIntakeItem");
        action.setParams({"iId" : intakeItem.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {   
                component.set("v.intakeItem", response.getReturnValue());
            } else {
                var message = 'There has been an error getting the intake item';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
            }
        });
        
        $A.enqueueAction(action);  
    },
    // this function automatic call by aura:waiting event  
    showSpinner: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
       component.set("v.Spinner", false);
    },
	save : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.addComment");
        var comment = component.find("comments").get("v.value");
        action.setParams({"iId" : intakeItem.Id, "comment" : comment});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               

                var a = component.get('c.init');
                $A.enqueueAction(a);
                var overlay = component.find("overlayLib");
                component.find("overlayLib").notifyClose();
            } else {
                var message = 'There has been an error updating this comment';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
            }
        });
        
        $A.enqueueAction(action);  
	},
    nochanges : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.noChanges");
        
        action.setParams({"iId" : intakeItem.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                var a = component.get('c.init');
                $A.enqueueAction(a);
                
                var overlay = component.find("overlayLib");
                component.find("overlayLib").notifyClose();
            } else {
                var message = 'There has been an error updating this comment';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
            }
        });
        
        $A.enqueueAction(action);  
	},
    close : function(component, event, helper) {
		var overlay = component.find("overlayLib");
        component.find("overlayLib").notifyClose();
    },
    
})