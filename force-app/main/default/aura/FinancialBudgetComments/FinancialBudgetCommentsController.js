({
    init: function(component){
        component.set("v.allowComments", false);
        let quarters = [];
        let accId = component.get("v.accId");
        let year = (component.get("v.enddatefy") - 1) + '-' + component.get("v.enddatefy");
        let startQ = component.get("v.startdatefq");
        console.log('startQ== '+JSON.stringify(startQ));
        let endQ = component.get("v.enddatefq");
        console.log('endQ== '+JSON.stringify(endQ));
        if (startQ == 'All' || endQ == 'All'){
            quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
        } else {
            for(let i = startQ[1]; i <= endQ[1]; i++){
                quarters.push('Q' + i);
            }
        }
		console.log('quarters== '+JSON.stringify(quarters));
        let action = component.get("c.getActualBudgetComments");
        action.setParams({
            clientId : accId,
            quarters : JSON.stringify(quarters),
            fiscalYear : year
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                let resp = response.getReturnValue();
                let maps = new Map();
                let opts = resp.map(item => {
                    maps[item.Id] = item.Actual_to_Budget_Variance_Comments__c;
                    return {'label' : item.Fiscal_Quarter__c,
                            'value' : item.Id
                		   };
                    });
                console.log('Options== '+JSON.stringify(opts));
                console.log('selectedValue == '+component.get('v.selectedValue'));
                component.set('v.commentMap', maps);
                component.set('v.selectedRecordId', resp[0].Id);
                component.set("v.selectedRecordComments", resp[0].Actual_to_Budget_Variance_Comments__c);
                component.set('v.options', opts);
                component.set('v.commentMap', maps);
            }
        });
        $A.enqueueAction(action);

    },

    close: function(component) {
        component.set("v.showBudgetComments", false);
        component.set("v.recordSaved", false);
    },

    save: function(component, event) {
        let recordId = component.get("v.selectedRecordId");
        let comments = component.get("v.selectedRecordComments");
        // console.log(recordId);
        // console.log(comments);
        component.set("v.spinner", true); 
        let action = component.get("c.updateComments");
        action.setParams({
            recordId : recordId,
            comments : comments
        });
        action.setCallback(this, function(response){
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.recordSaved", true);
                component.set("v.spinner", false); 
                //component.set("v.showBudgetComments", false);
            }
        });
        // console.log('finish');
        $A.enqueueAction(action);
    },

    quarterChange: function(component, event){
        console.log('In quarterChange');
        let newId = component.find('quarterId').get('v.value');
        if(newId){
        let comments = Object.assign({}, ...component.get("v.commentMap"));
        component.set("v.recordSaved", false);
        component.set("v.selectedRecordId", newId);
        component.set("v.selectedRecordComments", comments[newId]);
        component.set("v.allowComments", true);
        }else{
        component.set("v.allowComments", false);
        }
    },
})