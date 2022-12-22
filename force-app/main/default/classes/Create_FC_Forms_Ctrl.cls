public with sharing class Create_FC_Forms_Ctrl {
    public Opportunity opp {get;set;}
    public List<Contact> cons {get;set;}
    public Id objectId {get;set;}
    
    
    public PageReference back() {
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page;
        
    }
    
    public Create_FC_Forms_Ctrl(ApexPages.StandardController thecontroller) {
    
        opp = (Opportunity)thecontroller.getRecord();
        opp = [Select Id, AccountId, RecordTypeId, Name From Opportunity Where Id=:opp.Id];
        objectId = opp.Id;

    }
     
    public PageReference create() {
    	List<FC_FOrm__c> exist = [Select Id from FC_FOrm__c where Opportunity__c=:opp.Id];

    	if (exist.size()>0) {
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'FC Forms already exist for this Opportunity');
            ApexPages.addMessage(myMsg );
            return null;
    	}
    	
    	if (opp.Name.length()>57) {
    		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The Opportunity Name length cannot exceed 57 characters -give it a common sense Account Name.  Example: Initial Funding - The New York Education Academy of Fitzgerlad Butler could become Initial Funding - NY Education Academy');
            ApexPages.addMessage(myMsg );
            return null;
    	}
    	
    	if (opp.RecordTypeId==RecordTypes.IDFOFOpp|| opp.RecordTypeId==RecordTypes.IDFundingOpp|| opp.RecordTypeId==RecordTypes.IDLoanOpp  || opp.recordtypeid==recordtypes.IDFacilitiesOpp || opp.recordtypeid==recordtypes.ID5DFOpp) {
            System.debug('***** creating fc forms');
            List<FC_FOrm__c> forms = FCFormUtils.createFCForms(opp);
            System.debug('*****forms created: ' + forms);
            FCFOrmUtils.populateHeaderFieldsFromSFData(forms);
            FCFOrmUtils.populateHeaderCommentFieldsFromSFData(forms);

            List<Opp_School__c> oss = [Select Id, Opportunity__c, Name from Opp_School__c where Opportunity__c =:opp.Id];

            //when new Opp School is created, create FC Form detail objects
            List<FC_Details__c> det = FCFormUtils.createFCDetails(oss);
            System.debug('*****details created: ' + det);
            FCFOrmUtils.populateDetailFieldsFromSFData(det);
            FCFOrmUtils.populateDetailCommentFieldsFromSFData(det);
        		
        }
     	
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page;
    
    }
}