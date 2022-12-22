({
	init : function(component, event, helper) {
	 
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.getDownloadFileURL");
        action.setParams({"iId" : intakeItem.Id});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                var ids = response.getReturnValue();
                if (ids!='') {
                    var separated = ids.split(",");
                    component.set("v.totalNumDocs",separated.length -1);
                        for (var i in separated) {                           
                            var theid = separated[i];
                            if (theid != '') {
                                
                                var hostname = window.location.hostname;
                                component.set("v.thisUrl",'https://' + hostname + '/sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId='+theid);
                                component.set("v.thisDocId",theid);
                                break;     
                            }
                            
                        }
                     
                }
                  
                
            } else {
                var message = 'There has been an error getting the file';
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
    next : function(component, event, helper) {
	 
        var thisId = component.get("v.thisDocId");
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.getNextDocId");
        action.setParams({"iId" : intakeItem.Id, "thisId" : thisId});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                var id = response.getReturnValue();
                if (id!='') {
                    component.set("v.thisDocId",id);
                    var hostname = window.location.hostname;
                    
                    component.set("v.thisUrl",'https://' +hostname+'/sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId='+id);    
                	var currCount = component.get("v.docCount");
                    
                    component.set("v.docCount",currCount+1);
                }
            } else {
                var message = 'There has been an error getting the file';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible');                  
            }
          
        });
        
        $A.enqueueAction(action);  
	},
    prev : function(component, event, helper) {
	 
        var thisId = component.get("v.thisDocId");
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.getPrevDocId");
        action.setParams({"iId" : intakeItem.Id, "thisId" : thisId});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                var id = response.getReturnValue();
                if (id!='') {
                    component.set("v.thisDocId",id);
                    var hostname = window.location.hostname;
                    
                    component.set("v.thisUrl",'https://' +hostname+'/sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId='+id);    
                	var currCount = component.get("v.docCount");
                    component.set("v.docCount",currCount-1);
                }
            } else {
                var message = 'There has been an error getting the file';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible');                  
            }
          
        });
        
        $A.enqueueAction(action);  
	},
    
    approve : function(component, event, helper){ 
        
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.acceptedStatus");
        action.setParams({"iiId" : intakeItem.Id});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.intakeItem", response.getReturnValue());
                var message = 'Item has been Approved';
                helper.showToast('Status Approved', message, '4000', 'info_alt', 'success', 'dismissible');                  
            	var overlay = component.find("overlayLib");
                component.find("overlayLib").notifyClose();
            } else {
                var message = 'There has been an error updating item';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible');                  
            }
          
        });
        $A.enqueueAction(action); 
        
   },
	close : function(component, event, helper){ 
    	var overlay = component.find("overlayLib");
        component.find("overlayLib").notifyClose();
	},
})