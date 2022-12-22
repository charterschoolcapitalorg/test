/**=====================================================================
 * Appirio, Inc
 * Name: PAAAdviceGenerator_WSTest
 * Description: Test class for PAAAdviceGenerator_WS
 * Created Date: [07/25/2014]
 * Created By: [Manisha] (Appirio)
 * Date Modified                Modified By                  Description of the update
 *
 =====================================================================*/
@isTest
private class PAAAdviceGenerator_WSTest {

	static testmethod void getPAAAdviceTemplateIdTest(){
		Test.StartTest();

		Account acc = new Account();
		acc.Name = 'Test Account';
		insert acc;
		list<Redemption__c> listRedemption = new list<Redemption__c>();
		for(Integer i = 0; i< 20 ; i++){
			listRedemption.add(TestHelper.createRedemption(acc.Id));
		}

		insert listRedemption;
		String[] setRedempIds = new String[] {};
		for(Redemption__c redemp : listRedemption){
			setRedempIds.add(redemp.Id);
		}



		list<APXTConga4__Conga_Merge_Query__c> listCongaQuery = new list<APXTConga4__Conga_Merge_Query__c>();
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA School'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA PCSRC'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA EastWestBank'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA TwoSigma'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA CSC'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA EWB'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA TwoSigmaBankUsage'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA PCSR'));
		listCongaQuery.add(new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'PAA BankUsage'));

		insert listCongaQuery;

		APXTConga4__Conga_Template__c template = new APXTConga4__Conga_Template__c(APXTConga4__Name__c = 'PAA Advice');
		insert template;

		PAAAdviceGenerator_WS.GeneratePAAAdvice(setRedempIds);
		Test.StopTest();
	}
}