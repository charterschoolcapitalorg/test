({
   doInit : function(component, event, helper) {
      console.log('doInit of HomePageMainComp');
      $A.createComponent(
         "c:IntakeCommunity",
         {
 
         },
         function(newCmp){
            if (component.isValid()) {
                console.log('body: ' + newCmp);
               component.set("v.body", newCmp);
            }
         }
      );
   },
   NavigateComponent : function(component,event,helper) {
      //alert('**in NavigateCOmponent: ' + event.getParam("result"));
      $A.createComponent(
         "c:IntakeItemPQCOmmunity",
         {
           "res" : event.getParam("result")
         },
          
         function(newCmp){
             //alert('**in newcmp');
            if (component.isValid()) {
                //alert('** cmp is valid');
                component.set("v.body", newCmp);
            }
         }
      );
   },
    NavigateToFacPQ : function(component,event,helper) {
      console.log('**in NavigateToFacPQ: ' + event.getParam("result"));
      console.log(event.getSource().get("v.value"));
         $A.createComponent(
         "c:FacilitiesIntakeItemPQCommunity",
         {
           "res" : event.getParam("result")
         },
         function(newCmp){
            if (component.isValid()) {
                component.set("v.body", newCmp);
            } else {
                console.log('fac pq component is not valid');
            }
         }
      );
   }, 
   NavigateWorkingGroup : function(component,event,helper) {
      console.log('**in NavigateWorkingGroup: ' + event.getParam("result"));
      console.log(event.getSource().get("v.value"));
         $A.createComponent(
         "c:WorkingGroupForms",
         {
           "intakeId" : event.getParam("result")
         },
         function(newCmp){
            if (component.isValid()) {
                component.set("v.body", newCmp);
            } else {
                console.log('WorkingGroupForms component is not valid');
            }
         }
      );
   },
   NavigateToOpp : function(component,event,helper) {
      //alert('**in NavigateToOpp: ' + event.getParam("result"));
      console.log(event.getSource().get("v.value"));
         $A.createComponent(
             "c:IntakeCustomOpportunity2",
             {
               "res" : event.getParam("result")
             },
              
             function(newCmp){
                if (component.isValid()) {
                    component.set("v.body", newCmp);
                }
             }
      	);
   },
   FireDetailEvent : function(component,event,helper) {
      //alert('**in FireDetailEvent: ' + event.getParam("result"));
      console.log(event.getSource().get("v.value"));
         $A.createComponent(
             "c:IntakeCustomDetails",
             {
               "res" : event.getParam("result")
             },
              
             function(newCmp){
                if (component.isValid()) {
                    component.set("v.body", newCmp);
                }
             }
      	);
   }
})