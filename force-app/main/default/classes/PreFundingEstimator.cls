public with sharing class PreFundingEstimator {
	
	public List<Pre_FE_Installment__c> installments{get;set;} 

	public PreFundingEstimator(){

	}

	@AuraEnabled
	public static List<Pre_FE_Installment__c> getInstallments(String pfeJSON){
		
		System.debug(pfeJSON);
		Pre_Funding_Estimate__c pfe = new Pre_Funding_Estimate__c();
		pfe = (Pre_Funding_Estimate__c)System.JSON.deserialize(pfeJSON, Pre_Funding_Estimate__c.Class);
		System.debug('pfe ' + pfe);
		List<Pre_FE_Installment__c> pfeInstallments = new List<Pre_FE_Installment__c>();
		Integer installments = (Integer)pfe.Installments__c;

		State_Province__c state = getStateRecord(pfe.State__c);
		//default month offset is by one month
		Integer monthOffset = 1;
        if(pfe.Funding_Date__c.day() > Integer.valueOf(state.FE_Repayment_Day_of_Month__c)){
        	monthOffset = 2;
        }

		//Pre_Funding_Estimate__c pfe = pfes[0];
		if(pfe.Transaction_Type__c == 'Receivable Purchase'){
            Integer i = 0;
            do{
	        	//pfeInstallments = calculateReceivablesPurchase(pfe);
		        Pre_FE_Installment__c pfeInstallment = new Pre_FE_Installment__c();
		        pfeInstallment.Name__c = installmentMonth(pfe.Funding_Date__c, (Integer)pfe.Installment_Payment_Date__c, i + monthOffset);
		        //pfeInstallment.GRV_Amount__c = (Integer)(pfe.Annual_Availability__c/12.0).setscale(-3, System.RoundingMode.DOWN);
		        pfeInstallment.GRV_Amount__c = (Integer)(pfe.State_Rate__c * pfe.Student_Count__c / 12.0).setscale(-3, System.RoundingMode.DOWN);
		        Integer faceValue = (Integer)(pfeInstallment.GRV_Amount__c * pfe.Advance_Rate__c / 100.00).setscale(-2, System.RoundingMode.DOWN);
		        pfeInstallment.FV_Amount__c = faceValue;
		        pfeInstallment.MDPP__c = pfeInstallment.GRV_Amount__c - pfeInstallment.FV_Amount__c;
		        Date expectedDate = expectedPayDate(pfe.Funding_Date__c, (Integer)pfe.Installment_Payment_Date__c, (Integer)pfe.Installment_Month_Offset__c + i + monthOffset);
		        pfeInstallment.Expected_Pay_Date__c = expectedPayDate(pfe.Funding_Date__c, (Integer)pfe.Installment_Payment_Date__c, (Integer)pfe.Installment_Month_Offset__c + i + monthOffset);
		        Integer buffer = calculateMaturityBufferDays(expectedDate, pfe.Funding_Date__c, pfe.Target_Effective_Rate__c, pfe.Discount_Rate__c);
		        pfeInstallment.Maturity_Buffer__c = buffer;        
		        Date maturityDate = expectedDate.addDays(buffer);
		        pfeInstallment.Maturity_Date__c = maturityDate;
		        pfeInstallment.Funding_Date__c = pfe.Funding_Date__c;
		        Decimal discountAmt = ((1 - 1/(1 + (pfe.Discount_Rate__c / 100.00) * (pfe.Funding_Date__c.daysBetween(maturityDate) / 360.00) )) * faceValue).round();
		        pfeInstallment.Discount_Amount__c = discountAmt;
		        pfeInstallment.Upfront_Purchase_Price__c = faceValue - discountAmt;
				pfeInstallment.Transaction_Fee__c = faceValue * pfe.Transaction_Fee_Rate__c / 100;
				pfeInstallment.Program_Fees__c = faceValue * pfe.Program_Fee_Rate__c / 100;
                                
		        pfeInstallments.add(pfeInstallment);
		        i++;
		        } while (i < installments);
            
        } else {
            return null;
        }
        //System.debug(pfeInstallments);
		return pfeInstallments;
	}


	@AuraEnabled
	public static State_Province__c getStateRecord(String operatingState){
		State_Province__c st = [SELECT Id, Annual_Funding_FTE__c, FE_Advance_Rate__c, FE_Discount_Rate__c, FE_Repayment_Day_of_Month__c, FE_Repayment_Month_Ahead__c, Name FROM State_Province__c WHERE Name = :operatingState AND PreFE_Tool_Available__c = true LIMIT 1];
		return st;
	}

	@AuraEnabled
	public static String saveRecords(String parent, String pfeJSON){
		System.debug(pfeJSON);
		String recordId = '';
		Pre_Funding_Estimate__c pfe = new Pre_Funding_Estimate__c();
		pfe = (Pre_Funding_Estimate__c)System.JSON.deserialize(pfeJSON, Pre_Funding_Estimate__c.Class);
		pfe.Opportunity__c = parent;
		pfe.RecordTypeId = Schema.SObjectType.Pre_Funding_Estimate__c.getRecordTypeInfosByName().get(pfe.Transaction_Type__c).getRecordTypeId();
		List<Pre_FE_Installment__c> installments = getInstallments(pfeJSON);
		
		
		//insert record
		try{
			insert pfe;
		}catch(exception e){
			return 'Error occurred with PFE insert, contact your administrator';
		}
		System.debug('pfe ' + pfe);

		
		//insert installments
		for(Pre_FE_Installment__c pfei : installments){
			pfei.Pre_Funding_Estimate__c = pfe.Id;
			pfei.RecordTypeId = Schema.SObjectType.Pre_FE_Installment__c.getRecordTypeInfosByName().get(pfe.Transaction_Type__c).getRecordTypeId();
		}
		//insert record
		try{
			insert installments;
		}catch(exception e){
			return 'Error occurred with installment insert, contact your administrator';
		}

		recordId = pfe.Id;
		return recordId;
	}

	public static String installmentMonth(Date fundingDate, Integer paymentDay, Integer monthOffset){
		Date paymentDateMonth = fundingDate;
		String installment = '';
		System.debug('in' + paymentDateMonth);
		System.debug(fundingDate);
		System.debug(paymentDay);
		System.debug(monthOffset);
		paymentDateMonth = paymentDateMonth.addMonths(monthOffset);
		System.debug('payment date: ' + paymentDateMonth);
		installment = DateUtilities.getLongMonth(paymentDateMonth.month());
		installment += ', ';
		installment += paymentDateMonth.year();
		return installment;
	}


	public static Date expectedPayDate(Date fundingDate, Integer paymentDay, Integer monthOffset){
		Date payDate = fundingDate;
		payDate = Date.newInstance(fundingDate.year(), fundingDate.month(), paymentDay);
		payDate = payDate.addMonths(monthOffset);
		return payDate;
	}


    
    public static Integer calculateMaturityBufferDays(Date expectedPayDate, Date fundingDate, Decimal targetFundingRate, Decimal discountRate){
        Decimal targetRate = targetFundingRate / 100.00;
        Decimal discount = discountRate / 100.00;
        Integer maturityBuffer;
        Decimal buffer = fundingDate.daysBetween(expectedPayDate) * (targetRate/(discount * (1 - targetRate * (fundingDate.daysBetween(expectedPayDate)) / 360.00 )) - 1);
        maturityBuffer = (Integer)((buffer * 2.0 / 10.0).round(System.RoundingMode.UP) * 10.0 / 2.0 );
		System.debug(maturityBuffer);
        return maturityBuffer;
    }

}