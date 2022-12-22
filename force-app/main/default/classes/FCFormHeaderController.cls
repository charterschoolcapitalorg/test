public with sharing class FCFormHeaderController {


    public FC_Form__c summaryFCForm { get; set; }
    public FC_Form__c financeFCForm { get; set; }
    public FC_Form__c underwritingFCForm { get; set; }
    public FC_Form__c servicingFCForm { get; set; }
    public FC_Details__c fcDetails { get; set; }
    public FC_Form__c fcForm { get; set; }
    public String recordTypeName { get; set; }
    public String selectedOtherFCDetails { get; set; }
    public List<SelectOption> otherFCDetailsOptions { get; set; }  
    public String selectedPreviousFCDetails { get; set; }
    public List<SelectOption> previousFCDetailsOptions { get; set; }       
    public Boolean showPreviousFCDetailsSelectlist { get; set; } 
    public String currentSchool { get; set; } 
    public String currentOpportunity { get; set; } 
    public Boolean isEditMode { get; set; } 

    public FCFormHeaderController(ApexPages.StandardController controller) {

        fcDetails = (FC_Details__c) controller.getRecord();
        fcDetails = [Select RecordType.Name, Detail_Long_Name__c, FC_Form__c, FC_Form__r.Opportunity__r.Account.Name, FC_Form__r.Name, FC_Form__r.RecordTypeId, FC_Form__r.Opportunity__r.AccountId, Opp_School__r.School__r.Name, Opp_School__r.Opportunity__r.Name From FC_Details__c Where Id = :fcDetails.Id][0];
        fcForm = [Select Id, Name, RecordType.Name, RecordTypeId, Opportunity__r.AccountId From FC_Form__c Where Id = :fcDetails.FC_Form__c][0];
        //otherFCForms = [Select Id, Name, Recordtype.Name FROM FC_Form__c Where Recordtype.Name = :fcDetails.RecordType.Name And Opportunity__r.AccountId = :fcDetails.FC_Form__r.Opportunity__r.AccountId Order By Opportunity__r.Createddate];

        currentSchool = fcDetails.FC_Form__r.Opportunity__r.Account.Name;
        currentOpportunity = fcDetails.Opp_School__r.Opportunity__r.Name;
    


        // Get other FC Details options
        Set<Id> fcDetailIds = new Set<Id>();
        otherFCDetailsOptions = new List<SelectOption>();
        otherFCDetailsOptions.add(new SelectOption('-- select --', '-- select --'));
        for (FC_Details__c fcd : [Select Id, Name, Detail_Long_Name__c From FC_Details__c Where FC_Form__r.Opportunity__c = :fcDetails.FC_Form__r.Opportunity__c Order By CreatedDate]) {
            if (fcDetails.Id != fcd.Id) {
                otherFCDetailsOptions.add(new SelectOption(fcd.Id, fcd.Detail_Long_Name__c));    
                fcDetailIds.add(fcd.Id);
            }    
        }
       

        // Get record type options
        previousFCDetailsOptions = new List<SelectOption>();
        previousFCDetailsOptions.add(new SelectOption('-- select --', '-- select --'));
        for (FC_Details__c fcd : [Select Id, Name, Detail_Long_Name__c, Recordtype.Name, Opp_School__c, Opp_School__r.Legal_Name__c FROM FC_Details__c Where FC_Form__r.Opportunity__r.AccountId = :fcDetails.FC_Form__r.Opportunity__r.AccountId Order By CreatedDate]) {
            if (fcDetails.Id != fcd.Id && !fcDetailIds.contains(fcd.Id))
                previousFCDetailsOptions.add(new SelectOption(fcd.Id, fcd.Detail_Long_Name__c));    
        }
        showPreviousFCDetailsSelectlist = previousFCDetailsOptions.size() > 1;  


       
        // Get fields for each fieldset
        if (fcForm.RecordType.Name == 'Summary') summaryFCForm = getFCFormFieldSet('Summary_Header');
        if (fcForm.RecordType.Name == 'Finance') financeFCForm = getFCFormFieldSet('Finance_Header');
        if (fcForm.RecordType.Name == 'Underwriting') underwritingFCForm = getFCFormFieldSet('UW_Header');
        if (fcForm.RecordType.Name == 'Servicing') servicingFCForm = getFCFormFieldSet('Servicing_Header');
      
        // Set default
        //selectedOtherFCDetails = fcForm.Id;
        
        isEditMode = False;

    }

    
    private FC_Form__c getFCFormFieldSet(String fieldSetName) {
    
        List<Schema.FieldSetMember> fields;
        
        
        if (fieldSetName == 'Finance_Header') {
            fields = SObjectType.FC_Form__c.FieldSets.Finance_Header.getFields();
            recordTypeName = 'Finance';
        } 
        if (fieldSetName == 'UW_Header') {
            fields = SObjectType.FC_Form__c.FieldSets.UW_Header.getFields();
            recordTypeName = 'Underwriting';
        }  
        if (fieldSetName == 'Servicing_Header') {
            fields = SObjectType.FC_Form__c.FieldSets.Servicing_Header.getFields();
            recordTypeName = 'Servicing';
        }          
                  
        // Query FC Forms based on record type and fieldset
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : fields) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, Name, Recordtype.Name FROM FC_Form__c Where Id = \'' + fcForm.Id + '\' ';

        //List<FC_Form__c> fcForms = Database.query(query);
        return Database.query(query);
    }    

    public PageReference redirectRecordType() {
    //system.assertequals(null, selectedOtherFCDetails);
        PageReference pageRef = new PageReference('/apex/FCFormHeader?id=' + selectedOtherFCDetails);
        pageRef.setRedirect(true);
        return pageRef;
        //return null;
    }

    public PageReference edit() {
        isEditMode = True;
        return null;
    }
    
    public PageReference save() {
    
        try {
            if (recordTypeName == 'Summary') update summaryFCForm;
            if (recordTypeName == 'Finance') update financeFCForm;
            if (recordTypeName == 'Underwriting') update underwritingFCForm;
            if (recordTypeName == 'Servicing') update servicingFCForm;
            isEditMode = False;
        } catch(Exception ex){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage());
            ApexPages.addMessage(msg);
            //return null;
        }    
            
        return null;
    }
    
    public PageReference cancel() {
        isEditMode = False;
        return null;
    }        

}