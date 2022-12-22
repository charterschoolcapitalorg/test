({
    handleUploadFinished: function (component, event, helper) {
        // Get the list of uploaded files
        let uploadedFiles = helper.listGenerator(event.getParam("files"));
        let relatedObjects = component.get("v.relatedObjects");
        let relatedLibrary = component.get("v.library");
        let recordId = component.get("v.recordId");
        let action = component.get("c.relateFileToObjects");

        action.setParams({ 
            fileIds : uploadedFiles,
            records : relatedObjects,
            library : relatedLibrary,
            sourceObjectId : recordId
                 });
        action.setCallback(this, function(response) {
            // console.log('calledback');
            // console.log(response.getState());
            let state = response.getState();
            if (state === "SUCCESS") {
                helper.handleShowNotice(component, 'Files linked to associated records!');
                $A.get('e.force:refreshView').fire();

            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    }
})