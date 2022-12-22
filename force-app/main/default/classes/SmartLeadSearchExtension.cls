public without sharing class SmartLeadSearchExtension {
    
     //Search criteria fields
    public String RerenderControl {get;set;}
    public Boolean LeadCreatePermission {get;set;}
    public Boolean isDuplicatePermission{get;set;}
    public String leadFirstNameToSearch {set;get;}
    public String leadLastNameToSearch {set;get;}
    public String leadEmail {set;get;}
    public String leadCompany {set;get;}
    
    public integer searchCount{set; get;}
    public string searchStatus{set; get;}
    public string sortField{set;get;}
    private string previousSortField;
    private string sortOrder;
      
    public boolean isAsc{set; get;}
    public Integer showingFrom{get;set;}
    public Integer showingTo{get;set;}
    public string query ;
    public integer limitRecords{set; get;} 
    public boolean showLeadButton{set; get;}
    public boolean hasNext{get;set;}
    public boolean hasPrevious{get;set;}
    public String requestedPage {get;set;}
    public String leadPrefix {get;set;}
    public integer totalResults {set; get;}
    public String resetTextBoxName {set; get;}
    public Integer totalPage {set; get;}
    public String OtherPageCalling {set; get;}
    public ApexPages.StandardSetController leadResults;
    
    public SmartAccountSearchExtension accountSearch {get;set;}
    public SmartContactSearchExtension contactSearch {get;set;}
    public Boolean isBroaderSearchOn{get;set;}
    public String  LeadPageCalling {set; get;}
    public Boolean ShowLeadButtons{get;set;}
    //Constructor
    public SmartLeadSearchExtension(ApexPages.StandardController controller) {
        OtherPageCalling = 'true';
        if(LeadPageCalling =='true'){
            ShowLeadButtons=false;
        }
        else{
            ShowLeadButtons=true;
        }
        accountSearch = new SmartAccountSearchExtension();
        contactSearch = new SmartContactSearchExtension();
       
        isBroaderSearchOn=true;
        
        resetSearchStatus();
        getLeadPrefix();     
        list<DuplicateLead__c> listDuplicateLead=[Select d.Create_Duplicate_Leads__c From DuplicateLead__c d where Create_Duplicate_Leads__c=true];
            if(listDuplicateLead != null && listDuplicateLead.size()>0){
                LeadCreatePermission=true;  
            }
            else{
                LeadCreatePermission=false; 
            }      
    }
    
    
    
    
    public SmartLeadSearchExtension getThis() {
        return this;
    }
    
     public SmartLeadSearchExtension(){     
        resetSearchStatus();
        getLeadPrefix();       
     }
    public void showLeadButtonOff(){
        showLeadButton = false;
    }
    //set to default status of page
    public void resetSearchStatus(){
        //Reset Lead fields
        showLeadButton = false;
        //leads = new List<Lead>();
        searchCount = 0;
        searchStatus = '';
        sortOrder = IConstants.DEFAULT_SORT_ORDER;
        sortField = IConstants.DEFAULT_SORT_FIELD;
        previousSortField = IConstants.DEFAULT_SORT_FIELD;
        if(resetTextBoxName != ''){
            if(resetTextBoxName=='1'){
                 leadFirstNameToSearch = '';
                 RerenderControl='op1';
            }
            else if(resetTextBoxName=='2'){
                 leadLastNameToSearch = '';
                 RerenderControl='op2';
            }
            else if(resetTextBoxName=='3'){
                 leadEmail = '';
                 RerenderControl='op3';
            }
            else if(resetTextBoxName=='4'){
                 leadCompany = '';
                 RerenderControl='op4';
            }  
                  
        }
        else{        
        leadFirstNameToSearch = '';
        leadLastNameToSearch = '';
        leadEmail = '';
        leadCompany = '';        
        }
        resetTextBoxName='';
        isAsc = true;
        hasPrevious = false;
        hasNext = false; 
       
        // if(accountSearch!=null) accountSearch.resetSearchStatus(); 
        // if(contactSearch!=null) contactSearch.resetSearchStatus(); 
             
    }    
    public List<Lead> leads {
        get{
            return leads;
        }set;
    }
    
   
    
    public PageReference cancel(){
        Pagereference pg = null;
        return pg;  
    }
    
    /*@jazzyrocksr : Make a describe call get KeyPrefix for Lead Object to build dynamic URLs*/
    private void getLeadPrefix(){
        Schema.DescribeSObjectResult dsr = Lead.SObjectType.getDescribe();
        leadPrefix=dsr.getKeyPrefix();
    
    }
    
    public String findSearchCondition(String query){    
     if(leadFirstNameToSearch != null && leadFirstNameToSearch != ''){
         leadFirstNameToSearch = leadFirstNameToSearch.replace('*','');
         leadFirstNameToSearch = String.escapeSingleQuotes(leadFirstNameToSearch);
          if(query.toUpperCase().contains('WHERE')){
            query += ' and FirstName like \'%' + leadFirstNameToSearch.Trim() + '%\'';
          }else{
            query += ' where FirstName like \'%' + leadFirstNameToSearch.Trim() +  '%\'';
          }
      }
      if(leadLastNameToSearch != null && leadLastNameToSearch != ''){
          leadLastNameToSearch = leadLastNameToSearch.replace('*','');
          leadLastNameToSearch = String.escapeSingleQuotes(leadLastNameToSearch);
          if(query.toUpperCase().contains('WHERE')){
            query += ' and LastName like \'%' + leadLastNameToSearch.Trim() + '%\'';
          }else{
            query += ' where LastName like \'%' + leadLastNameToSearch.Trim() +  '%\'';
          }
      }
      if(leadEmail != null && leadEmail != ''){
          leadEmail = leadEmail.replace('*','');
          leadEmail = String.escapeSingleQuotes(leadEmail);
          if(query.toUpperCase().contains('WHERE')){
            query += ' and Email like \'%' + leadEmail.Trim() + '%\'';
          }else{
            query += ' where Email like \'%' + leadEmail.Trim() +  '%\'';
          }
      }
      
      if(leadCompany != null && leadCompany != ''){
          leadCompany = leadCompany.replace('*','');
          leadCompany = String.escapeSingleQuotes(leadCompany);
          if(query.toUpperCase().contains('WHERE')){
            query += ' and Company like \'%' + leadCompany.Trim() + '%\'';
          }else{
            query += ' where Company like \'%' + leadCompany.Trim() +  '%\'';
          }
      }
      
      system.debug('query======'+query );
        return query;
  }
  
  
    
    
    public void performSearch() {
        if(leadFirstNameToSearch == null && leadLastNameToSearch==null && leadEmail==null && leadCompany==null)
        {
            showLeadButton = false;
            return;
        }
        searchLead();         
       if(isBroaderSearchOn) {
            contactSearch.isBroaderSearchOn=false;
            contactSearch.contactFirstNameToSearch=leadFirstNameToSearch;
            contactSearch.contactLastNameToSearch=leadLastNameToSearch;
            contactSearch.contactAccount= leadCompany;
            contactSearch.contactEmail=leadEmail;
            contactSearch.performSearch();
            
            accountSearch.isBroaderSearchOn=false;
            accountSearch.accountNameToSearch=leadCompany;
            accountSearch.performSearch();          
        }
    }
    
    //method to search Lead and make list according to pagesize
    private void searchLead(){
        showLeadButton = true;
        limitrecords=250;
        /**************************************************************
         * The code is updated by Jazzy Rock to support fieldsets in 
           Lead for dynamic display of columns*   
         **************************************************************/
         
         List<Schema.FieldSetMember> fsm= Schema.SObjectType.Lead.FieldSets.Lead_Search_Result.getFields();
         String query = 'SELECT ';
         for(Schema.FieldSetMember f : fsm) {
            query += f.getFieldPath() + ', ';
         }
         query += 'Id,Owner.Name FROM Lead';
        
        query = findSearchCondition(query);
        System.debug('Lead QUERY======' + query);
        query += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords;
          
        //try{  
                
            leads = new List<Lead>();
            leadResults = new ApexPages.StandardSetController(Database.query(query));            
            leadResults.setPageSize(IConstants.DEFAULT_RESULTS_PER_PAGE);
            leads = leadResults.getRecords();                   
            // Create lead button will be disabled if we have any field is blank
            if((leadFirstNameToSearch == '' ||  leadLastNameToSearch == '' || leadCompany == '' ||
            leadEmail == '') && leads.size()==0){                
                showLeadButton = false;
            }
            if((leadFirstNameToSearch != '' ||  leadLastNameToSearch != '' || leadCompany != '' ||
            leadEmail != '') && leads.size() >0 && LeadCreatePermission==true){               
                showLeadButton = true;
            }            
            if(leads.size()>0 && LeadCreatePermission==false){           
               showLeadButton = false;     
            }
            
            //NEW_CODE - Rajeev Arya(Appirio India) - [07/08/2014] - I-120345 SmartSearch asset on Production
            if((leadFirstNameToSearch != '' ||  leadLastNameToSearch != '' || leadCompany != '' ||
            leadEmail != '') && leads.size() == 0 ){               
                showLeadButton = true;
            } 
            //END_NEW_CODE - Rajeev Arya(Appirio India) - [07/08/2014] - I-120345 SmartSearch asset on Production
            
             if((leads.size()>0 && LeadCreatePermission==true) || (leads.size()==0 && LeadCreatePermission==false)
            || (leads.size()==0 && LeadCreatePermission==true)){                
                    system.debug('inside here isDuplicatePermission ='+isDuplicatePermission);
                    isDuplicatePermission=true;             
            }
            else if(leads.size()>0 && LeadCreatePermission==false){
                isDuplicatePermission=false;  
            }  
            system.debug('isDuplicatePermission ='+isDuplicatePermission); 
            searchCount = leadResults.getResultSize();
            if (searchCount >= limitRecords) {
                searchStatus = 'Search returned more than ' + limitRecords + ' records. Please refine your search';
            }
       /* }catch(Exception e){
            //searchCount = 0;
            system.debug('============== exception occur ================ '+e);
        }*/  
        if (searchCount  == 0){
            searchStatus = Label.No_Matching_Results;
        }
        requestedPage = String.valueOf(leadResults.getPageNumber());
        showingFrom = 1;
        totalResults = 0;
        for (List<Sobject> recordBatch:Database.query(query))  {
             totalResults = totalResults + recordBatch.size();
         }
        totalPage = 0;
        totalPage = totalResults / leadResults.getPageSize() ; 
        if (totalPage * leadResults.getPageSize() < totalResults){
          totalPage++;
        }
        
        if(searchCount < leadResults.getPageSize()) {
            showingTo = searchCount;
        } else {
            showingTo = leadResults.getPageSize();
        }
        if(leadResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        hasPrevious = false;        
    }
    
    
    public PageReference nextLeadPage(){
        
        if(leadResults.getHasNext()) {
            leads = new List<Lead>();
            leadResults.next();
            leads = leadResults.getRecords();
            showingFrom = showingFrom + leadResults.getPageSize();
            showingTo =  showingTo + leads.size();
            if(leadResults.getHasNext()) {
                hasNext = true;
            } else {
                hasNext = false;
            }
            hasPrevious = true; 
        }
        requestedPage = String.valueOf(leadResults.getPageNumber());
        return null;
    }
    
   
  
    public PageReference previousLeadPage(){
        if(leadResults.getHasPrevious()) {
            showingTo =  showingTo - leads.size();
            leads = new List<Lead>();
            leadResults.previous();
            leads = leadResults.getRecords();
            showingFrom = showingFrom - leadResults.getPageSize();
            hasNext = true;
            if(leadResults.getHasPrevious()) {
                hasPrevious = true;
            } else {
                hasPrevious = false;
            }
        }
        requestedPage = String.valueOf(leadResults.getPageNumber());  
        return null;
    }
    
   
  
    public PageReference requestedLeadPage(){
        
        boolean check = pattern.matches('[0-9]+',requestedPage); 
        Integer pageNo = check? Integer.valueOf(requestedPage) : 0;
        if(pageNo == 0 || pageNo > totalPage){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Invalid_Page_Number)); 
            return null;       
        }  
        leadResults.setPageNumber(pageNo);
        leads = leadResults.getRecords();
        if(leadResults.getHasPrevious()) {
            hasPrevious = true;
         } else {
            hasPrevious = false;
         }
         if(leadResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        showingFrom  = (pageNo - 1) * leadResults.getPageSize() + 1;
       
        showingTo = showingFrom + leads.size() - 1;
        if(showingTo > totalResults) {
            showingTo = totalResults;
        }
        return null;
    }
    
    
  
    //used to sort
    public void sortData(){
        if (previousSortField.equals(sortField)){
          isAsc = !isAsc;  
        }else{
            isAsc = true;
        }   
        sortOrder = isAsc ? IConstants.SORT_ASC_ORDER : IConstants.SORT_DESC_ORDER;
        previousSortField = sortField;
        searchLead();
    }
    
    
   
    

}