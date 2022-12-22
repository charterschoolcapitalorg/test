({
	 toggleSection : function(component, event, helper){
        console.log("%%%%%%%%%%%%%%% toggleSection: ");
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