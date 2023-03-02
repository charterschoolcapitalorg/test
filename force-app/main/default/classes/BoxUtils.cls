public class BoxUtils {
	
	 /**
	* Validates the oauth code
	*
	* @param code The code to validate
	* @param redirect_uri The URL to redirect to after successful validation
	* @return The oauth result
	*/
	public static String latestRefreshToken;
	public static String latestToken;
	
	public static void GetBoxRootFolders() {
		
			String oppId = '';
            String acctId = '';
            BoxFolderIds__c sett = BoxFolderIds__c.getOrgDefaults();
            BoxFieldStructures.FolderFiles ff = BOxAPIUtils.getFolderFilesList('0','100','0');
            System.debug('FolderFiles: ' + ff);
            for (BoxFieldStructures.FolderFile f : ff.entries) {
            	if (f.Name==sett.Root_Folder_Name__c) {
            		BoxFieldStructures.FolderFiles ff2 = BOxAPIUtils.getFolderFilesList(f.Id,'100','0');	
            		for (BoxFieldStructures.FolderFile f2 : ff2.entries) {
	            		if (f2.Name=='Opportunities') {
		            		oppId = f2.Id;
		            	}
		            	if (f2.Name=='Accounts') {
		            		acctId = f2.Id;
		            	}
            		}
            	}
            	
            }
            if (oppId!='') { sett.Opportunity_Root_Folder__c = oppId; }
            if (acctId!='') { sett.Account_Root_Folder__c = acctId; }
            update sett;
       
	}
	
	public static OAuthResult GetBoxTokens(String code, String redirect_uri, boolean updateCreds) {
        String client_id = BoxCredentials__c.getOrgDefaults().Client_Id__c;
        String client_secret = BoxCredentials__c.getOrgDefaults().Client_Secret__c;

		List<String> urlParams = new List<String> {
			'grant_type=authorization_code',
			'code=' + EncodingUtil.urlEncode(code, 'UTF-8'),
			'client_id=' + EncodingUtil.urlEncode(client_id, 'UTF-8'),
			'client_secret=' + EncodingUtil.urlEncode(client_secret, 'UTF-8'),
			'redirect_uri=' + EncodingUtil.urlEncode(redirect_uri, 'UTF-8')
		};

		Http h = new Http();

		HttpRequest req = new HttpRequest();
		req.setEndpoint(AuthorizeBoxController.ACCESS_TOKEN_URL);
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		req.setHeader('Accept', 'application/json');
		String body = String.join(urlParams, '&');
		req.setBody(body);
		OAuthResult result;
		
		if (!test.isrunningtest()) {
			HttpResponse response = h.send(req);
			SYstem.debug('***response from GetBoxTokens: ' + response);
			System.debug(response);
			if(response.getStatusCode() > 299){BoxAuthError error = (BoxAuthError)JSON.deserialize(response.getBody(), BoxAuthError.class); throw new BoxAuthException(error.error_description);}
			
			result = (OAuthResult)(JSON.deserialize(response.getBody(), OAuthResult.class));
		} else {
			result = new OAUthResult();
			result.refresh_token = '123';
			result.access_token = '123';
		}
	
		
		latestRefreshToken = result.refresh_token;
        latestToken = result.access_token;
        
        SYstem.debug('***new Box tokens: ' + result);
        
        if (updateCreds) {
	        BoxCredentials__c creds = BoxCredentials__c.getOrgDefaults();
	        creds.Access_Token__c = result.access_token;
	        creds.Refresh_Token__c = result.refresh_token;
	        update creds;
	        return null;
        }  else {
        	return result;
        }
            
	}
	
    
  
  //Refresh tokens  - for schedulable
  public static OAUthResult RefreshBoxTokens(boolean updateTokenNow){
  	
  		BoxCredentials__c creds = BoxCredentials__c.getOrgDefaults();
  		System.debug('***RefreshBoxTokens latestRefreshToken: ' + latestRefreshToken);
  		System.debug('***RefreshBoxTokens creds.Refresh_Token__c: ' + creds.Refresh_Token__c);
  		
  		String rToken;
  		if (latestRefreshToken!=null) {
  			rToken = latestRefreshToken;
  		} else {
  			rToken = creds.Refresh_Token__c;
  		}
        
        if (creds==null||rToken==null) {
        	throw new BoxAuthException('BoxCredentials Custom Setting needs a Refresh Token');
        }
        
        
        Http h = new Http();
        HttpRequest request = new HttpRequest();
        String endpoint = AUthorizeBoxCOntroller.ACCESS_TOKEN_URL;
        String body = 'Content-Type=' + EncodingUtil.urlEncode('application/x-www-form-urlencoded', 'UTF-8') +
                    '&charset=' + EncodingUtil.urlEncode('UTF-8', 'UTF-8') +
                    '&grant_type=' + EncodingUtil.urlEncode('refresh_token', 'UTF-8') +
                    '&client_id=' + EncodingUtil.urlEncode(creds.Client_ID__c, 'UTF-8') +
                    '&client_secret=' + EncodingUtil.urlEncode(creds.Client_Secret__c, 'UTF-8') +
                    '&refresh_token=' + EncodingUtil.urlEncode(rToken, 'UTF-8');
       request.setEndpoint(endpoint);
       request.setBody(body);
       request.setMethod('POST');
       OAUthResult boxTokens;
       if (!test.isrunningtest()) {
	       HttpResponse response = h.send(request);
	       SYstem.debug('***response from RefreshBoxTokens: ' + response);
	    
	       if(response.getStatusCode() > 299){
	       		BoxAuthError error = (BoxAuthError)JSON.deserialize(response.getBody(), BoxAuthError.class); 
	       		throw new BoxAuthException(error.error_description);
	       	}
	       
	        boxTokens= (OAuthResult) JSON.deserialize(response.getBody(), OAUthREsult.class);
       } else {
			boxTokens = new OAUthResult();
			boxTokens.refresh_token = '123';
			boxTokens.access_token = '123';
		}
		
       if(boxTokens != null && boxTokens.access_token != null && boxTokens.refresh_token != null){
       	  latestRefreshToken = boxTokens.refresh_token;
          latestToken = boxTokens.access_token;
          
          //Update
          if (updateTokenNow) {
	          creds.Access_Token__c = boxTokens.access_token;
	          creds.Refresh_Token__c = boxTokens.refresh_token;        
	          try {
	                  upsert creds;
	                  
	              } catch (Exception e){
	              		BoxAuthError error = new BoxAuthError(); 
	              		error.error = 'Error saving tokens'; 
	              		error.error_description = e.getMessage(); 
	              		throw new BoxAuthException(error.error_description);
	              }               
          	  return null;
          	  
          } else {return boxTokens;}
          
      } else return null;
     
  }

  //JSON Objects
  @TestVisible
  private class BoxAuthResponse {
       @TestVisible
       private String access_token {get;set;}
       @TestVisible
       private Integer expires_in {get;set;}
       @TestVisible
       private List<String> restricted_to {get;set;}
       @TestVisible
       private String refresh_token {get;set;}
       @TestVisible
       private String token_type {get;set;}
  } 

 
  public class BoxAuthException extends Exception {}
  
  @TestVisible
  private class BoxAuthError {
    @TestVisible
    private String error {get;set;}
    @TestVisible
    private String error_description {get;set;}
  }
	
  /** The JSON result from a successful oauth call */
    public class OAuthResult {
        /** The access token */
        public String access_token {get; set;}
        
        
        /** The refresh token */
        public String refresh_token {get; set;}
    }

}