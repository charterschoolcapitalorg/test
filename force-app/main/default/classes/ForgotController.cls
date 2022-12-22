/**
 * An apex page controller that exposes the site forgot password functionality
 */
public with sharing class ForgotController {
    public String username {get; set;}   
       
    public ForgotController() {}
  
    public PageReference forgotPassword() {
      String user = SigninControllerNew.getUsername(username);
      
      if (Site.isValidUsername(user)) {
        boolean success = Site.forgotPassword(user);
        PageReference pr = Page.ForgotConfirmNew;
        pr.setRedirect(true);
        return pr;
      }
      ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, username + ' is not a valid email/username.');
      ApexPages.addmessage(errorMsg);
      return null;
    }
}