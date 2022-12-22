/**=====================================================================
 * Appirio, Inc
 * Trigger Name: ProgramFeeTriggerManager
 * Description: T-278354 : Manager Class for Trigger ProgramFeetrigger
 * Created Date: [05/23/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
public class ProgramFeeTriggerManager {

	public static void RecentProgramFeeRPAUpdate(list<Program_Fee__c> lstPgmFee){
		set<ID> RPAIds = new set<ID>();
		//set<Id> setProcessedRPAIds = new set<Id>();
		list<RPA__c> lstRPA = new list<RPA__c>();
		for(Program_Fee__c pgmFee : [select Terms_Letter__r.RPA__c
									from Program_Fee__c
									where id in:lstPgmFee]){
			RPAIds.add(pgmFee.Terms_Letter__r.RPA__c);
		}

		for(Program_Fee__c fee : [Select Program_Fee__c, Start_Date__c, End_Date__c, Terms_Letter__r.RPA__c
									from Program_Fee__c
									where End_Date__c >= TODAY
									and Start_Date__c <= TODAY
									and Terms_Letter__r.RPA__c in : RPAIds
									and Terms_Letter__r.Status__c = 'Active'
									order by End_Date__c desc]){
			if(RPAIds.contains(fee.Terms_Letter__r.RPA__c)){
				lstRPA.add(new RPA__c(
										Id = fee.Terms_Letter__r.RPA__c,
										Current_Program_Fee_Value__c = fee.Program_Fee__c,
										Current_Program_Fee_Months__c = fee.Start_Date__c.monthsBetween(fee.End_Date__c)));
				//setProcessedRPAIds.add(fee.Terms_Letter__r.RPA__c);
				RPAIds.remove(fee.Terms_Letter__r.RPA__c);
			}
		}

		/*for(Id rpaId : RPAIds){
			lstRPA.add(new RPA__c(
								Id = rpaId,
								Current_Program_Fee_Value__c = null,
								Current_Program_Fee_Months__c = null));
		}*/
		update lstRPA;
	}
}