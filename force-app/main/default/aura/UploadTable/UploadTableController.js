({
    doInit : function(component, event, helper){
        //var selectedOptionValue = component.find("daterangeselect").get("v.value");
        //console.log('Default Filter:' + selectedOptionValue);
        var currDateValue = component.get("v.currDateValue");
        console.log('currDateValue in init: ' + currDateValue);
        helper.loadIntakeItems(component,event,currDateValue);
        
    },
    handleChange : function (component, event, helper) {
        var selectedOptionValue = event.getParam("value");
        console.log('Updated Filter:' + selectedOptionValue);
        component.set("v.currDateValue", selectedOptionValue);
        //helper.helperMethod(component,event,selectedOptionValue);
        component.set("v.itemHasRedFlag", false);
        helper.loadIntakeItems(component,event,selectedOptionValue);
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
                helper.showUploadInfoToast(component, event, fileNames);  
                console.log("File Names: " + fileNames);
                component.set("v.fileNames", fileNames);
            }            
        });
        $A.enqueueAction(action);  
        
        console.log('***** reinit');
        var a = component.get('c.doInit');
        $A.enqueueAction(a);
        console.log('***** end of reinit');
        //helper.loadIntakeItems(component,event,"45");
    },
    handleClose : function(component, event, helper){
        var overlay = component.find("overlayLib");
        console.log('Overlay: '+ overlay);
        component.find("overlayLib").notifyClose();
    },
    handleDocUploaded: function (cmp, event, helper) {
         console.log('***** in handleDocUploaded of UploadTableController');
        var a = cmp.get('c.doInit');
        $A.enqueueAction(a);
        
        console.log('***** end of handleDocUploaded of of UploadTableController');
    },
    handleRedFlag: function (cmp, event, helper) {
         console.log('***** got redflag event');
        cmp.set("v.itemHasRedFlag", true);
        
    },
   
})