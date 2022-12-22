/**
 * Created by Ivan Garcia on 3/26/2018.
 */
({
	downloadfile : function (component, event, helper){  
    var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      "url": 'https://cscfull-charterschoolcapitalportal.cs54.force.com/sfc/servlet.shepherd/version/download/0680g000006E4TiAAK/0680S0000006whpQAA?'
    });
    urlEvent.fire();
    
    urlEvent.setParams({
      "url": 'https://cscfull-charterschoolcapitalportal.cs54.force.com/sfc/servlet.shepherd/version/download/0680S0000006whpQAA'
    });
    urlEvent.fire();
    
    },
        
    doInit: function(component, event, helper) {
        helper.loadSections(component);

        var action = component.get("c.getClosedOpportunities");
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                 var items = response.getReturnValue();
                 component.set("v.opps", items);
            }
            
        });
            $A.enqueueAction(action);
        
        action = component.get("c.getRecTypes");
        
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 component.set("v.rectypes", item);
            }
         });
         
         $A.enqueueAction(action);

        var action2 = component.get("c.getCMOs");

        action2.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {  
                var cmo = response.getReturnValue();
                component.set("v.cmoaccounts", cmo);
                
            } else {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
            } 
        });
             
        $A.enqueueAction(action2);
    },
    displayOpportunities: function(component, event, helper) {
	},
	 toggleSection : function(component, event, helper) {
         var icon = event.currentTarget;
         var globalId = component.getGlobalId();

         var iconid = icon.id;
         
         if(icon.id.includes("open_")){
             var oelement = document.getElementById(icon.id);
             oelement.classList.remove("slds-show");
             oelement.classList.add("slds-hide");
             var celement = document.getElementById("closed_" + icon.name + '_' + globalId);             
             celement.classList.remove("slds-hide");
             celement.classList.add("slds-show");   
             var content = document.getElementById("content_" + icon.name + '_' + globalId); 
             content.classList.remove("slds-hide");
             content.classList.add("slds-show");               
         } else {
             var element = document.getElementById(icon.id);
             element.classList.remove("slds-show");
             element.classList.add("slds-hide");
             var celement = document.getElementById("open_" + icon.name + '_' + globalId);             
             celement.classList.remove("slds-hide");
             celement.classList.add("slds-show"); 
             var content = document.getElementById("content_" + icon.name + '_' + globalId); 
             content.classList.remove("slds-show");
             content.classList.add("slds-hide");                 
         }
     },
     submitBttn: function(component, event, helper) {
            		//var action = component.get("c.submitStatus");
            		var action = component.get("c.acceptedStatus");
         			var idx = event.currentTarget.getAttribute("id");

            		action.setParams({
        	 		   iiId : idx
        	 		   });
                    action.setCallback(this, function(response) {
                    	var state = response.getState();
                    	if (state === "SUCCESS") {
                    	    var a = component.get('c.doInit');
                                    $A.enqueueAction(a);
                           component.set("v.isOpen", true);
                           component.set("v.modalMessage", "Successfully Submitted");
                        } else{
                           component.set("v.isOpen", true);
                           component.set("v.modalMessage", "Error saving the records, please contact your Administrator.");
                        }
                    });
                 $A.enqueueAction(action);
     },            
     handleUploadFinished: function (cmp, event) {
        var a = component.get('c.doInit');
        $A.enqueueAction(a);
    },
    onCheck: function(cmp, evt) {
        var checkCmp = cmp.find("checkbox1");
    },
    makeRowCompact: function(component, event, helper) {
        
        var idx = event.currentTarget.getAttribute("id");
        var sel = component.find(idx);
        $A.util.toggleClass(sel, 'slds-show'); 
        component.set("v.compact", true);
    },

    makeRowDetailed: function(component, event, helper) {
    	var idx = event.currentTarget.getAttribute("id");
        var sel = component.find(idx);
        $A.util.toggleClass(sel, 'slds-hide'); 
        
        component.set("v.compact", false);
    }, 
    FireWorkingGroups: function(component, event, helper) {
      
      //var idx = event.target.id;
      var idx = event.currentTarget.getAttribute("id");
      var evt = $A.get("e.c:NavigateToWorkingGroup");
      evt.setParams({ "result": idx});
      evt.fire();
      
     },
      //the custom Opp component
      FireDetailEvent : function(component, event, helper) {
      
       var idx = event.currentTarget.getAttribute("id");
      var evt = $A.get("e.c:FireDetailEvent");
      evt.setParams({ "result": idx});
      evt.fire();
      
     },
     //the custom Opp component
      FireDocEvent : function(component, event, helper) {
      var idx = event.currentTarget.getAttribute("id");
      component.set("v.docIdEvent", idx);
      
     },
     closeModel: function(component, event, helper) {
          component.set("v.docIdEvent", null);
       },
    
     //the PQ component
     FireEvent : function(component, event, helper) {
      var idx = event.currentTarget.getAttribute("id");
      var evt = $A.get("e.c:NavigateToC2");
      evt.setParams({ "result": idx});
      evt.fire();
    
     },
     
     //the FacilitiesPQ component
     FireFacEvent : function(component, event, helper) {
      var idx = event.currentTarget.getAttribute("id");
      var evt = $A.get("e.c:NavigateToFacPQ");
      evt.setParams({ "result": idx});
      evt.fire();
    
     },
     
    sectionOne : function(component, event, helper) {
            helper.helperFun(component,event,'articleOne');
    },
    
	handleDocUploaded: function (component, event, helper) {
        action = component.get("c.getRecTypeItem");
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state === "SUCCESS") {
                 var item = response.getReturnValue();
                 component.set("v.rectypelist", item);
            }
         });
         
         $A.enqueueAction(action);
    },
    scriptsLoaded : function(component, event, helper) {
	},
   
    scriptsLoaded2 : function(component, event, helper) {    
	},
    scriptsLoaded3 : function(component, event, helper) {
	},
    scriptsLoaded4 : function(component, event, helper) {
        component.set("v.loadedjquery", true);
        
	},
    
    handleFilterChange: function(component, event, helper) {
        var cmoIds = component.get('v.cmoaccounts')
                .filter(function(acct) { return acct.Checked; })
                .map(function(acct) { return acct.Id; });

        component.set('v.cmoIdsSelected', cmoIds);
        helper.loadItems(component, cmoIds);
    }
})