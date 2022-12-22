/**=====================================================================
 * Appirio, Inc
 * Manager Class Name: AllocationTriggerManager
 * Description: T-279945 : Manager Class for Trigger AllocationTrigger
 * Created Date: [05/20/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 06/10/2014					Rajeev Arya 				 T-286219 Revise trigger code
 * 06/13/2014					Rajeev Arya 			     I-117940 Show Commissionable Amount
 * 07/18/2014					Rajeev Arya 			     I-122095 - Issue related to Clear Date in Redemption and AllocationTrigger
 * 06/07/2016					John Caughie 			     Changed allAlloc sort to Date Cleared desc rather than ID desc 
 * 09/20/2016					John Caughie 			     Added logic for Loans - Last Payment Received 
 =====================================================================*/
public class AllocationTriggerManager {
	
	public static map<ID,Account> SchoolToIdMap =  new  map<ID,Account>();
	public static map <ID, user> IdToUserMap = new  map <ID, user>();
	public static void AddAllocationToFundedReceivable(list<Allocation__c> lstNew){
		map<id,Draw_Note_TX__c> recToDrawNoteTX = new map<id,Draw_Note_TX__c>();
		list <Draw_Note_TX__c> lstDrawTX = new list <Draw_Note_TX__c>();
		Set<ID> RecIDs = new Set<ID>();
		Set<ID> SchoolIDs = new Set<ID>();
		Set<ID> UserIDs = new Set<ID>();
		map<ID,Decimal> FundedReceivableToAllocSumMap =  new  map<ID,Decimal>();
		map<ID,Decimal> FundedReceivableToIntAllocSumMap =  new  map<ID,Decimal>();												//2016.09.20 J Caughie - Map to store FR to Loan Interest
		map<ID,Date> FundedReceivableToRedClearDate =  new  map<ID,Date>();
		Decimal amount, interestAmount;																							//2016.09.20 J Caughie - added interestAmount
		
		list<Funded_Receivable__c> lstFundRec =  new list<Funded_Receivable__c>();
		list<Commission__c> lstComs =  new list<Commission__c>();
		for(Allocation__c alloc : lstNew){
			RecIDs.add(alloc.Funded_Receivable__c);
		}
		system.debug('the receivable ids are ' + RecIDs);	
		
		for(Allocation__c allAlloc : [select id,Face_Amount_Applied__c,Funded_Receivable__c, Redemption_Date_Cleared__c, Interest_Applied__c from Allocation__c 
									where Funded_Receivable__c in : RecIDs
									order by Redemption_Date_Cleared__c desc]){
			if(!FundedReceivableToAllocSumMap.containsKey(allAlloc.Funded_Receivable__c)){
        		FundedReceivableToAllocSumMap.put(allAlloc.Funded_Receivable__c,allAlloc.Face_Amount_Applied__c);
        		FundedReceivableToIntAllocSumMap.put(allAlloc.Funded_Receivable__c,allAlloc.Interest_Applied__c);					//2016.09.20 J Caughie - if not in map add to map
        		FundedReceivableToRedClearDate.put(allAlloc.Funded_Receivable__c,allAlloc.Redemption_Date_Cleared__c );
        	}
        	else{
        		//system.debug(LoggingLevel.ERROR,'receivable is ' +alloc.Funded_Receivable__c);
	        	amount = FundedReceivableToAllocSumMap.get(allAlloc.Funded_Receivable__c);
	        	interestAmount = FundedReceivableToIntAllocSumMap.get(allAlloc.Funded_Receivable__c);								//2016.09.20 J Caughie - if in map get allocation amount
	        	//system.debug(LoggingLevel.ERROR,'its filtered alloc amount is ' +alloc.Face_Amount_Applied__c);
	        	amount += allAlloc.Face_Amount_Applied__c;
	        	interestAmount += (allAlloc.Interest_Applied__c == null ? 0 : allAlloc.Interest_Applied__c);						//2016.09.20 J Caughie - add new interest allocation amount
	        	FundedReceivableToAllocSumMap.put(allAlloc.Funded_Receivable__c,amount);
				FundedReceivableToIntAllocSumMap.put(allAlloc.Funded_Receivable__c,interestAmount);									//2016.09.20 J Caughie - update to map to be updated
        	}
		}
		
		for (Draw_Note_TX__c drtx : [select Funded_Receivable__c, name, id from Draw_Note_TX__c where Funded_Receivable__c in: RecIDs and Status__c='Active'] ){
			recToDrawNoteTX.put(drtx.Funded_Receivable__c, drtx);
		}
		list<Funded_Receivable__c> lstFr = [select Id, name, Opportunity_Owner_ID__c, School__c,FV_Amount__c,Payments_Applied__c,Discount_Amount__c, 
		                                    Source_Funding_Estimate_Receivable__r.Funding_Estimate__r.Opportunity__c, Loan_Interest_Paid__c, Final_Payment_Date__c
											from Funded_Receivable__c 
											where id in:RecIDs];
		
		System.debug('-***lstFr****-'+lstFr);
		
		for(Funded_Receivable__c FrRec : lstFr){
			SchoolIDs.add(FrRec.School__c);
			UserIDs.add(FrRec.Opportunity_Owner_ID__c);
			System.debug('---FrRec***-'+FrRec.Opportunity_Owner_ID__c);
			System.debug(FrRec+'---FrRec####***-'+FrRec.Source_Funding_Estimate_Receivable__r.Funding_Estimate__r.Opportunity__c);									
		}
		
		list <Account> AllSchools = [select name, id, ownerid, Account_Commission_Status__c from account where id in:SchoolIDs];
		if(!AllSchools.isEmpty()){
			for(Account sch : AllSchools){
				SchoolToIdMap.put(sch.id,sch);
			}
		}
		
		list<User> lstUser = [select NewAcctCommission__c, ExistingAcctCommission__c, IsActive from user where id in:UserIDs];
		if(!lstUser.isEmpty()){
			for(User usr : lstUser){
				system.debug('user is ' + usr);
				IdToUserMap.put(usr.id,usr);
			}
		}
		for(Funded_Receivable__c Fr : lstFr){
			//Date LastPayDate = Date.parse(Date.today().format());
			Decimal PaymentsAppplied = 0.00, InterestApplied = 0;
			Decimal FVAmount = Fr.FV_Amount__c;
			/*if(Fr.Payments_Applied__c == null){
				PaymentsAppplied = 0.00;
			}
			else{
				PaymentsAppplied = Fr.Payments_Applied__c;
			}*/
			if(FundedReceivableToAllocSumMap.get(Fr.Id) != null){
				/*for (Allocation__c allocation : FundedReceivableToAllocSumMap.get(Fr.Id)){
					PaymentsAppplied = PaymentsAppplied + allocation.Face_Amount_Applied__c;
				}*/
				PaymentsAppplied = FundedReceivableToAllocSumMap.get(Fr.Id);
				InterestApplied = FundedReceivableToIntAllocSumMap.get(Fr.Id);
				Fr.Payments_Applied__c = PaymentsAppplied;
				Fr.Loan_Interest_Paid__c = InterestApplied;																			//2016.09.20 J Caughie - Update FR with amount of interest applied
				Fr.Last_Payment_Received__c = FundedReceivableToRedClearDate.get(Fr.Id);											//2016.09.20 J Caughie - Last Payment
				System.debug('---FVAmount**@'+FVAmount);
				System.debug('---PaymentsAppplied**@'+PaymentsAppplied);
				System.debug('---Fr**@'+Fr);
				if(FVAmount-PaymentsAppplied == 0){
					system.debug('check1');
					if(Fr.Final_Payment_Date__c==null){
						Fr.Final_Payment_Date__c = FundedReceivableToRedClearDate.get(Fr.Id);	
					}
					Draw_Note_TX__c drTX1 = recToDrawNoteTX.get(Fr.Id);
					System.debug('***recToDrawNoteTX***'+recToDrawNoteTX);
					System.debug('***drTX1***'+drTX1);
					if(drTX1 != null){
						drTX1.status__c = 'Paid';
						lstDrawTX.add(drTX1);
					}
					
					Commission__c newCom = new Commission__c();
					system.debug('check2');
					if(GetCommissionRate(Fr) != null){
						newCom.Commission_Rate__c = GetCommissionRate(Fr);
						newCom.Commission_Type__c = GetCommissionType(Fr);
						newCom.Funded_Receivable__c = Fr.id;
						newCom.User__c = Fr.Opportunity_Owner_ID__c;
						newCom.Paid_On__c = 'Discount';
						newCom.Commissionable_Amount__c = Fr.Discount_Amount__c;
						if(Fr.Discount_Amount__c != null){
							newCom.Commission__c = (Fr.Discount_Amount__c * newCom.Commission_Rate__c)/100;
						}
						else{
							newCom.Commission__c = 0.00;
						}
						lstComs.add(newCom);
					}
				}
				lstFundRec.add(Fr);
			}
			else{
				Fr.Payments_Applied__c = 0.00;
				lstFundRec.add(Fr);
			}
		}
		
		if(!lstFundRec.isEmpty()){
			update lstFundRec;
		}
		if(!lstComs.isEmpty()){
			insert lstComs;
		}
		if(!lstDrawTX.isEmpty()){
			update lstDrawTX;
		}
		
	}
	
	public static Decimal GetCommissionRate (Funded_Receivable__c frec){
		System.debug(frec.Opportunity_Owner_ID__c+'--frec->'+frec);
		System.debug('**8SchoolToIdMap.get(frec.school__c)**'+SchoolToIdMap.get(frec.school__c));
		Decimal CommissionRate;
		Account accSchool = SchoolToIdMap.get(frec.school__c);
		User usr = IdToUserMap.get(frec.Opportunity_Owner_ID__c);
		if(usr != null){
			if(accSchool.Account_Commission_Status__c == 'New'){
			CommissionRate = usr.NewAcctCommission__c;
			}
			if(accSchool.Account_Commission_Status__c == 'Existing'){
			CommissionRate = usr.ExistingAcctCommission__c;
			}
		}
		
		return CommissionRate;
	}
	//This method is used to retrieve the Commission Type from the School(Account) while performing commission calculations
	public static String GetCommissionType (Funded_Receivable__c frec){
		String Type;
		Account accSchool = SchoolToIdMap.get(frec.school__c);
		User usr = IdToUserMap.get(accSchool.ownerId);
		if(accSchool.Account_Commission_Status__c == 'New'){
			Type = 'New';
		}
		if(accSchool.Account_Commission_Status__c == 'Existing'){
			Type = 'Existing';
		}
		return Type;
	}
}