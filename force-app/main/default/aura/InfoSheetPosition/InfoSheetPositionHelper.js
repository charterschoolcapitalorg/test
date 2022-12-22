({
	isVacantChecked : function(component) {
		const isRequired = false; //not needed if the position is vacant
        component.set("v.isVacant", true);
        component.find("firstName").set("v.placeholder", "");
        component.find("firstName").set("v.required", isRequired);
        component.find("lastName").set("v.placeholder", "");
        component.find("lastName").set("v.required", isRequired);
        component.find("address").set("v.placeholder", "");
        component.find("address").set("v.required", isRequired);
        component.find("phone").set("v.placeholder", "");
        component.find("phone").set("v.required", isRequired);
        component.find("email").set("v.placeholder", "");
        component.find("email").set("v.required", isRequired);
        if(!component.get("v.person.School_Administrator__c")){
            component.find("term").set("v.placeholder", "");
            component.find("term").set("v.required", isRequired);
        };
        component.set("v.person.Name", "Vacant");
        component.set("v.person.First_Name__c", "");
        component.set("v.person.Address__c", "");
        component.set("v.person.Phone__c", "");
        component.set("v.person.Email__c", "");
        component.set("v.person.Term_of_Office_Board_Member__c", "");
    },

	isVacantUnchecked : function(component){
		const isRequired = true; //needed if the position is vacant
		component.set("v.isVacant", false);
        component.find("firstName").set("v.placeholder", "First Name");
        component.find("firstName").set("v.required", isRequired);
        component.find("lastName").set("v.placeholder", "Last Name");
        component.find("lastName").set("v.required", isRequired);
        component.set("v.person.Name", null);
        component.find("address").set("v.placeholder", "Address");
		component.find("address").set("v.required", isRequired);
        component.find("phone").set("v.placeholder", "Phone");
        component.find("phone").set("v.required", isRequired);
        component.find("email").set("v.placeholder", "Email");
        component.find("email").set("v.required", isRequired);
        if(!component.get("v.person.School_Administrator__c")){
            component.find("term").set("v.placeholder", "Beginning & ending date");
            component.find("term").set("v.required", isRequired);
        }
	}
})