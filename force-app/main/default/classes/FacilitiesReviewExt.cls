public with sharing class FacilitiesReviewExt {

	private final Opportunity opp;
    private Contact con;

    // The extension constructor initializes the private member
    // variable opp by using the getRecord method from the standard
    // controller.
    public FacilitiesReviewExt(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
    }

    public Contact getPrimaryContact() {
        List<OpportunityContactRole> ocr = [SELECT ContactId 
                FROM OpportunityContactRole 
                WHERE OpportunityId = :opp.Id AND IsPrimary = TRUE AND IsDeleted = FALSE LIMIT 1];
        if (ocr.size() > 0){
            con = [SELECT FirstName, LastName, Email, Phone, MobilePhone, Salutation, Name 
                FROM Contact 
                WHERE Id = :ocr[0].ContactId];
        }
        return con;
    }
}