/**
 * An apex page controller that exposes the site login functionality
 */
global without sharing class SigninControllerNew {
    global String username {get; set;}
    global String password {get; set;}
    public String orgId {get; set;}
    public String siteURL  {get; set;}
    public String startURL {get; set;}
    
    global SigninControllerNew () {
        orgId = UserInfo.getOrganizationId();
        siteURL  = Site.getBaseUrl();
        startURL = System.currentPageReference().getParameters().get('startURL');
        if (startURL == null) startURL = '/';
    }

    global PageReference login() {
        //return Site.login(username, password, startUrl);
        String user = getUsername(username);
        if(user != null && Site.isValidUsername(user)) {
            return Site.Login(user,password,startURL);
        }
        else {
            ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Your login attempt failed. ' + username + ' does not exist.  Make sure the username and password are correct.');
            ApexPages.addmessage(errorMsg);
            return null;      
        }
    }
    
    /*global String getEncodedSiteUrl() {
        return EncodingUtil.urlEncode(siteURL, 'UTF-8');
    }
    
    global String getEncodedStartUrl() {
        return EncodingUtil.urlEncode(startURL, 'UTF-8');
    }*/

    public static String getUsername(String user){
        List<User> userQueryList = [SELECT Id,Username FROM User where (username=:user OR ( Email = :user AND usertype='PowerPartner')) AND IsActive = true ];
        if(userQueryList !=null && userQueryList.size()==1) {
            return userQueryList[0].Username;
        }
        return null;
    }


    
}