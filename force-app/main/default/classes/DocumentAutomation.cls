/**=====================================================================
 * Name: DocumentAutomation
 * Description: Class for document automation
 * Created Date: [08/10/2017]
 * Created By: John Caughie
 * Date Modified                Modified By                 Description of the update
 * 
 * 2017.09.01					John Caughie				Added logic for DBA
 * 2017.09.01					John Caughie				Disabled DocuSign   
 * 2017.09.06					John Caughie				Added Legal Notice splits
 * 2022.06.13                   Slava Krel                  Usage picklist value change
 * 2022.08.22                   Slava Krel                  Bank usage record criteria   
 =====================================================================================**/
global with sharing class DocumentAutomation {
	
	private static String sessionId{get;}
	private static String fullRecordURL{get;}
	private static String orgId{get;}
	private static Opportunity opp{get;}
	private static Conga_Query_Ids__c congaQueries {get;}
	private static List<Id> excludeSignatories{get;}

	@InvocableMethod(label='Get Conga URL' description='Returns the list of conga URLs for the current opportunity.' category='Opportunity')
	public static List<String> generateDocsFlow(List<Id> recordIds){
		String returnURL = '';
		opp = getOpportunity(recordIds[0]);
		String docTemplate = '';
		docTemplate = 'WC - ' + opp.State__c;
		Boolean adminUser = isCurrentUserAdmin();
		List<String> urls = new List<String>();
		urls.add(oppFundingDocsURL(recordIds[0], docTemplate, adminUser));
		return urls;
	}


	webservice static String oppFundingDocsURL(Id recordId, String templates, Boolean isAdminUser){
    	
		String endUrl;
		excludeSignatories = new List<Id>();
		//mapCongaQueryNameMap = getCongaQueryMap(recordId);
		congaQueries = Conga_Query_Ids__c.getOrgDefaults();
		opp = getOpportunity(recordId);
		endUrl = generateBaseURL(recordId);
		endUrl += '&TemplateGroup=' + templates;
		endUrl += '&OFN=' + opp.Account_Nick_Name__c + ' ' + '{Template.Label}' + ' ' + opp.Internal_Ref__c;
		endUrl += '&MTOFN=' + opp.Opp_Ref_Num__c + ' Docs';		
		endUrl += '&ZipPDFs=1';
		endUrl += '&ZipFiles=1';
		endUrl += '&SelectTemplates=1';

		if(!isAdminUser){
			//Disable email
			endUrl += '&DS2=1';
			//Disable attach
			endUrl += '&DS10=1';
			//Disable logging
			endUrl += '&DS3=1';
			//Disable view data
			endUrl += '&DS5=1';
			//Disable template view
			endUrl += '&DS6=1';
			//Disable template builder
			endUrl += '&DS9=1';
			//Return to original record
			endUrl += '&DS7=13';
		}

		endUrl += '&queryId=';
		//the following do not depend on the receivables being purchased
		endUrl += '[BNK]' + congaQueries.Opp_School_Banks__c + '?pv0=' + recordId + ',';
		endUrl += '[BLK]' + congaQueries.Opp_School_Blocked_Acc__c + '?pv0=' + recordId + ',';
		endUrl += '[NOA]' + congaQueries.Opp_NoA_Details__c + '?pv0=' + recordId + ',';
		endUrl += '[SCL]' + congaQueries.Opp_Schools__c + '?pv0=' + recordId + ',';
		endUrl += '[AS]' + congaQueries.Opp_AS_List__c + '?pv0=' + opp.AccountId + ',';
		endUrl += '[MAS]' + congaQueries.Opp_MAS_List__c + '?pv0=' + opp.AccountId + ',';
		endUrl += '[TRM]' + congaQueries.Opp_Charter_Terms__c + '?pv0=' + recordId + ',';
		endUrl += '[LN]' + congaQueries.Opp_LNs__c + '?pv0=' + opp.AccountId + ',';
		endUrl += '[IMG]' + congaQueries.Opp_Bank_Usage_Attachments__c + '?pv0=' + oppSchoolBankUsageId(recordId) + ',';
		endUrl += '[CMO]' + congaQueries.Opp_Charter_CMO__c + '?pv0=' + opp.AccountId + ',';
		endUrl += '[LNP]' + congaQueries.Opp_LN_Primary__c + '?pv0=' + opp.AccountId + ',';
		endUrl += '[LNC]' + congaQueries.Opp_LN_CCs__c + '?pv0=' + opp.AccountId + ',';
				
		//if receivables are purchased the following are based on Funded Receivables otherwise use Funding Estimate Receivables
		if(opp.Receivables_Purchased__c){
				endUrl += '[FY]' + congaQueries.Opp_FR_Rec_FY_Summary__c + '?pv0=' + recordId + ',';
				endUrl += '[RS]' + congaQueries.Opp_FR_Summary__c + '?pv0=' + recordId + ',';
				endUrl += '[NR]' + congaQueries.Opp_FR_Receivables__c + '?pv0=' + recordId + ',';
				endUrl += '[DED]' + congaQueries.Opp_FR_Deduction_Desc__c + '?pv0=' + recordId + ',';
				endUrl += '[RECS]' + congaQueries.Opp_FR_Recs__c + '?pv0=' + recordId + ',';
				endUrl += '[SUMM]' + congaQueries.Opp_FR_Summ__c + '?pv0=' + recordId + ',';
			} else {
				endUrl += '[FY]' + congaQueries.Opp_FE_Rec_FY_Summary__c + '?pv0=' + recordId + ',';
				endUrl += '[RS]' + congaQueries.Opp_FE_Summary__c + '?pv0=' + recordId + ',';
				endUrl += '[NR]' + congaQueries.Opp_FE_Receivables__c + '?pv0=' + recordId + ',';
				endUrl += '[DED]' + congaQueries.Opp_FE_Deduction_Desc__c + '?pv0=' + recordId + ',';
				endUrl += '[RECS]' + congaQueries.Opp_FE_Recs__c + '?pv0=' + recordId + ',';
				endUrl += '[SUMM]' + congaQueries.Opp_FE_Summ__c + '?pv0=' + recordId + ',';
			}

		//Docusign parameters
		//endUrl += '&DocuSignVisible=1';
		endUrl += '&DocuSignEmailSubject=Action+Needed+-+' + opp.Account.Name + '+-+Charter+School+Capital+Transaction+Documents';
		endUrl += '&DocuSignEmailBody=To+meet+your+funding+date+of+' + opp.CloseDate.format() + ',+please+sign+the+attached+documents+via+DocuSign+by+' + opp.Pre_Close_Date__c.format() + '+at+3pm+PST.+Please+let+us+know+if+you+have+any+questions.';

		//Listed Signers
		endUrl += '&DocuSignR1Type=Signer';
		endUrl += '&DocuSignR1Role=Signer+1';
		endUrl += '&DocuSignR1ID=' + opp.Signer_1__c;
		endUrl += '&DocuSignR1RoutingOrder=1';
		excludeSignatories.add(opp.Signer_1__c);
		endUrl += '&DocuSignR2Type=Signer';
		endUrl += '&DocuSignR2Role=Signer+2';
		endUrl += '&DocuSignR2ID=' + opp.Signer_2__c;
		endUrl += '&DocuSignR2RoutingOrder=1';
		excludeSignatories.add(opp.Signer_2__c);
		
		//Conditionally attach the management signers
		if(opp.Signer_Manager_1__c != null){
			endUrl += '&DocuSignR3Type=Signer';
			endUrl += '&DocuSignR3Role=Signer+3';
			endUrl += '&DocuSignR3ID=' + opp.Signer_Manager_1__c;
			endUrl += '&DocuSignR3RoutingOrder=1';
			excludeSignatories.add(opp.Signer_Manager_1__c);
		}
		if(opp.Signer_Manager_2__c != null){
			endUrl += '&DocuSignR4Type=Signer';
			endUrl += '&DocuSignR4Role=Signer+4';
			endUrl += '&DocuSignR4ID=' + opp.Signer_Manager_2__c;
			endUrl += '&DocuSignR4RoutingOrder=1';
			excludeSignatories.add(opp.Signer_Manager_2__c);
		}
		if(opp.Signer_AP__c != null){
			endUrl += '&DocuSignR5Type=Signer';
			endUrl += '&DocuSignR5Role=Signer+5';
			endUrl += '&DocuSignR5ID=' + opp.Signer_AP__c;
			endUrl += '&DocuSignR5RoutingOrder=1';
			excludeSignatories.add(opp.Signer_AP__c);
		}

		//CSC carbon copies
		endUrl += '&DocuSignR6Type=Carbon+Copy';
		endUrl += '&DocuSignR6ID=' + opp.Paralegal__c;
		endUrl += '&DocuSignR6RoutingOrder=1';
		endUrl += '&DocuSignR7Type=Carbon+Copy';
		endUrl += '&DocuSignR7ID=' + opp.User__c;
		endUrl += '&DocuSignR7RoutingOrder=1';

		//add additional FD recipients
		Integer startingCC = 10;
		Set<Id> recipients = new Set<Id>();
		recipients.addAll(getOtherFundingDocRecipients(opp.AccountId));
		for (Id recipient : recipients){
			endUrl += '&DocuSignR' + startingCC + 'Type=Carbon+Copy';
			endUrl += '&DocuSignR' + startingCC + 'ID=' + recipient;
			endUrl += '&DocuSignR' + startingCC + 'RoutingOrder=1';
			startingCC++;
		}

    	return endUrl;
	}

	private static String generateBaseURL(Id recordId){
		sessionId = UserInfo.getSessionId();
		fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;
		orgId = UserInfo.getOrganizationId();
		// String endpointUrl = 'https://composer.congamerge.com/composer8/index.html';
		// endpointUrl += '?SessionId=' + sessionId;
		String endpointUrl = '/apex/APXTConga4__Conga_Composer';
		endpointUrl += '?SessionId=' + sessionId;
		endpointUrl += '&ServerUrl=' + URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/37.0/' + orgId;
		endpointUrl += '&id=' + recordId;
		return endpointUrl;
	}

	private static Opportunity getOpportunity(Id oppId){
		return [SELECT Id, Account_Nick_Name__c, AccountId, Account.Name, Receivables_Purchased__c, DocuSign_Transaction__c, 
		Internal_Ref__c, Opp_Ref_Num__c, Pre_Close_Date__c, CloseDate, Signer_1__c, 
		Signer_2__c, Signer_Manager_1__c, Signer_Manager_2__c, Paralegal__c, User__c, Signer_AP__c, State__c FROM Opportunity WHERE id = : oppId];
	}

	private static List<Id> getOtherFundingDocRecipients(Id charterId){
		List<Id> fundingCCs = new List<Id>();
		System.debug('exclude: ' + excludeSignatories);
		for (Related_Contact__c r :[SELECT Contact__c FROM Related_Contact__c WHERE Funding_Docs__c = True AND Inactive__c = False AND Signatory__c = null AND Account__c =  :charterId AND Contact__r.id NOT IN :excludeSignatories]){
			fundingCCs.add(r.Contact__c);
		}
		System.debug('ccs: ' + fundingCCs);
		return fundingCCs;
	}

	private static Id oppSchoolBankUsageId(Id oppId){
		Id oppSchoolBankUsage; //= new Id();
		List<Bank_Usage__c> bankUsages = [SELECT Id, Account__c, Usage__c, Account_Number__c, Start_Date__c
                                            FROM Bank_Usage__c 
                                            WHERE Usage__c = 'Working Capital Deposit Account' 
                                            AND Account__c IN (SELECT School__c FROM Opp_School__c WHERE Opportunity__c = : oppId)
                                            AND End_Date__c = null
                                            ORDER BY Start_Date__c DESC];
		System.debug(oppId);
		if(bankUsages.size() > 0){
			oppSchoolBankUsage = bankUsages[0].Id;
		}
		return oppSchoolBankUsage;
	}

	private static Boolean isCurrentUserAdmin(){
		Id currentUserProfile = UserInfo.getProfileId();
		Profile p = [SELECT ID, Name FROM Profile WHERE id = :currentUserProfile];
		return p.Name.contains('System Administrator');
	} 

}