({
  toggleInsertButton: function(component, toggleValue){
    let button = component.find('submitButton');
    button.set('v.disabled',toggleValue);
  },

  showToast : function(type, title, message) {
    let toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
        "type": type,
        "title": title,
        "message": message
    });
    toastEvent.fire();
}

})