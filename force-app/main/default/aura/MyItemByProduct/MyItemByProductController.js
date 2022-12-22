({
    scriptsLoaded : function(component, event, helper) {
	},
    scriptsLoaded2 : function(component, event, helper) {
	},
    doInit : function(component, event, helper) {
        console.log('***** MyItemByProduct: doInit called...');
        var intake = component.get("v.iName");
        var currDateValue = component.get("v.currDateValue");
        component.set("v.bulkDisable", true);
        component.set("v.selectedIds", "");
        helper.loadIntakeItems(component,event,currDateValue);
        helper.getFundRecType(component, event);
        helper.getFacRecType(component, event);  
        console.log('***** MyItemByProduct: doInit completed...');
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
    handleCheck : function(component, event, helper) {

          //using event passing
          console.log('firing event');
          var intake = component.get("v.iName");
          console.log('name: ' + intake);
            var source = event.getSource();
            var checked = source.get("v.checked");
            if (checked) {
                //var ischk = component.get("v.isParentChecked");
                component.set("v.isParentChecked", true);
          		var myEvent = $A.get("e.c:SelectAllChecked");
                myEvent.setParams({ "parentId": intake});
                myEvent.fire();
                console.log('checked event fired');      
            } else {
                component.set("v.isParentChecked", false);
                var myEvent = $A.get("e.c:SelectAllUnChecked");
                myEvent.setParams({ "parentId": intake});
                myEvent.fire();
                console.log('unchecked event fired');
            }
        
	},
    
    
	toggleSection : function(component, event, helper){
        var source = event.getSource();  
        var iconName = source.get("v.iconName");
        
        if(iconName == "utility:add"){
            source.set("v.iconName", "utility:dash");
            component.set("v.showList", true);
        } else {
            source.set("v.iconName", "utility:add");
            component.set("v.showList", false);
        }
    },
    setSelectedIds : function(component, event, helper){
        var recordId = event.getParam("recordId");
        var checked = event.getParam("checked");
        var bulkDisable = component.get("v.bulkDisable");
        console.log('Record ID called ' + recordId);
        var selectedIds = component.get("v.selectedIds");
        selectedIds = (!selectedIds || selectedIds.trim().length == 0) ? new Array() : selectedIds.split(",");
        if(checked){
            if(! selectedIds.includes(recordId)){
                selectedIds.push(recordId);
            }
        } else {
            var index = selectedIds.indexOf(recordId);
            if(index !== -1) selectedIds.splice(index, 1);
        }
        if(selectedIds.length == 0) {
            component.set("v.bulkDisable", true);
            component.set("v.firstId", "");
        } else {
            component.set("v.bulkDisable", false);
            component.set("v.firstId", selectedIds[0]);
        }
        component.set("v.selectedIds", selectedIds.join(","));
        console.log('Selected Ids: ' + component.get("v.selectedIds").split(","));
    },
    handleBulkUploadFinished : function(component, event, helper){
        var selectedIds = component.get("v.selectedIds");
        var fileNames = component.get("v.fileNames");
        fileNames = (fileNames && fileNames.trim().length > 0) ? fileNames.split(",") : new Array();
        var docIds = new Array();
        var uploadedFiles = event.getParam("files");
        for(var i = 0; i < uploadedFiles.length; i++){
        	console.log('File Name : ' + uploadedFiles[i].name);
            console.log('Doc Id : ' + uploadedFiles[i].documentId);
            docIds.push(uploadedFiles[i].documentId);
            fileNames.push(uploadedFiles[i].name);
        }
        var documentIds = docIds.join(",");
        //replicate doc links
        var action = component.get("c.insertUpload");
        action.setParams({"recordIds" : selectedIds, "documentIds" : documentIds});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('Replicate Content ' + state);
            if (state === "SUCCESS") {               
                fileNames = (fileNames.length > 1) ? fileNames.join(",") : fileNames[0];
                component.set("v.fileNames", fileNames);
                component.set("v.isParentChecked", false);
        
            }            
        });
        $A.enqueueAction(action);  
        
        var a = component.get('c.doInit');
        $A.enqueueAction(a);

    },
    handleClose : function(component, event, helper){
        var overlay = component.find("overlayLib");
        console.log('Overlay: '+ overlay);
        component.find("overlayLib").notifyClose();
    },
    handleDocUploaded: function (cmp, event, helper) {
        var a = cmp.get('c.doInit');
        $A.enqueueAction(a);
    },
    handleRedFlag: function (cmp, event, helper) {
        cmp.set("v.itemHasRedFlag", true);
    },
   approveSelected : function(component, event, helper){ 
        console.log('in ApproveSelected ');
        var selectedIds = component.get("v.selectedIds");
        console.log('Ids ' + selectedIds);
        
        var action = component.get("c.acceptedSelected");
        action.setParams({"iiIds" : selectedIds});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('Approve Status ' + state);
            if (state === "SUCCESS") {               
                component.set("v.intakeItem", response.getReturnValue());
                var message = 'Items have been Approved';
                console.log('showing toast');
                helper.showToast('Status Approved', message, '4000', 'info_alt', 'success', 'dismissible');                  
            	console.log('refreshing page');
                var a = component.get('c.doInit');
                $A.enqueueAction(a);
               console.log('end of refreshing page');
                component.set("v.isParentChecked", false);
            } else {
                var message = 'There has been an error updating items';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible');                  
            }
          
        });
        $A.enqueueAction(action); 
        
   },
	
    downloadSelected : function(component, event, helper){ 
        console.log('in downloadSelected ');
        var selectedIds = component.get("v.selectedIds");
        console.log('Ids ' + selectedIds);
        if (selectedIds!='') {
            var separatedids = selectedIds.split(",");
            for (var si in separatedids) {
                console.log('Intake Item ' + separatedids[si]);
                var action = component.get("c.getDownloadFileURL");
                action.setParams({"iId" : separatedids[si]});                        
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    console.log('getFileURL Status ' + state);
                    if (state === "SUCCESS") {               
                        console.log(response.getReturnValue() );
                        var ids = response.getReturnValue();
                        if (ids!='') {
                            var separated = ids.split(",");
                            
                                for (var i in separated) {
                                    //console.log('i: ' + separated[i]);
                                    var theid = separated[i];
                                    console.log('thedocid: ' + theid);
                                    if (theid != '') {
                                        var url = '../sfc/servlet.shepherd/version/download/' + theid; 
                                        console.log('opening:' + url);
                                        window.open(url);    
                                    }
                                    
                                }  
                        }
                          
                        component.set("v.isParentChecked", false);
                    } else {
                        var message = 'There has been an error getting the file';
                        helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible');                  
                    }
                  
                });
                
                $A.enqueueAction(action);     
            }
        }
        
        var a = component.get('c.doInit');
        $A.enqueueAction(a);
        
        
   },
    
})