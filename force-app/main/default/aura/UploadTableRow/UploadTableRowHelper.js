({
    showUploadInfoToast : function(component, event, fileName) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Info Message',
            message: fileName + ' has been uploaded!',
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:'5000',
            key: 'info_alt',
            type: 'info',
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
})