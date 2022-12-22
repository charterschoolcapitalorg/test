public with sharing class FCApprovalsController {

    public Class FCApprovalWrapper {
        public Boolean isCurrentUser { get; set; }
        public Boolean isRejected { get; set; }
        public FC_Approval__c fcApproval { get; set; }
    }
    

    public List<FCApprovalWrapper> fcApprovalWrapperList { get; set; }
    public List<FC_Approval__c> fcApprovals { get; set; }
    public FC_Form__c fcForm { get; set; }
    public List<String> types { get; set; }
    public String selectedType { get; set; }
    public List<SelectOption> typeOptions { get; set; }
    public FC_Form__c summaryPreFCFields { get; set; }
    public FC_Form__c summaryAccountInfoFields { get; set; }
    public FC_Form__c summaryOpportunityTeamFields { get; set; }
    public FC_Form__c summaryOutstandingItemsFields { get; set; }
    public FC_Form__c underwritingFields { get; set; }
    public FC_Form__c underwritingSchoolProfileFields { get; set; }
    public FC_Form__c underwritingReviewFields { get; set; }
    public FC_Form__c underwritingOppReviewFields { get; set; }
    public FC_Form__c financeFields { get; set; }
    public FC_Form__c financeRPAFields { get; set; }
    public FC_Form__c financeReviewFields { get; set; }
    public FC_Form__c servicingFields { get; set; }
    public FC_Form__c servicingFundingExposureFields { get; set; }
    public Map<String, FC_Details__c> financeRPAFieldsMap { get; set; }
    public Map<String, FC_Details__c> financeReviewFieldsMap { get; set; }
    public Map<String, FC_Details__c> financeEWSFieldsMap { get; set; }
    public Map<String, FC_Details__c> financeAssessmentFieldsMap { get; set; }
    public Map<String, FC_Details__c> uwSchoolProfileFieldsMap { get; set; }
    public Map<String, FC_Details__c> uwReviewFieldsMap { get; set; }
    public Map<String, FC_Details__c> uwEWSFieldsMap { get; set; }
    public Map<String, FC_Details__c> servicingFieldsMap { get; set; }
    public Map<String, FC_Details__c> servicingExposureFieldsMap { get; set; }
    public Map<String, FC_Details__c> servicingRatingsFieldsMap { get; set; }
    public Map<String, String> type2IdMap { get; set; }
    public String updatedFCApprovalId { get; set; }
    public Map<String, FC_Details__c> schoolMap { get; set; }
    public Map<String, String> attachmentMap { get; set; }
    public List<String> schoolNames { get; set; }
    public Integer currentIndex { get; set; }
    public Integer totalSchools {get; set; }
    public String currentSchoolName { get; set; }
    public Id oppId { get; set; }
    public Boolean isAnyFCApprovals { get; set; }
    public Boolean isFacilities { get; set; }
    public String summaryAttachmentCount { get; set; }
    public String financeCommentsForSummary { get; set; }

    // Constructor
    public FCApprovalsController(ApexPages.StandardController controller) {
        fcForm = (FC_Form__c) controller.getRecord();
        fcForm = [Select Opportunity__c, Opportunity__r.RecordType.Name, Opportunity__r.Account.Name, Status__c, Funding_Date__c, Prepared_by_UW_Link__c, Prepared_by_FIN_Link__c, RecordType.DeveloperName
                        , Prepared_by_SVC_Link__c, (Select Id From Attachments), (SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLinks WHERE LinkedEntityId = :fcForm.Id) From FC_Form__c Where Id = :fcForm.Id];
        oppId = fcForm.Opportunity__c;
        isFacilities = (fcForm.Opportunity__r.RecordType.Name == 'Facilities' || fcForm.RecordType.DeveloperName == 'Facilities');    
        summaryAttachmentCount = String.valueOf(fcForm.attachments.size() + fcForm.ContentDocumentLinks.size());    
       
        // Get related FC Forms and populate type2IdMap
        type2IdMap = new Map<String, String>();
        for (FC_Form__c f : [Select Id, RecordType.Name From FC_Form__c Where Opportunity__c = :oppId]) {
            type2IdMap.put(f.RecordType.Name, f.Id);
        }
        
        // Get fields for each fieldset
        if (!isFacilities) {

            // Populate Schools data structure from FC Details
            populateSchools(oppId);
        
            // Get FC Form data from fieldsets
            summaryPreFCFields = getFCFormFieldSet('FC_Approvals_Summary_Pre_FC');
            summaryAccountInfoFields = getFCFormFieldSet('FC_Approvals_Summary_AccountInfo');
            summaryOpportunityTeamFields = getFCFormFieldSet('FC_Approvals_Summary_OpportunityTeam');
            summaryOutstandingItemsFields = getFCFormFieldSet('FC_Approvals_Summary_OutstandingItems');
            underwritingFields = getFCFormFieldSet('FC_Approvals_Underwriting');
            underwritingSchoolProfileFields = getFCFormFieldSet('FC_Approvals_Underwriting_SchoolProfile');
            underwritingReviewFields = getFCFormFieldSet('FC_Approvals_Underwriting_Review');
            underwritingOppReviewFields = getFCFormFieldSet('FC_Approvals_Underwriting_OppReview');
            financeFields = getFCFormFieldSet('FC_Approvals_Finance');
            financeRPAFields = getFCFormFieldSet('FC_Approvals_Finance_RPA');
            financeReviewFields = getFCFormFieldSet('FC_Approvals_Finance_Review');
            financeFields.Enrollment_Cap_By_Site__c = underwritingFields.Enrollment_Cap_By_Site__c;     // Exception, need to copy the Enrollment_Cap_By_Site__c value from UW to Finance
            servicingFields = getFCFormFieldSet('FC_Approvals_Servicing');
            servicingFundingExposureFields = getFCFormFieldSet('FC_Approvals_Servicing_FundingExposure');
            
            // Get FC Details data from fieldsets
            uwSchoolProfileFieldsMap = getFCDetailsFieldSet('UW_School_Profile');
            uwReviewFieldsMap = getFCDetailsFieldSet('UW_Review');
            uwEWSFieldsMap = getFCDetailsFieldSet('UW_EWS');
            financeRPAFieldsMap = getFCDetailsFieldSet('Finance_RPA');
            financeReviewFieldsMap = getFCDetailsFieldSet('Finance_Review');
            for (String s : schoolNames) financeReviewFieldsMap.get(s).Enrollment_Cap_By_Site__c = uwReviewFieldsMap.get(s).Enrollment_Cap_By_Site__c;  // Exception, need to copy the Enrollment_Cap_By_Site__c value from UW to Finance
            financeEWSFieldsMap = getFCDetailsFieldSet('Finance_EWS');
            financeAssessmentFieldsMap = getFCDetailsFieldSet('Finance_Assessment');
            financeCommentsForSummary = getFinanceCommentsForSummary();
            servicingFieldsMap = getFCDetailsFieldSet('Servicing');        
            servicingExposureFieldsMap = getFCDetailsFieldSet('Servicing_Exposure');
            servicingRatingsFieldsMap = getFCDetailsFieldSet('Servicing_Ratings');
    
            
            // Set the current school index to 0, the first school in the list
            currentIndex = 0;
            totalSchools = schoolNames.size();
        
            if (totalSchools > 0) 
                currentSchoolName = schoolNames[0];
            else 
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There are no Opp Schools associated with this FC Form.'));
        }    
        else 
            totalSchools = 0; 
            
    }


    
    // Populate the approvals table, this gets called on page load and also
    // any time the filter value is changed
    public PageReference refreshApprovals() {
    
        // Get FC Approvals associated to this FC Form
        String query = 'Select Name, Approver__c, Approver__r.Name, Status__c, Type__c, Contingencies__c, Comments__c ' +
                       'From FC_Approval__c Where FC_Form__c = \'' + fcForm.Id + '\' ';
                        
        if (selectedType != null && selectedType != '-- show all --')
            query += 'And Type__c = \'' + selectedType + '\'';
       
        query += ' Order by LastmodifiedDate DESC';
        system.debug(query);
        fcApprovals = Database.query(query); 

        fcApprovalWrapperList = new List<FCApprovalWrapper>();
        for (FC_Approval__c fca : fcApprovals) {
            FCApprovalWrapper fcaw = new FCApprovalWrapper();
            fcaw.fcApproval = fca;
            
            if (UserInfo.getUserId().left(15) == fca.Approver__c)
                fcaw.isCurrentUser = true;
            else      
                fcaw.isCurrentUser = false;
            
            if (fca.Status__c == 'Rejected')
                fcaw.isRejected = true;
            else      
                fcaw.isRejected = false;            
               
            fcApprovalWrapperList.add(fcaw);    
        }

                        
        // Populate the Filter by type dropdown list 
        if (fcApprovals.size() > 0) isAnyFCApprovals = True; else isAnyFCApprovals = False;
        if (typeOptions == null && isAnyFCApprovals) getTypeOptions();    
        return null;
    }


    public void getTypeOptions() {
            
            Set<String> typesSet = new Set<String>();
            
            for (FC_Approval__c fca : fcApprovals)
                typesSet.add(fca.Type__c);                
                            
            types = new List<String>(typesSet); 
            typeOptions = new List<SelectOption>();
            types.sort();                       
            
            for (String t : types)
                typeOptions.add(new SelectOption(t, t));
            
            typeOptions.add(0, new SelectOption('-- show all --', '-- show all --'));

    }


    private String getFinanceCommentsForSummary() {
        String finComments = '';
        
        for (String k : financeAssessmentFieldsMap.keySet()) {
            finComments += '<b>School Name: ' +  k  + '</b><br/>' + financeAssessmentFieldsMap.get(k).Finance_comments__c + '<br/><br/>';
        }

        return finComments;
    
    }



    private FC_Form__c getFCFormFieldSet(String fieldSetName) {
    
        List<Schema.FieldSetMember> fields;
        String fcId;
        String additionalFields = '';
        
        if (fieldSetName == 'FC_Approvals_Summary_AccountInfo') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Summary_AccountInfo.getFields();
            fcId = type2IdMap.get('Summary');
            if (fcId == null && !isFacilities) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Summary FC Form associated with this FC Form.'));
                return null;
            }    
        }  
        if (fieldSetName == 'FC_Approvals_Summary_Pre_FC') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Summary_Pre_FC.getFields();
            fcId = type2IdMap.get('Summary');
            if (fcId == null && !isFacilities) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Summary FC Form associated with this FC Form.'));
                return null;
            }    
        }                
        if (fieldSetName == 'FC_Approvals_Summary_OpportunityTeam') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Summary_OpportunityTeam.getFields();
            fcId = type2IdMap.get('Summary');
            if (fcId == null && !isFacilities) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Summary FC Form associated with this FC Form.'));
                return null;
            }    
        }           
        if (fieldSetName == 'FC_Approvals_Summary_OutstandingItems') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Summary_OutstandingItems.getFields();
            fcId = type2IdMap.get('Summary');
            if (fcId == null && !isFacilities) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Summary FC Form associated with this FC Form.'));
                return null;
            }    
        }
        if (fieldSetName == 'FC_Approvals_Underwriting') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Underwriting.getFields();
            fcId = type2IdMap.get('Underwriting');
            additionalFields = 'Enrollment_Cap_By_Site__c, ';  // Exception, need to copy the Enrollment_Cap_By_Site__c value from UW to Finance. Getting the UW value here.
            if (fcId == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Underwriting FC Form associated with this FC Form.'));
                return null;
            }                
        }  
        if (fieldSetName == 'FC_Approvals_Underwriting_SchoolProfile') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Underwriting_SchoolProfile.getFields();
            fcId = type2IdMap.get('Underwriting');
            if (fcId == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Underwriting FC Form associated with this FC Form.'));
                return null;
            }                
        }  
        if (fieldSetName == 'FC_Approvals_Underwriting_Review') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Underwriting_Review.getFields();
            fcId = type2IdMap.get('Underwriting');
            if (fcId == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Underwriting FC Form associated with this FC Form.'));
                return null;
            }                
        }  
        if (fieldSetName == 'FC_Approvals_Underwriting_OppReview') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Underwriting_OppReview.getFields();
            fcId = type2IdMap.get('Underwriting');
            if (fcId == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Underwriting FC Form associated with this FC Form.'));
                return null;
            }                
        }                                                  
        if (fieldSetName == 'FC_Approvals_Finance') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Finance.getFields();
            fcId = type2IdMap.get('Finance');
            if (fcId == null && !isFacilities) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Finance FC Form associated with this FC Form.'));
                return null;
            }    
        } 
        if (fieldSetName == 'FC_Approvals_Finance_RPA') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Finance_RPA.getFields();
            fcId = type2IdMap.get('Finance');
            if (fcId == null && !isFacilities) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Finance FC Form associated with this FC Form.'));
                return null;
            }    
        } 
        if (fieldSetName == 'FC_Approvals_Finance_Review') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Finance_Review.getFields();
            fcId = type2IdMap.get('Finance');
            if (fcId == null && !isFacilities) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Finance FC Form associated with this FC Form.'));
                return null;
            }    
        } 
        if (fieldSetName == 'FC_Approvals_Servicing') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Servicing.getFields();
            fcId = type2IdMap.get('Servicing');
            if (fcId == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Servicing FC Form associated with this FC Form.'));
                return null;
            }    
        }                     
        if (fieldSetName == 'FC_Approvals_Servicing_FundingExposure') {
            fields = SObjectType.FC_Form__c.FieldSets.FC_Approvals_Servicing_FundingExposure.getFields();
            fcId = type2IdMap.get('Servicing');
            if (fcId == null) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no Servicing FC Form associated with this FC Form.'));
                return null;
            }    
        }                     
    
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : fields) {
            query += f.getFieldPath() + ', ';
        }
        query += additionalFields;
        query += 'Id, Name FROM FC_Form__c Where Id = \'' + fcId + '\' ';
       
        return Database.query(query);
    }


    private Map<String, FC_Details__c> getFCDetailsFieldSet(String fieldsetName) {

        List<Schema.FieldSetMember> fields;
        String recordTypeName;
        String additionalFields = '';
        
        
        if (fieldSetName == 'Finance_RPA') {
            fields = SObjectType.FC_Details__c.FieldSets.Finance_RPA.getFields();
            recordTypeName = 'Finance';
        }      
        if (fieldSetName == 'Finance_Review') {
            fields = SObjectType.FC_Details__c.FieldSets.Finance_Review.getFields();
            recordTypeName = 'Finance';
        }        
        if (fieldSetName == 'Finance_EWS') {
            fields = SObjectType.FC_Details__c.FieldSets.Finance_EWS.getFields();
            recordTypeName = 'Finance';
        }        
        if (fieldSetName == 'Finance_Assessment') {
            fields = SObjectType.FC_Details__c.FieldSets.Finance_Assessment.getFields();
            recordTypeName = 'Finance';
        }        
        if (fieldSetName == 'UW_School_Profile') {
            fields = SObjectType.FC_Details__c.FieldSets.UW_School_Profile.getFields();
            recordTypeName = 'Underwriting';
        }  
        if (fieldSetName == 'UW_Review') {
            fields = SObjectType.FC_Details__c.FieldSets.UW_Review.getFields();
            additionalFields = 'Enrollment_Cap_By_Site__c, ';    // Exception, need to copy the Enrollment_Cap_By_Site__c value from UW to Finance. Getting the UW value here.
            recordTypeName = 'Underwriting';
        }  
        if (fieldSetName == 'UW_EWS') {
            fields = SObjectType.FC_Details__c.FieldSets.UW_EWS.getFields();
            recordTypeName = 'Underwriting';
        }  
        if (fieldSetName == 'Servicing') {
            fields = SObjectType.FC_Details__c.FieldSets.Servicing.getFields();
            recordTypeName = 'Servicing';
        }     
        if (fieldSetName == 'Servicing_Exposure') {
            fields = SObjectType.FC_Details__c.FieldSets.Servicing_Exposure.getFields();
            recordTypeName = 'Servicing';
        }                           
        if (fieldSetName == 'Servicing_Ratings') {
            fields = SObjectType.FC_Details__c.FieldSets.Servicing_Ratings.getFields();
            recordTypeName = 'Servicing';
        }  
    
        String query = 'Select ';
        for(Schema.FieldSetMember f : fields) {
            query += f.getFieldPath() + ', ';
        }
        
        query += additionalFields;        
        query += 'Id, Name, Detail_Long_Name__c, Opp_School__r.Legal_Name__c FROM FC_Details__c Where Opp_School__r.Opportunity__c = \'' + oppId; 
        query += '\' And RecordType.Name = \'' + recordTypeName + '\'';

        Map<String, FC_Details__c> fcDetailsMap = new Map<String, FC_Details__c>();
        for (FC_Details__c fcd : Database.query(query)) {
            fcDetailsMap.put(fcd.Opp_School__r.Legal_Name__c, fcd);  
        }
        return fcDetailsMap;

    }





    public void populateSchools(Id oppId) {
                
        // Get FC Details for each School
        schoolMap = new Map<String, FC_Details__c>();
        attachmentMap = new Map<String, String>();
        schoolNames = new List<String>();
        
        for (FC_Details__c fcd : [Select Id, Detail_Long_Name__c, Recordtype.Name, Opp_School__r.Legal_Name__c,
                                            (Select Id From Attachments), (SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLinks) 
                                            From FC_Details__c Where Opp_School__r.Opportunity__c = :oppId
                                            Order by Opp_School__r.Legal_Name__c] ) {

                                            
            String key = fcd.Opp_School__r.Legal_Name__c + ':' + fcd.Recordtype.Name;
            
            if (!schoolNames.contains(fcd.Opp_School__r.Legal_Name__c)) 
                schoolNames.add(fcd.Opp_School__r.Legal_Name__c);
            
    
            schoolMap.put(key, fcd);
            attachmentMap.put(key, String.valueOf(fcd.attachments.size() + fcd.ContentDocumentLinks.size()));
        }   
                                            
    }
    
    
    
    public PageReference updateStatus() {

        String url = '';
        for (FCApprovalWrapper fcaw : fcApprovalWrapperList) {
            if (fcaw.fcApproval.Id == updatedFCApprovalId) {
                url = '/apex/FC_Approval_Update?id=' + fcaw.fcApproval.Id + '&retUrl=/apex/FCApprovals?id=' + FCForm.Id + '&status=' + fcaw.fcApproval.Status__c;
            }    
        }
        return new PageReference(url);
    }


    public PageReference previous() {
        currentIndex--; 
        currentSchoolName = schoolNames[currentIndex];
        return null;
    }


    public PageReference next() {
        currentIndex++; 
        currentSchoolName = schoolNames[currentIndex];
        return null;
    }

    
    public PageReference back() {
        return (new PageReference('/' + fcForm.Id));
    }

}