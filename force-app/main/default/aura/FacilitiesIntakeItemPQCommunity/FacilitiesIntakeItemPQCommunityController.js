({
    doInit : function(component, event, helper) {
        
        var action = component.get("c.getPQ");
        var res = component.get("v.res");
        action.setParams({ oppId : res });
        console.log('***getting pq for: ' + res);
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
    dosubmit:function(component, event, helper) {    
    	var allValid = component.find('pq2').reduce(function (validSoFar, inputCmp) {
             inputCmp.showHelpMessageIfInvalid();
             return validSoFar && inputCmp.get('v.validity').valid;
          }, true);
        
        //var isDateError = component.get("v.dateValidationError");
        
        var expDate = component.find("expireDate");
        var expValue = expDate.get("v.value");
        var charterDate = component.find("desirefundDate");
        var charterValue = charterDate.get("v.value");
        var openingDate = component.find("openingDate");
        var openingValue = charterDate.get("v.value");
        console.log('exp date: *' + expValue+'*');
        console.log('opening date: *' + openingValue+'*');
        console.log('charter date: *' + charterValue+'*');
        //alert('charter date: *' + charterValue+'*');
        if(expValue !=null && expValue!='' && charterValue !=null && charterValue!=''
          && openingValue !=null && openingValue!=''){
        
          if (allValid ) {
        	  var action = component.get("c.submitPQ");
                           action.setParams({
                               upsertData : JSON.stringify(component.get("v.pqForm"))
                               //oppId : component.get("v.oppId")
                           });
                           action.setCallback(this, function(response) {
                               var state = response.getState();
                                  if (state === "SUCCESS") {
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
     handleReturn: function(component, event, helper){
        var evt = $A.get("e.c:NavigateToHomePage");
        evt.fire();
    },
    
     dateUpdate : function(component, event, helper) {
        
         alert('expire component: ' + component.find("expiredate") ) ;
         var someDate = new Date(component.find("expiredate"));
         alert('expiredate: ' + someDate ) ;
         if (someDate==null) {
         	component.set("v.dateValidationError" , true);
             alert('bad date');
         }

    },
    
     openModel: function(component, event, helper) {
          component.set("v.isOpen", true);
       },

       closeModel: function(component, event, helper) {
          component.set("v.isOpen", false);
       },
    
})