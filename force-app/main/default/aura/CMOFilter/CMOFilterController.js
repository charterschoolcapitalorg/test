({	
    doInit : function(component, event, helper) {
        
    },
    
	close : function(component, event, helper) {
        console.log('setting value back to: ' + component.get('v.origcmonamelist'));
        component.set("v.cmonamelist",  component.get('v.origcmonamelist'));
        console.log('setting id value back to: ' + component.get('v.origcmonamelist'));
        component.set("v.cmolist",  component.get('v.origcmolist'));
        
		var overlay = component.find("overlayLib");
        console.log('Overlay: '+ overlay);
        component.find("overlayLib").notifyClose();
    },
    save : function(component, event, helper) {
        
        //console.log('firing updated event');
        //var saveEvent = component.getEvent("filterupdated");
        //saveEvent.setParams({"recordId" : intakeItem.Id, "checked" : false});
        //saveEvent.fire();
        
        //var evt = $A.get("e.c:FilterUpdated");
        //evt.fire();
        //console.log('fired updated event');
        //
     	console.log('saving value: ' + component.get('v.cmotempnamelist'));
        component.set("v.cmonamelist", component.get('v.cmotempnamelist'));
        console.log('saving value: ' + component.get('v.cmotemplist'));
        component.set("v.cmolist", component.get('v.cmotemplist'));
        
        
        var overlay = component.find("overlayLib");
        console.log('Overlay: '+ overlay);
        component.find("overlayLib").notifyClose();
	},
    
    selectoptionvalue: function(component, event, helper) {
        var selected = [], checkboxes = component.find("checkbox");
        if(!checkboxes) {   // Find returns zero values when there's no items
            checkboxes = [];
        } else if(!checkboxes.length) { // Find returns a normal object with one item
            checkboxes = [checkboxes];
        }
        
        checkboxes
        .filter(checkbox => checkbox.get("v.value"))    // Get only checked boxes
        .forEach(checkbox => selected.push(checkbox.get("v.label").replace(',', '')))   // And get the labels
        //.forEach(checkbox => console.log("uiyguygyuguyguygyugyug"));   // And get the labels

        var selectedids = [];       
        for(var i = 0; i < checkboxes.length; i++){
            if (checkboxes[i].get("v.value")) {
                console.log('value: ' + checkboxes[i].get("v.text"));
                selectedids.push(checkboxes[i].get("v.text").replace(',', ''));
            }
        }
        
        component.set("v.cmotempnamelist", selected.toString());
        console.log('name list to: ' + component.get("v.cmonamelist"));
        
        component.set("v.cmotemplist", selectedids.toString());
        console.log('name ids to: ' + component.get("v.cmolist"));
    },
})