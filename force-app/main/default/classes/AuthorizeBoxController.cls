public with sharing class AuthorizeBoxController {
    @TestVisible public static String SETTING_NAME = 'CredentialsBox';
    @TestVisible public static String ACCESS_TOKEN_URL = 'https://api.box.com/oauth2/token';
    @TestVisible public static String AUTHORIZE_URL = 'https://account.box.com/api/oauth2/authorize';
	@TestVisible public static string API_ROOT = 'https://api.box.com/2.0';
	@TestVisible public static string API_ROOT_FOR_UPLOAD = 'https://upload.box.com/api/2.0';
	
	@TestVisible public static String FOLDER_URL = API_ROOT+'/folders';    

    @TestVisible private String access_token;
    @TestVisible private Boolean isCallback;
    
    

    /**
    * Generic constructor
    */
    public AuthorizeBoxController() {
   		//Opportunity opp = (Opportunity)thecontroller.getRecord();
        //opp = [Select Id, AccountId  From Opportunity Where Id=:opp.Id];
        //this.objectId = opp.Id;
    
        this.isCallback = ApexPages.currentPage().getParameters().containsKey('code');
		
        if (BoxCredentials__c.getOrgDefaults() != null) {
            this.access_token = BoxCredentials__c.getOrgDefaults().Access_Token__c;
        }
    }
	
	/*public PageReference forceRefresh() {
		BOxUtils.GetBoxTokens(code, this.getPageUrl());
       BoxCredentials__c creds = BoxCredentials__c.getOrgDefaults();
       this.access_token = creds.Access_Token__c;
       
       return null;
	}*/
	
    /**
	* Gets the authroization URL
	*
	* @return The authorization url
	*/
    public String getAuthUrl() {
        Map<String, String> urlParams = new Map<String, String> {
			'client_id' => BoxCredentials__c.getOrgDefaults().Client_Id__c,
			//'redirect_uri' => 'cscfull-charterschoolcapital.cs78.force.com/boxauth',
			'redirect_uri' => getPageUrl(),
			'response_type' => 'code'
		};

		PageReference ref = new PageReference(AUTHORIZE_URL);
		ref.getParameters().putAll(urlParams);

		return ref.getUrl();
    }
    
    /**
    * Gets the page url
    * 
    * @return The page url
    */
    @testVisible
    private String getPageUrl() {
        String host = ApexPages.currentPage().getHeaders().get('Host');
        String path = ApexPages.currentPage().getUrl().split('\\?').get(0);
        
        return 'https://' + host + path;
    }
    
    /**
    * If the access token is set
    * 
    * @return If the access token is set
    */
    public Boolean getHasToken() {
        return (this.access_token != null);
    }
    
    /**
    * Validates the callback code and generates the access and refresh tokens
    * 
    * @return null to refresh the page
    */
    public PageReference redirectOnCallback() {
        if (this.isCallback) {
            String code = ApexPages.currentPage().getParameters().get('code');
            
            BOxUtils.OAuthResult result = BOxUtils.GetBoxTokens(code, this.getPageUrl(), false);
            
            
            BoxUtils.GetBoxRootFolders();
            
            if (result!=null) {
            	BoxCredentials__c creds = BoxCredentials__c.getOrgDefaults();
		        creds.Access_Token__c = result.access_token;
		        creds.Refresh_Token__c = result.refresh_token;
		        update creds;
		        this.access_token = creds.Access_Token__c;
            }
            
        }
        
        return null;
    }
    
    
    
    
       
    
}