/**=====================================================================
 * Appirio, Inc
 * Manager Class Name: FundingEstimateReceivableTriggerManager
 * Description: Case :00001565 - Identify receivables being purchased on a weekend or holiday
 * Created Date:[09/09/2019]
 * Created By: Johnno
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
public class FundingEstimateReceivableTriggerManager {
	public static void determineBusinessDay(List<Funding_Estimate_Receivable__c> feReceivables){
		for(Funding_Estimate_Receivable__c fer : feReceivables){
			fer.Is_not_a_Business_Day__c = !DateUtilities.isBusinessDay(fer.Purchase_Date__c);
		}
	}
}