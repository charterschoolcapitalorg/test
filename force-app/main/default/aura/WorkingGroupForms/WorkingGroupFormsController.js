/**
 * Created by Ivan Garcia on 4/3/2018.
 */
({
    doInit: function(component, event, helper) {
        var iId = component.get("v.intakeId");
    //    console.log('iId: ' + iId);
        
        component.set("v.intakeId",iId);
        var action = component.get("c.getAccountByIntake");
        action.setParams({
            inId : component.get("v.intakeId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var accountResponse = response.getReturnValue();
                let accountId = accountResponse["Opportunity__r"]["AccountId"];
                let opportunityId = accountResponse["Opportunity__c"];
                let oppState = accountResponse["Opportunity__r"]["STATE__c"];
                var action_2 = component.get("c.getTableData");
                action_2.setParams({
                        accId : accountId
                });
                action_2.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS"){
                        var items = response.getReturnValue();
                        component.set("v.loadedData", items);
                        component.set("v.accountId", accountId);
                        component.set("v.opportunityId", opportunityId);
                        component.set("v.accountState", oppState);
                    }
                });
                $A.enqueueAction(action_2);
            }
        });
        $A.enqueueAction(action);
        
        var action = component.get("c.getBoardPositions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                component.set("v.boardpositions", item);
                // console.log(item);
            }
         });
        $A.enqueueAction(action);
        
        var action = component.get("c.getCorporatePositions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                component.set("v.corporatepositions", item);
                // console.log(item);
            }
         });
        $A.enqueueAction(action);

        var action = component.get("c.getGoverningPositions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                component.set("v.governingpositions", item);
                // console.log(item);
            }
         });
        $A.enqueueAction(action);

        var action = component.get("c.getAdministratorPositions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var item = response.getReturnValue();
                component.set("v.administratorpositions", item);
                // console.log(item);
            }
         });
        $A.enqueueAction(action);

     },

    handleNewMemberRecord:function(component, event, helper) {
         var items = component.get("v.loadedData");
         items.push({'Position__c':'Position '+items.length, 'Board_Member__c':true});
         component.set("v.loadedData", items);
    },

    handleNewGoverningBody:function(component, event, helper) {
         var items = component.get("v.loadedData");
         items.push({'Position__c':'Position '+items.length, 'Governing_Body__c':true});
         component.set("v.loadedData", items);
    },

    handleNewCorporateRecord:function(component, event, helper) {
         var items = component.get("v.loadedData");
         items.push({'Title__c':'Title '+items.length, 'Corporate_Officer__c':true});
         component.set("v.loadedData", items);
    },

    handleNewAdministratorRecord:function(component, event, helper) {
        let items = component.get("v.loadedData");
        items.push({'Role__c':'Role '+items.length, 'School_Administrator__c':true});
        component.set("v.loadedData", items);
    },

    handleNewContactRecord:function(component, event, helper) {
         var items = component.get("v.loadedData");
         items.push({'Name':'Last Name '+items.length,'Legal_Contact__c':true});
         component.set("v.loadedData", items);
    },

    // handleSaveAndSubmit : function(component, event, helper){
    //     var loadData = component.get("v.loadedData");
    //     // console.log('loadData ', loadData);
    //     let state = component.get("v.accountState");
    //     var flagMember = false;
    //     var flagCorporate = false;
    //     var flagContact = false;
    //     var flagGoverning = false;
    //     var flagAdministrator = false;
    //     // let dataupload = {};
    //     if(loadData.length > 0){
    //         for(var i=0; i<loadData.length; i++){
    //             // console.log('loadData[i].Name ', loadData[i]);
    //                     if(loadData[i].Board_Member__c == true){
    //                         flagMember = true;
    //                         // dataupload[i] = loadData[i];
    //                     }
    //                     if(loadData[i].Corporate_Officer__c == true){
    //                         flagCorporate = true;
    //                         // dataupload[i] = loadData[i];
    //                     }
    //                     if(loadData[i].Legal_Contact__c == true){
    //                         flagContact = true;
    //                         // dataupload[i] = loadData[i];
    //                     }
    //                     if(loadData[i].School_Administrator__c == true){
    //                         flagAdministrator = true;
    //                         // dataupload[i] = loadData[i];
    //                     }
    //                     if(loadData[i].Governing_Body__c == true){
    //                         flagGoverning = true;
    //                         // dataupload[i] = loadData[i];
    //                     }
    //                 }
    //         // console.log('flagged');
    //         // console.log('flagGoverning ', flagGoverning);
    //         // console.log(flagMember, flagCorporate, flagContact);
    //         if(flagMember == true && flagCorporate == true && flagContact == true && flagAdministrator == true){
    //             // console.log('dataUpload ', dataUpload);
    //               var allValidMember = component.find('Member').reduce(function (validSoFar, inputCmp) {
    //                  inputCmp.showHelpMessageIfInvalid();
    //                  return validSoFar && inputCmp.get('v.validity').valid;
    //               }, true);
    //               var allValidCorporate = component.find('Corporate').reduce(function (validSoFar, inputCmp) {
    //                  inputCmp.showHelpMessageIfInvalid();
    //                  return validSoFar && inputCmp.get('v.validity').valid;
    //               }, true);
    //               var allValidContact = component.find('Contact').reduce(function (validSoFar, inputCmp) {
    //                  inputCmp.showHelpMessageIfInvalid();
    //                  return validSoFar && inputCmp.get('v.validity').valid;
    //               }, true);
    //               var allValidAdministrator = component.find('Administrator').reduce(function (validSoFar, inputCmp) {
    //                  inputCmp.showHelpMessageIfInvalid();
    //                  return validSoFar && inputCmp.get('v.validity').valid;
    //               }, true);
    //               var allValidGoverning = false;
    //               if(flagGoverning){
    //                 allValidGoverning = component.find('Governing').reduce(function (validSoFar, inputCmp) {
    //                     inputCmp.showHelpMessageIfInvalid();
    //                     return validSoFar && inputCmp.get('v.validity').valid;
    //                 }, true);
    //               }
    //               if(flagGoverning === false && state !== 'AZ'){
    //                 allValidGoverning = true;
    //               }
                  
    //              if (allValidMember && allValidCorporate && allValidContact && allValidGoverning && allValidAdministrator) {
    //                   var action = component.get("c.setUpsertData");//TODO
    //                           action.setParams({
    //                                     //upsertData : JSON.stringify(dataupload),
    //                                     upsertData : JSON.stringify(component.get("v.loadedData")),
    //                                     accId : component.get("v.accountId"),
    //                                     oppId : component.get("v.opportunityId")
    //                           });
    //                       action.setCallback(this, function(response) {
    //                              var state = response.getState();
    //                              if (state === "SUCCESS") {
    //                                  var items = response.getReturnValue();
    //                                  component.set("v.isOpen", true);
    //                                  component.set("v.modalMessage", "Records saved Correctly!");
    //                                  component.set("v.loadedData", items);

    //                                  var action2 = component.get("c.submitStatus");
    //                                           action2.setParams({
    //                                                  iiId : component.get("v.intakeId")
    //                                              });
    //                                          action2.setCallback(this, function(response) {
    //                                              var state = response.getState();
    //                                              if (state === "SUCCESS") {

    //                                                 var action3 = component.get("c.handleReturn");
    //                                                      $A.enqueueAction(action3);

    //                                              }else{
    //                                                      component.set("v.isOpen", true);
    //                                                      component.set("v.modalMessage", "There was an error submitting please try again.");
    //                                              }
    //                                          });
    //                                          $A.enqueueAction(action2);

    //                              }else{
    //                                  component.set("v.isOpen", true);
    //                                  component.set("v.modalMessage", "Error saving the records, please contact your Administrator.");
    //                              }
    //                        });
    //                       $A.enqueueAction(action);
    //           } else {
    //               component.set("v.isOpen", true);
    //               component.set("v.modalMessage", "Please update the invalid form entries and try again.");
    //           }
    //         }else{
    //             component.set("v.isOpen", true);
    //             component.set("v.modalMessage", "Add at least one of each record.");
    //         }

    //     }else{
    //         component.set("v.isOpen", true);
    //         component.set("v.modalMessage", "Add at least one of each record.");
    //     }



    // },

    deleteBoardMember:function(component, event, helper) {
        var idx = event.target.id;
        // console.log('idx' + idx);
        var originalList = component.get("v.loadedData");

        var toDelete;
        toDelete = originalList.filter(function(el) {
                return el.Position__c == idx;
        });
        var cleanList;
        cleanList = originalList.filter(function(el) {
                return el.Position__c !== idx;
        });
        component.set("v.loadedData", cleanList);

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

    },

    deleteCorporate:function(component, event, helper) {
        var idx = event.target.id;
        var originalList = component.get("v.loadedData");
        var toDelete;
        toDelete = originalList.filter(function(el) {
                return el.Title__c == idx;
        });

        var cleanList;
        cleanList = originalList.filter(function(el) {
                return el.Title__c !== idx;
        });
        component.set("v.loadedData", cleanList);
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
    },

    deleteAdministrator:function(component, event, helper) {
        var idx = event.target.id;
        var originalList = component.get("v.loadedData");
        var toDelete;
        toDelete = originalList.filter(function(el) {
                return el.Role__c == idx;
        });

        var cleanList;
        cleanList = originalList.filter(function(el) {
                return el.Role__c !== idx;
        });
        component.set("v.loadedData", cleanList);
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
    },

    deleteContact:function(component, event, helper) {
        var idx = event.target.id;
        var originalList = component.get("v.loadedData");
        var toDelete;
        toDelete = originalList.filter(function(el) {
                return el.Name == idx;
        });

        var cleanList;
        cleanList = originalList.filter(function(el) {
                return el.Name !== idx;
        });
        component.set("v.loadedData", cleanList);
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
    },

    handleDeleteMember: function(component, event, helper){
        const record = event.getParam('record')
        //console.log('event is: ' + record);
        const records = component.get("v.loadedData");
        const member = records.splice(record, 1);
        component.set("v.loadedData", records);
        helper.deleteMember(component, member);
    },

    handleSaveAndSubmitUpdated : function(component, event, helper){
        var loadData = component.get("v.loadedData");
        let goodData = [];
        if(loadData.length > 0){
            // for(var i=0; i<loadData.length; i++){
            //     if(loadData[i].Name){
            //         goodData.push(loadData[i]);
            //     }
            // }
            goodData = loadData.filter(data => data.Name);
            component.set("v.goodData", goodData);
            // console.log('loadData ' + JSON.stringify(loadData));
            // console.log('goodData ' + JSON.stringify(goodData));           
            var action = component.get("c.setUpsertData");//TODO
            action.setParams({
                    upsertData : JSON.stringify(component.get("v.goodData")),
                    accId : component.get("v.accountId"),
                    oppId : component.get("v.opportunityId")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var items = response.getReturnValue();
                    component.set("v.isOpen", true);
                    component.set("v.modalMessage", "Contact information submitted, thank you!");
                    component.set("v.goodData", items);
                    component.set("v.loadedData", items);

                    var action2 = component.get("c.submitStatus");
                            action2.setParams({
                                    iiId : component.get("v.intakeId")
                                });
                            action2.setCallback(this, function(response) {
                                var state = response.getState();
                                if (state === "SUCCESS") {

                                /*var action3 = component.get("c.handleReturn");
                                        $A.enqueueAction(action3);*/

                                }else{
                                        component.set("v.isOpen", true);
                                        component.set("v.modalMessage", "There was an error submitting please try again.");
                                }
                            });
                            $A.enqueueAction(action2);

                }else{
                    component.set("v.isOpen", true);
                    component.set("v.modalMessage", "Error saving the records, please contact your Administrator.");
                }
            });
            $A.enqueueAction(action);



        }else{
            component.set("v.isOpen", true);
            component.set("v.modalMessage", "Add at least one of each record.");
        }



    },

})