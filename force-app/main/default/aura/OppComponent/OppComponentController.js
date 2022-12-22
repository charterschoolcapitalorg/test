({
	doInit : function(component, event, helper) {
		helper.getIFRecType(component, event);
        helper.getFOFRecType(component, event);
        helper.getFacRecType(component, event); 
	},
       
      //the custom Opp component
      FireOppEvent : function(component, event, helper) {
          
        var opp = component.get("v.opp");  
        var spinner = component.find("modalWait");
        var header = "Closing Details for " + opp.Name ;
        var modalBody;
        var modalHeader;
        $A.createComponents([ ["c:OppDetails", {opp: opp}], ["c:UploadTableHeader", {title : header}] ],
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
                           
                       }
                   });
               }                               
           });
     },
 
})