({
	parseUserList : function(cmp, opps) {
		let users = new Set();
		for (let index = 0; index < opps.length; index++) {
			users.add(opps[index].opp.Owner.User_Fullname__c);
			//check to see user on each reacord before adding to array
			if(opps[index].opp.Paralegal__c !== undefined){
				users.add(opps[index].opp.Paralegal__r.User_Fullname__c);
			}
			if(opps[index].opp.Financial_Review__c !== undefined){
				users.add(opps[index].opp.Financial_Review__r.User_Fullname__c);
			}
			if(opps[index].opp.Legal_Assistant__c !== undefined){
				users.add(opps[index].opp.Legal_Assistant__r.User_Fullname__c);
			}
		};
		//conver set to array and sort alphabetically
		let userArray = Array.from(users);
		userArray.sort();
		//convert to key/value pair for picklist
		let userList = [];
		userList.push(
			{
				value: "All",
				label: "All"
			}
		);
		for (let item of userArray){
			userList.push(
				{
					value: item,
					label: item
				}
			)
		};
		return userList;
	},

	filterOpps: function(opps, userName){
		let updatedArray = [];
		if(userName === 'All'){
			updatedArray = opps;
		} else {
			for (let opp of opps){
				if(this.userInOpp(opp, userName)){
					updatedArray.push(opp);
				}
			};
		}
		return updatedArray;
	},

	userInOpp: function(opp, userName){
		let userFound = false;
		if(opp.opp.Owner.User_Fullname__c === userName){
			userFound = true;
		}

		if(opp.opp.Paralegal__c !== undefined && opp.opp.Paralegal__r.User_Fullname__c === userName){
			userFound = true;
		}

		if(opp.opp.Financial_Review__c !== undefined && opp.opp.Financial_Review__r.User_Fullname__c === userName){
			userFound = true;
		}

		if(opp.opp.Legal_Assistant__c !== undefined  && opp.opp.Legal_Assistant__r.User_Fullname__c === userName){
			userFound = true;
		}

		return userFound;
	},
})