({
    listGenerator : function(uploadedFiles) {
        let fileList = [];
        for (let index = 0; index < uploadedFiles.length; index++) {
            fileList.push(uploadedFiles[index].documentId);
        }
        return fileList;
    },

    handleShowNotice : function(component, items) {
        component.find('notifLib').showToast({
            "title": "Success!",
            "variant": "success",
            "message": items
        });
    }
})