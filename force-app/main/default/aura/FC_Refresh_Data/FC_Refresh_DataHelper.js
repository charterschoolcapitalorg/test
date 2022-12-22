({
    showToast : function(message, mType, mHeader) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": mType,
            "title": mHeader+"!",
            "message": message
        });
        toastEvent.fire();
    },
})