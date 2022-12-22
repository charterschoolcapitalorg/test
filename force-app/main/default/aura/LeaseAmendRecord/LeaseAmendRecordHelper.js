({
    showToast : function(message, mType) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": mType,
            "title": "Success!",
            "message": message
        });
        toastEvent.fire();
    }
})