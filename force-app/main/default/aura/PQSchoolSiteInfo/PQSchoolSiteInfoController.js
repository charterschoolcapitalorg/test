({
    doInit: function(component, event, helper) {
       var iId = component.get("v.intakeId");
       console.log('pq oppid: ' + iId);
        
        component.set("v.intakeId",iId);
        var action = component.get("c.getAccountByIntake");
         action.setParams({
                inId : component.get("v.intakeId")
            });
        console.log('before init calls');
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('getAccountByIntake response: ' + state);
            if (state === "SUCCESS") {
                var accountResponse = response.getReturnValue();
                console.log('accountResponse: ' + accountResponse);
                //component.set("v.accountId", accountResponse);
                
                   var action_2 = component.get("c.getTableData");
                           action_2.setParams({
                                   accId : accountResponse
                           });
                       action_2.setCallback(this, function(response) {
                           var state = response.getState();
                           if (state === "SUCCESS"){
                           var items = response.getReturnValue();
                           console.log('getTableData response: ' + items);
                           component.set("v.loadedData", items);
                           component.set("v.accountId", accountResponse);
                             }
                    });
                   $A.enqueueAction(action_2);
                   
            }
        });
        $A.enqueueAction(action);
        
        action = component.get("c.getStates");
        action.setCallback(this, function(response) {
        	var state = response.getState();
            //alert('***got states: ' + state);
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 component.set("v.billingStates", item);
                console.log(item);
            }
         });
        $A.enqueueAction(action);
        
     },

    handleNewSchoolRecord:function(component, event, helper) {
         console.log('handleNewSchoolRecord');
         var items = component.get("v.loadedData");
        console.log('items: ' + items);
        /*var lastnum = 0;
        for (item i : items) {
        	lastnum = i.School_Number_From_PQ__c;    
        }
        lastnum = lastnum + 1;*/
        items.push({'School_Number_From_PQ__c':items.length + 1,'Name':'','Charter_Number__c':'', 'BillingStreet':'', 
                    'BillingState':'', 'BillingCity':'', 'BillingPostalCode':'', 
                    'CMO_Total_Enrollment__c':'0', 'Phone':''});
         component.set("v.loadedData", items);
    },

    handleSaveAndSubmit : function(component, event, helper){
        var loadData = component.get("v.loadedData");
            var flagMember = false;
            var flagCorporate = false;
            var flagContact = false;
            if(loadData.length > 0){
                
                      var allValidMember = component.find('school').reduce(function (validSoFar, inputCmp) {
                         inputCmp.showHelpMessageIfInvalid();
                         return validSoFar && inputCmp.get('v.validity').valid;
                      }, true);
                     if (allValidMember ) {
                          var action = component.get("c.setUpsertData");//TODO
                                  action.setParams({
                                            upsertData : JSON.stringify(component.get("v.loadedData")),
                                            accId : component.get("v.accountId")
                                  });
                              action.setCallback(this, function(response) {
                                     var state = response.getState();
                                     if (state === "SUCCESS") {
                                         //fire success event
                                         console.log(' firing schol success');
                                         var compEvent = component.getEvent("navigatetoParent"); //
                                         //pass school list
                                         compEvent.setParams({'schools' : loadData });
										 compEvent.fire();
                                         console.log(' after firing schol success');
                                         
                                         //var items = response.getReturnValue();
                                         //component.set("v.isOpen", true);
                                         //component.set("v.modalMessage", "Records saved Correctly!");
                                         //component.set("v.loadedData", items);

                                     }else{
                                         component.set("v.isOpen", true);
                                         component.set("v.modalMessage", "Error saving the records, please contact your Administrator.");
                                     }
                               });
                              $A.enqueueAction(action);
                  } else {
                      component.set("v.isOpen", true);
                      component.set("v.modalMessage", "Please update the invalid school entries and try again.");
                  }
                

            }else{
                component.set("v.isOpen", true);
                component.set("v.modalMessage", "Add at least one school record.");
            }



    },

    deleteSchool:function(component, event, helper) {
        var idx = event.target.id;
        var originalList = component.get("v.loadedData");
        console.log('***** deleteSchool: ' + idx);
        
        /*var toDelete;
        toDelete = originalList.filter(function(el) {
                return el.School_Number_From_PQ__c == idx;
        });
        console.log('***** deletelist: ' + toDelete.School_Number_From_PQ__c);    
        */
        
        var cleanList;
        var integer = parseInt(idx, 10);
        cleanList = originalList.filter(function(el) {
                return el.School_Number_From_PQ__c !== integer;
        });
        
        /*
        var accrecordsId;
         for(i = 0; i < accrecords.length ; i++){
               accrecordsId.push(accrecords[i].id);
         }
        */
        
        console.log('***** cleanList: ' + cleanList);    
        component.set("v.loadedData", cleanList);
        
        
        /*
        var action2 = component.get("c.setDeleteIntake");
             action2.setParams({
                 toDelete : JSON.stringify(toDelete)
             });
             action2.setCallback(this, function(response) {
                 var state = response.getState();
                    if (state === "SUCCESS") {

                }
          });
         $A.enqueueAction(action2);
		*/
    },
    
    handleReturn: function(component, event, helper){
        var evt = $A.get("e.c:NavigateToHomePage");
        evt.fire();
    },

    handleSubmit: function(component, event, helper){
        var action = component.get("c.submitStatus");
         action.setParams({
                iiId : component.get("v.intakeId")
            });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                    component.set("v.isOpen", true);
                    component.set("v.modalMessage", "Submitted.");
            }else{
                    component.set("v.isOpen", true);
                    component.set("v.modalMessage", "There was an error submitting please try again.");
            }
        });
        $A.enqueueAction(action);
    },

       openModel: function(component, event, helper) {
          component.set("v.isOpen", true);
       },

       closeModel: function(component, event, helper) {
          component.set("v.isOpen", false);
       }

})