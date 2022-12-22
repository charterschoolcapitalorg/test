({
	doInit : function(component, event, helper) {
        console.log('***** My Items doInit called...');
        var action = component.get("c.getOpenOpportunities");
        action.setParams({
            cmos: component.get('v.cmos') || [],
            statusfilter: component.get('v.statusfilter') || null
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {               
                component.set("v.opps", response.getReturnValue());
                console.log('***** My Items: ' + response.getReturnValue());
                var oppMap = response.getReturnValue();
                  var count = 0;
                  var i;
                   for (i in oppMap){
                    if(oppMap.hasOwnProperty(i)){
                       count++;
                     }
                   }
                component.set("v.oppSize", count);
                if (count) {
                    component.getEvent('showOpportunityItems').fire();
                }
            } else {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
            }            
        });
        $A.enqueueAction(action);   		
	},
    
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
})