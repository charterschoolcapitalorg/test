/**=====================================================================
 * Appirio, Inc
 * Manager Class Name: FundedReceivableManager
 * Description: T-278335 : Manager Class for Trigger FundedReceivableAfterInsertAfterUpdate
 * Created Date: [05/13/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 06/03/2014 					MANISHA GUPTA 			     T-284077 : Create RPA-Redemption from FR
 * 06/13/2014					Rajeev Arya 			     I-117940 Show Commissionable Amount
 * 06/27/2014					Rajeev Arya 			     I-119257 Update PurchaseUID field when is blank for new Funded Receivable
 * 08/23/2016					John Caughie 			     AccountUpdateAfter - Roll-up for last purchase date and to make account status = 'Active'
 * 09/08/2016					John Caughie 			     AccountUpdateAfter - Roll-up for max expected date and GRV/FV outstanding 
 =====================================================================*/
public class FundedReceivableManager {
	//public static Boolean UpdatedOnce = true;
	public static Set<ID> SchoolIDs = new Set<ID>();
	public static Set<ID> UserIDs = new Set<ID>();
	public static Set<ID> FRIDs = new Set<ID>();
	public static map<ID,Account> SchoolToIdMap =  new  map<ID,Account>();
	public static list <Account> AccList = new list <Account> ();
	public static map <ID, user> IdToUserMap = new  map <ID, user>();
	public static map <ID, Funded_Receivable__c> IdToFundedRecMap = new map <ID, Funded_Receivable__c>();
	public static ID School;
	public static list<Commission__c> lstCommission =  new list<Commission__c>();
	public static list<Funded_Receivable__c> lstFundRec =  new list<Funded_Receivable__c>();

	public static void UpdateFundedReceivablePurchaseUID(List<Funded_Receivable__c> frec){
		AggregateResult[] MaxPurUID = [select max(purchaseuid__c) mp from funded_receivable__c];
		String MaxPurchaseUID = (String)MaxPurUID[0].get('mp');
		Integer MaxPurchaseUIDInt;
		if(MaxPurchaseUID != null){
			MaxPurchaseUIDInt = Integer.ValueOf(MaxPurchaseUID);
		}
        else{
        	MaxPurchaseUIDInt = 0;
        }
		for(Funded_Receivable__c FunRec : frec){
			MaxPurchaseUIDInt = MaxPurchaseUIDInt + 1;
			FunRec.purchaseuid__c = String.ValueOf(MaxPurchaseUIDInt);
		}
	}
	
	public static void AccountUpdateAfter(List<Funded_Receivable__c> frec){
		AccList = new list <Account> ();
		for(Funded_Receivable__c FunRec : frec){
			SchoolIDs.add(FunRec.School__c);
		}

		SchoolToIdMap = new map<Id, Account>([select name, id, ownerid, first_purchase_date__c, last_purchase_date__c, account_status__c from account where id in:SchoolIDs]);			//2016.08.23 J Caughie - Added Last Purchase Date
		/*if(!AllSchools.isEmpty()){
			for(Account sch : AllSchools){
				SchoolToIdMap.put(sch.id,sch);
			}
		}*/
		AggregateResult[] groupedResultsSchool = [select min(purchase_date__c) minp, max(purchase_date__c) maxp, school__c,
													sum(FV_Amount_Due__c ) FV_Due, sum(GRV_Amount_Due__c ) GRV_Due
												from  Funded_Receivable__c
												where school__c in : SchoolIDs
												group by school__c];															//2016.08.23 J Caughie - Added max aggregate 


		//Map School Id to Max Expected pay date for active receivables - used to update account
		Map<Id, Date> accountToMaxDate = new Map<Id, Date>();
		AggregateResult[] groupedMaxExpectedPayDate = [SELECT School__c Id, Max(Expected_Pay_Date__c) Max_Exp 
												FROM Funded_Receivable__c 
												WHERE Status__c = 'Active' AND School__c in : SchoolIDs
												GROUP BY School__c];
		for(AggregateResult ar : groupedMaxExpectedPayDate){
		    accountToMaxDate.put((Id)ar.get('Id'), (Date)ar.get('Max_Exp'));
		}


		system.debug('AccountUpdateAfter.groupedResultsSchool: '+ groupedResultsSchool);
		if(system.Test.isRunningTest()){
			AccList = new list <Account> ();
		}
		Account acc;
		for (AggregateResult ar : groupedResultsSchool){
			School = (Id)ar.get('school__c');
			acc = SchoolToIdMap.get(School);
			// RA: As discussed with Rajeev, Account Purchase date should be lowest date of child recevibales
			if(acc <> null){
				acc.first_purchase_date__c = (Date)ar.get('minp');
				acc.last_purchase_date__c = (Date)ar.get('maxp');													//2016.08.23 J Caughie - Added max date
				acc.FV_Outstanding_School__c = (Decimal)ar.get('FV_Due');											//2016.09.08 J Caughie - Added FV O/S
				acc.GRV_Outstanding_School__c = (Decimal)ar.get('GRV_Due');											//2016.09.08 J Caughie - Added GRV O/S
				acc.Account_Status__c = 'Active Client';															//2016.08.23 J Caughie - Change to Active
				acc.Max_Expected_Pay_Date__c = null;
				//Update Max Expected Pay Date with date from Active receivables
				if(accountToMaxDate.containsKey(School)){
					acc.Max_Expected_Pay_Date__c = (Date)accountToMaxDate.get(School);
				}
				AccList.add(acc);
			}
		}
		system.debug('AccountUpdateAfter.AccList: '+ AccList);
		update AccList;

	}

	public static void CommissionCaculation (List<Funded_Receivable__c> frlst, Map<ID, Funded_Receivable__c> oldValueMap, boolean isInsert){
		//If (UpdatedOnce){
			List<RPA_Redemption__c> listRPARedemToInsert = new list<RPA_Redemption__c>();

			for(Funded_Receivable__c FunRec : frlst){
				// 06/03/2014 : MANISHA GUPTA : T-284077 : Create RPA-Redemption from FR
				if(isInsert){
					if(funRec.Program_Fees_Collected__c <> null){
						listRPARedemToInsert.add(new RPA_Redemption__c(
													Funded_Receivable__c = funRec.Id,
													Program_Fee_Collected__c = funRec.Program_Fees_Collected__c,
													RPA__c = funRec.RPA__c));
					}
				}
				SchoolIDs.add(FunRec.School__c);
				UserIDs.add(FunRec.Opportunity_Owner_ID__c);
				system.debug('rajeev 1');
			}

			// insert list of RPA Redemptions (RPA Program Fee Collected)
			if(!listRPARedemToInsert.isEmpty()){
				try{
					insert listRPARedemToInsert;
				}catch(Exception e){
					system.debug('Exception while inserting RPA Redemptions' + e.getMessage());
				}
			}
			system.debug('rajeev 1' + UserIDs);

			SchoolToIdMap = new map<Id, Account>([select name, id, ownerid, Account_Commission_Status__c from account where id in:SchoolIDs]);

			IdToUserMap = new map<Id, User>([select NewAcctCommission__c, ExistingAcctCommission__c, IsActive from user where id in:UserIDs]);

			decimal commissionRate;
			Funded_Receivable__c oldFr;
			User usrCheck;
			Account accSchool;
			Commission__c newCom;
			if(system.Test.isRunningTest()){
				lstCommission = new list <Commission__c> ();
			}
			for (Funded_Receivable__c f: frlst) {
		        oldFr = oldValueMap <> null ? oldValueMap.get(f.ID) : null;
		        usrCheck = IdToUserMap.get(f.Opportunity_Owner_ID__c);
				if(usrCheck != null){
			       	if(f.FV_Amount_Due__c != 0.00){
			       		if(usrCheck != null && usrCheck.IsActive == true ){
				        	commissionRate = GetCommissionRate(f, usrCheck);
				        	accSchool = SchoolToIdMap.get(f.school__c);
					        if (f.Transaction_Fee_Collected__c <> null
					        		&& f.Transaction_Fee_Collected__c != 0.00 && commissionRate <> null &&
					        			(isInsert || (!isInsert && f.Transaction_Fee_Collected__c != oldFr.Transaction_Fee_Collected__c))) {
					           	newCom = new Commission__c();
					            newCom.Commission_Rate__c = commissionRate;
					            newCom.Commission_Type__c = GetCommissionType(f);
					            newCom.Funded_Receivable__c = f.id;
					            //Account accSchool1 = SchoolToIdMap.get(f.school__c);
					            newCom.User__c = f.Opportunity_Owner_ID__c;
			            		Decimal AddedFeesTr = 0;
		            			newCom.Paid_On__c = 'Transaction Fees Collected';
		            			if(oldFr <> null && oldFr.Transaction_Fee_Collected__c <> null){
		            				AddedFeesTr = f.Transaction_Fee_Collected__c - oldFr.Transaction_Fee_Collected__c;
		            			}
		            			else {
		            				AddedFeesTr = f.Transaction_Fee_Collected__c;
		            			}
		            			newCom.Commissionable_Amount__c = AddedFeesTr;
		            			newCom.Commission__c = (newCom.Commission_Rate__c * AddedFeesTr)/100;
	        					lstCommission.add(newCom);
					        }
					 	}

	    			}
				}
			}

			system.debug('CommissionCaculation.lstCommission: '+lstCommission);
			if(!lstCommission.IsEmpty()){
				insert lstCommission;
			}
	}


	public static Decimal GetCommissionRate (Funded_Receivable__c frec, User usr){
		Decimal CommissionRate;
		Account accSchool = SchoolToIdMap.get(frec.school__c);
		if(accSchool.Account_Commission_Status__c == 'New'){
			CommissionRate = usr.NewAcctCommission__c;
		}
		if(accSchool.Account_Commission_Status__c == 'Existing'){
			CommissionRate = usr.ExistingAcctCommission__c;
		}
		return CommissionRate;
	}
	//This method is used to retrieve the Commission Type from the School(Account) while performing commission calculations
	public static String GetCommissionType (Funded_Receivable__c frec){
		String Type;
		Account accSchool = SchoolToIdMap.get(frec.school__c);
		if(accSchool.Account_Commission_Status__c == 'New'){
			Type = 'New';
		}
		if(accSchool.Account_Commission_Status__c == 'Existing'){
			Type = 'Existing';
		}
		return Type;
	}
}