({
	doInit : function(component, event, helper) {
        
        var action = component.get("c.getOpp");
        
        var sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        var sURLVariables = sPageURL.split('&'); //Split by & so that you get the key value pairs separately in a list
        var sParameterName;
        var i;
		
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('='); //to split the key from the value.

            if (sParameterName[0] === 'res') { //lets say you are looking for param name - firstName
                sParameterName[1] === undefined ? 'Not found' : sParameterName[1];
            }
        }
        var res = sParameterName[1];
        component.set("v.res", res);
        
        //good old way of getting id - var res = component.get("v.res");
        action.setParams({ oppId : res });
        //alert('***getting opp in custom opp component');
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert('***response: ' + state);
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                //alert('***response item: ' + item);
                 component.set("v.opp", item);
                console.log(item);
            }
         });
        $A.enqueueAction(action);
        
        var action = component.get("c.getFiles");
        var res = component.get("v.res");
        action.setParams({ oppId : res });
        //alert('***getting opp in custom opp component');
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert('***response: ' + state);
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                //alert('***response item: ' + item);
                component.set("v.files", item);
                console.log('files: ' + item);
            }
        });
        $A.enqueueAction(action);
        
        /*action = component.get("c.getOwner");
        res = component.get("v.res");
        action.setParams({ oppId : res });
        //alert('***getting opp in custom opp component');
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert('***response: ' + state);
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                //alert('***response item: ' + item);
                 component.set("v.owner", item);
                console.log(item);
            }
         });
        $A.enqueueAction(action);
        */
    },
     handleReturn: function(component, event, helper){
        //var evt = $A.get("e.c:NavigateToHomePage");
        //evt.fire();
         
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/'
        });
        urlEvent.fire();
    },
    dosubmit:function(component, event, helper) {    
    	
        	  var action = component.get("c.submit");
        	  //alert('in dosubmit');
              action.setParams({
              	upsertData : JSON.stringify(component.get("v.opp"))
              });
                           action.setCallback(this, function(response) {
                               var state = response.getState();
                               //alert('response: ' + state);
                                  if (state === "SUCCESS") {
                                      component.set("v.isOpen", true);
                                      component.set("v.modalMessage", "Your comment has been submitted to your Customer Service Rep.");
                                  }else{
                                      component.set("v.isOpen", true);
                                      component.set("v.modalMessage", "Error saving the records, please contact your Administrator.");
                                  }

                            });
                           $A.enqueueAction(action);
         
         var evt = $A.get("e.c:NavigateToHomePage");
         evt.fire();
      
    },
     openModel: function(component, event, helper) {
          component.set("v.isOpen", true);
       },

    closeModel: function(component, event, helper) {
          component.set("v.isOpen", false);
    },
    
    handleUploadFinished: function (component, event, helper) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("fileUploads");
        //console.log('upload fired!');
        helper.getFileAttachments(component, event);
    }
})