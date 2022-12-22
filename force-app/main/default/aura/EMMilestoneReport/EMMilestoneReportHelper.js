({
	totalRecordCount : function(cmp, opps) {
		let recordCount = 0;
		for (let index = 0; index < opps.length; index++) {
			recordCount = recordCount + 1;
		}
		return recordCount;
	},

    getStateList : function(cmp, opps) {
		let stateList = [];
		stateList.push(
			{value: "All States",label: "All States"},
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
		userList.push(
			{
				value: "All Users",
				label: "All Users"
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