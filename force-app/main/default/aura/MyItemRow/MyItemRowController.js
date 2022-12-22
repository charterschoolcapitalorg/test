({
        doInit : function(component, event, helper){   
        var intakeItem = component.get("v.intakeItem");
        var onlyOpp = component.get("v.isOnlyOpp"); 
        if (onlyOpp) {
           component.set("v.showList",true);
        }       
        var action = component.get("c.getIntakeItems");
        
        helper.getFundRecType(component, event);
        helper.getFacRecType(component, event); 
        helper.get5DFRecType(component, event); 
        
        action = component.get("c.getIntakeItemClientComments");
        action.setParams({"iId" : intakeItem.item.Id});
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
        action.setParams({"iId" : intakeItem.item.Id});
        
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
    
    refreshIntakeItemWrapper : function(component, event, helper){
    	var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.getIntakeItemWrapper");
        action.setParams({"iId" : intakeItem.item.Id});
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
        
    openItemDetail : function(component, event, helper){
        var intakeItem = component.get("v.intakeItem");
        var spinner = component.find("modalWait");
        var header = "Item Details for " + intakeItem.item.Client_Facing_Item_Name__c;
        var modalBody;
        var modalHeader;
        
        $A.createComponents([ ["c:ItemDetails", {intakeItem: intakeItem.item}], ["c:UploadTableHeader", {title : header}] ],
           function(components, status) {
               if (status === "SUCCESS") {
                   modalBody = components[0];
                   modalHeader = components[1];
                   component.find('overlayLib').showCustomModal({
                       header: modalHeader,
                       body: modalBody, 
                       showCloseButton: true,
                       //cssClass: "slds-modal_small",
                       closeCallback: function() {
                           //alert('You closed the alert!');
                       }
                   });
               }                               
           });
    },
    
    reviewfile : function (component, event, helper){ 
        var intakeItem = component.get("v.intakeItem");
        var aUrl = intakeItem.item.Action_URL__c;
        var status = intakeItem.item.Status__c;
        var canApprove = (aUrl=='Edit Item Details' && status!='Accepted' && status!='Submitted');
        
        var spinner = component.find("modalWait");
        var header = "File Preview for " + intakeItem.item.Client_Facing_Item_Name__c;
        var modalBody;
        var modalHeader;
        
        $A.createComponents([ ["c:FilesPreviewComponent", {intakeItem: intakeItem.item, hasApprove: canApprove}], ["c:UploadTableHeader", {title : header}] ],
           function(components, status) {
               if (status === "SUCCESS") {
                   modalBody = components[0];
                   modalHeader = components[1];
                   component.find('overlayLib').showCustomModal({
                       body: modalBody, 
                       showCloseButton: true,
                       header: modalHeader,
                       //cssClass: "mymodal slds-modal_large",
                       //cssClass: "slds-modal_xlarge",
                       closeCallback: function() {
                           var a = component.get('c.doInit');
                            $A.enqueueAction(a);
                           var b = component.get('c.refreshIntakeItemWrapper');
                            $A.enqueueAction(b);
                       }
                   });
               }                               
           });
        
    },
    
    downloadfile : function (component, event, helper){ 
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.getDownloadFileURL");
        action.setParams({"iId" : intakeItem.item.Id});
        
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
    
	nochanges : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.noChanges");
        
        action.setParams({"iId" : intakeItem.item.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                var b = component.get('c.refreshIntakeItemWrapper');
        		$A.enqueueAction(b);
                        
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
        var header = "Add Comment for " + intakeItem.item.Client_Facing_Item_Name__c;
        var modalBody;
        var modalHeader;
        
        $A.createComponents([ ["c:ClientComments", {intakeItem: intakeItem.item}], ["c:UploadTableHeader", {title : header}] ],
           function(components, status) {
               if (status === "SUCCESS") {
                   modalBody = components[0];
                   modalHeader = components[1];
                   component.find('overlayLib').showCustomModal({
                       header: modalHeader,
                       body: modalBody, 
                       showCloseButton: true,
                       //cssClass: "slds-modal_large",
                       closeCallback: function() {
                          var a = component.get('c.doInit');
                          $A.enqueueAction(a);
                          var b = component.get('c.refreshIntakeItemWrapper');
                          $A.enqueueAction(b);
                       }
                   });
               }                               
           });
    },
    toggleSection : function(component, event, helper){
        var source = event.getSource();  
        var iconName = source.get("v.iconName");
     
        if(iconName == "utility:add"){
            source.set("v.iconName", "utility:dash");
            component.set("v.showList", true);
            component.set("v.isRendered", true);
            var myRow = component.find("myRow");
            if ($A.util.isArray(myRow)) {
                for(var i = 0; i < myRow.length; i++){
                    if(i == 0){
                       $A.util.addClass(myRow[i], "isExpandedLeft");
                    } else {
                       $A.util.addClass(myRow[i], "isExpanded");
                    }
                    if(i == (myRow.length - 1)){
                        $A.util.addClass(myRow[i], "isExpandedRight");
                    }
                }
            }       
        } else {
            source.set("v.iconName", "utility:add");
            component.set("v.showList", false); 
            component.set("v.parentId", null);
            var myRow = component.find("myRow");
            if ($A.util.isArray(myRow)) {
                for(var i = 0; i < myRow.length; i++){
                    if(i == 0){
                       $A.util.removeClass(myRow[i], "isExpandedLeft");
                    } else {
                       $A.util.removeClass(myRow[i], "isExpanded");
                    }
                    if(i == (myRow.length - 1)){
                        $A.util.removeClass(myRow[i], "isExpandedRight");
                    }
                }
            }                     
        }
    },
    
    fireDetailEvent : function(component, event, helper) {      
        var intakeItem = component.get("v.intakeItem");
        var idx = intakeItem.item.Id;
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/itemdetail?res='+idx,
          "res": idx
        });
        urlEvent.fire();
    },
    
    approveStatus : function(component, event, helper){            
        var intakeItem = component.get("v.intakeItem");
        var action = component.get("c.acceptedStatus");
        action.setParams({"iiId" : intakeItem.item.Id});
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
    //the PQ component
    fireEvent : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var idx = intakeItem.item.Id;
        var evt = $A.get("e.c:NavigateToC2");
        evt.setParams({ "result": idx});
        evt.fire();
    },
    
     //the FacilitiesPQ component
     fireFacEvent : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var idx = intakeItem.item.Id;
        var evt = $A.get("e.c:NavigateToFacPQ");
        evt.setParams({ "result": idx});
        evt.fire();
     },
    
     fireDetailEvent : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var idx = intakeItem.item.Id;
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/itemdetail?res='+idx,
          "res": idx
        });
        urlEvent.fire();
     },
    
    fireWorkingGroups: function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        var idx = intakeItem.item.Id;
        var evt = $A.get("e.c:NavigateToWorkingGroup");
        evt.setParams({ "result": idx});
        evt.fire();
     },
    handleUploadFinished: function (cmp, event) {
        cmp.set("v.showList", true);
        cmp.set("v.isRendered", true);
        var b = cmp.get('c.refreshIntakeItemWrapper');
        $A.enqueueAction(b);
        
        
    },
    handleDocUploaded: function (cmp, event, helper) {
        
        cmp.set("v.showList", true);
        cmp.set("v.isRendered", true);
        
        var a = cmp.get('c.doInit');
        $A.enqueueAction(a);
        
    },
       
})