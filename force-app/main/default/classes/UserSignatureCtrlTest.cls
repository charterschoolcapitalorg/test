@IsTest
private class UserSignatureCtrlTest {

    @isTest static void testNoId(){
        User u = new User();
        PageReference pageRef = Page.User_Signature;
        ApexPages.StandardController sc = new ApexPages.StandardController(u);
        UserSignatureCtrl controller = new UserSignatureCtrl(sc);
        String uId = pageRef.getParameters().get('id');
        System.assertEquals(null, uId, 'no value passed in');
        Test.setCurrentPage(pageRef);
        Pagereference pr = UserSignatureCtrl.redirect();
        uId = pageRef.getParameters().get('id');
        System.assertEquals(UserInfo.getUserId(), uId, 'should be the current user');
    }

    @isTest static void testId(){
        User u = [SELECT Id, Name FROM User LIMIT 1];
        PageReference pageRef = Page.User_Signature;
        pageref.getParameters().put('id', u.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(u);
        UserSignatureCtrl controller = new UserSignatureCtrl(sc);
        String uId = pageRef.getParameters().get('id');
        System.assertEquals(u.Id, uId, 'value passed in ');
        Test.setCurrentPage(pageRef);
        Pagereference pr = UserSignatureCtrl.redirect();
        uId = pageRef.getParameters().get('id');
        System.assertEquals(u.Id, uId, 'should be the value passed inr');
    }

}