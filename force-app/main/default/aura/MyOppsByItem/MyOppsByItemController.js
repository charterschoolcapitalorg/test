({
	doInit : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        if(intakeItem.Is_Ongoing__c) {
            component.set("v.accountName", intakeItem.Account_Name__r.Name);
        } else {
            component.set("v.accountName", intakeItem.Opportunity__r.Account.Name);
        }
        console.log('***** MyOppsByItem - v.accountName: ' + component.get("v.accountName"));
        var action = component.get("c.getIntakeItemClientComments");
        action.setParams({"iId" : intakeItem.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.intakeItemCC", response.getReturnValue());
            } else {
                var message = 'There has been an error getting the intake item';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
            }
        });
        $A.enqueueAction(action);
       
        action = component.get("c.getNumDocs");
        action.setParams({"iId" : intakeItem.Id});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.numDocsAvail", response.getReturnValue());
            } else {
                var message = 'There has been an error getting number of files';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
            }
        });
        
        $A.enqueueAction(action);  
	},
    refresh : function(component, event, helper) {
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
                
        action = component.get("c.getIntakeItemClientComments");
        action.setParams({"iId" : intakeItem.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.intakeItemCC", response.getReturnValue());
            } else {
                var message = 'There has been an error getting the intake item';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
            }
        });
        $A.enqueueAction(action);
        
        
        action = component.get("c.getNumDocs");
        action.setParams({"iId" : intakeItem.Id});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.numDocsAvail", response.getReturnValue());
            } else {
                var message = 'There has been an error getting number of files';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
            }
        });
        
        $A.enqueueAction(action);  
	},
    fireWorkingGroups: function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var idx = intakeItem.Id;
        
        var evt = $A.get("e.c:NavigateToWorkingGroup");
        evt.setParams({ "result": idx});
        evt.fire();
     },
    //the PQ component
    fireEvent : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var idx = intakeItem.Id;
        var evt = $A.get("e.c:NavigateToC2");
        evt.setParams({ "result": idx});
        evt.fire();
    },
    
     //the FacilitiesPQ component
     fireFacEvent : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var idx = intakeItem.Id;
        var evt = $A.get("e.c:NavigateToFacPQ");
        evt.setParams({ "result": idx});
        evt.fire();
     },

    nochanges : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.noChanges");
        
        action.setParams({"iId" : intakeItem.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                var a = component.get('c.refresh');
                $A.enqueueAction(a);    
            } else {
                var message = 'There has been an error updating this comment';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
            }
        });
        
        $A.enqueueAction(action);  
	},
    openComments : function(component, event, helper){
        var intakeItem = component.get("v.intakeItem");
        var spinner = component.find("modalWait");
        var header = "Add Comment for " + intakeItem.Client_Facing_Item_Name__c;
        var modalBody;
        var modalHeader;

        $A.createComponents([ ["c:ClientComments", {intakeItem: intakeItem}], ["c:UploadTableHeader", {title : header}] ],
           function(components, status) {
               if (status === "SUCCESS") {
                   
                   modalBody = components[0];
                   modalHeader = components[1];
                   component.find('overlayLib').showCustomModal({
                       header: modalHeader,
                       body: modalBody, 
                       showCloseButton: true,
                       //cssClass: "slds-modal_large",
                       //slds-modal_medium
                       closeCallback: function() {
                            var a = component.get('c.refresh');
                            $A.enqueueAction(a);
                       }
                   });
               }                               
           });
    },
    openItemDetail : function(component, event, helper){
        var intakeItem = component.get("v.intakeItem");
        var spinner = component.find("modalWait");
        var header = "Item Details for " + intakeItem.Client_Facing_Item_Name__c;
        var modalBody;
        var modalHeader;
        $A.createComponents([ ["c:ItemDetails", {intakeItem: intakeItem}], ["c:UploadTableHeader", {title : header}] ],
           function(components, status) {
               if (status === "SUCCESS") {
                   
                   modalBody = components[0];
                   modalHeader = components[1];
                   component.find('overlayLib').showCustomModal({
                       header: modalHeader,
                       body: modalBody, 
                       showCloseButton: true,
                       //cssClass: "slds-modal_small",
                       //slds-modal_medium mymodal
                       closeCallback: function() {
                       }
                   });
               }                               
           });
    },
    
    reviewfile : function (component, event, helper){ 
        var intakeItem = component.get("v.intakeItem");
        var status = intakeItem.Status__c;
        var aUrl = component.get("v.intakeItem.Action_URL__c");
        var canApprove = (aUrl=='Edit Item Details' && status!='Accepted' && status!='Submitted');
        
        var spinner = component.find("modalWait");
        var header = "File Preview for " + intakeItem.Client_Facing_Item_Name__c;
        var modalBody;
        var modalHeader;
        
        $A.createComponents([ ["c:FilesPreviewComponent", {intakeItem: intakeItem, hasApprove: canApprove}], ["c:UploadTableHeader", {title : header}] ],
           function(components, status) {
               if (status === "SUCCESS") {
                   
                   modalBody = components[0];
                   modalHeader = components[1];
                   component.find('overlayLib').showCustomModal({
                       body: modalBody, 
                       showCloseButton: true,
                       header: modalHeader,
                       //cssClass: "slds-modal_xlarge",
                       //cssClass: "mymodal slds-modal_large",
                       closeCallback: function() {
                           var a = component.get('c.refresh');
                            $A.enqueueAction(a);
                       }
                   });
               }                               
           });
        
    },
    
    downloadfile : function (component, event, helper){ 
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.getDownloadFileURL");
        action.setParams({"iId" : intakeItem.Id});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var ids = response.getReturnValue();
                if (ids!='') {
                    var separated = ids.split(",");
                	for (var i in separated) {
                            var theid = separated[i];
                            if (theid != '') {
                            	var url = '../sfc/servlet.shepherd/version/download/' + theid; 
                                window.open(url);    
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
    
    handleParentUnCheck : function(component, event) {   

        var v = component.get("v.isChecked");
        var intakeItem = component.get("v.intakeItem");
        
        if (intakeItem.Name===event.getParam("parentId")) {
            component.set('v.isChecked', false);
            
            var rowEvent = component.getEvent("rowEvent");
            rowEvent.setParams({"recordId" : intakeItem.Id, "checked" : false});
            rowEvent.fire();
            var fUpload = component.find("singleFileUpload");
            if (fUpload!=null) { fUpload.set("v.disabled", false); }
        }
        
    },
    
    handleParentCheck : function(component, event) {   
        
        var v = component.get("v.isChecked");
        var intakeItem = component.get("v.intakeItem");
        
        if (intakeItem.Name===event.getParam("parentId")) {
            component.set('v.isChecked', true);
            
            var rowEvent = component.getEvent("rowEvent");
            rowEvent.setParams({"recordId" : intakeItem.Id, "checked" : true});
            rowEvent.fire();
            var fUpload = component.find("singleFileUpload");
            if (fUpload!=null) { fUpload.set("v.disabled", true); }
        }
        
    },
    
	handleCheck : function(component, event, helper) { 
            var intakeItem = component.get("v.intakeItem");
            var rowEvent = component.getEvent("rowEvent");
        	component.set("v.selectedId", intakeItem.Id);
            var ischecked = component.get('v.isChecked');
            rowEvent.setParams({"recordId" : intakeItem.Id, "checked" : ischecked});
            rowEvent.fire();
            var fUpload = component.find("singleFileUpload");
            if (fUpload!=null) { 
                fUpload.set("v.disabled", ischecked); 
            }
    	
	},
    approveStatus : function(component, event, helper){ 
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.acceptedStatus");
        action.setParams({"iiId" : intakeItem.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.intakeItem", response.getReturnValue());
                var message = 'Status has been approved for ' + intakeItem.item.Name;
                helper.showToast('Status Approved', message, '4000', 'info_alt', 'success', 'dismissible');                  
            } else {
                var message = 'There has been an error updating status for ' + intakeItem.item.Name;
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible');                  
            }
          
        });
        $A.enqueueAction(action); 
    },
    handleSingleUploadFinished : function(component, event, helper){
        var selectedIds = component.get("v.selectedIds");
        var uploadedFiles = event.getParam("files");
        var myEvent = component.getEvent("docUploaded");
        myEvent.fire();
        var myEvent = component.getEvent("docUploadedToTop");
        myEvent.fire();
        
        helper.showUploadInfoToast(component, event, uploadedFiles[0].name);
    },
    FireOppEvent : function(component, event, helper) {
      var idx = event.currentTarget.getAttribute("id");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/itemdetail?res='+idx,
          "res": idx
        });
        urlEvent.fire();
     },
})