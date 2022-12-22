public with sharing class UserSignatureCtrl {
 
    public UserSignatureCtrl(ApexPages.StandardController thecontroller) {
        System.debug(ApexPages.currentPage());
    }

    public static PageReference redirect(){
        String id = ApexPages.currentPage().getParameters().get('id');
        if(id == null){
            PageReference pageRef = ApexPages.currentPage();
            pageref.getParameters().put('id', UserInfo.getUserId());
            pageRef.setRedirect(true);
            System.debug(pageRef);
            return pageRef;
        } else {
            return null;
        }
        
    }


}