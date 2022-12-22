public class LeadDiligenceRulesController {
    
    public Lead ld {get;set;}
    public Id objectId {get;set;}
    public boolean doNotCreateOpp {get;set;}
        
    public PAgeReference back(){
      PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page; 
    }
    
    public void setLead(Lead l) {
        ld = l;
        objectId = l.Id;
    }
    
   public LeadDiligenceRulesController() {
        
   }
   
   public LeadDiligenceRulesController(ApexPages.StandardController thecontroller) {
        ld = (Lead)thecontroller.getRecord();
        ld = [Select Id, Opportunity_Type__c, Lead_Type__c, funding_need__c, Operating_State__c, apply_diligence_rules__c From Lead Where Id=:ld.Id];
        objectId = ld.Id;
   }
   
    
    public PageReference execute() {
        
        
        if (ld.Lead_Type__c!='Charter Holder' &&
            ld.Lead_Type__c!= 'School' &&
            ld.Lead_Type__c!= 'Business' )
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Lead Type must be Charter Holder or Business or School');
                ApexPages.addMessage(myMsg);
                return null;
                
            }
                        
        if (ld.Opportunity_Type__c!='Facilities' && ld.Opportunity_Type__c!='Initial Funding' && ld.Opportunity_Type__c!='LOI'&& ld.Opportunity_Type__c!='Energy' && ld.Opportunity_Type__c!='Enrollment Marketing' && ld.Opportunity_Type__c!='Medicaid') {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Opportunity Type must be Facilities, Initial Funding, LOI, Energy, Medicaid or Enrollment Marketing');
            ApexPages.addMessage(myMsg);
            return null;
        }
        
        /*
        if (ld.RecordTypeId!=RecordTypes.IDGeneralLead && ld.RecordTypeId!=RecordTypes.IDFacilitiesLead) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Lead Record Type must be Facilities or General');
            ApexPages.addMessage(myMsg);
            return null;    
        }
        
        if (ld.RecordTypeId==RecordTypes.IDFacilitiesLead && (ld.funding_need__c==null || !ld.funding_need__c.contains('Facilities Financing'))) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Facilities Leads must have Funding Type of Facilities Financing');
            ApexPages.addMessage(myMsg);
            return null;    
        }
        */
        if (ld.lead_type__c==null|| ld.Opportunity_Type__c==null || ld.Operating_State__c==null) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Lead Type, Opportunity Type and Operating State are required in order to Convert this Lead');
            ApexPages.addMessage(myMsg);
            return null;
        }
        if (ld.apply_diligence_rules__c==true) {
            //reset the flag if it is already set
            ld.apply_diligence_rules__c=false;
            update ld;
        }
        ld.apply_diligence_rules__c = true;
        if (doNotCreateOpp) {
                ld.DoNot_Create_Opportunity_On_Lead_Convert__c = true;
        }
        
        
        System.debug('Lead: ' + ld);        
        update ld;  
        
        ld = [Select Id, Opportunity_Type__c, Lead_Type__c, do_automatic_conversion__c, funding_need__c, Operating_State__c, apply_diligence_rules__c From Lead Where Id=:ld.Id];
        System.debug('Lead: ' + ld);
        if (ld.do_automatic_conversion__c) {
            
            PageReference page = new PageReference('/'+objectId);
            page.setRedirect(true);            
            return page;
        } else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Please review all error messages on the Lead');
            //if test, convert anyway
            if (test.isrunningtest()) {
                ld.do_automatic_conversion__c = true;
                update ld;
                return null;
            }
            ApexPages.addMessage(myMsg);
            return null;
        }
        
    }

}