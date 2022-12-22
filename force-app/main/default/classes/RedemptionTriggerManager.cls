public class RedemptionTriggerManager {
	
	public static void OnBeforeUpdate(Map<Id, Redemption__c> oldMap, Map<Id, Redemption__c> newMap) {

		List<Redemption__c> reds = new List<Redemption__c>();
		for(Id rId : newMap.keySet()){
			if(newMap.get(rId).Date_Paid__c != null && newMap.get(rId).Distribution_Email_Sent_Date__c != null 
				&& (oldMap.get(rId).Date_Paid__c != newMap.get(rId).Date_Paid__c || oldMap.get(rId).Distribution_Email_Sent_Date__c != newMap.get(rId).Distribution_Email_Sent_Date__c)){
				reds.add(newMap.get(rId));
			}
		}
		calculateBusinessDays(reds);
	}

	public static void calculateBusinessDays(List<Redemption__c> updateReds){

		for(Redemption__c r : updateReds){
			r.Distribution_Email_Sent_Days__c = DateUtilities.calculateBusinessDays(r.Date_Paid__c, r.Distribution_Email_Sent_Date__c);
		}
	}
}