({
    setup : function(component, event) {
        let lodingName = "setup";
        this.addLoading(component, lodingName);
        this.clearAllErrorMessages(component);

        let action = component.get("c.whatToRescore");
		action.setParams({
			pRateId : component.get("v.recordId")
		});
	
		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let resp = response.getReturnValue();
                for (let o in resp) {
                    let obj = resp[o];
                    if (obj.type==="score") {
                        component.set("v.oldMarketRateId", obj.obj.rateScoring.Market_Rate__c);
                        component.set("v.childRates", obj.obj.childRates);
                    }
                    if (obj.type==="error") {
                        this.addErrorMessage(component, obj);
                    }
                }
            }
            else {
                this.addErrorMessage(component, "An unknow error occured, please contact your administrator.");
            }
			this.removeLoading(component, lodingName);
		}); 
		
		$A.enqueueAction(action);
    },

    rescore : function(component, event) {
        console.log('Re-score button pressed, helper kicks in');
        console.log('@@@ record id = ' + component.get("v.recordId"));

        let action = component.get("c.rescoreRate")

		action.setParams({
			pRateId : component.get("v.recordId")
		});

		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
                // close the rescore modal and refresh the page
                const URL = 'https://charterschoolcapital--cscfull.sandbox.lightning.force.com/lightning/r/Pricing_Rate__c/'+component.get("v.recordId")+'/view';
                this.gotoURL(URL);
            }
        });

        $A.enqueueAction(action);

        // Dan ============================================
        // let lodingName = "rescore";
        // this.addLoading(component, lodingName);
        // this.clearAllErrorMessages(component);

        // let action = component.get("c.rescoreRate");
		// action.setParams({
		// 	pRateId : component.get("v.recordId")
		// });
	
		// action.setCallback(this, function(response) {
		// 	let state = response.getState();
		// 	if (state === "SUCCESS") {
		// 		let resp = response.getReturnValue();
        //         for (let o in resp) {
        //             let obj = resp[o];
        //             if (obj.type==="score") {
        //                 component.set("v.oldMarketRateId", obj.obj.rateScoring.Market_Rate__c);
        //                 component.set("v.childRates", obj.obj.childRates);
        //             }
        //             if (obj.type==="error") {
        //                 this.addErrorMessage(component, obj);
        //             }
        //         }
        //     }
        //     else {
        //         this.addErrorMessage(component, "An unknow error occured, please contact your administrator.");
        //     }
        //     component.set("v.isBefore", false);
        //     this.removeLoading(component, lodingName);
		// });
		
		// $A.enqueueAction(action);
        
    },

    //===========================================================
    //===========================================================
    gotoURL : function (url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": url
        });
        urlEvent.fire();
    },
    //===========================================================
    //===========================================================

    setColumns : function(component, event) {
        let lodingName = "setColumns";
        this.addLoading(component, lodingName);
        this.clearAllErrorMessages(component);

        let action = component.get("c.getFieldSets");

		action.setCallback(this, function(response) {
			let state = response.getState();
			if (state === "SUCCESS") {
                let resp = response.getReturnValue();
                for (let o in resp) {
                    let obj = resp[o];
                    if (obj.type==="cRateFlds") {
                        let cols = [];
                        for (let f in obj.obj) {
                            let fld = obj.obj[f];

                            cols.push({"label": fld.label, "fieldName": fld.fieldPath, "type": fld.type, editable: true});
                        }
                        component.set( "v.rateColumns", cols );
                    }
                    if (obj.type==="rateFields") {
                        let cols = [];
                        for (let f in obj.obj) {
                            let fld = obj.obj[f];
                            cols.push(fld);
                        }
                        component.set( "v.pRateFlds", cols );
                    }
                    if (obj.type==="mRateFields") {
                        let cols = [];
                        for (let f in obj.obj) {
                            let fld = obj.obj[f];
                            cols.push(fld);
                        }
                        component.set( "v.mRateFlds", cols );
                    }
                    if (obj.type==="error") {
                        this.addErrorMessage(component, obj);
                    }
                }
            }
            else {
                this.addErrorMessage(component, "An unknow error occured, please contact your administrator.");
            }
            this.removeLoading(component, lodingName);
		});
		
		$A.enqueueAction(action);
    },

    clearAllErrorMessages : function(component) {
        component.set("v.errMsgs", []);
        component.set("v.cRateErrors", { rows: {}, table: {} }); 
        component.set("v.hasErrors", false);
	},
    
    setErrorTitle : function(component, title) {
		component.set("v.errorTitle", title);
	},
    
    addErrorMessage : function(component, erObj) {
        this.setErrorTitle(component, "Error");

        if (typeof variable === 'string') {
            this.addTopError(component, erObj);
        }
        else {
            if (erObj.recId===component.get("v.recordId")) {
                this.addTopError(component, erObj.obj.message);
            }
            else {
                this.addTableError(component, erObj);
            }
        }
    },

    addTopError : function(component, erMsg) {
        var errors = component.get("v.errMsgs");
		var newMsg = {message: erMsg};
		errors.push(newMsg);
        component.set("v.errMsgs", errors);
        component.set("v.hasErrors", true);
    },

    addTableError : function(component, erObj) {

        let tblErObj = { rows: {}, table: {} };
        tblErObj.table = {title: "The following errors were encountered when rescoring school rates", messages: ['']};
        if (typeof tblErObj.rows[erObj.recId] === "undefined") {
            tblErObj.rows[erObj.recId] = { title: "Rescore Error", 
                                            messages: [],
                                            fieldNames: ["Name"]
                                        };
        }
        tblErObj.rows[erObj.recId].messages.push(erObj.obj.message);
        component.set("v.cRateErrors", tblErObj);
    },

    addLoading : function(component, loadingName) {
		component.set("v.loading", true);
		var loadingList = component.get("v.loadingList");
		loadingList.push(loadingName);
		component.set("v.loadingList", loadingList);
	},

	removeLoading : function(component, loadingName) {
        try {
            var loadingList = component.get("v.loadingList");
            loadingList.splice(loadingList.indexOf(loadingName), 1);
            component.set("v.loadingList", loadingList);
            if ( !this.somethingStillLoading(component) ) {
                component.set("v.loading", false);
            }
        } catch (err) {
            //console.log("Error: ", err);
        }
	},
    
    somethingStillLoading : function(component) {
   		var loadingList = component.get("v.loadingList");
        if (loadingList.length>0) {
            return true;
        }
        else {
            return false;
        }
    },
})