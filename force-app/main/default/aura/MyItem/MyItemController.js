({
        doInit : function(component, event, helper){
            
            var opportunity = component.get("v.opportunity");  
           
            var action = component.get("c.getIntakeItems");
            action.setParams({
                "opportunityId" : opportunity.Id,
                "intakeParentId" : null,
                cmos: component.get('v.cmos') || [],
                statusfilter: component.get('v.statusfilter') || null
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {               
                    component.set("v.intakeItems", response.getReturnValue());
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
    handleDocUploaded: function (cmp, event, helper) {
        
        var parentId = event.getParam("parentId");
        cmp.set("v.parentId", parentId);
        var a = cmp.get('c.doInit');
        $A.enqueueAction(a);
    },
    FireOppEvent : function(component, event, helper) {
      var idx = event.currentTarget.getAttribute("id");
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/transactiondetail?res='+idx,
          "res": idx
        });
        urlEvent.fire();
     },
})