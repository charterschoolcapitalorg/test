/**=====================================================================
 * Appirio, Inc
 * Name: Manager Class RPARedemptionManager
 * Description: T-280412 : Manager Class for the trigger CommissionFromRPARedemption
 * Created Date: [05/26/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  	Description of the update
 * 06/02/2014					Rahul Agrawal					Update Redemption records for populating Face_Amount_Applied_Fee__c
 * 06/02/2014					Rajeev Arya 					T-284079 Capture correct oppty rep name for commission
 * 06/12/2014					Rajeev Arya 					I-117915 Commission Rep change
 * 06/13/2014					Rajeev Arya 					I-117940 Show Commissionable Amount
 * 06/13/2014					Rajeev Arya 					T-286219 Revise trigger code
 =====================================================================*/
public class RPARedemptionManager {
	public static void CreateCommissions(list<RPA_Redemption__c> lstRPARed){
		set<ID> UserIDs = new set<ID>();
		list<Commission__c> lstCommissions = new list<Commission__c>();
		map<ID, User> OwnerIdtoUser = new map<ID, User>();
		list<RPA_Redemption__c> lstRPARedemption = [select id, Redemption__c,Funded_Receivable__c,  RPA__r.Account__r.Account_Commission_Status__c ,
													RPA__r.Account__r.OwnerId, Program_Fee_Collected__c, RPA__r.Account__c,
													Funded_Receivable__r.School__c,Funded_Receivable__r.School__r.Account_Commission_Status__c,
													Redemption__r.School__c,Redemption__r.School__r.Account_Commission_Status__c
													from RPA_Redemption__c
													where id in : lstRPARed];
		if(!lstRPARedemption.IsEmpty()){
			for(RPA_Redemption__c rpaRed : lstRPARedemption){
				/*if(rpaRed.Redemption__c != null){
					UserIDs.add(rpaRed.Redemption__r.School__r.OwnerId);
				}
				else if(rpaRed.Funded_Receivable__c != null){*/
					UserIDs.add(rpaRed.RPA__r.Account__r.OwnerId);
				//}
			}
		}

		for(User usr : [select NewAcctCommission__c, ExistingAcctCommission__c from User where id in : UserIDs]){
			OwnerIdtoUser.put(usr.id,usr);
		}

		if(!lstRPARedemption.IsEmpty()){
			for(RPA_Redemption__c rpaRed1 : lstRPARedemption){

				Commission__c newCom = new Commission__c();
				newCom.Paid_On__c = 'Program Fees Collected';
				//User usrRate = OwnerIdtoUser.get(rpaRed1.Redemption__r.School__r.OwnerId);
				if(rpaRed1.RPA__r.Account__c <> null && rpaRed1.RPA__r.Account__r.OwnerId <> null){
					User usrRate = OwnerIdtoUser.get(rpaRed1.RPA__r.Account__r.OwnerId);
					newCom.User__c = rpaRed1.RPA__r.Account__r.OwnerId;
					system.debug('rpaRed1_RA: '+ rpaRed1);
					if(rpaRed1.Funded_Receivable__c != null &&
						rpaRed1.Funded_Receivable__r.School__c <> null &&
						rpaRed1.Funded_Receivable__r.School__r.Account_Commission_Status__c <> null){
						if(rpaRed1.Funded_Receivable__r.School__r.Account_Commission_Status__c  == 'New'){
							newCom.Commission_Type__c = 'New';
							newCom.Commission_Rate__c = usrRate.NewAcctCommission__c;
						}
						if(rpaRed1.Funded_Receivable__r.School__r.Account_Commission_Status__c  == 'Existing'){
							newCom.Commission_Type__c = 'Existing';
							newCom.Commission_Rate__c = usrRate.ExistingAcctCommission__c;
						}
					}
					system.debug(rpaRed1.Redemption__c +'; '+ rpaRed1.Redemption__r.School__c +'; '+ rpaRed1.Redemption__r.School__r.Account_Commission_Status__c);
					if(rpaRed1.Redemption__c != null &&
						rpaRed1.Redemption__r.School__c <> null &&
						rpaRed1.Redemption__r.School__r.Account_Commission_Status__c <> null){
						if(rpaRed1.Redemption__r.School__r.Account_Commission_Status__c  == 'New'){
							newCom.Commission_Type__c = 'New';
							newCom.Commission_Rate__c = usrRate.NewAcctCommission__c;
						}
						if(rpaRed1.Redemption__r.School__r.Account_Commission_Status__c  == 'Existing'){
							newCom.Commission_Type__c = 'Existing';
							newCom.Commission_Rate__c = usrRate.ExistingAcctCommission__c;
						}
					}
				}
				/*if(rpaRed1.Funded_Receivable__c != null &&
						rpaRed1.Funded_Receivable__r.Source_Opportunity__c <> null &&
						rpaRed1.Funded_Receivable__r.Source_Opportunity__r.OwnerId <> null){
					User usrRate = OwnerIdtoUser.get(rpaRed1.Funded_Receivable__r.Source_Opportunity__r.OwnerId);
					newCom.User__c = rpaRed1.Funded_Receivable__r.Source_Opportunity__r.OwnerId;
					if(usrRate <> null && rpaRed1.Funded_Receivable__r.School__r.Account_Commission_Status__c == 'New'){
						newCom.Commission_Type__c = 'New';
						newCom.Commission_Rate__c = usrRate.NewAcctCommission__c;
					}
					if(usrRate <> null && rpaRed1.Funded_Receivable__r.School__r.Account_Commission_Status__c == 'Existing'){
						newCom.Commission_Type__c = 'Existing';
						newCom.Commission_Rate__c = usrRate.ExistingAcctCommission__c;
					}
				}
				*/
				system.debug('newCom_RA: '+ newCom);
				if(newCom.Commission_Rate__c <> null && newCom.Commission_Type__c != null){
					newCom.RPA_Redemption__c = rpaRed1.id;
					newCom.Commissionable_Amount__c = rpaRed1.Program_Fee_Collected__c;
			    	newCom.Commission__c = (newCom.Commission_Rate__c * rpaRed1.Program_Fee_Collected__c)/100;
			    	lstCommissions.add(newCom);
				}
			}
		}
		// Insert commisions once after Insert trigger executes
		if(!lstCommissions.isEmpty()){
			insert lstCommissions;
		}
	}

	public static void calculateRedemptionFaceAmount(list<RPA_Redemption__c> lstRPARed){
		map<id, Redemption__c> mapRedemption = new map<id, Redemption__c>();
		set<ID> RedemptionIds = new set<ID>();

		for(RPA_Redemption__c rpaRed : lstRPARed){
			if(rpaRed.Redemption__c != null){
				RedemptionIds.add(rpaRed.Redemption__c);
			}
		}

		list<RPA_Redemption__c> lstRPARedemption = [select id, RPA__r.Account__r.Account_Commission_Status__c,RPA__r.Account__r.OwnerId,
													Program_Fee_Collected__c, Redemption__c, Redemption__r.Face_Amount_Applied_Fee__c
													from RPA_Redemption__c
													where Redemption__c in : RedemptionIds];
		if(!lstRPARedemption.IsEmpty()){
			for(RPA_Redemption__c rpaRed1 : lstRPARedemption){
			    // For Redemtion Object
			    if(rpaRed1.Redemption__c != null){
				    if(rpaRed1.Redemption__r.Face_Amount_Applied_Fee__c == null){
				    	rpaRed1.Redemption__r.Face_Amount_Applied_Fee__c = 0.00;
				    }
				    if(!mapRedemption.containsKey(rpaRed1.Redemption__c)){
				    	mapRedemption.put(rpaRed1.Redemption__c, new Redemption__c(id = rpaRed1.Redemption__c,
				    											Face_Amount_Applied_Fee__c = rpaRed1.Redemption__r.Face_Amount_Applied_Fee__c ));
				    }
				    Redemption__c r = mapRedemption.get(rpaRed1.Redemption__c);
			    	r.Face_Amount_Applied_Fee__c = r.Face_Amount_Applied_Fee__c + rpaRed1.Program_Fee_Collected__c;
			    }
			}
		}
		// Redemption Updates after any dml operation
		if(!mapRedemption.isEmpty()){
			update mapRedemption.values();
		}

	}
}