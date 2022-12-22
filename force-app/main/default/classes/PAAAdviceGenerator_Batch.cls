/**=====================================================================
 * Appirio, Inc
 * Name: Batch Class to Generate PAA Advice for Selected Redemptions if number of selected redemptions is greater than 10
 * Description:
 * Created Date: [06/25/2014]
 * Created By: [Manisha Gupta] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 08/07/2014 					Manisha Gupta					Updated to resolve session id null issue in production
 =====================================================================*/
global with sharing class PAAAdviceGenerator_Batch implements database.Batchable<sObject>, Database.AllowsCallouts{
	set<Id> redemptionIds;
	// 08/07/2014 : MG : Updated to resolve sessionId issue in Production
	String sessionId;
	String orgId;

	// 08/07/2014 : MG : Updated to resolve sessionId issue in Production
	public PAAAdviceGenerator_Batch(set<Id> redemptionIds, String sessionId, String orgId){
		this.redemptionIds = redemptionIds;
		this.sessionId = sessionId;
		this.orgId = orgId;
	}

	global Database.QueryLocator start(Database.BatchableContext context) {
		String query = 'Select Id, School__c, School__r.Name, PAA_Extract_Date__c, PAA_Record__c, Date_Paid__c from Redemption__c where Id in :redemptionIds';

		return database.getQueryLocator(query);
  	}

  	global void execute(Database.BatchableContext context, List<Redemption__c> listRedemption){

  		for(Redemption__c redemption : listRedemption){
  			// 08/07/2014 : MG : Updated to resolve sessionId issue in Production
  			PAAAdviceGenerator_WS.generatePAAAdviceForRedemption(redemption, sessionId, orgId);
        	if(redemption.PAA_Extract_Date__c == null){
				redemption.PAA_Extract_Date__c = date.Today();
			}
			if(redemption.Date_Paid__c == null){
                redemption.Date_Paid__c = date.Today();
            }
  		}

  		if(!listRedemption.isEmpty()){
  			update listRedemption;
  		}
  	}

  	global void finish(Database.BatchableContext context){

  	}
}