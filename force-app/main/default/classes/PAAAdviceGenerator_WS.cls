/**=====================================================================
 * Appirio, Inc
 * Name: Class to Generate PAA Advice for Selected Redemptions
 * Description:
 * Created Date: [06/25/2014]
 * Created By: [Manisha Gupta] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * [07/09/2014]                [Rajeev Arya]                  [I-120343 PAA Issues]
 * 08/07/2014 					Manisha Gupta					Updated to resolve session id null issue in production
 =====================================================================*/
global class PAAAdviceGenerator_WS {
    public static Conga_Query_Ids__c queryIds = Conga_Query_Ids__c.getInstance();
    public static Id PAAAdviceTemplateId;

    public static Id getPAAAdviceTemplateId(){
        system.debug('here1');
        List<APXTConga4__Conga_Template__c> listCongaTemplate = [Select Id from APXTConga4__Conga_Template__c where APXTConga4__Name__c = 'PAA Advice' limit 1];
        if(!listCongaTemplate.isEmpty()){
            system.debug('here2');
            PAAAdviceTemplateId = listCongaTemplate[0].Id;
        }
        return PAAAdviceTemplateId;

    }
    static webservice void GeneratePAAAdvice(String[] RedemptionIds){
        system.debug('here3');
        set<Id> setRedemptionIds = new set<Id>();
        Integer counter = 1;
        list<Redemption__c> listRedempToUpdate = new list<Redemption__c>();
        for(Redemption__c redemption : [Select Id, School__c, School__r.Name, PAA_Extract_Date__c, PAA_Record__c, Date_Paid__c from Redemption__c where Id in :RedemptionIds]){
            if(counter++ <= 10){
                system.debug('here4');
                // 08/07/2014 : MG : Updated to resolve sessionId issue in Production
                generatePAAAdviceForRedemption(redemption, userInfo.getSessionId(), userInfo.getOrganizationId());

                //rajeev
                list<attachment> attlst = [select id from attachment where ParentId = : redemption.Id];
                system.debug('attachment(s) are ' +attlst);
                //rajeev
                if(redemption.PAA_Extract_Date__c == null){
                    redemption.PAA_Extract_Date__c = date.Today();
                }
                if(redemption.Date_Paid__c == null){
                    redemption.Date_Paid__c = date.Today();
                }
                listRedempToUpdate.add(redemption);
            }else{
                system.debug('here5');
                setRedemptionIds.add(redemption.Id);
            }
        }

        if(!listRedempToUpdate.isEmpty()){
            system.debug('here6');
            update listRedempToUpdate;
        }



        if(!setRedemptionIds.isEmpty()){
            system.debug('here7');
            system.debug('here');
            if(!Test.isRunningTest()){
                system.debug('here8');
                // 08/07/2014 : MG : Updated to resolve sessionId issue in Production
                DataBase.ExecuteBatch(new PAAAdviceGenerator_Batch(setRedemptionIds, userInfo.getSessionId(), userInfo.getOrganizationId()), 10);
            }
        }
    }


	// 08/07/2014 : MG : Updated to resolve sessionId issue in Production
    public static void generatePAAAdviceForRedemption(Redemption__c redemption, String sessionId, String orgId){
        map<String, Id> mapCongaQueryNameId = new map<String,Id>();
        for(APXTConga4__Conga_Merge_Query__c query : [Select Id, APXTConga4__Name__c
                                                        from APXTConga4__Conga_Merge_Query__c
                                                        where APXTConga4__Name__c like 'PAA %']){
            mapCongaQueryNameId.put(query.APXTConga4__Name__c, query.Id);
        }

        system.debug('-------------' + mapCongaQueryNameId);
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setTimeout(60000);
        String todaysDate = String.valueOf(system.today()).substring(0,10);
        String endpointUrl = 'https://www.appextremes.com/apps/Conga/PM.aspx';
        // 08/07/2014 : MG : Updated to resolve sessionId issue in Production
        endpointUrl += '?SessionId=' + sessionId;
        // 08/07/2014 : MG : Updated to resolve sessionId issue in Production
        endpointUrl += '&ServerUrl=' + URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/28.0/' + orgId;
        endpointUrl += '&id=' + redemption.Id;
        endpointUrl += '&TemplateId=' + (redemption.PAA_Record__c != null ? redemption.PAA_Record__c : getPAAAdviceTemplateId());       //+getPAAAdviceTemplateId() removed J Caughie 2014.07.24
        endpointUrl += '&APIMode=1&OFN=PAA_Advice_' + (redemption.School__r.Name != null ? redemption.School__r.Name : '').replaceAll(' ', '_').replaceAll('[^a-z^A-z^0-9]', '') + '_' + todaysDate;
        endpointUrl += '&queryId=[School]'+mapCongaQueryNameId.get('PAA School')+'?pv0='+redemption.School__c+
                        ',[PCSRC]'+mapCongaQueryNameId.get('PAA PCSRC')+'?pv0='+redemption.Id+
                        ',[EastWestBank]'+mapCongaQueryNameId.get('PAA EastWestBank')+'?pv0='+redemption.Id+
                        ',[TwoSigma]'+mapCongaQueryNameId.get('PAA TwoSigma')+'?pv0='+redemption.Id+
                        ',[CSC]'+mapCongaQueryNameId.get('PAA CSC')+'?pv0='+redemption.Id+
                        ',[EWB]'+mapCongaQueryNameId.get('PAA EWB')+
                        ',[TwoSigmaBankUsage]'+mapCongaQueryNameId.get('PAA TwoSigmaBankUsage')+
                        ',[PCSR]'+mapCongaQueryNameId.get('PAA PCSR')+''+
                        ',[BankUsage]'+mapCongaQueryNameId.get('PAA BankUsage')+'?pv0='+redemption.School__c+
                        '&DefaultPDF=1';
        req.setEndpoint(endpointUrl);

        Http http = new Http();
        httpresponse res = new httpresponse ();
        if(!test.isRunningTest()){
            system.debug('here10');
            res = http.send(req);
            system.debug('respone is '+ res);

        }

    }

    webservice static list<String> downloadPAA(String[] RedemptionIds){
        set<String> setProcessedRedemptionIds = new set<String>();
        list<String> attachmentIds = new list<String>();
        for(Attachment attach : [Select Id,parentId from Attachment where Name Like 'PAA_Advice%' and parentId in : RedemptionIds order by createdDate desc, Id desc]){
            if(!setProcessedRedemptionIds.contains(attach.parentId)){
                attachmentIds.add(attach.Id);
                setProcessedRedemptionIds.add(attach.parentId);
            }
        }

        //attachmentIds = attachmentIds.replaceFirst(',','');
        system.debug('========' + attachmentIds);
        return attachmentIds;
    }








}