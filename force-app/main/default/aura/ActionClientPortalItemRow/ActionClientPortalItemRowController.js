({
	init : function(component, event, helper) {
        var action = component.get("c.getFiles");
        var action1 = component.get("c.getActionItem");
        var action2 = component.get('c.getIntakeItem');
        var intakeItem = component.get("v.cpi");
        var actionItem = component.get("v.ai");
        var isODRecordType = false;
        
        action.setParams({ theid : intakeItem.Id });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                component.set("v.allFiles", item);
                component.set("v.selectedFiles", item);
                var count = 0;
                var i;
                var fileids = new Array();
                
                for (var i=0; i<item.length; i++) {
                    //console.log('file : ' + item[i].Id);
                    fileids.push(item[i].Id);
                    count++;
                }
                component.set("v.numFiles", count);
                
                //default mapped files to ALL files
        		component.set("v.selectedIdsArray", fileids);
                component.set("v.selectedIds", fileids.join(","));
            }
        });

        action2.setParams({ iId : intakeItem.Id });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                if(item.Opportunity__c !== undefined) {
                    console.log('@@@ This is an Opportunity @@@');
                    isODRecordType = true;
                }
            }
        });

        action1.setParams({ aiId : actionItem.Id });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                if(item[0].CSC_Action_List__r.Account__r.Charter_Holder__c !== undefined 
                    && isODRecordType === false
                    && (item[0].CSC_Action_List__r.Account__r.Charter_Holder__r.Legal_Assistant__c === undefined 
                    || item[0].CSC_Action_List__r.Account__r.Charter_Holder__r.Legal_Assistant__c === null)) {
                        component.set('v.warningShow', true);
                }
            }
        });

        $A.enqueueAction(action);
        $A.enqueueAction(action2);
        $A.enqueueAction(action1);
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
    setSelectedIds : function(component, event, helper){
        var recordIds = event.getParam("recordIds");
        var checked = event.getParam("checked");
        var bulkDisable = component.get("v.bulkDisable");
        
        component.set("v.selectedIds", recordIds);
        component.set("v.selectedIdsArray", recordIds);
        
    },
    
    openDocument: function(component, event, helper){
        //console.log('in save');
        var actionItem = component.get("v.ai");
        var url = '../sfc/servlet.shepherd/version/download/' + theid; 
        window.open(url); 
    },
    
    openActionItem: function(component, event, helper){

        var actionItem = component.get("v.ai");
        var win = window.open('/' + actionItem.Id, '_blank');
  		win.focus();
    },
    
    save: function(component, event, helper){
        console.log('in save');
        var actionItem = component.get("v.ai");
        var intakeItem = component.get("v.cpi");
        
        var params = event.getParam('arguments');
        if (params) {
            var status;// = params.status;
            status = component.find("status").get("v.value");
            console.log('status: ' + status);
        }
        
        var selIds = component.get("v.selectedIdsArray").join(",");
        var action = component.get("c.saveActionItem");
        
        var CSCComment = '';
        var expDate = '';
        var effDate = '';
        var naDate = '';
        var cpDate = '';
		var createFinance = '';
        
        try {
        	CSCComment = component.find("includecsccomment").get("v.value");
            effDate = component.find("effdate").get("v.value");
            naDate = component.find("nadate").get("v.value");
            cpDate = component.find("cpdate").get("v.value");
            expDate = component.find("expdate").get("v.value");
            createFinance =  component.find("createfinancial").get("v.checked");
            
            console.log('createFinance: ' + createFinance);
        } catch (e) {console.log('exception: ' + e);}
        
        action.setParams({ iId : intakeItem.Id, aId : actionItem.Id, status : status, 
            fileIds : selIds, copyClientComment : component.find("includecomment").get("v.checked"),
                          CSCComment : CSCComment,  effDate : effDate, expDate : expDate, naDate : naDate, cpDate : cpDate, createFinance : createFinance});

        //console.log('Firing for action id: ' + actionItem.Id);
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
            	window.location.href='/' + intakeItem.Id;
            } else {
                console.log('******ERROR for id: ' + intakeItem.Id);
                
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                 errors[0].message);
                    }
                    component.set("v.Spinner", false);
                    var message = 'There has been an error saving the action item: ' + errors[0].message;
                    
            		helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
        			
                } else {
                    var message = 'There has been an error saving the action item';
            		helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible'); 
                }

            }
        });
        $A.enqueueAction(action);
        
    }

    

})