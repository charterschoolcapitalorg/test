({
    
    doInit: function(component, event, helper) {
        	//alert('in init of ViewFodlers');
            var action = component.get("c.getFolders");
            console.log('enter init ');
                    action.setCallback(this, function(response) {
                           var state = response.getState();
                           if (state === "SUCCESS") {
                               var items = response.getReturnValue();
                               component.set("v.folderList", items);
                           }
                           console.log('items '+items);
                           debugger;
                       });
                       $A.enqueueAction(action);
			
     },
      //the custom Opp component
      FireOppEvent : function(component, event, helper) {
      var idx = event.currentTarget.getAttribute("id");
      //alert('id in FireOppEvent: ' +idx);
      var evt = $A.get("e.c:NavigateToOpp");
      evt.setParams({ "result": idx});
      evt.fire();
    
     }

})