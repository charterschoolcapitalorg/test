({
   openModel: function(component, event, helper) {
      component.set("v.isOpen", true);
   },
 
   closeModel: function(component, event, helper) {
      component.set("v.isOpen", false);
   },
   
   onRender: function(component, event, helper) {
      try {
          var checkboxes = component.find("chkSelected");
          var selectedIds = component.get("v.selectedIds");
          
          if (!checkboxes.length) {
              
              if (selectedIds.includes(checkboxes.get("v.value"))) {
                checkboxes.set("v.checked", true);
              }
          } else {
              for (var i=0; i<checkboxes.length; i++) {
                  if (selectedIds.includes(checkboxes[i].get("v.value"))) {
                      checkboxes[i].set("v.checked", true);
                  }
              }    
          }
      } catch (e) {}
       
   },
    
   saveClose: function(component, event, helper) { 
      component.set("v.isOpen", false);
      var checkboxes = component.find("chkSelected");
 	  var checkboxesChecked = [];
      var selectedIds = component.get("v.selectedIds");
      
      if (!checkboxes.length) {
          if (checkboxes.get("v.checked")) {
                if(!selectedIds.includes(checkboxes.get("v.value"))){
                    selectedIds.push(checkboxes.get("v.value"));
                }
          } else {
                var index = selectedIds.indexOf(checkboxes.get("v.value"));
                if(index !== -1) selectedIds.splice(index, 1);
          }
          component.set("v.selectedIds", selectedIds.join(","));
          component.set("v.selectedIds", selectedIds);
      } else {
          for (var i=0; i<checkboxes.length; i++) {
              //console.log('item: ' + checkboxes[i].get("v.value") + ' checked? ' + checkboxes[i].get("v.checked"));
                if (checkboxes[i].get("v.checked")) {
                    if(!selectedIds.includes(checkboxes[i].get("v.value"))){
                      selectedIds.push(checkboxes[i].get("v.value"));
                    }
                } else {
                    var index = selectedIds.indexOf(checkboxes[i].get("v.value"));
                    if(index !== -1) selectedIds.splice(index, 1);
                }
           }
           component.set("v.selectedIds", selectedIds.join(","));
           component.set("v.selectedIds", selectedIds);
      }
       //push the selected event for this file
       try{                
           var rowEvent = component.getEvent("rowEvent");
           rowEvent.setParams({"recordIds" : component.get("v.selectedIds"), "checked" : true});
           rowEvent.fire();
       } catch (e) {console.log('exception: ' + e);}
       
       
   },
})