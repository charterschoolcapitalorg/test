/**=====================================================================
 * Appirio, Inc
 * Name: RateCard Trigger
 * Description: Manager Class for Rate Card Trigger
 * Created Date: [06/02/2014]
 * Created By: [Manisha] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
public with sharing class RateCardManager {

	public static void rateCardAfterInsert(list<Rate_Card__c> newCards){

		map<Id,Id> mapRateCardIdParetnId = new map<Id,Id>();

		for(Rate_Card__c newCard : newCards){

			// code to check active cards and create map of Card Id with parent COE District and State Province to inactive sibling cards
			if(newCard.Active__c){
				if(newCard.State_Province__c <> null){
					mapRateCardIdParetnId.put(newCard.Id, newCard.State_Province__c);
				}else if(newCard.COE_District__c <> null){
					mapRateCardIdParetnId.put(newCard.Id, newCard.COE_District__c);
				}
			}
		}

		inactiveOldCards(mapRateCardIdParetnId);
	}

	// method to inactive Old Cards
	private static void inactiveOldCards(map<Id,Id> mapRateCardIdParetnId){
		// get list of old cards that are active
		list<Rate_Card__c> oldCards = [Select Id
									from Rate_Card__c
									where Id Not IN : mapRateCardIdParetnId.keySet()
									AND (COE_District__c IN : mapRateCardIdParetnId.values()
									OR State_Province__c IN : mapRateCardIdParetnId.values())
									AND Active__c = true];

		// make old cards inactive
		for(Rate_Card__c oldCard : oldCards){
			oldCard.Active__c = false;
		}

		if(!oldCards.isEmpty()){
			update oldCards;
		}
	}
}