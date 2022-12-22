({
    init : function(component, event, helper) {
        var action = component.get("c.getFiles");
        var intakeItem = component.get("v.cpi");
        
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
    setSelectedIds : function(component, event, helper){
        var recordIds = event.getParam("recordIds");
        var checked = event.getParam("checked");
        var bulkDisable = component.get("v.bulkDisable");
        
        component.set("v.selectedIds", recordIds);
        component.set("v.selectedIdsArray", recordIds);
    },
    
    openDocument: function(component, event, helper){
        //console.log('in save');
        //var leaseCompliance = component.get("v.pt");
        var url = '../sfc/servlet.shepherd/version/download/' + theid; 
        window.open(url); 
    },
    
    openPropertyTax: function(component, event, helper){
        var propertyTax = component.get("v.pt");
        var win = window.open('/' + propertyTax.Id, '_blank');
        win.focus();
    },
     
    save: function(component, event, helper){
        console.log('in save property tax');
        let itemMapped = component.find("mappropertytax").get("v.checked");
        //console.log('cb = ' + component.find("mappropertytax").get("v.checked"));
        //console.log('itemMapped = ' + itemMapped);
        if(itemMapped){
            var propertyTax = component.get("v.pt");
            var intakeItem = component.get("v.cpi");
            var selIds = component.get("v.selectedIdsArray").join(",");
            var action = component.get("c.savePropertyTax");
            var CSCComment = '';
            var copyClientComment = '';
            var paidAmount = component.find("cpamount").get("v.value");
            var paidDate = component.find("cpdate").get("v.value");

            try {
                CSCComment = component.find("includecsccomment").get("v.value");
            } catch (e) {console.log('exception: ' + e);}
                
            action.setParams({
                iId : intakeItem.Id,
                ptId : propertyTax.Id,
                copyClientComment : component.find("includecomment").get("v.checked"),
                //copyClientComment : copyClientComment,
                CSCComment : CSCComment,
                fileIds : selIds,
                paidAmount : paidAmount,
                paidDate : paidDate
            });
            
            //execute save
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

            //requiredCheck(paidAmount, paidDate);

            //console.log('@@@ paidDate = '+component.find("cpdate").get("v.value"));
            
        //  try {
        //      CSCComment = component.find("includecsccomment").get("v.value");
        //      // createFinance =  component.find("createfinancial").get("v.checked");
        //      //console.log('createFinance = ' + createFinance);
        //  } catch (e) {console.log('exception: ' + e);}
            
            
        }
    },
 
    updatePT: function(cmp){
        // console.log('before: ' + cmp.get("v.updateLC"));
        cmp.set("v.updatePT", !cmp.get("v.updatePT"));
        // console.log('after: ' + cmp.get("v.updateLC"));
    },
})