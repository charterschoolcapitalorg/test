({
    doInit : function(component, event, helper) {
        console.log('doInit of IntakeCustomDetails');
        var action = component.get("c.getItem");
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
        
        //good old way - var res = component.get("v.res");
        console.log('passed param: ' + res);
        action.setParams({ iId : res });
        //alert('***getting opp in custom opp component');
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert('***response: ' + state);
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                //alert('***response item: ' + item);
                component.set("v.ii", item);
                
                console.log(item);
            }
        });
        $A.enqueueAction(action);
        
        var action = component.get("c.getFiles");
        var res = component.get("v.res");
        console.log('v.res: ' + res);
        
        action.setParams({ iId : res });
        //alert('***getting opp in custom opp component');
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('files state: ' + state);
            if (state === "SUCCESS") {
                var items = response.getReturnValue();
                //alert('***response item: ' + item);
                component.set("v.files", items);
                console.log('files: ' + items);
            }
        });
        $A.enqueueAction(action);
        
        var action = component.get("c.getBoxURL");
        var res = component.get("v.res");
        action.setParams({ iId : res });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('boxUrl state: ' + state);
            if (state === "SUCCESS") {
                var items = response.getReturnValue();
                component.set("v.boxUrl", items);
                console.log('boxUrl: ' + items);
            }
        });
        $A.enqueueAction(action);
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
        component.set("v.ii.Status__c", 'Submitted');
        var action = component.get("c.submit");
        //alert('in dosubmit');
        action.setParams({
            upsertData : JSON.stringify(component.get("v.ii"))
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
        
        /*var evt = $A.get("e.c:NavigateToHomePage");
         evt.fire();*/
        
    },
    
    openModel: function(component, event, helper) {
        component.set("v.isOpen", true);
    },
    
    closeModel: function(component, event, helper) {
        //component.set("v.isOpen", false);
        component.set("v.isOpen", false);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/"
        });
        urlEvent.fire();
    },
    
    //the custom Opp component
    FireOppEvent : function(component, event, helper) {
        var idx = event.currentTarget.getAttribute("id");
        //alert('id in FireOppEvent: ' +idx);
        //var evt = $A.get("e.c:NavigateToOpp");
        //evt.setParams({ "result": idx});
        //evt.fire();
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/transactiondetail?res='+idx,
            "res": idx
        });
        urlEvent.fire();
        
    },
    
    handleUploadFinished: function (component, event, helper) {
        // Get the list of uploaded files
        var uploadedFiles = event.getParam("fileUploads");
        //console.log('upload fired!');
        helper.getFileAttachments(component, event);
    }
    
})