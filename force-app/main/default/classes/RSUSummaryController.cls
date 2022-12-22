/**=====================================================================
 * Appirio, Inc
 * Name: RSUSummaryController
 * Description: COntroller class to create RSU Summary for Charter Holder Accounts
 * Created Date: [07/16/2014]
 * Created By: [Manisha Gupta] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 08/07/2014 					Manisha Gupta					Updated to resolve session id null issue in production
 * 09/21/2014                   John Caughie                    Issue with paid off balances not being zeroed out
 **=====================================================================================**/
global class RSUSummaryController {

    private set<String> accountIds;
    private final static String urlFieldName = 'Conga_Conductor_RSU_flexible_dates__c';
    public RSU_Dates__c rsuDateSetting{get;set;}
    private ApexPages.StandardSetController controller;
    List<Id> accountIdsList = new List<Id>();
    private String partnerServerUrl;

	public RSUSummaryController(){
        accountIds = new set<String>(ApexPages.CurrentPage().getParameters().get('accountIds').split(','));
		system.debug('----------' + accountIds);
		rsuDateSetting = new RSU_Dates__c();

    }
    
    public RSUSummaryController(ApexPages.StandardSetController controller){
		this.controller = controller;
        for (sObject sObj : controller.getSelected()){
            accountIdsList.add(sObj.Id);
        }
        system.debug('----------' + accountIdsList);
        rsuDateSetting = new RSU_Dates__c();
    }

    public PageReference rsuGeneration(){
        updateRsuDates();
        partnerServerUrl = 'https://'+ApexPages.currentPage().getHeaders().get('Host')+'/services/Soap/u/49.0/'+UserInfo.getOrganizationId();
        return generateCongaBatchUrl();
    }

    public void updateRsuDates(){
		if(rsuDateSetting.Id == null){
			delete [Select Id from RSU_Dates__c];
		}
        rsuDateSetting.setupOwnerId = userInfo.getUserId();
        rsuDateSetting.Start_Date_String__c = String.valueOf(rsuDateSetting.Start_Date__c).substring(0,10);
        rsuDateSetting.End_Date_String__c = String.valueOf(rsuDateSetting.End_Date__c).substring(0,10);
        upsert rsuDateSetting;
    }

    public PageReference generateCongaBatchUrl() {
        PageReference conductorUrl = new PageReference('https://conductor.congamerge.com?');
        conductorUrl.getParameters().put('MOID', String.join(accountIdsList,','));
        conductorUrl.getParameters().put('SessionId',  UserInfo.getSessionID());
        conductorUrl.getParameters().put('ServerUrl',  partnerServerUrl);
        conductorUrl.getParameters().put('UrlFieldName',  urlFieldName);
        System.debug('conductorUrl ' + conductorUrl);
        return conductorUrl;
      }




	public void updateBalance(){
		if(rsuDateSetting.Id == null){
			delete [Select Id from RSU_Dates__c];
		}
		rsuDateSetting.setupOwnerId = userInfo.getUserId();
		upsert rsuDateSetting;

		//query FV_Amount of all Funded_Receivables__c records where Charter_Holder__c = Account.Id AND (Final_Payment__c >
		//End Date OR Final_Payment__c = NULL) AND Purchase_Date__c <= End Date ------ Subtract from that result, SUM of Face_Amount_Applied__c
		//from all Allocation__c records where Allocation__c.Funded_Receivable__c is in list from previous query AND
		//Redemption_Clear_Date__c <= End Date
		//map<Id,decimal> mapAccountIdNewBal1 = new map<Id,decimal>();        2014.09.26 J Caughie - not used in code
		map<Id,decimal> mapAccountIdNewBal = new map<Id, decimal>();

        List<Account> listAccount = [Select Id
                                        From Account
                                        Where Id in : accountIds];

        // 2014.09.29 J Caughie - CH's without any outstanding Funded Receivables, but values paid off did not have their
        // balance re-set to zero if one existed previously. This FOR loop initializes the balance to zero for all selected accounts.

        for(Account acc : listAccount){
            mapAccountIdNewBal.put(acc.Id, 0);
        }
        System.debug('zeroed balances: ' + mapAccountIdNewBal);

        //2014.09.29 J Caughie - end

		List<Funded_Receivable__c> listFundedRec = [Select FV_Amount__c, Charter_Holder__c
													from Funded_Receivable__c
													where Charter_Holder__c in : accountIds
													and (Final_Payment_Date__c > :rsuDateSetting.End_Date__c
													OR Final_Payment_Date__c = NULL)
													AND Purchase_Date__c <= :rsuDateSetting.End_Date__c];

		for(Funded_Receivable__c rec : listFundedRec){
			decimal amount = mapAccountIdNewBal.get(rec.Charter_Holder__c);
			if(amount == null){
				mapAccountIdNewBal.put(rec.Charter_Holder__c, rec.FV_Amount__c);
			}else{
				mapAccountIdNewBal.put(rec.Charter_Holder__c, amount + rec.FV_Amount__c);
			}
		}

		for(Allocation__c alloc : [Select Face_Amount_Applied__c, Funded_Receivable__r.Charter_Holder__c
									from Allocation__c
									where Funded_Receivable__c in :listFundedRec
									and Redemption_Date_Cleared__c <= :rsuDateSetting.End_Date__c]){

			Id accountId = alloc.Funded_Receivable__r.Charter_Holder__c;
			decimal amount = mapAccountIdNewBal.get(accountId);
			mapAccountIdNewBal.put(accountId, amount - alloc.Face_Amount_Applied__c);

		}


		list<Account> listAccountsToUpdate = new list<Account>();

		for(Id accId : mapAccountIdNewBal.keySet()){
			listAccountsToUpdate.add(new Account(Id = accId, RSU_New_Balance__c = mapAccountIdNewBal.get(accId)));
		}

		if(!listAccountsToUpdate.isEmpty()){
			update listAccountsToUpdate;
		}



	}

	public void createRSUSummary(){

		map<Id,Account> mapAccount = new map<Id, Account>([Select Id, Name
										From Account
										Where Id in : accountIds]);
		system.debug('here3');
        set<Id> setAccountIds = new set<Id>();
        Integer counter = 1;
		String StartDate = String.valueOf(rsuDateSetting.Start_Date__c).substring(0,10);
		String EndDate = String.valueOf(rsuDateSetting.End_Date__c).substring(0,10);
        for(Account account : mapAccount.values()){
            if(counter++ <= 10){
            	system.debug('here4');
                generateRSUSummaryForAccount(account.Id, startDate, endDate, account.Name, userInfo.getSessionId(), userInfo.getOrganizationId());
            }else{
            	system.debug('here5');
                setAccountIds.add(account.Id);
            }
        }


        if(!setAccountIds.isEmpty()){
        	system.debug('here7');
            system.debug('here');
            if(!Test.isRunningTest()){
            	system.debug('here8');
                DataBase.ExecuteBatch(new RSUSummary_Batch(setAccountIds, startDate, endDate, userInfo.getSessionId(), userInfo.getOrganizationId()), 10);
            }
        }
	}

	public static void generateRSUSummaryForAccount(Id accId, String startDate, String endDate, String accName, String sessionId, String orgId){
        map<String, Id> mapCongaQueryNameId = new map<String,Id>();
        for(APXTConga4__Conga_Merge_Query__c query : [Select Id, APXTConga4__Name__c
        												from APXTConga4__Conga_Merge_Query__c
        												where APXTConga4__Name__c like 'RSU %']){
        	mapCongaQueryNameId.put(query.APXTConga4__Name__c, query.Id);
		}



		//system.debug('--------' + startDate + '------' + String.valueOf(rsuDateSetting.Start_Date__c).substring(0,10));

		system.debug('-------------' + mapCongaQueryNameId);
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setTimeout(60000);
        String endpointUrl = 'https://www.appextremes.com/apps/Conga/PM.aspx';
        endpointUrl += '?SessionId=' + sessionId;
        endpointUrl += '&ServerUrl=' + URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/28.0/' + orgId;
        endpointUrl += '&id=' + accId;
        endpointUrl += '&TemplateId='+getRSUSummaryTemplateId('RSU Summary');
        endpointUrl += '&APIMode=1&OFN=RSU_Summary_'+accName.replaceAll(' ', '_');
        endpointUrl += '&queryId=[Dates]'+mapCongaQueryNameId.get('RSU Dates')+
        				',[Outstanding]'+mapCongaQueryNameId.get('RSU Outstanding')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
        				',[SoldSummary]'+mapCongaQueryNameId.get('RSU SoldSummary')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
        				',[CollectedSummary]'+mapCongaQueryNameId.get('RSU CollectedSummary')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
        				',[Sold]'+mapCongaQueryNameId.get('RSU Sold')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
        				',[Collected]'+mapCongaQueryNameId.get('RSU Collected')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
        				',[PAA]'+mapCongaQueryNameId.get('RSU PAA')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
        				',[Penalty]'+mapCongaQueryNameId.get('RSU Penalty')+'?pv0='+accId+
        				',[Bank]'+mapCongaQueryNameId.get('RSU Bank')+'?pv0='+accId+
                        '&DefaultPDF=1';
        req.setEndpoint(endpointUrl);
        System.debug(endpointUrl);
        Http http = new Http();
        httpresponse res = new httpresponse ();
        if(!test.isRunningTest()){
        	system.debug('here10');
            res = http.send(req);
            system.debug('respone is '+ res);

        }

    }


	public static Id getRSUSummaryTemplateId(String rsuType){
		Id RSUSummaryTemplateId;
        system.debug('here1');
        List<APXTConga4__Conga_Template__c> listCongaTemplate = [Select Id from APXTConga4__Conga_Template__c where APXTConga4__Name__c = :rsuType limit 1];
        if(!listCongaTemplate.isEmpty()){
        	system.debug('here2');
            RSUSummaryTemplateId = listCongaTemplate[0].Id;
        }
        return RSUSummaryTemplateId;

    }

    public void createRSUDetail(){

        map<Id,Account> mapAccount = new map<Id, Account>([Select Id, Name
                                        From Account
                                        Where Id in : accountIds]);
        system.debug('here3');
        set<Id> setAccountIds = new set<Id>();
        Integer counter = 1;
        String StartDate = String.valueOf(rsuDateSetting.Start_Date__c).substring(0,10);
        String EndDate = String.valueOf(rsuDateSetting.End_Date__c).substring(0,10);
        for(Account account : mapAccount.values()){
            if(counter++ <= 10){
                system.debug('here4');
                generateRSUDetailForAccount(account.Id, startDate, endDate, account.Name, userInfo.getSessionId(), userInfo.getOrganizationId());
            }else{
                system.debug('here5');
                setAccountIds.add(account.Id);
            }
        }


        if(!setAccountIds.isEmpty()){
            system.debug('here7');
            system.debug('here');
            if(!Test.isRunningTest()){
                system.debug('here8');
                DataBase.ExecuteBatch(new RSUDetail_Batch(setAccountIds, startDate, endDate, userInfo.getSessionId(), userInfo.getOrganizationId()), 10);
            }
        }
    }

    public static void generateRSUDetailForAccount(Id accId, String startDate, String endDate, String accName, String sessionId, String orgId){
        map<String, Id> mapCongaQueryNameId = new map<String,Id>();
        for(APXTConga4__Conga_Merge_Query__c query : [Select Id, APXTConga4__Name__c
                                                        from APXTConga4__Conga_Merge_Query__c
                                                        where APXTConga4__Name__c like 'RSU %']){
            mapCongaQueryNameId.put(query.APXTConga4__Name__c, query.Id);
        }



        //system.debug('--------' + startDate + '------' + String.valueOf(rsuDateSetting.Start_Date__c).substring(0,10));

        system.debug('-------------' + mapCongaQueryNameId);
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setTimeout(60000);
        String endpointUrl = 'https://www.appextremes.com/apps/Conga/PM.aspx';
        endpointUrl += '?SessionId=' + sessionId;
        endpointUrl += '&ServerUrl=' + URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/28.0/' + orgId;
        endpointUrl += '&id=' + accId;
        endpointUrl += '&TemplateId='+getRSUSummaryTemplateId('RSU Detail');
        endpointUrl += '&APIMode=1&OFN=RSU_Detail_'+accName.replaceAll(' ', '_');
        endpointUrl += '&queryId=[Dates]'+mapCongaQueryNameId.get('RSU Dates')+
                        ',[Outstanding]'+mapCongaQueryNameId.get('RSU Outstanding')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
                        ',[SoldSummary]'+mapCongaQueryNameId.get('RSU SoldSummary')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
                        ',[CollectedSummary]'+mapCongaQueryNameId.get('RSU CollectedSummary')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
                        ',[Sold]'+mapCongaQueryNameId.get('RSU Sold')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
                        ',[Collected]'+mapCongaQueryNameId.get('RSU Collected')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
                        ',[PAA]'+mapCongaQueryNameId.get('RSU PAA')+'?pv0='+accId+'~pv1='+StartDate+'~pv2='+EndDate+
                        ',[Penalty]'+mapCongaQueryNameId.get('RSU Penalty')+'?pv0='+accId+
                        ',[Bank]'+mapCongaQueryNameId.get('RSU Bank')+'?pv0='+accId+
                        '&DefaultPDF=1';
        req.setEndpoint(endpointUrl);
        System.debug(endpointUrl);
        Http http = new Http();
        httpresponse res = new httpresponse ();
        if(!test.isRunningTest()){
            system.debug('here10');
            res = http.send(req);
            system.debug('respone is '+ res);

        }

    }


    webservice static list<String> downloadRSU(String[] accIds){
    	set<String> setProcessedAccountIds = new set<String>();
    	list<String> attachmentIds = new list<String>();
    	for(Attachment attach : [Select Id,parentId from Attachment where Name Like 'RSU_Summary%' and parentId in : accIds order by createdDate desc, Id desc]){
    		if(!setProcessedAccountIds.contains(attach.parentId)){
    			attachmentIds.add(attach.Id);
    			setProcessedAccountIds.add(attach.parentId);
    		}
    	}

    	//attachmentIds = attachmentIds.replaceFirst(',','');
		system.debug('========' + attachmentIds);
    	return attachmentIds;
    }

}