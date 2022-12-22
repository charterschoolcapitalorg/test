@isTest
global class ForgotControllerTest {
	@IsTest global static void testInvalidUser () {
        // Instantiate a new controller with all parameters in the page
        ForgotController controller = new ForgotController ();
        controller.username = 'test@salesforce.com';
                
        //System.debug(controller.forgotPassword());
        System.assertEquals(controller.forgotPassword(),null);                           
    }
}