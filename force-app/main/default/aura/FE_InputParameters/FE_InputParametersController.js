({
    doInit: function(component, event, helper) {
        // Prepare a new record from template
        let action = component.get("c.getStateRecord");
        let stateName = component.get("v.stateName");
        let ld = component.get("v.lead");
        let opp = component.get("v.opportunity");
        component.set("v.preFundingEstimate.State__c", stateName);
        action.setParams({ operatingState : stateName });
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                let returned = response.getReturnValue();
                component.set("v.operatingState", returned);
                component.set("v.preFundingEstimate.State_Rate__c", returned["Annual_Funding_FTE__c"]);
                component.set("v.preFundingEstimate.Advance_Rate__c", returned["FE_Advance_Rate__c"]);
                component.set("v.preFundingEstimate.Discount_Rate__c", returned["FE_Discount_Rate__c"]);
                component.set("v.preFundingEstimate.Installment_Month_Offset__c", returned["FE_Repayment_Month_Ahead__c"]);
                component.set("v.preFundingEstimate.Installment_Payment_Date__c", returned["FE_Repayment_Day_of_Month__c"]);
                component.set("v.preFundingEstimate.Opportunity__c", opp);
                component.set("v.preFundingEstimate.Lead__c", ld);
            } else if (state === "ERROR") {
                component.set("v.error", true);
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
         $A.enqueueAction(action);
    },
    
    handleCancel : function(component, event, helper) {
        let opp = component.get("v.opportunity");
        let lead = component.get("v.lead");
		//alert('cancel');
        if( (typeof sforce != 'undefined') && (sforce != null) ) {
            sforce.one.navigateToSObject(opp || lead);
        } else {
            window.parent.location = '/' + (opp || lead);
        }
	},
    
    calculate : function(component, event, helper) {
        console.log('here');
        console.log(component.get("v.preFundingEstimate.Funding_Date__c"));
        if(!component.get("v.preFundingEstimate.Funding_Date__c") || !component.get("v.preFundingEstimate.Student_Count__c") || 
            !component.get("v.preFundingEstimate.Installments__c") || !component.get("v.preFundingEstimate.Program_Fee_Rate__c") || 
            !component.get("v.preFundingEstimate.Transaction_Fee_Rate__c") || !component.get("v.preFundingEstimate.Target_Effective_Rate__c") ){
            component.set("v.error", "true");
            return;
        }
        let pfe = JSON.stringify(component.get("v.preFundingEstimate"));
        let action = component.get("c.getInstallments");
        action.setParams({ pfeJSON : pfe });
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.installments", response.getReturnValue());
                component.set("v.calculated", "true");
            } else if (state === "ERROR") {
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
         $A.enqueueAction(action);
	},

    save : function(component, event, helper){
        let action = component.get("c.saveRecords");
        let pfe = JSON.stringify(component.get("v.preFundingEstimate"));
        let destination = '';
        action.setParams({ parent : component.get("v.opportunity"),
                            pfeJSON : pfe});
        action.setCallback(this, function(response){
            let state = response.getState();
            console.log('state is: ' + state);
            if (state === "SUCCESS") {
                destination += response.getReturnValue();
                if( (typeof sforce != 'undefined') && (sforce != null) ) {
                    sforce.one.navigateToSObject(destination);
                } else {
                    window.parent.location = '/' + destination;
                }
            } else if (state === "ERROR") {
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);       
    },

    changeType: function (component, event, helper) {
        if(component.get("v.preFundingEstimate.Transaction_Type__c")=='Loan'){
            component.set("v.preFundingEstimate.Installments__c", "1");
            component.set("v.isLoan", true);
            component.set("v.error", true);
        } else {
            component.set("v.preFundingEstimate.Installments__c", "");
            component.set("v.isLoan", false);
            component.set("v.error", false);
        }
    },

    changeGeneral: function (component, event, helper) {
        helper.toggleButtonOff(component);
    }
    
})