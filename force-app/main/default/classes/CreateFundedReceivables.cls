/**=====================================================================
 * Appirio, Inc
 * Name: CreateFundedReceivables
 * Description: [T-281129 "Create Funded Receivables" button and functionality]
 * Created Date: [05/22/2014]
 * Created By: [Rahul Agrawal] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * 05/30/2014					Manisha Gupta 				Changes as per T-281129
 * 08/21/2014					John Caughie				Added Source_Payout_Date_Record__r.Calculation__r.Receivable_Type__c to query to populate on creation
 * 05/06/2016					John Caughie				Added Non_financeable_Reason__c to logic
 * 07/29/2016					John Caughie				Added Issues__c to logic
 * 06/02/2020					John Caughie				Locked FE For Update - issue with user having multiple tabs open
 =====================================================================*/
global with sharing class CreateFundedReceivables {

	private static string fundingEstimateId;

	private static list<Funding_Estimate_Receivable__c> getFundingEstimateReceivable(){
		return [select Id, Name, Discount_Amount__c, Expected_Pay_Date__c, FV_Amount__c, GRV_Amount__c, Initial_Purchase_Factor__c, Maturity_Date__c,
					Max_Deferred_Purchase_Price__c, Purchase_Date__c, Opp_School__r.School__c, Source_Payout_Date_Record__r.Default_Distribution_Date__c,
					Opp_School__r.Opportunity__c, Opp_School__r.Opportunity__r.AccountId,
					Source_Payout_Date_Record__c, Upfront_Purchase_Price__c, Opp_School__r.Opportunity__r.RPA__c,
					Source_School_Attendance_Record__c, Source_State_Rate_Card__c, Source_District_Rate_Card__c, Source_COE_Rate_Card__c,
					Calculator_Audit_Log__c, Attendance_Audit_Log__c, Source_Payout_Date_Record__r.Calculation__r.Receivable_Type__c,
					Donated_Discount_Receivable__c, Discount_Rate__c, Discount_Rate_formula__c, Donated_Discount_Rate__c, Statutory_Expected_Pay_Date__c
				from Funding_Estimate_Receivable__c
				where Funding_Estimate__c =: fundingEstimateId
				and Included_In_Estimate__c = true]; // 05/30/2014 : MG : only included FER has to be fetched
	}

	private static Funding_Estimates__c getFundingEstimate(){
		list<Funding_Estimates__c> lst = [select Id, Application_Fee_Credit__c, Blocked_Account_Fee_Collected__c, Bond_or_Other_Payment__c,
												Description_of_Unpaid_Balance_Receivable__c, Penalty_Interest__c, Program_Fees_Collected__c,
												Refund_Reimbursements__c, Transaction_Fee_Collected__c, Unpaid_Balance_Receivables_Collected__c,
												Discount__c, Opportunity__r.Account.Financeable__c, Opportunity__r.Account.Non_financeable_Reason__c,
												Opportunity__r.Account.Issues__c, Manual_FE__c
												from Funding_Estimates__c
												where Id =: fundingEstimateId
												AND Converted_to_FR__c = FALSE
												FOR UPDATE];
		Funding_Estimates__c fe = new Funding_Estimates__c();

		if(!lst.isEmpty()){
				fe = lst[0];
		} else {
				throw new AuraHandledException('Either this FE has been converted or the record is locked, refresh the page and try again!');
		}
		return fe;
	}

	webservice static void wsCreateFundedReceivables(string feId){
		fundingEstimateId = feId;

		Funding_Estimates__c fe = getFundingEstimate();
		fe.Converted_to_FR__c = true;
		list<Funding_Estimate_Receivable__c> lstFER = new list<Funding_Estimate_Receivable__c>();
		if(fe.Id != null){
			lstFER = getFundingEstimateReceivable();
		}

		list<Funded_Receivable__c> lstFR = new list<Funded_Receivable__c>();
		Funded_Receivable__c newFR;
		boolean firstFR = true;
		for(Funding_Estimate_Receivable__c fer : lstFER){
			newFR = new Funded_Receivable__c(Expected_Pay_Date__c = fer.Expected_Pay_Date__c,
										Donated_Discount_Receivable__c = fer.Donated_Discount_Receivable__c,
										Donated_Discount_Rate__c = fer.Donated_Discount_Rate__c,
										Discount_Rate__c = fer.Discount_Rate_formula__c,
										Financeable__c = fe.Opportunity__r.Account.Financeable__c,
										Issue__c = fe.Opportunity__r.Account.Issues__c,
										Non_financeable_Reason__c = fe.Opportunity__r.Account.Non_financeable_Reason__c,
										FV_Amount__c = fer.FV_Amount__c,
										GRV_Amount__c = fer.GRV_Amount__c,
										Initial_Purchase_Factor__c = fer.Initial_Purchase_Factor__c,
										Maturity_Date__c = fer.Maturity_Date__c,
										Max_Deferred_Purchase_Price__c = fer.Max_Deferred_Purchase_Price__c,
										Purchase_Date__c = fer.Purchase_Date__c,
										Distribution_Date__c = (fe.Manual_FE__c ? fer.Statutory_Expected_Pay_Date__c : fer.Source_Payout_Date_Record__r.Default_Distribution_Date__c),
										Source_Opportunity__c = (fer.Opp_School__c <> null ? fer.Opp_School__r.Opportunity__c : null),
										School__c = (fer.Opp_School__c != null ? fer.Opp_School__r.School__c : null),
										Charter_Holder__c = (fer.Opp_School__c != null && fer.Opp_School__r.Opportunity__c != null ?
																fer.Opp_School__r.Opportunity__r.AccountId : null),
										Source_Payout_Date_Record__c = fer.Source_Payout_Date_Record__c,
										Source_School_Attendance_Record__c = fer.Source_School_Attendance_Record__c,
										Source_State_Rate_Card__c = fer.Source_State_Rate_Card__c,
										Source_COE_Rate_Card__c = fer.Source_COE_Rate_Card__c,
										Source_District_Rate_Card__c = fer.Source_District_Rate_Card__c,
										Calculator_Audit_Log__c = fer.Calculator_Audit_Log__c,
										Attendance_Audit_Log__c = fer.Attendance_Audit_Log__c,
										Upfront_Purchase_Price__c = fer.Upfront_Purchase_Price__c,
										Source_Funding_Estimate_Receivable__c = fer.Id,
										Receivable_Type__c = fer.Source_Payout_Date_Record__r.Calculation__r.Receivable_Type__c,
										RPA__c =  (fer.Opp_School__c != null && fer.Opp_School__r.Opportunity__c != null ?
													fer.Opp_School__r.Opportunity__r.RPA__c : null),
										Name = fer.Name);
			// 05/30/2014 : Manisha : Funding Estimate Data has to be copied only on first Funded Receivable Record
			if(firstFR){
				newFR.Application_Fee_Credit__c = fe.Application_Fee_Credit__c;
				newFR.Blocked_Account_Fee_Collected__c = fe.Blocked_Account_Fee_Collected__c;
				newFR.Bond_or_Other_Payment__c = fe.Bond_or_Other_Payment__c;
				newFR.Description_of_Unpaid_Balance_Receivable__c = fe.Description_of_Unpaid_Balance_Receivable__c;
				newFR.Penalty_Interest__c = fe.Penalty_Interest__c;
				newFR.Program_Fees_Collected__c = fe.Program_Fees_Collected__c;
				newFR.Refund_Reimbursements__c = fe.Refund_Reimbursements__c;
				newFR.Transaction_Fee_Collected__c = fe.Transaction_Fee_Collected__c;
				newFR.Unpaid_Balance_Receivables_Collected__c = fe.Unpaid_Balance_Receivables_Collected__c;
				firstFR = false;
			}

			lstFR.add(newFR);

		}

		if(!lstFR.isEmpty()){
			insert lstFR;
			update fe;
		}
	}
}