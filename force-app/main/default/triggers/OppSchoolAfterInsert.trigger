trigger OppSchoolAfterInsert on Opp_School__c (after insert) {
    
    /*Set<Id> osIds = new Set<Id>();
    
    for(Opp_School__c oppSchool : trigger.new) {
		osIds.add(opPSchool.Id);
	}
	*/
    if(!test.isrunningtest()) {
	    //when new Opp School is created, create FC Form detail objects
		List<FC_Details__c> det = FCFormUtils.createFCDetails(trigger.new);
		System.debug('*****details created: ' + det);
		
	
		FCFOrmUtils.populateDetailFieldsFromSFData(det);
		FCFOrmUtils.populateDetailCommentFieldsFromSFData(det);
	}
	
}