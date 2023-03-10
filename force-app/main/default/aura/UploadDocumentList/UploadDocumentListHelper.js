({
	toggleClass: function(component,componentId,className) {
		var modal = component.find(componentId);
		$A.util.removeClass(modal,className+'hide');
		$A.util.addClass(modal,className+'open');
	},

	toggleClassInverse: function(component,componentId,className) {
		var modal = component.find(componentId);
		$A.util.addClass(modal,className+'hide');
		$A.util.removeClass(modal,className+'open');
	},

	getopportunitylst : function(component,event){
			var action = component.get("c.getOpps");
			var self = this;
			var intakeItemName = event.getParam("intakeItemName");
			console.log(intakeItemName);
			action.setParams({
	        	"intakeItemName": intakeItemName
	    	});
			action.setCallback(this, function(response) {
			var state = response.getState();
			console.log('STATE'+response.getReturnValue());
				if (component.isValid() && state === "SUCCESS") {
					component.set("v.lstopps",response.getReturnValue());
				}else if (state === "ERROR") {
	                var errors = response.getError();
                }
			});
		$A.enqueueAction(action);
	}
})