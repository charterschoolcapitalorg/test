({
    doInit : function(component, event, helper) {
        
        var action = component.get("c.getPQ");
        var res = component.get("v.res");
        action.setParams({ oppId : res });
        //alert('***getting pq');
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert('***response: ' + state);
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 
                 component.set("v.pqForm", item);
                console.log(item);
            }
         });
        $A.enqueueAction(action);
         
        action = component.get("c.getStates");
        //alert('***getting states');
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
         
         action = component.get("c.getCountries");
        //alert('***getting countries');
        action.setCallback(this, function(response) {
        	var state = response.getState();
            //alert('***got countries: ' + state);
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 component.set("v.billingCountries", item);
                console.log(item);
            }
         });
         
         $A.enqueueAction(action);
         
        action = component.get("c.getRecTypes");
        //alert('***getting getRecTypes');
        action.setCallback(this, function(response) {
        	var state = response.getState();
            //alert('***got getRecTypes: ' + state);
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 component.set("v.rectypes", item);
                console.log(item);
            }
         });
         
         $A.enqueueAction(action);
        
    },
    
    doAddSchoolSuccess:function(component, event, helper) { 
        console.log(' in doAddSchoolSuccess');
        //component.set("v.addSchoolSuccess", true);
        var data = event.getParam("schools");
        // console.log(JSON.parse(JSON.stringify(data)));
        let schools = JSON.parse(JSON.stringify(data));
        // for (let index = 0; index < schools.length; index++) {
        //     const element = schools[index].CMO_Total_Enrollment__c;
        //     console.log('element ' + element);
        // }

        const enrollment = schools.map(element => element.CMO_Total_Enrollment__c).reduce((a, b) => parseInt(a) + parseInt(b), 0);

        var allValid = component.find('pq').reduce(function (validSoFar, inputCmp) {
                 inputCmp.showHelpMessageIfInvalid();
                 return validSoFar && inputCmp.get('v.validity').valid;
              }, true);
           
            //var isDateError = component.get("v.dateValidationError");
            
            var expDate = component.find("expireDate");
            var expValue = expDate.get("v.value");
            //alert('exp date: *' + expValue+'*');
            var charterDate = component.find("charterDate");
            var charterValue = charterDate.get("v.value");
            //alert('charter date: *' + charterValue+'*');
            if(expValue !=null && expValue!='' && charterValue !=null && charterValue!='' ){
            
              if (allValid ) {
                    var action = component.get("c.submitPQ");
                    let pqForm = component.get("v.pqForm");
                    pqForm["Current_number_of_enrolled_students__c"] = enrollment;
                               action.setParams({
                                   upsertData : JSON.stringify(pqForm)
                                   //oppId : component.get("v.oppId")
                               });
                               action.setCallback(this, function(response) {
                                   var state = response.getState();
                                   //alert('response from update: *' + state+'*');
                                      if (state === "SUCCESS") {
                                          component.set("v.isOpen", true);
                                          component.set("v.modalMessage", "PQ Form Successfully Submitted");
                                          component.set("v.toggleEMO", false);
                                         var evt = $A.get("e.c:NavigateToHomePage");
                                         evt.fire();
                                      }else{
                                          
                                          var errors = response.getError();
                                          var errorstr = '';
                                          if (errors) {
                                            if (errors[0] && errors[0].message) {
                                                    console.log("Error message: " + 
                                                             errors[0].message);
                                                errorstr = errors[0].message;
                                                }
                                            } else {
                                                console.log("Unknown error");
                                                errorstr = "Unknown error";
                                            }
                                          component.set("v.isOpen", true);
                                          component.set("v.modalMessage", "Unable to save the record. " + errorstr);
                                      }
    
                                });
                               $A.enqueueAction(action);
             
          
            } else {
                  component.set("v.isOpen", true);
                  component.set("v.modalMessage", "Please update the invalid form entries");
              }
          } else {
                  component.set("v.isOpen", true);
                  component.set("v.modalMessage", "Date field is Required");
              }
    },
    
    dosubmit:function(component, event, helper) { 
        var nestedcomponent= component.find("schoolinfo");
    	var resnested = nestedcomponent.childmethod(component);
        console.log('****** after calling addSchool');
        var schSuccess = expDate.get("v.addSchoolSuccess");
        console.log('****** schSuccess: ' + schSuccess);
        
        if (schSuccess) {
            
        }
    },
     handleReturn: function(component, event, helper){
        var evt = $A.get("e.c:NavigateToHomePage");
        evt.fire();
    },
    toggleEMO: function (component, event, helper) {
         console.log('*** in toggleEMO');
         var sel = component.find("hasemo");
         if (sel == null || sel=='undefined') {
             console.log('*** toggleEMO is false');
             component.set("v.toggleEMO", false);
         } else {
             var nav =	sel.get("v.value");
    		if (nav == "Yes") {     
                  component.set("v.toggleEMO", true);
             }
             else {
                component.set("v.toggleEMO", false);
             } 
		  }
        console.log('*** end of toggleEMO');
    },
    toggleApplied: function (component, event, helper) {
         console.log('in toggleApplied');
         var sel = component.find("applied");
         var nav =	sel.get("v.value");
         console.log('toggleApplied value is: ' + nav);
        
         if (nav == "Yes") {     
              component.set("v.toggleApplied", true);
         }
         else {
            component.set("v.toggleApplied", false);
         }
	 
    },
    toggleBOP: function (component, event, helper) {
         console.log('&&&& in toggleBOP');
         var sel = component.find("backoffice");
        console.log('&&&& in toggleBOP: ' + sel);
         var nav =	sel.get("v.value");
         if (nav == "Yes") {     
              component.set("v.toggleBOP", true);
         }
         else {
            component.set("v.toggleBOP", false);
         }
	 	console.log('&&&& end toggleBOP');
    },
    toggleFund: function (component, event, helper) {
         
         var sel = component.find("fund");
         var nav =	sel.get("v.value");
         console.log('toggleFund value is: ' + nav);
         if (nav == "Yes") {     
              component.set("v.toggleFund", true);
         }
         else {
            component.set("v.toggleFund", false);
         }
	 
    },
    toggleState: function (component, event, helper) {
        
        /*
         var sel = component.find("state_opt");
         var nav =	sel.get("v.value");
        
         if (nav == "CA") {     
              component.set("v.toggleCA", true);
         }
         else {
            component.set("v.toggleCA", false);
         }
	 	*/
    },
     dateUpdate : function(component, event, helper) {
        
         alert('expire component: ' + component.find("expiredate") ) ;
         var someDate = new Date(component.find("expiredate"));
         alert('expiredate: ' + someDate ) ;
         if (someDate==null) {
         	component.set("v.dateValidationError" , true);
             alert('bad date');
         }
         
         
     //var todayFormattedDate = yyyy+'-'+mm+'-'+dd;
     //   if(component.get("v.myDate") != '' && component.get("expiredate") < todayFormattedDate){
     //       component.set("v.dateValidationError" , true);
     //   }else{
     //       component.set("v.dateValidationError" , false);
     //   }
    },
    
     openModel: function(component, event, helper) {
          component.set("v.isOpen", true);
       },

       closeModel: function(component, event, helper) {
          component.set("v.isOpen", false);
       },
       toggleALL: function(component, event, helper) {
         //if(!component.get("v.firstLoad")){
  
         console.log('in toggleALL init');
         //console.log('v.pqForm.First_Name__c: ' +component.get("v.pqForm.First_Name__c"));
    	 /*
         var sel = component.find("state_opt");
         console.log('toggleALL: state_opt: ' + sel);
         var nav =	sel.get("v.value");
         console.log('toggleAll: state value is: ' + nav);
         if (nav == "CA") {     
              component.set("v.toggleCA", true);
         }
         else {
            component.set("v.toggleCA", false);
         }
         */  
         var sel = component.find("fund");
         var nav =	sel.get("v.value");
         
         if (nav == "Yes") {     
             //console.log('toggleAll:toggleFund true');
              component.set("v.toggleFund", true);
         }
         else {
             //console.log('toggleAll:toggleFund false');
            component.set("v.toggleFund", false);
         }
	 	
         var sel = component.find("backoffice");
         var nav =	sel.get("v.value");
         if (nav == "Yes") {     
             //console.log('toggleAll:toggleBOP true');
              component.set("v.toggleBOP", true);
         }
         else {
             //console.log('toggleAll:toggleBOP false');
            component.set("v.toggleBOP", false);
         }
	 
          //console.log('toggleAll:in toggleEMO');
         var sel = component.find("hasemo");
         
         if (sel == null || sel=='undefined') {
             //console.log('toggleAll: toggleEMO is false');
             component.set("v.toggleEMO", false);
         } else {
             var nav =	sel.get("v.value");
    		if (nav == "Yes") {     
                  component.set("v.toggleEMO", true);
             }
             else {
                component.set("v.toggleEMO", false);
             } 
		  } 
         //console.log('toggleAll: after toggleEMO:');
           
          // console.log('toggleAll: in toggleApplied');
         var sel = component.find("applied");
         var nav =	sel.get("v.value");
         //console.log('toggleAll: toggleApplied value is: ' + nav);
        
         if (nav == "Yes") {     
              component.set("v.toggleApplied", true);
         }
         else {
            component.set("v.toggleApplied", false);
         }
           
          // console.log('end of toggleAll:');
           //component.set("v.firstLoad", true);
         //}
       }
    
})