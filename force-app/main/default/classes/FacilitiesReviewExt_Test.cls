@isTest
private class FacilitiesReviewExt_Test {

	@isTest static void testFacilitiesReviewExt() {
		
		Account acc = new Account();
		acc.Name = 'Test Account';
		insert acc;

		Opportunity o = new Opportunity();
		o.AccountId = acc.Id;
		o.Name = 'Test Opportunity';
		o.StageName = 'Stage 1';
		o.CloseDate = Date.today().addDays(3);
		insert o;

		Contact c1 = new Contact();
		c1.FirstName = 'Montogmery';
		c1.LastName = 'Scott';
		insert c1;

		Contact c2 = new Contact();
		c2.FirstName = 'Jim';
		c2.LastName = 'Kirk';
		insert c2;

		OpportunityContactRole ocr = new OpportunityContactRole();
		ocr.OpportunityId = o.id;
		ocr.ContactId = c1.id;
		ocr.IsPrimary = true;
		insert ocr;

		OpportunityContactRole ocr1 = new OpportunityContactRole();
		ocr1.OpportunityId = o.id;
		ocr1.ContactId = c2.id;
		ocr1.IsPrimary = false;
		insert ocr1;

		ApexPages.StandardController std = new ApexPages.StandardController(o);
		ApexPages.currentPage().getParameters().put('id',o.id);
		FacilitiesReviewExt facilitiesReviewController  = new FacilitiesReviewExt(std);

		System.debug(facilitiesReviewController.getPrimaryContact());
		System.assertEquals('Scott', facilitiesReviewController.getPrimaryContact().LastName, 'Last Name should be Scott');
	}

}