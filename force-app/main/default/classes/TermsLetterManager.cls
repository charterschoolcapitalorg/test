/**=====================================================================
 * Appirio, Inc
 * Trigger Name: ProgramFeeTrigger
 * Description: I-116731(T-278354) : Manager class for Trigger on Terms_Letter__c for task 'Create RPA monthly report Fields'
 * Created Date: [06/24/2014]
 * Created By: [Manisha Gupta] (Appirio)
 * Date Modified                Modified By                  Description of the update
 *
 =====================================================================*/
public class TermsLetterManager {
	public static void termsLetterAfterUpdate(list<Terms_Letter__c> listTermsLetter, map<Id, Terms_Letter__c> mapOldTermsLetter){
		set<ID> RPAIds = new set<ID>();
		for(Terms_Letter__c termsLetter : listTermsLetter){
			if(termsLetter.Status__c <> mapOldTermsLetter.get(termsLetter.Id).Status__c &&
				(termsLetter.Status__c == 'Active' || mapOldTermsLetter.get(termsLetter.Id).Status__c == 'Active')){
				RPAIds.add(termsLetter.RPA__c);
			}
		}
		updateParentRPAProgramFeeValues(RPAIds);
	}

	private static void updateParentRPAProgramFeeValues(set<Id> RPAIds){

		list<RPA__c> lstRPA = new list<RPA__c>();
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
				RPAIds.remove(fee.Terms_Letter__r.RPA__c);
			}
		}

		/*for(Id rpaId : RPAIds){
			lstRPA.add(new RPA__c(Id = fee.Terms_Letter__r.RPA__c,
								  Current_Program_Fee_Value__c = null,
								  Current_Program_Fee_Months__c = null));
		}*/
		update lstRPA;
	}

}