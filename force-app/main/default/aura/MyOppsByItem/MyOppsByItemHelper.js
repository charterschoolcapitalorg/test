({
    
	showToast : function(title, message, duration, key, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        if(! toastEvent){
            confirm(title + ': ' + message);
            return;
        }
        toastEvent.setParams({
            title : title,
            message: message,
            duration: duration,
            key: key,
            type: type,
            mode: mode
        });
        toastEvent.fire();
    },
})