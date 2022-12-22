({
    toggleSection : function(component, event, helper){
        var source = event.getSource();  
        var iconName = source.get("v.iconName");
        
        if(iconName == "utility:add"){
            source.set("v.iconName", "utility:dash");
            component.set("v.showList", true);
        } else {
            source.set("v.iconName", "utility:add");
            component.set("v.showList", false);
        }
    },
    
    handleClick : function(component, event, helper){
        
        var source = event.getSource();  
        var label = source.get("v.name");
        var spinner = component.find("modalWait");
        console.log('Label: ' + label);
        var header = "Upload Files: ";
        var modalBody;
        var modalHeader;
        $A.createComponents([ ["c:UploadTable", {intakeName: label}], ["c:UploadTableHeader", {title : header, fileName : label}] ],
           function(components, status) {
               if (status === "SUCCESS") {
                   modalBody = components[0];
                   modalHeader = components[1];
                   component.find('overlayLib').showCustomModal({
                       header: modalHeader,
                       body: modalBody, 
                       showCloseButton: true,
                       cssClass: "slds-modal_medium",
                       closeCallback: function() {
                           //alert('You closed the alert!');
                       }
                   });
               }                               
           });
    },
    handleDocUploaded: function (component, event, helper) {
         console.log('&&&&& in handleDocUploaded of RecTypeMenu');
        
        //toggleSection();
        
        console.log('***** end of handleDocUploaded of RecTypeMenu');
    },
})