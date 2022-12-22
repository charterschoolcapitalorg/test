({
    doInit: function(component, event, helper) {
        console.log('init.....');
        component.set('v.columns', helper.getColumnDefinitions());
        let action = component.get("c.getAllPropertyRentContacts");
		action.setCallback(this, function(actionResult) {
			let state = actionResult.getState();
			if (state == "SUCCESS") {
				let retVal = actionResult.getReturnValue();
                let relatedContacts = [];
                for(var key in retVal){
                    retVal[key].forEach(element => {
                        console.log(key);
                        element.FirstName = element.Contact__r.FirstName;
                        element.LastName = element.Contact__r.LastName;
                        element.email = element.Contact__r.Email;
                        element.Account = element.Account__r.Name;
                        element.Property = key.slice(38,key.search(', Nick_Name__c:'));
                        element.StateName = key.slice(key.search(', BillingState:') + 15,key.search(', Equity_Investor__c:'));
                        if(key.includes('Account (Nick_Name__c:')){
                            element.Owner = key.slice(key.search('Equity_Investor__r:') + 42, key.search(', Id:'));}
                        else {
                            element.Owner = 'Add nickname to owner';
                        }
                        element.NickName = key.slice(key.search(', Nick_Name__c:') + 15, key.search(', BillingState:'));
                        element.accUrl = 'https://charterschoolcapital.lightning.force.com/lightning/r/Account/' + key.slice(13,31) + '/view';
                        element.rcUrl = 'https://charterschoolcapital.lightning.force.com/lightning/r/Related_Contact__c/' + element.Id + '/view';
                        element.altEmail = element.Alt_Email__c;
                        relatedContacts.push(element)
                    });
                }

                component.set("v.data", relatedContacts);
                helper.sortData(component, 'Property', 'asc');

            }
        });
		$A.enqueueAction(action);

	},

    onSort: function(cmp, event, helper) {
        helper.handleSort(cmp, event);
    },

})