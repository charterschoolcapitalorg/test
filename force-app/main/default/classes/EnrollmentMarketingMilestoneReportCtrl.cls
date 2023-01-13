/**=====================================================================
 * Charter School Capital
 * Name: EnrollmentMarketingMilestoneReportCtrl
 * Test Class: EMMilestoneReportCtrlTest
 * Description: Facilities Milestone Report
 * Created Date: Nov 2022
 * Created By: Slava Krel 
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 * Dec 19, 2022                 Slava Krel                   Split per channel not need the at this point
 * Dec 28, 2022                 Slava Krel                   Adding pipeline report on the page
 =====================================================================*/

public class EnrollmentMarketingMilestoneReportCtrl {

    // add dinamic file name
    public string fileName {get;set;}

    public List<OpportunityWrapper> oppsToExport {get;set;}
    // remove the split per channel per Kirt

    // this is for pipeline table
    public List<OppByPipelineStageWrapper> oppPipeline {get;set;}

    public OppByPipelineStageWrapper oppPipelineStage {get;set;}
    public OppByPipelineStageWrapper oppPipelineTotals {get;set;}
    public Integer oppTotal {get;set;}
    
    public EnrollmentMarketingMilestoneReportCtrl() {
        oppsToExport = getEnrollmentMarketingMilestone();
        oppPipelineStage = getPipelineData(oppsToExport);
        oppTotal = getTotalNunberOpps(oppsToExport);
        oppPipeline = getPipeline(oppsToExport);

        fileName = getFileName();
    }

    @AuraEnabled
    public static String getFileName() {
        String name = 'EM Milestone Report' + '_' + String.valueOf(Date.today().year()) + '-' + String.valueOf(Date.today().month()) + '-' + String.valueOf(Date.today().day());
        return name;
    }

    @AuraEnabled
    public static List<OpportunityWrapper> getEnrollmentMarketingMilestone() {

        List<OpportunityWrapper> allEMOpps = new List<OpportunityWrapper>();
        List<OpportunityWrapper> contractedOppOpen = new List<OpportunityWrapper>();

        //this is what will be displayed
        List<OpportunityWrapper> opportunityToDisplay = new List<OpportunityWrapper>();

        Map<Opportunity, List<CSC_Action_Item__c>> oppItemMap = new Map<Opportunity, List<CSC_Action_Item__c>>();

        //query opps that are certain record type and not closed
        Map<Id, Opportunity> initialopps = 
        new Map<ID, Opportunity>([SELECT id, 
                                    Name, 
                                    CloseDate, 
                                    State__c, 
                                    Owner.LastName,
                                    CreatedDate,
                                    Due_Diligence_End_Date__c,
                                    Estimate_EM_Project_Value__c,
                                    Referral_Source__c,
                                    Fee_Structure_Type__c,
                                    Pipeline_Stage__c,
                                    Num_of_Opp_Schools__c,
                                    Contract_Signed_Date__c
                                    FROM Opportunity 
                                    WHERE RecordType.DeveloperName = 'Enrollment_Marketing'
                                    AND isClosed = false
                                    AND Contract_Signed_Date__c = null
                                    ORDER BY CloseDate ASC]);

        // adding opps
        // query opp that are in the same FY
        List<Opportunity> oppsToAdd = new List<Opportunity>();
        List<Opportunity> addOppsList = [
            SELECT 
            id, 
            Name, 
            Contract_Signed_Date__c, 
            CloseDate, 
            State__c, 
            Owner.LastName,
            CreatedDate,
            Due_Diligence_End_Date__c,
            Estimate_EM_Project_Value__c,
            Referral_Source__c,
            Fee_Structure_Type__c,
            Pipeline_Stage__c,
            Num_of_Opp_Schools__c 
            FROM Opportunity 
            WHERE RecordType.DeveloperName = 'Enrollment_Marketing' 
            AND Contract_Signed_Date__c != null];

        String currentFiscalYearString = [SELECT FiscalYearSettings.Name FROM Period WHERE Type = 'Year' AND StartDate <= TODAY AND EndDate >= TODAY].FiscalYearSettings.Name;
        Integer currentFiscalYear = Integer.valueof(currentFiscalYearString); // from the org

        for (Opportunity o : addOppsList) {
            if((o.Contract_Signed_Date__c.year() + 1 == currentFiscalYear) && o.Contract_Signed_Date__c.month() >= 7) {
                oppsToAdd.add(o);
            }
            if(o.Contract_Signed_Date__c.year() == currentFiscalYear) {
                oppsToAdd.add(o);
            }
        }

        Map<Id, Opportunity> addOpps = new Map<ID, Opportunity>(oppsToAdd);

        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        opps.putAll(addOpps);
        opps.putAll(initialopps);
        // ===================================


        //collect opp ids to query action item
        Set<Id> oppIds = opps.keySet();

        //list of action item names
        List<String> actionItemNames = new List<String>{
            'Collect pre-qualification information',
            'Present Enrollment Marketing pitch deck to Prospect',
            'Approve Enrollment Marketing client for contracting',
            'Receive signed contract'};

        List<CSC_Action_Item__c> actionItemList = [SELECT id, 
                                                            Name,
                                                            Action_Item_Name__c,
                                                            Opportunity_Id__c, 
                                                            Status__c, 
                                                            Assigned_To__r.Name, 
                                                            Date_Completed__c, 
                                                            CSC_Action_List__r.Opportunity__r.CloseDate, 
                                                            Status_Value__c  
                                                            FROM CSC_Action_Item__c 
                                                            WHERE CSC_Action_List__r.Opportunity__c IN :oppIds 
                                                            AND Action_Item_Name__c IN :actionItemNames 
                                                            ORDER BY CSC_Action_List__r.Opportunity__r.CloseDate ASC];
        
        for(CSC_Action_Item__c actionItem : actionItemList){
            if(oppItemMap.containsKey(opps.get(actionItem.Opportunity_Id__c))){
                (oppItemMap.get(opps.get(actionItem.Opportunity_Id__c))).add(actionItem);
            } else {
                oppItemMap.put(opps.get(actionItem.Opportunity_Id__c), 
                new List<CSC_Action_Item__c>{actionItem});
            }
        }

        for(Opportunity oppFromMap : oppItemMap.keySet()) {

            DateTime dt = oppFromMap.createddate;
            Date oppCreatedDate = dt.date();

            OpportunityWrapper opportunityWrapperItem = new OpportunityWrapper();
            opportunityWrapperItem.oppId = oppFromMap.Id;
            opportunityWrapperItem.opp = oppFromMap;
            opportunityWrapperItem.oppName = oppFromMap.Name;
            opportunityWrapperItem.createdDate = oppCreatedDate;
            opportunityWrapperItem.closeDate = oppFromMap.CloseDate;
            opportunityWrapperItem.oppOwner = oppFromMap.Owner.LastName;
            opportunityWrapperItem.oppPipelineStage = oppFromMap.Pipeline_Stage__c;
            opportunityWrapperItem.emChannel = oppFromMap.Referral_Source__c;
            opportunityWrapperItem.estimatedCost = oppFromMap.Estimate_EM_Project_Value__c;
            opportunityWrapperItem.businessDaysToClose = 
                DateUtilities.calculateBusinessDays(Date.today(), oppFromMap.CloseDate);

            Map<String, List<CSC_Action_Item__c>> mapItem = new Map<String, List<CSC_Action_Item__c>>();
            mapItem.put('preQualInfo', new List<CSC_Action_Item__c>());
            mapItem.put('pitchDeck', new List<CSC_Action_Item__c>());
            mapItem.put('approveContracting', new List<CSC_Action_Item__c>());
            mapItem.put('signedContract', new List<CSC_Action_Item__c>());

            for(CSC_Action_Item__c actionItemToDisplay : oppItemMap.get(oppFromMap)){
                if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Collect pre-qualification information')){
                    mapItem.get('preQualInfo').add(actionItemToDisplay);
                } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Present Enrollment Marketing pitch deck to Prospect')){
                    mapItem.get('pitchDeck').add(actionItemToDisplay);
                } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Approve Enrollment Marketing client for contracting')){
                    mapItem.get('approveContracting').add(actionItemToDisplay);
                } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Receive signed contract')){
                    mapItem.get('signedContract').add(actionItemToDisplay);
                }
            }

            opportunityWrapperItem.preQualInfo = getStatus(mapItem.get('preQualInfo'));
            opportunityWrapperItem.pitchDeck = getStatus(mapItem.get('pitchDeck')); 
            opportunityWrapperItem.approveContracting = getStatus(mapItem.get('approveContracting'));
            opportunityWrapperItem.signedContract = getStatus(mapItem.get('signedContract')); 
            
            allEMOpps.add(opportunityWrapperItem);
            
        }
        return allEMOpps;
    }

    public static string getStatus(List<CSC_Action_Item__c> items){
        String status = '';
        for(CSC_Action_Item__c item : items) {
            if(item.Status__c == 'Completed') {
                status = 'Completed';
            } else {status = 'Incomplete';}
        }
        return status;
    }

    public static OppByPipelineStageWrapper getPipelineData(List<OpportunityWrapper> opportunityToDisplay) {
        OppByPipelineStageWrapper pipeline = new OppByPipelineStageWrapper();
        return pipeline;
    }

    // get pipeline totals (top table)
    public static List<OppByPipelineStageWrapper> getPipeline(List<OpportunityWrapper> opportunityToDisplay) {
        List<OppByPipelineStageWrapper> pipelineList = new List<OppByPipelineStageWrapper>();
        OppByPipelineStageWrapper pipeline = new OppByPipelineStageWrapper();
        pipeline.wonOppCount = 0;
        pipeline.convertedOppCount = 0;
        pipeline.proposedOppCount = 0;
        pipeline.sourcedOppCount = 0;
        pipeline.createdOppCount = 0;
        pipeline.wonOppAmount = 0;
        pipeline.convertedOppAmount = 0;
        pipeline.proposedOppAmount = 0;
        pipeline.sourcedOppAmount = 0;
        pipeline.createdOppAmount = 0;
        if(!opportunityToDisplay.isEmpty()) {
            for(OpportunityWrapper oppItem : opportunityToDisplay) {
                if(oppItem.signedContract != null && oppItem.signedContract == 'Completed') {
                    pipeline.wonOppCount = pipeline.wonOppCount + 1;
                    if(oppItem.estimatedCost != null) {
                        pipeline.wonOppAmount = pipeline.wonOppAmount + oppItem.estimatedCost;
                    }
                }
                if(oppItem.approveContracting != null && oppItem.approveContracting == 'Completed' && oppItem.signedContract == 'Incomplete') {
                    pipeline.convertedOppCount = pipeline.convertedOppCount + 1;
                    if(oppItem.estimatedCost != null) {
                        pipeline.convertedOppAmount = pipeline.convertedOppAmount + oppItem.estimatedCost;
                    }
                }
                if(oppItem.pitchDeck != null && oppItem.pitchDeck == 'Completed' && oppItem.signedContract == 'Incomplete' && oppItem.approveContracting == 'Incomplete') {
                    pipeline.proposedOppCount = pipeline.proposedOppCount + 1;
                    if(oppItem.estimatedCost != null) {
                        pipeline.proposedOppAmount = pipeline.proposedOppAmount + oppItem.estimatedCost;
                    }
                } else {
                    if(oppItem.oppPipelineStage != null 
                    && oppItem.preQualInfo != null 
                    && oppItem.preQualInfo == 'Completed' 
                    && oppItem.pitchDeck == 'Incomplete' 
                    && oppItem.signedContract == 'Incomplete' 
                    && oppItem.approveContracting == 'Incomplete') {
                        pipeline.sourcedOppCount = pipeline.sourcedOppCount + 1;
                        if(oppItem.estimatedCost != null) {
                            pipeline.sourcedOppAmount = pipeline.sourcedOppAmount + oppItem.estimatedCost;
                        }
                    } 
                    if(oppItem.preQualInfo == 'Incomplete' 
                    && oppItem.pitchDeck == 'Incomplete' 
                    && oppItem.signedContract == 'Incomplete' 
                    && oppItem.approveContracting == 'Incomplete') {
                        pipeline.createdOppCount = pipeline.createdOppCount + 1;
                        if(oppItem.estimatedCost != null) {
                            pipeline.createdOppAmount = pipeline.createdOppAmount + oppItem.estimatedCost;
                        }
                    }
                }
            }
        }
        pipelineList.add(pipeline);
        return pipelineList;
    }

    // split per channel -- not needed at this point
    // save it for now, remove it the future (ask Kirt or Jen)
    // a lot has changed, so make sure to rename the methods
    // ==============================================
    // public static List<OppByPipelineStageWrapper> getPipelineData(List<OpportunityWrapper> opportunityToDisplay) {
        
    //     List<OppByPipelineStageWrapper> emPipelineList = new List<OppByPipelineStageWrapper>();
        
    //     List<OpportunityWrapper> isOpportunities = new List<OpportunityWrapper>();
    //     List<OpportunityWrapper> lldbOpportunities = new List<OpportunityWrapper>();
    //     List<OpportunityWrapper> bopOpportunities = new List<OpportunityWrapper>();
    //     List<OpportunityWrapper> osOpportunities = new List<OpportunityWrapper>();
    //     List<OpportunityWrapper> bsOpportunities = new List<OpportunityWrapper>();
    //     List<OpportunityWrapper> bbOpportunities = new List<OpportunityWrapper>();
    //     List<OpportunityWrapper> oOpportunities = new List<OpportunityWrapper>();

    //     if(!opportunityToDisplay.isEmpty()) {
    //         for(OpportunityWrapper opp : opportunityToDisplay) {
    //             if(opp.emChannel == 'Internally Sourced') {
    //                 isOpportunities.add(opp);
    //             } else if(opp.emChannel == 'LLDB') {
    //                 lldbOpportunities.add(opp);
    //             } else if(opp.emChannel == 'BOP') {
    //                 bopOpportunities.add(opp);
    //             } else if(opp.emChannel == 'Other School') {
    //                 osOpportunities.add(opp);
    //             } else if(opp.emChannel == 'BioStar') {
    //                 bsOpportunities.add(opp);
    //             } else if(opp.emChannel == 'Bond Broker') {
    //                 bbOpportunities.add(opp);
    //             } else if(opp.emChannel == 'Other') {
    //                 oOpportunities.add(opp);
    //             }
    //         }
    //     }

    //     //isOpportunities
    //     if(!isOpportunities.isEmpty()) {
    //         OppByPipelineStageWrapper singleOppChannel = new OppByPipelineStageWrapper();
    //         singleOppChannel.opportunityEMChannel = 'Internally Sourced';
    //         for(OpportunityWrapper itemOpp : isOpportunities) {
    //             OppByPipelineStageWrapper getDataPerChannel = getPipelineDataPerChannel(itemOpp);
    //             singleOppChannel.wonOppCount = getDataPerChannel.wonOppCount;
    //             singleOppChannel.convertedOppCount = getDataPerChannel.convertedOppCount;
    //             singleOppChannel.proposedOppCount = getDataPerChannel.proposedOppCount;
    //             singleOppChannel.sourcedOppCount = getDataPerChannel.sourcedOppCount;
    //             singleOppChannel.wonOppAmount = getDataPerChannel.wonOppAmount;
    //             singleOppChannel.convertedOppAmount = getDataPerChannel.convertedOppAmount;
    //             singleOppChannel.proposedOppAmount = getDataPerChannel.proposedOppAmount;
    //             singleOppChannel.sourcedOppAmount = getDataPerChannel.sourcedOppAmount;
    //         }
    //         emPipelineList.add(singleOppChannel);
    //     }
    //     //lldbOpportunities
    //     if(!lldbOpportunities.isEmpty()) {
    //         OppByPipelineStageWrapper singleOppChannel = new OppByPipelineStageWrapper();
    //         singleOppChannel.opportunityEMChannel = 'LLDB';
    //         for(OpportunityWrapper itemOpp : lldbOpportunities) {
    //             OppByPipelineStageWrapper getDataPerChannel = getPipelineDataPerChannel(itemOpp);
    //             singleOppChannel.wonOppCount = getDataPerChannel.wonOppCount;
    //             singleOppChannel.convertedOppCount = getDataPerChannel.convertedOppCount;
    //             singleOppChannel.proposedOppCount = getDataPerChannel.proposedOppCount;
    //             singleOppChannel.sourcedOppCount = getDataPerChannel.sourcedOppCount;
    //             singleOppChannel.wonOppAmount = getDataPerChannel.wonOppAmount;
    //             singleOppChannel.convertedOppAmount = getDataPerChannel.convertedOppAmount;
    //             singleOppChannel.proposedOppAmount = getDataPerChannel.proposedOppAmount;
    //             singleOppChannel.sourcedOppAmount = getDataPerChannel.sourcedOppAmount;
    //         }
    //         emPipelineList.add(singleOppChannel);
    //     }
    //     //bopOpportunities
    //     if(!bopOpportunities.isEmpty()) {
    //         OppByPipelineStageWrapper singleOppChannel = new OppByPipelineStageWrapper();
    //         singleOppChannel.opportunityEMChannel = 'BOP';
    //         for(OpportunityWrapper itemOpp : bopOpportunities) {
    //             OppByPipelineStageWrapper getDataPerChannel = getPipelineDataPerChannel(itemOpp);
    //             singleOppChannel.wonOppCount = getDataPerChannel.wonOppCount;
    //             singleOppChannel.convertedOppCount = getDataPerChannel.convertedOppCount;
    //             singleOppChannel.proposedOppCount = getDataPerChannel.proposedOppCount;
    //             singleOppChannel.sourcedOppCount = getDataPerChannel.sourcedOppCount;
    //             singleOppChannel.wonOppAmount = getDataPerChannel.wonOppAmount;
    //             singleOppChannel.convertedOppAmount = getDataPerChannel.convertedOppAmount;
    //             singleOppChannel.proposedOppAmount = getDataPerChannel.proposedOppAmount;
    //             singleOppChannel.sourcedOppAmount = getDataPerChannel.sourcedOppAmount;
    //         }
    //         emPipelineList.add(singleOppChannel);
    //     }
    //     //osOpportunities
    //     if(!osOpportunities.isEmpty()) {
    //         OppByPipelineStageWrapper singleOppChannel = new OppByPipelineStageWrapper();
    //         singleOppChannel.opportunityEMChannel = 'Other School';
    //         for(OpportunityWrapper itemOpp : osOpportunities) {
    //             OppByPipelineStageWrapper getDataPerChannel = getPipelineDataPerChannel(itemOpp);
    //             singleOppChannel.wonOppCount = getDataPerChannel.wonOppCount;
    //             singleOppChannel.convertedOppCount = getDataPerChannel.convertedOppCount;
    //             singleOppChannel.proposedOppCount = getDataPerChannel.proposedOppCount;
    //             singleOppChannel.sourcedOppCount = getDataPerChannel.sourcedOppCount;
    //             singleOppChannel.wonOppAmount = getDataPerChannel.wonOppAmount;
    //             singleOppChannel.convertedOppAmount = getDataPerChannel.convertedOppAmount;
    //             singleOppChannel.proposedOppAmount = getDataPerChannel.proposedOppAmount;
    //             singleOppChannel.sourcedOppAmount = getDataPerChannel.sourcedOppAmount;
    //         }
    //         emPipelineList.add(singleOppChannel);
    //     }
    //     //bsOpportunities
    //     if(!bsOpportunities.isEmpty()) {
    //         OppByPipelineStageWrapper singleOppChannel = new OppByPipelineStageWrapper();
    //         singleOppChannel.opportunityEMChannel = 'BioStar';
    //         for(OpportunityWrapper itemOpp : bsOpportunities) {
    //             OppByPipelineStageWrapper getDataPerChannel = getPipelineDataPerChannel(itemOpp);
    //             singleOppChannel.wonOppCount = getDataPerChannel.wonOppCount;
    //             singleOppChannel.convertedOppCount = getDataPerChannel.convertedOppCount;
    //             singleOppChannel.proposedOppCount = getDataPerChannel.proposedOppCount;
    //             singleOppChannel.sourcedOppCount = getDataPerChannel.sourcedOppCount;
    //             singleOppChannel.wonOppAmount = getDataPerChannel.wonOppAmount;
    //             singleOppChannel.convertedOppAmount = getDataPerChannel.convertedOppAmount;
    //             singleOppChannel.proposedOppAmount = getDataPerChannel.proposedOppAmount;
    //             singleOppChannel.sourcedOppAmount = getDataPerChannel.sourcedOppAmount;
    //         }
    //         emPipelineList.add(singleOppChannel);
    //     }
    //     //bbOpportunities
    //     if(!bbOpportunities.isEmpty()) {
    //         OppByPipelineStageWrapper singleOppChannel = new OppByPipelineStageWrapper();
    //         singleOppChannel.opportunityEMChannel = 'Bond Broker';
    //         for(OpportunityWrapper itemOpp : bbOpportunities) {
    //             OppByPipelineStageWrapper getDataPerChannel = getPipelineDataPerChannel(itemOpp);
    //             singleOppChannel.wonOppCount = getDataPerChannel.wonOppCount;
    //             singleOppChannel.convertedOppCount = getDataPerChannel.convertedOppCount;
    //             singleOppChannel.proposedOppCount = getDataPerChannel.proposedOppCount;
    //             singleOppChannel.sourcedOppCount = getDataPerChannel.sourcedOppCount;
    //             singleOppChannel.wonOppAmount = getDataPerChannel.wonOppAmount;
    //             singleOppChannel.convertedOppAmount = getDataPerChannel.convertedOppAmount;
    //             singleOppChannel.proposedOppAmount = getDataPerChannel.proposedOppAmount;
    //             singleOppChannel.sourcedOppAmount = getDataPerChannel.sourcedOppAmount;
    //         }
    //         emPipelineList.add(singleOppChannel);
    //     }
    //     //oOpportunities
    //     if(!oOpportunities.isEmpty()) {
    //         OppByPipelineStageWrapper singleOppChannel = new OppByPipelineStageWrapper();
    //         singleOppChannel.opportunityEMChannel = 'Other';
    //         for(OpportunityWrapper itemOpp : oOpportunities) {
    //             OppByPipelineStageWrapper getDataPerChannel = getPipelineDataPerChannel(itemOpp);
    //             singleOppChannel.wonOppCount = getDataPerChannel.wonOppCount;
    //             singleOppChannel.convertedOppCount = getDataPerChannel.convertedOppCount;
    //             singleOppChannel.proposedOppCount = getDataPerChannel.proposedOppCount;
    //             singleOppChannel.sourcedOppCount = getDataPerChannel.sourcedOppCount;
    //             singleOppChannel.wonOppAmount = getDataPerChannel.wonOppAmount;
    //             singleOppChannel.convertedOppAmount = getDataPerChannel.convertedOppAmount;
    //             singleOppChannel.proposedOppAmount = getDataPerChannel.proposedOppAmount;
    //             singleOppChannel.sourcedOppAmount = getDataPerChannel.sourcedOppAmount;
    //         }
    //         emPipelineList.add(singleOppChannel);
    //     }

    //     return emPipelineList;
    // }

    // public static OppByPipelineStageWrapper getPipelineDataPerChannel(OpportunityWrapper item) {

    //     OppByPipelineStageWrapper emPipeline = new OppByPipelineStageWrapper();

    //     emPipeline.sourcedOppCount = 0;
    //     emPipeline.proposedOppCount = 0;
    //     emPipeline.convertedOppCount = 0;
    //     emPipeline.wonOppCount = 0;

    //     emPipeline.wonOppAmount = 0;
    //     emPipeline.convertedOppAmount = 0;
    //     emPipeline.proposedOppAmount = 0;
    //     emPipeline.sourcedOppAmount = 0;

    //     //Won opportunities
    //     if(item.signedContract == 'Completed') {
    //         emPipeline.wonOppCount = emPipeline.wonOppCount + 1;
    //         if(item.estimatedCost != null) {
    //             emPipeline.wonOppAmount = emPipeline.wonOppAmount + item.estimatedCost;
    //         }
    //     }

    //     //Converted opportunity
    //     else if(item.approveContracting == 'Completed' && item.signedContract != 'Completed') {
    //         emPipeline.convertedOppCount = emPipeline.convertedOppCount + 1;
    //         if(item.estimatedCost != null) {
    //             emPipeline.convertedOppAmount = emPipeline.convertedOppAmount + item.estimatedCost;
    //         }
    //     }

    //     //Proposed opportunity
    //     else if((item.pitchDeck == 'Completed') 
    //         && item.approveContracting != 'Completed' && item.signedContract != 'Completed') {
    //             emPipeline.proposedOppCount = emPipeline.proposedOppCount + 1;
    //             if(item.estimatedCost != null) {
    //                 emPipeline.proposedOppAmount = emPipeline.proposedOppAmount + item.estimatedCost;
    //             }
    //     }

    //     //sourced opportunity
    //     else {
    //         emPipeline.sourcedOppCount = emPipeline.sourcedOppCount + 1;
    //         if(item.estimatedCost != null) {
    //             emPipeline.sourcedOppAmount = emPipeline.sourcedOppAmount + item.estimatedCost;
    //         }
    //     }

    //     return emPipeline;
    // }
    // ==============================================


    public static Integer getTotalNunberOpps(List<OpportunityWrapper> opportunityToDisplay) {
        Integer oppNumber = 0;
        for(OpportunityWrapper item : opportunityToDisplay) {
            if(item != null) {
                oppNumber = oppNumber + 1;
            }
        }
        return oppNumber;
    }


    public class OpportunityWrapper{
        @AuraEnabled
        public String oppId {get;set;}
        @AuraEnabled
        public Opportunity opp {get;set;}
        @AuraEnabled
        public Integer businessDaysToClose {get;set;}
        @AuraEnabled
        public Date createdDate {get;set;}
        @AuraEnabled
        public String oppName {get;set;}
        @AuraEnabled
        public Date closeDate {get;set;}
        @AuraEnabled
        public String emChannel {get;set;}
        @AuraEnabled
        public String state {get;set;}
        @AuraEnabled
        public String oppOwner {get;set;}
        @AuraEnabled
        public String preQualInfo {get;set;}
        @AuraEnabled
        public String pitchDeck {get;set;}
        @AuraEnabled
        public String approveContracting {get;set;}
        @AuraEnabled
        public String signedContract {get;set;}
        @AuraEnabled
        public String won {get;set;}
        @AuraEnabled
        public String oppPipelineStage {get;set;}
        @AuraEnabled
        public Decimal estimatedCost {get;set;}
    }

    public class OppByPipelineStageWrapper{
        public String opportunityEMChannel {get;set;}
        public Integer wonOppCount {get;set;}
        public Integer convertedOppCount {get;set;}
        public Integer proposedOppCount {get;set;}
        public Integer sourcedOppCount {get;set;}
        public Integer createdOppCount {get;set;}
        public Decimal wonOppAmount {get;set;}
        public Decimal convertedOppAmount {get;set;}
        public Decimal proposedOppAmount {get;set;}
        public Decimal sourcedOppAmount {get;set;}
        public Decimal createdOppAmount {get;set;}
    }
}