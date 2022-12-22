public without sharing class SmartContactSearchExtension {

    
    //Search criteria fields
    public Boolean CreatePermission {get;set;}
    public Boolean isDuplicateCreatePermission{get;set;}
    public String contactFirstNameToSearch {set;get;}
    public String contactLastNameToSearch {set;get;}
    public String contactEmail {set;get;}
    public STring contactAccount {get;set;}
    public String resetTextBoxName {set; get;}
     
    public integer searchCount{set; get;}
    public string searchStatus{set; get;}
    public string sortField{set;get;}
    private string previousSortField;
    private string sortOrder;
    public integer limitRecords{set; get;}   
    public boolean isAsc{set; get;}
    public Integer showingFrom{get;set;}
    public Integer showingTo{get;set;}
    public string query ;    
    public boolean showContactButton{set; get;}
    public boolean hasNext{get;set;}
    public boolean hasPrevious{get;set;}
    public String requestedPage {get;set;}
    
    public integer totalResults {set; get;}
    
    public Integer totalPage {set; get;}
    public String contactPrefix{set;get;}
    public String  OtherPageCalling {get;set;}
    public boolean showAllContactButton{set; get;}
    
    public ApexPages.StandardSetController contactResults;
    
      //to enable the lead search
    public SmartLeadSearchExtension leadSearch {get;set;}
    public Boolean isBroaderSearchOn{get;set;}
    
    //Constructor
    public SmartContactSearchExtension(ApexPages.StandardController controller) {         
        isDuplicateCreatePermission=false; 
        leadSearch= new SmartLeadSearchExtension();
        isBroaderSearchOn = true;   
        
        resetSearchStatus();
        getContactPrefix();   
        list<DuplicateContact__c> listDuplicate=[Select d.Create_Duplicate_Contacts__c From DuplicateContact__c d where Create_Duplicate_Contacts__c=true];
        if(listDuplicate != null && listDuplicate.size()>0){
            CreatePermission=true;  
        }
        else{
            CreatePermission=false; 
        }  
        if(OtherPageCalling=='true'){
            showAllContactButton=false;
        }
        else{
            showAllContactButton=true;
        }
    }    
    public SmartContactSearchExtension() {           
        resetSearchStatus();
        getContactPrefix();          
    }

    /*@jazzyrocksr : Make a describe call get KeyPrefix for Contact Object to build dynamic URLs*/
    private void getContactPrefix(){        
        Schema.DescribeSObjectResult dsr = Contact.SObjectType.getDescribe();
        contactPrefix=dsr.getKeyPrefix();
    }
    //set to default status of page
    public void resetSearchStatus(){        
        //Reset Contact fields
        showContactButton = false;
        //contacts = new List<Contact>();
        searchCount = 0;
        searchStatus = '';
        sortOrder = IConstants.DEFAULT_SORT_ORDER;
        sortField = IConstants.DEFAULT_SORT_FIELD;
        previousSortField = IConstants.DEFAULT_SORT_FIELD;
        
        if(resetTextBoxName != ''){
            if(resetTextBoxName=='1'){
                 contactFirstNameToSearch = '';
            }
            else if(resetTextBoxName=='2'){
                 contactLastNameToSearch = '';
            }
            else if(resetTextBoxName=='3'){
                 contactEmail = '';
            }
            else if(resetTextBoxName=='4'){
                 contactAccount = '';
            }        
        }
        else{    
            contactFirstNameToSearch = '';
            contactLastNameToSearch = '';
            contactEmail = '';
            contactAccount = '';
        }
        isAsc = true;
        hasPrevious = false;
        hasNext = false; 
        
        //if(leadSearch!=null) leadSearch.resetSearchStatus();           
    }
    
    public List<Contact> contacts {
        get{
            return contacts;
        }set;
    }
    
   
    
    public PageReference cancel(){ 
        Pagereference pg = null;         
        return pg;  
        
    }
    
    public String findSearchCondition(String query){     
     if(contactFirstNameToSearch != null && contactFirstNameToSearch != ''){
          contactFirstNameToSearch = contactFirstNameToSearch.replace('*','');
          contactFirstNameToSearch = String.escapeSingleQuotes(contactFirstNameToSearch);
          if(query.toUpperCase().contains('WHERE')){
            query += ' and FirstName like \'%' + contactFirstNameToSearch.Trim() + '%\'';
          }else{
            query += ' where FirstName like \'%' + contactFirstNameToSearch.Trim() +  '%\'';
          }
      }
      if(contactLastNameToSearch != null && contactLastNameToSearch != ''){
          contactLastNameToSearch = contactLastNameToSearch.replace('*','');
          contactLastNameToSearch = String.escapeSingleQuotes(contactLastNameToSearch);
          if(query.toUpperCase().contains('WHERE')){
            query += ' and LastName like \'%' + contactLastNameToSearch.Trim() + '%\'';
          }else{
            query += ' where LastName like \'%' + contactLastNameToSearch.Trim() +  '%\'';
          }
      }
      if(contactEmail != null && contactEmail != ''){
          contactEmail = contactEmail.replace('*','');
          contactEmail = String.escapeSingleQuotes(contactEmail);
          if(query.toUpperCase().contains('WHERE')){
            query += ' and Email like \'%' + contactEmail.Trim() + '%\'';
          }else{
            query += ' where Email like \'%' + contactEmail.Trim() +  '%\'';
          }
      }
      
      if(contactAccount != null && contactAccount != ''){
          contactAccount = contactAccount.replace('*','');
          contactAccount = String.escapeSingleQuotes(contactAccount);
          if(query.toUpperCase().contains('WHERE')){
            query += ' and Account.Name like \'%' + contactAccount.Trim() + '%\'';
          }else{
            query += ' where Account.Name like \'%' + contactAccount.Trim() +  '%\'';
          }
      }
      
      system.debug('query======'+query );
    return query;
  }
  
  
    
    
    public void performSearch() {       
        system.debug('query======'+query );
        if(contactFirstNameToSearch == null && contactLastNameToSearch==null && contactEmail==null && contactAccount==null)
            return;
        
        searchContact();
        if(isBroaderSearchOn) {
            leadSearch.isBroaderSearchOn=false;
            leadSearch.leadFirstNameToSearch=contactFirstNameToSearch;
            leadSearch.leadLastNameToSearch=contactLastNameToSearch;
            leadSearch.leadEmail=contactEmail;
            leadSearch.performSearch();
        } 
        
        System.debug('Contact list ::::::::::::' + contacts);
    }
    
    //method to search Contact and make list according to pagesize
    private void searchContact(){
        showContactButton = true;
         limitRecords=250;
        /**************************************************************
         * The code is updated by Jazzy Rock to support fieldsets in 
           Contact for dynamic display of columns*   
         **************************************************************/
         
         List<Schema.FieldSetMember> fsm= Schema.SObjectType.Contact.FieldSets.Contact_Search_Result.getFields();
         String query = 'SELECT ';
         for(Schema.FieldSetMember f : fsm) {
            query += f.getFieldPath() + ', ';
         }
         query += 'Id,Owner.Name,Account.Name FROM Contact';
        
        query = findSearchCondition(query);
        System.debug('QUERY+++++++++:' + query);
        query += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords ;
          
        try{                         
            contacts = new List<Contact>();
            contactResults = new ApexPages.StandardSetController(Database.query(query));
            contactResults.setPageSize(IConstants.DEFAULT_RESULTS_PER_PAGE);
            contacts = contactResults.getRecords();
            
            // Create lead button will be disabled if we have any field is blank
            if((contactFirstNameToSearch == '' ||  contactLastNameToSearch == '' || contactEmail == '' ||
            contactAccount == '')&& contacts.size()==0){
                system.debug(' ============= all are blank ==============');
                showContactButton = false;
            }
            if((contactFirstNameToSearch != '' ||  contactLastNameToSearch != '' || contactEmail != '' ||
            contactAccount != '') && contacts.size() >0 && CreatePermission==true){
                system.debug(' ============= all are blank ==============');
                showContactButton = true;
            } 
            
            //NEW_CODE - Rajeev Arya(Appirio India) - [07/08/2014] - I-120345 SmartSearch asset on Production
            if((contactFirstNameToSearch != '' ||  contactLastNameToSearch != '' || contactEmail != '' ||
            contactAccount != '') && contacts.size() == 0 ){
                system.debug(' ============= all are blank ==============');
                showContactButton = true;
            }    
            //END_NEW_CODE - Rajeev Arya(Appirio India) - [07/08/2014] - I-120345 SmartSearch asset on Production
            
            if(contacts.size()>0 && CreatePermission==false){
           system.debug(' ============= contacts.size()>0 && CreatePermission==false ==============');
               showContactButton = false;     
            }
              
            if((contacts.size()>0 && CreatePermission==true) || (contacts.size()==0 && CreatePermission==false)
            || (contacts.size()==0 && CreatePermission==true)){             
                    system.debug('inside here isDuplicateCreatePermission in contact ='+isDuplicateCreatePermission);
                    isDuplicateCreatePermission=true;               
            }
            else if(contacts.size()>0 && CreatePermission==false){
                isDuplicateCreatePermission=false;  
            }  
            searchCount = contactResults.getResultSize();
            if (searchCount >= limitRecords) {
                searchStatus = 'Search returned more than ' + limitRecords + ' records. Please refine your search';
            }
        }catch(Exception e){
            searchCount = 0;
        }  
        if (searchCount  == 0){
            searchStatus = Label.No_Matching_Results;
        }
        requestedPage = String.valueOf(contactResults.getPageNumber());
        showingFrom = 1;
        
        
        totalResults = 0;
        for (List<Sobject> recordBatch:Database.query(query))  {
             totalResults = totalResults + recordBatch.size();
         }
        totalPage = 0;
        totalPage = totalResults / contactResults.getPageSize() ; 
        if (totalPage * contactResults.getPageSize() < totalResults){
          totalPage++;
        }
        if(searchCount < contactResults.getPageSize()) {
            showingTo = searchCount;
        } else {
            showingTo = contactResults.getPageSize();
        }
        if(contactResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        hasPrevious = false;
    }
    
    
    public PageReference nextContactPage(){
        
        if(contactResults.getHasNext()) {
            contacts = new List<Contact>();
            contactResults.next();
            contacts = contactResults.getRecords();
            showingFrom = showingFrom + contactResults.getPageSize();
            showingTo =  showingTo + contacts.size();
            if(contactResults.getHasNext()) {
                hasNext = true;
            } else {
                hasNext = false;
            }
            hasPrevious = true; 
        }
        requestedPage = String.valueOf(contactResults.getPageNumber());
        return null;
    }
    
   
  
    public PageReference previousContactPage(){
        if(contactResults.getHasPrevious()) {
            showingTo =  showingTo - contacts.size();
            contacts = new List<Contact>();
            contactResults.previous();
            contacts = contactResults.getRecords();
            showingFrom = showingFrom - contactResults.getPageSize();
            hasNext = true;
            if(contactResults.getHasPrevious()) {
                hasPrevious = true;
            } else {
                hasPrevious = false;
            }
        }
        requestedPage = String.valueOf(contactResults.getPageNumber());  
        return null;
    }
    
   
  
    public PageReference requestedContactPage(){
        
        boolean check = pattern.matches('[0-9]+',requestedPage); 
        Integer pageNo = check? Integer.valueOf(requestedPage) : 0;
        if(pageNo == 0 || pageNo > totalPage){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Invalid_page_number)); 
            return null;       
        }  
        contactResults.setPageNumber(pageNo);
        contacts = contactResults.getRecords();
        if(contactResults.getHasPrevious()) {
            hasPrevious = true;
         } else {
            hasPrevious = false;
         }
         if(contactResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        showingFrom  = (pageNo - 1) * contactResults.getPageSize() + 1;
       
        showingTo = showingFrom + contacts.size() - 1;
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
        searchContact();
    }
    
    public SmartContactSearchExtension getThis() {
        return this;
    }
    
   

}