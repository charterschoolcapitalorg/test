({
	calculateTotals : function(component) {
        let installments = component.get("v.installments");
        let len = installments.length;
		let faceValue = 0, upp = 0, transFee = 0, discount = 0, programFees = 0, totalCost = 0, netToSchool = 0;
		let effectiveRate = 0;
        let totalDays = 0;

        for(let i = 0; i < len; i++){
            faceValue += installments[i].FV_Amount__c;
            upp += installments[i].Upfront_Purchase_Price__c;
            transFee += installments[i].Transaction_Fee__c;
            discount += installments[i].Discount_Amount__c;
            programFees += installments[i].Program_Fees__c;
            let date1 = Date.parse(installments[i].Funding_Date__c);
            let date2 = Date.parse(installments[i].Expected_Pay_Date__c);
            let timeDiff = Math.abs(date2 - date1);
            let diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24));
            totalDays += diffDays;
        }


		totalCost += (discount + transFee + programFees);
        effectiveRate = ((totalCost/faceValue)*(360/(totalDays/len))).toFixed(4);
		netToSchool += (upp - transFee - programFees);
        component.set("v.faceValue", faceValue);
        component.set("v.upp", upp);
        component.set("v.transactionFees", transFee);
        component.set("v.discount", discount);
        component.set("v.programFees", programFees);
        component.set("v.totalCost", totalCost);
        component.set("v.netToSchool", netToSchool);
        component.set("v.transactionEffectiveRate", effectiveRate);
	}
})