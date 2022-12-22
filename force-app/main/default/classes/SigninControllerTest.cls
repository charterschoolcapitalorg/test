@isTest
global class SigninControllerTest {
	@IsTest global static void testInvalidUser () {
        // Instantiate a new controller with all parameters in the page
        SigninControllerNew controller = new SigninControllerNew ();
        controller.username = 'test@salesforce.com';
        controller.password = '123456'; 
                
        //System.debug(controller.login());
        System.assertEquals(controller.login(),null);                           
    }
}