/*******************************************************************
Name  : SmartAccountSearchExtension
Author: Appirio OffShore
Date  : July 11, 2011 
 
*************************************************************************/
//Assumption : In order to access all the records, we have used without sharing keyword
public virtual without sharing class SmartAccountSearchExtension {
    
    //Search criteria fields
    public Boolean CreatePermission {get;set;}
    public Boolean isDuplicatePermission{get;set;}
    public String accountNameToSearch {set;get;}
    public string accountPrefix{get;set;}    
    public integer searchCount{set; get;}
    public string searchStatus{set; get;}
    public string sortField{set;get;}
    public integer limitRecords{set; get;} //May25-2012 by sdash@appirio.com: added limit 250 to avoid the query overflow of 50,000 records
    private string previousSortField;
    private string sortOrder;
      
    public boolean isAsc{set; get;}
    public Integer showingFrom{get;set;}
    public Integer showingTo{get;set;}
    public string query;
    
    public boolean showAccountButton{set; get;}
    public boolean hasNext{get;set;}
    public boolean hasPrevious{get;set;}
    public String requestedPage {get;set;}
    
    public integer totalResults {set; get;}
    
    public Integer totalPage {set; get;}
    
    public ApexPages.StandardSetController accountResults{get;set;}
    
    //to enable the lead search
    public SmartLeadSearchExtension leadSearch {get;set;}
    public Boolean isBroaderSearchOn{get;set;}
    public String  OtherPageCalling {get;set;}
    public boolean showAllContactButton{set; get;}          
    //Constructor
    public SmartAccountSearchExtension(ApexPages.StandardController controller) {
        
       leadSearch= new SmartLeadSearchExtension();
       isBroaderSearchOn = true;       
       resetSearchStatus();
       getAccountPrefix(); 
       list<DuplicateAccount__c> listDuplicate=[Select d.DuplicateAccount__c From DuplicateAccount__c d where DuplicateAccount__c=true];
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
    
    public SmartAccountSearchExtension(){       
        resetSearchStatus();
        getAccountPrefix();             
    }
        
    //set to default status of page
    public void resetSearchStatus(){
        //Reset account fields
        showAccountButton = false;
        //accounts = new List<Account>();
        searchCount = 0;
        searchStatus = '';
        sortOrder = IConstants.DEFAULT_SORT_ORDER;
        sortField = IConstants.DEFAULT_SORT_FIELD;
        previousSortField = IConstants.DEFAULT_SORT_FIELD;
        accountNameToSearch = '';
        isAsc = true;
        hasPrevious = false;
        hasNext = false;
         
        //if(leadSearch!=null) leadSearch.resetSearchStatus(); 
                                  
    }
    
    /*@jazzyrocksr : Make a describe call get KeyPrefix for account Object to build dynamic URLs*/
    private void getAccountPrefix(){
        Schema.DescribeSObjectResult dsr = Account.SObjectType.getDescribe();
        accountPrefix=dsr.getKeyPrefix();
    
    }
    public List<Account> accounts {
        get{
            return accounts;
        }set;
    }
    
   
    
    public PageReference cancel(){
        Pagereference pg = null;
        return pg;  
    }
    
    public String findSearchCondition(String query){
                
        if(accountNameToSearch != null && accountNameToSearch != ''){
            accountNameToSearch = accountNameToSearch.replace('*','');
            accountNameToSearch = String.escapeSingleQuotes(accountNameToSearch);
            if(query.toUpperCase().contains('WHERE')){
                query += ' and Name like \'%' + accountNameToSearch.Trim() + '%\'';
            }else{
                query += ' where Name like \'%' + accountNameToSearch.Trim() +  '%\'';
            }
        }
        system.debug('query======'+query );
        return query;
    }
  
  
    
    
    public void performSearch() {
        if(accountNameToSearch == null || accountNameToSearch == '')
            return;
        searchAccount();
        if(isBroaderSearchOn) {
            leadSearch.isBroaderSearchOn=false;
            leadSearch.leadCompany=accountNameToSearch;
            leadSearch.performSearch();
        }
        System.debug('Account list ::::::::::::' + accounts);
    }
    
    
    //method to search account and make list according to pagesize
    private void searchAccount(){
        showAccountButton = true;
        limitRecords=250;
        /**************************************************************
         * The code is updated by Jazzy Rock to support fieldsets in 
           Account for dynamic display of columns*   
         **************************************************************/
         
         List<Schema.FieldSetMember> fsm= Schema.SObjectType.Account.FieldSets.Account_Search_Result.getFields();
         String query = 'SELECT ';
         for(Schema.FieldSetMember f : fsm) {
            query += f.getFieldPath() + ', ';
         }
         query += 'Id,Owner.Name FROM Account';
         query = findSearchCondition(query);
         System.debug('QUERY+++++++++:' + query);
         query += ' order by ' + sortField + sortOrder + ' nulls last' + ' LIMIT ' + limitRecords  ;
          
        try{            
            accounts = new List<Account>();
            accountResults = new ApexPages.StandardSetController(Database.query(query));
            accountResults.setPageSize(IConstants.DEFAULT_RESULTS_PER_PAGE);
            accounts = accountResults.getRecords();            
            
             if(accountNameToSearch == ''){
                system.debug(' ============= all are blank ==============');
                showAccountButton = false;
            }
            if(accounts.size()>0 && CreatePermission==false){
           system.debug(' ============= accounts.size()>0 && CreatePermission==false ==============');
               showAccountButton = false;     
            }
            
            
            if((accounts.size()>0 && CreatePermission==true) || (accounts.size()==0 && CreatePermission==false)
            || (accounts.size()==0 && CreatePermission==true)){             
                    system.debug('inside here isDuplicatePermission ='+isDuplicatePermission);
                    isDuplicatePermission=true;             
            }
            else if(accounts.size()>0 && CreatePermission==false){
                isDuplicatePermission=false;  
            }  
            system.debug('isDuplicatePermission ='+isDuplicatePermission);
            searchCount = accountResults.getResultSize();
            if (searchCount >= limitRecords) {
                searchStatus = 'Search returned more than ' + limitRecords + ' records. Please refine your search';
            }
        }
        catch(Exception e){
            searchCount = 0;
        }  
        if (searchCount  == 0){
            searchStatus = Label.No_Matching_Results;
        }
        
        requestedPage = String.valueOf(accountResults.getPageNumber());
        showingFrom = 1;
        
        
        totalResults = 0;
        for (List<Sobject> recordBatch:Database.query(query))  {
             totalResults = totalResults + recordBatch.size();
         }
        totalPage = 0;
        totalPage = totalResults / accountResults.getPageSize() ; 
        if (totalPage * accountResults.getPageSize() < totalResults){
          totalPage++;
        }
        if(searchCount < accountResults.getPageSize()) {
            showingTo = searchCount;
        } else {
            showingTo = accountResults.getPageSize();
        }
        if(accountResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        hasPrevious = false;
      
    }
    
    
    public PageReference nextAccountPage(){
        
        if(accountResults.getHasNext()) {
            accounts = new List<Account>();
            accountResults.next();
            accounts = accountResults.getRecords();
            showingFrom = showingFrom + accountResults.getPageSize();
            showingTo =  showingTo + accounts.size();
            if(accountResults.getHasNext()) {
                hasNext = true;
            } else {
                hasNext = false;
            }
            hasPrevious = true; 
        }
        requestedPage = String.valueOf(accountResults.getPageNumber());
        return null;
    }
    
   
  
    public PageReference previousAccountPage(){
        if(accountResults.getHasPrevious()) {
            showingTo =  showingTo - accounts.size();
            accounts = new List<Account>();
            accountResults.previous();
            accounts = accountResults.getRecords();
            showingFrom = showingFrom - accountResults.getPageSize();
            hasNext = true;
            if(accountResults.getHasPrevious()) {
                hasPrevious = true;
            } else {
                hasPrevious = false;
            }
        }
        requestedPage = String.valueOf(accountResults.getPageNumber());  
        return null;
    }
    
   
  
    public PageReference requestedAccountPage(){
        
        boolean check = pattern.matches('[0-9]+',requestedPage); 
        Integer pageNo = check? Integer.valueOf(requestedPage) : 0;
        if(pageNo == 0 || pageNo > totalPage){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Invalid_page_number)); 
            return null;       
        }   
        accountResults.setPageNumber(pageNo);
        accounts = accountResults.getRecords();
        if(accountResults.getHasPrevious()) {
            hasPrevious = true;
         } else {
            hasPrevious = false;
         }
         if(accountResults.getHasNext()) {
            hasNext = true;
        } else {
            hasNext = false;
        }
        showingFrom  = (pageNo - 1) * accountResults.getPageSize() + 1;
       
        showingTo = showingFrom + accounts.size() - 1;
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
        searchAccount();
    }
    
    public SmartAccountSearchExtension getThis() {
        return this;
    }
    
   

}