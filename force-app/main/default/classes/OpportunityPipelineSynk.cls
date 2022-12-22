public with sharing class OpportunityPipelineSynk {
    //Anonymous apex to set pipeline stage values
    
    public static void getFacilitiesMilestone() {
    
    Map<Opportunity, List<CSC_Action_Item__c>> oppItemMap = 
    new Map<Opportunity, List<CSC_Action_Item__c>>();

    //this is what gets displayed
    List<OpportunityWrapper> opportunityToDisplay = 
    new List<OpportunityWrapper>();

    //query opps that are certain record type and not closed
    Map<Id, Opportunity> opps = 
        new Map<ID, Opportunity>([SELECT Id, 
                                            Account.Name, 
                                            Name, 
                                            CloseDate, 
                                            State__c, 
                                            NET_Amount_Requested__c, 
                                            Owner.LastName, 
                                            Paralegal__r.LastName, 
                                            Financial_Review__r.LastName, 
                                            Legal_Assistant__r.User_Fullname__c, 
                                            Paralegal__r.User_Fullname__c, 
                                            Financial_Review__r.User_Fullname__c, 
                                            Owner.User_Fullname__c, 
                                            Client_Portal_Testing_Opp__c, 
                                            RecordType.Name, 
                                            Receivables_Purchased__c, 
                                            Date_Submitted__c, 
                                            RecordType.DeveloperName,
                                            Due_Diligence_End_Date__c,
                                            Facilities_Channel__c,
                                            Purchase_Price__c,
                                            Deal_Specialist__r.LastName,
                                            Deal_Specialist__r.User_Fullname__c,
                                            isClosed,
                                            createddate, 
                                            Lease_Cap_Rate__c,
                                            Estimated_Project_Cost__c,
                                            recordtypeid,
                                            Attorney__c,
                                            Attorney__r.LastName,
                                            Attorney__r.User_Fullname__c,
                                            Facilities_Underwriting_Manager_FAUM__c,
                                            Facilities_Underwriting_Manager_FAUM__r.LastName,
                                            Facilities_Underwriting_Manager_FAUM__r.User_Fullname__c,
                                            Account_Owner__c,
                                            Account_Owner__r.LastName,
                                            Account_Owner__r.User_Fullname__c,
                                            Financial_Consultant__c,
                                            Financial_Consultant__r.LastName,
                                            Financial_Consultant__r.User_Fullname__c
                                            FROM Opportunity 
                                            WHERE (RecordType.DeveloperName = 'Facilities' OR RecordType.DeveloperName = 'Broker_Network')
                                            AND isClosed = false 
                                            ORDER BY CloseDate ASC]);

    
    //collect opp ids to query action item
    Set<Id> oppIds = opps.keySet();

    //list of action item names
    List<String> actionItemNames = new List<String>{
        'Approve Phase 1 Opportunity',
        'Verify Rent and/or Establish Property Valuation',
        'FC Pre-Approval Prepared and Presented',
        'Send LOI',
        'Sign LOI',
        'Deliver Lease Proposal (MOU)',
        'Receive Lease Proposal (MOU) Approval',
        'Sign PSA',
        'Sign Lease',
        'Present Opportunity and Receive Final FC Approval',
        'Waive Diligence',
        'Fund Acquisition'};

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
                                                        AND Action_Item_Name__c IN :actionItemNames];
            
    for(CSC_Action_Item__c actionItem : actionItemList){
        if(oppItemMap.containsKey(opps.get(actionItem.Opportunity_Id__c))){
            (oppItemMap.get(opps.get(actionItem.Opportunity_Id__c))).add(actionItem);
        } else {
            oppItemMap.put(opps.get(actionItem.Opportunity_Id__c), 
            new List<CSC_Action_Item__c>{actionItem});
        }
    }

    for(Opportunity oppFromMap : oppItemMap.keySet()) {
        
        OpportunityWrapper opportunityWrapperItem = new OpportunityWrapper();
        opportunityWrapperItem.oppId = oppFromMap.Id;
        opportunityWrapperItem.opp = oppFromMap;
        opportunityWrapperItem.oppName = oppFromMap.Name;
        opportunityWrapperItem.closeDate = oppFromMap.CloseDate;
        opportunityWrapperItem.diligenceEnd = oppFromMap.Due_Diligence_End_Date__c;
        opportunityWrapperItem.oppChannel = oppFromMap.Facilities_Channel__c;
        opportunityWrapperItem.state = oppFromMap.State__c;
        opportunityWrapperItem.oppOwner = oppFromMap.Owner.LastName;
        opportunityWrapperItem.dealSpecialist = oppFromMap.Deal_Specialist__r.LastName;
        opportunityWrapperItem.estimatedCost = oppFromMap.Estimated_Project_Cost__c;
        opportunityWrapperItem.capRate = oppFromMap.Lease_Cap_Rate__c;

        DateTime dt = oppFromMap.createddate;
        Date oppCreatedDate = dt.date();
        opportunityWrapperItem.createdDate = oppCreatedDate;

        opportunityWrapperItem.businessDaysToClose = 
            DateUtilities.calculateBusinessDays(Date.today(), oppFromMap.CloseDate);
        
        Map<String, List<CSC_Action_Item__c>> mapItem = new Map<String, List<CSC_Action_Item__c>>();
        mapItem.put('dealApproved', new List<CSC_Action_Item__c>());
        mapItem.put('preFC', new List<CSC_Action_Item__c>());
        mapItem.put('loiSent', new List<CSC_Action_Item__c>());
        mapItem.put('loiSigned', new List<CSC_Action_Item__c>());
        mapItem.put('mouSent', new List<CSC_Action_Item__c>());
        mapItem.put('mouSigned', new List<CSC_Action_Item__c>());
        mapItem.put('psaSigned', new List<CSC_Action_Item__c>());
        mapItem.put('leaseSigned', new List<CSC_Action_Item__c>());
        mapItem.put('finalFC', new List<CSC_Action_Item__c>());
        mapItem.put('diligenceWaived', new List<CSC_Action_Item__c>());
        mapItem.put('funded', new List<CSC_Action_Item__c>());

        for(CSC_Action_Item__c actionItemToDisplay : oppItemMap.get(oppFromMap)){
            if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Approve Phase 1 Opportunity') || actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Verify Rent and/or Establish Property Valuation')){
                mapItem.get('dealApproved').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('FC Pre-Approval Prepared and Presented')){
                mapItem.get('preFC').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Send LOI')){
                mapItem.get('loiSent').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Sign LOI')){
                mapItem.get('loiSigned').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Deliver Lease Proposal (MOU)')){
                mapItem.get('mouSent').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Receive Lease Proposal (MOU) Approval')){
                mapItem.get('mouSigned').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Sign PSA')){
                mapItem.get('psaSigned').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Sign Lease')){
                mapItem.get('leaseSigned').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Present Opportunity and Receive Final FC Approval')){
                mapItem.get('finalFC').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Waive Diligence')){
                mapItem.get('diligenceWaived').add(actionItemToDisplay);
            } else if(actionItemToDisplay.Action_Item_Name__c.containsIgnoreCase('Fund Acquisition')){
                mapItem.get('funded').add(actionItemToDisplay);
            } 
        }

        //add the record type check for Broker Network
        // if(oppFromMap.recordtypeid != brokerNetworkRecordTypeId) {
        //     opportunityWrapperItem.dealApproved = getStatusOptionOne(mapItem.get('dealApproved'));
        // } else { opportunityWrapperItem.dealApproved = 'Blank'; }
        
        opportunityWrapperItem.dealApproved = getStatusOptionOne(mapItem.get('dealApproved'));
        opportunityWrapperItem.preFC = getStatusOptionOne(mapItem.get('preFC')); 
        opportunityWrapperItem.loiSent = getStatusOptionOne(mapItem.get('loiSent'));
        opportunityWrapperItem.loiSigned = getStatusOptionOne(mapItem.get('loiSigned')); 
        opportunityWrapperItem.mouSent = getStatusOptionTwo(mapItem.get('mouSent'));
        opportunityWrapperItem.mouSigned = getStatusOptionTwo(mapItem.get('mouSigned'));
        opportunityWrapperItem.psaSigned = getStatusOptionOne(mapItem.get('psaSigned'));
        opportunityWrapperItem.leaseSigned = getStatusOptionThree(mapItem.get('leaseSigned'), oppFromMap.Due_Diligence_End_Date__c);
        opportunityWrapperItem.finalFC = getStatusOptionFour(mapItem.get('finalFC'), oppFromMap.Due_Diligence_End_Date__c);
        opportunityWrapperItem.diligenceWaived = getStatusOptionThree(mapItem.get('diligenceWaived'), oppFromMap.Due_Diligence_End_Date__c);
        opportunityWrapperItem.funded = getStatusOptionThree(mapItem.get('funded'), oppFromMap.CloseDate);

        opportunityToDisplay.add(opportunityWrapperItem);

        system.debug('@@@ opportunityToDisplay = ' + opportunityToDisplay);

    }

    List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
    //get ids to update opportunities
    List<Id> oppWonIds = new List<Id>();
    List<Id> oppContractedIds = new List<Id>();
    List<Id> oppConvertedIds = new List<Id>();
    List<Id> oppProposedIds = new List<Id>();
    List<Id> oppSourcedIds = new List<Id>();

    Integer won = 0;
    Integer Contracted = 0;
    Integer Converted = 0;
    Integer Proposed = 0;
    Integer Sourced = 0;

    for(OpportunityWrapper opp : opportunityToDisplay) {
        if(opp.oppChannel != null) {
            if(opp.oppChannel != 'Influencer') {
                if(opp.funded == 'Completed') {
                    oppWonIds.add(opp.oppId);
                } else if(opp.psaSigned == 'Completed' && opp.funded != 'Completed') {
                    oppContractedIds.add(opp.oppId);
                } else if((opp.loiSigned == 'Completed' || opp.mouSigned == 'Completed') 
                    && opp.psaSigned != 'Completed' && opp.funded != 'Completed') {
                    
                        oppConvertedIds.add(opp.oppId);
                } else if((opp.loiSent == 'Completed' || opp.mouSent == 'Completed') 
                    && opp.loiSigned != 'Completed' && opp.mouSigned != 'Completed' 
                    && opp.psaSigned != 'Completed' && opp.funded != 'Completed') {
                    
                        oppProposedIds.add(opp.oppId);
                } else {oppSourcedIds.add(opp.oppId);}
            }
        }
    }

    List<Opportunity> oppWon = [select id, pipeline_stage__c from opportunity where id in :oppWonIds];
    for(Opportunity opp : oppWon) {
        opp.pipeline_stage__c = 'Won';
        oppsToUpdate.add(opp);
        Won = won + 1;
        system.debug('@@@ won = ' + opp.id);
    }
    List<Opportunity> oppContracted = [select id, pipeline_stage__c from opportunity where id in :oppContractedIds];
    for(Opportunity opp : oppContracted) {
        opp.pipeline_stage__c = 'Contracted';
        oppsToUpdate.add(opp);
        Contracted = Contracted +1;
        system.debug('@@@ Contracted = ' + opp.id);
    }
    List<Opportunity> oppConverted = [select id, pipeline_stage__c from opportunity where id in :oppConvertedIds];
    for(Opportunity opp : oppConverted) {
        opp.pipeline_stage__c = 'Converted';
        oppsToUpdate.add(opp);
        Converted = Converted + 1;
        system.debug('@@@ Converted = ' + opp.id);
    }
    List<Opportunity> oppProposed = [select id, pipeline_stage__c from opportunity where id in :oppProposedIds];
    for(Opportunity opp : oppProposed) {
        opp.pipeline_stage__c = 'Proposed';
        oppsToUpdate.add(opp);
        Proposed = Proposed+1;
        system.debug('@@@ Proposed = ' + opp.id);
    }
    List<Opportunity> oppSourced = [select id, pipeline_stage__c from opportunity where id in :oppSourcedIds];
    for(Opportunity opp : oppSourced) {
        opp.pipeline_stage__c = 'Sourced';
        oppsToUpdate.add(opp);
        Sourced = Sourced +1;
        system.debug('@@@ Sourced = ' + opp.id);
    }
    system.debug('@@@ oppsToUpdate = ' + oppsToUpdate);

    system.debug(Won);
    system.debug(Contracted);
    system.debug(Converted);
    system.debug(Proposed);
    system.debug(Sourced);

    update oppsToUpdate;
}

//green or blank
public static string getStatusOptionOne(List<CSC_Action_Item__c> items){
    String status = '';
    
    for(CSC_Action_Item__c item : items) {
        if(item.Status__c == 'Completed') {
            status = 'Completed';
        } else {status = 'Blank';}
    }
    return status;
}

//green, NA or blank
public static string getStatusOptionTwo(List<CSC_Action_Item__c> items){
    String status = '';
    for(CSC_Action_Item__c item : items) {
        if(item.Status__c == 'Completed') {
            status = 'Completed';
        } else if (item.Status__c == 'N/A') {
            status = 'NA';
        } else {
            status = 'Blank';
        }
    }
    return status;
}

//only for lease signed -- green, red, NA or blank
public static string getStatusOptionThree(List<CSC_Action_Item__c> items, Date ddend){
    String status = '';
    Date todayDate = Date.today();
    for(CSC_Action_Item__c item : items) {
        if (item.Status__c == 'Completed') {
            if (todayDate > ddend) {
                status = 'Incomplete';
            } else {
                status = 'Completed';
            }
        } else if (item.Status__c == 'N/A') {
            if (todayDate > ddend) {
                status = 'Incomplete';
            } else {
                status = 'Completed';
            }
        } else {
            status = 'Blank';
        }
    }
    return status;
}

//green, red or blank
public static string getStatusOptionFour(List<CSC_Action_Item__c> items, Date ddend){
    String status = '';
    Date todayDate = Date.today();
    if (ddend != null) {
        Integer dayDifference = todayDate.daysBetween(ddend);
        for(CSC_Action_Item__c item : items) {
            if (item.Status__c == 'Completed') {
                status = 'Completed';
            } else if (item.Status__c != 'Completed' && dayDifference < 7) {
                status = 'Incomplete';
            } else {
                status = 'Blank';
            }
        }
    } else {
        status = 'Blank';
    }
    return status;
}

//green, red or blank
public static string getStatusOptionFive(List<CSC_Action_Item__c> items, Date closeDate){
    String status = '';
    Date todayDate = Date.today();
    if (closeDate != null) {
        Integer dayDifference = todayDate.daysBetween(closeDate);
        for(CSC_Action_Item__c item : items) {
            if (item.Status__c == 'Completed') {
                status = 'Completed';
            } else if (item.Status__c != 'Completed' && dayDifference < 2) {
                status = 'Incomplete';
            } else {
                status = 'Blank';
            }
        }
    } else {
        status = 'Blank';
    }
    return status;
}

    public class OpportunityWrapper{
        @AuraEnabled
        public String oppId {get;set;}
        @AuraEnabled
        public Opportunity opp {get;set;}
        @AuraEnabled
        public String dealApproved {get;set;}
        @AuraEnabled
        public String preFC {get;set;}
        @AuraEnabled
        public String loiSent {get;set;}
        @AuraEnabled
        public String loiSigned {get;set;}
        @AuraEnabled
        public String mouSent {get;set;}
        @AuraEnabled
        public String mouSigned {get;set;}
        @AuraEnabled
        public String psaSigned {get;set;}
        @AuraEnabled
        public String leaseSigned {get;set;}
        @AuraEnabled
        public String finalFC {get;set;}
        @AuraEnabled
        public String diligenceWaived {get;set;}
        @AuraEnabled
        public String funded {get;set;}
        @AuraEnabled
        public Integer businessDaysToClose {get;set;}
        @AuraEnabled
        public Date createdDate {get;set;}
        @AuraEnabled
        public String oppName {get;set;}
        @AuraEnabled
        public Date closeDate {get;set;}
        @AuraEnabled
        public Date diligenceEnd {get;set;}
        @AuraEnabled
        public String oppChannel {get;set;}
        @AuraEnabled
        public String state {get;set;}
        @AuraEnabled
        public String oppOwner {get;set;}
        @AuraEnabled
        public String dealSpecialist {get;set;}
        @AuraEnabled
        public Decimal estimatedCost {get;set;}
        @AuraEnabled
        public Decimal capRate {get;set;}
    }
}