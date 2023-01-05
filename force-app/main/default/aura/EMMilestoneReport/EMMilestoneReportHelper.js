({
	totalRecordCount : function(cmp, opps) {
		let recordCount = 0;
		for (let index = 0; index < opps.length; index++) {
            if(opps[index].signedContract !== 'Completed') {
                recordCount = recordCount + 1;
            }
		}
		return recordCount;
	},

    totalSourced : function(cmp, opps) {
		let recordSourced = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].preQualInfo == 'Completed' 
            && opps[index].pitchDeck == 'Incomplete'
            && opps[index].approveContracting == 'Incomplete'
            && opps[index].signedContract == 'Incomplete') {
				recordSourced = recordSourced + 1;
			}
		}
		return recordSourced;
	},

	totalDollarSourced : function(cmp, opps) {
		let dollarSourced = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].preQualInfo == 'Completed' 
            && opps[index].pitchDeck == 'Incomplete'
            && opps[index].approveContracting == 'Incomplete'
            && opps[index].signedContract == 'Incomplete'
            && opps[index].opp.Estimate_EM_Project_Value__c !== undefined) {
				dollarSourced = dollarSourced + opps[index].opp.Estimate_EM_Project_Value__c;
			}
		}
		return dollarSourced;
	},

    totalWon : function(cmp, opps) {
		let recordWon = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].signedContract == 'Completed') {
				recordWon = recordWon + 1;
			}
		}
		return recordWon;
	},

	totalDollarWon : function(cmp, opps) {
		let dollarWon = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].signedContract == 'Completed'
            && opps[index].opp.Estimate_EM_Project_Value__c !== undefined) {
				dollarWon = dollarWon + opps[index].opp.Estimate_EM_Project_Value__c;
			}
		}
		return dollarWon;
	},

    totalProposed : function(cmp, opps) {
		let recordProposed = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].pitchDeck == 'Completed'
            && opps[index].approveContracting == 'Incomplete'
            && opps[index].signedContract == 'Incomplete') {
				recordProposed = recordProposed + 1;
			}
		}
		return recordProposed;
	},

	totalDollarProposed : function(cmp, opps) {
		let dollarProposed = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].pitchDeck == 'Completed'
            && opps[index].approveContracting == 'Incomplete'
            && opps[index].signedContract == 'Incomplete'
            && opps[index].opp.Estimate_EM_Project_Value__c !== undefined) {
				dollarProposed = dollarProposed + opps[index].opp.Estimate_EM_Project_Value__c;
			}
		}
		return dollarProposed;
	},

    totalConverted : function(cmp, opps) {
		let recordConverted = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].approveContracting == 'Completed'
            && opps[index].signedContract == 'Incomplete') {
				recordConverted = recordConverted + 1;
			}
		}
		return recordConverted;
	},

	totalDollarConverted : function(cmp, opps) {
		let dollarConverted = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].approveContracting == 'Completed'
            && opps[index].signedContract == 'Incomplete'
            && opps[index].opp.Estimate_EM_Project_Value__c !== undefined) {
				dollarConverted = dollarConverted + opps[index].opp.Estimate_EM_Project_Value__c;
			}
		}
		return dollarConverted;
	},

    totalCreated : function(cmp, opps) {
		let recordCreated = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].preQualInfo == 'Incomplete' 
            && opps[index].pitchDeck == 'Incomplete'
            && opps[index].approveContracting == 'Incomplete'
            && opps[index].signedContract == 'Incomplete') {
				recordCreated = recordCreated + 1;
			}
		}
		return recordCreated;
	},

	totalDollarCreated : function(cmp, opps) {
		let dollarCreated = 0;
		for (let index = 0; index < opps.length; index++) {
			if(opps[index].preQualInfo == 'Incomplete' 
            && opps[index].pitchDeck == 'Incomplete'
            && opps[index].approveContracting == 'Incomplete'
            && opps[index].signedContract == 'Incomplete'
            && opps[index].opp.Estimate_EM_Project_Value__c !== undefined) {
				dollarCreated = dollarCreated + opps[index].opp.Estimate_EM_Project_Value__c;
			}
		}
		return dollarCreated;
	},

    getStateList : function(cmp, opps) {
		let stateList = [];
		stateList.push(
			//{value: "All States",label: "All States"},
			{value: "AL",label: "AL"},
			{value: "AK",label: "AK"},
			{value: "AZ",label: "AZ"},
			{value: "AR",label: "AR"},
			{value: "DC",label: "DC"},
			{value: "CA",label: "CA"},
			{value: "CO",label: "CO"},
			{value: "CT",label: "CT"},
			{value: "DE",label: "DE"},
			{value: "FL",label: "FL"},
			{value: "GA",label: "GA"},
			{value: "HI",label: "HI"},
			{value: "ID",label: "ID"},
			{value: "IL",label: "IL"},
			{value: "IN",label: "IN"},
			{value: "IA",label: "IA"},
			{value: "KS",label: "KS"},
			{value: "KY",label: "KY"},
			{value: "LA",label: "LA"},
			{value: "ME",label: "ME"},
			{value: "MD",label: "MD"},
			{value: "MA",label: "MA"},
			{value: "MI",label: "MI"},
			{value: "MN",label: "MN"},
			{value: "MS",label: "MS"},
			{value: "MO",label: "MO"},
			{value: "MT",label: "MT"},
			{value: "NE",label: "NE"},
			{value: "NV",label: "NV"},
			{value: "NH",label: "NH"},
			{value: "NJ",label: "NJ"},
			{value: "NM",label: "NM"},
			{value: "NY",label: "NY"},
			{value: "NC",label: "NC"},
			{value: "ND",label: "ND"},
			{value: "OH",label: "OH"},
			{value: "OK",label: "OK"},
			{value: "OR",label: "OR"},
			{value: "PA",label: "PA"},
			{value: "RI",label: "RI"},
			{value: "SC",label: "SC"},
			{value: "SD",label: "SD"},
			{value: "TN",label: "TN"},
			{value: "TX",label: "TX"},
			{value: "UT",label: "UT"},
			{value: "VT",label: "VT"},
			{value: "VA",label: "VA"},
			{value: "WA",label: "WA"},
			{value: "WV",label: "WV"},
			{value: "WI",label: "WI"},
			{value: "WY",label: "WY"}
		);
		return stateList;
	},

    getUserList : function(cmp, opps) {
		let users = new Set();
		for (let index = 0; index < opps.length; index++) {
			users.add(opps[index].opp.Owner.LastName);
		}
		//conver set to array and sort alphabetically
		let userArray = Array.from(users);
		userArray.sort();
		//convert to key/value pair for picklist
		let userList = [];
		// userList.push(
		// 	{
		// 		value: "All Users",
		// 		label: "All Users"
		// 	}
		// );
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

    	//filter opportunities
	filterOpps: function(opps, userName, state){
		let updatedArray = [];
		if(userName === 'All Users' && state === 'All States'){
			updatedArray = opps;
		} else {
			for (let opp of opps){
				if(this.recordSearch(opp, userName, state)){
					updatedArray.push(opp);
				}
			};
		}
		return updatedArray;
	},

	recordSearch: function(opp, userName, state){
		let recordFound = false;
        //only user
		if(userName !== undefined && state === undefined) {
            if(opp.opp.Owner.LastName === userName) {
                recordFound = true;
            }
        //only state
        } else if(userName === undefined && state !== undefined) {
            if(opp.opp.STATE__c === state) {
                recordFound = true;
            }
        //both user and state
        } else if(userName !== undefined && state !== undefined) {
            if(opp.opp.STATE__c === state && opp.opp.Owner.LastName === userName) {
                recordFound = true;
            }
        }
		return recordFound;
	},

    totalContracted: function(cmp, opps) {
		let recordCount = 0;
		for (let opp of opps) {
            if(opp.signedContract === 'Completed') {
                recordCount = recordCount + 1;
            }
		}
		return recordCount;
	}

})