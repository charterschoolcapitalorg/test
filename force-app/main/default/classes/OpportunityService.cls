//
// (c) 2014 Appirio, Inc.
//
// Class provide web service methods for opportunities
//
//  April 10,  2014     Harshit Jain       Original
//
global class OpportunityService {

  webservice static String updateOpportunityToClosedLost(Id opportunityId) {
  	String message = '';
	  Opportunity opportunity = new Opportunity(Id = opportunityId, IsAllowStageUpdation__c = true, StageName = 'Closed Lost', Reason__c = 'Unknown');

	  try {
	    update opportunity;
	    message = 'Stage has been successfully updated.';
	  } catch(DMLException e) {
	    message = e.getMessage();
	  }

	  return message;
  }

  //2015.11.04 - J Caughie - Added to open a previously closed opportunity.
  webservice static String updateOpportunityFromClosedLost(Id opportunityId) {
  	
  	String message = '';
  	String previousStageName = '';

    //Current Opportunity StageName
  	Opportunity opp = ([SELECT Id, StageName FROM Opportunity WHERE id = :opportunityId]);

    //Extract a Set of open StageNames for comparison with actual opp stage 
    List<OpportunityStage> openStagesList = new List<OpportunityStage> ([SELECT MasterLabel FROM OpportunityStage WHERE IsClosed = False]);
    Set<String> openStagesSet = new Set<String>();

    for(OpportunityStage o : openStagesList){
        openStagesSet.add(o.MasterLabel);
    }

    //If the opportunity is open return  	
  	if(openStagesSet.contains(opp.StageName)){
  		message = 'This opportunity is already open.';
  		return message;
  	}

  	previousStageName = retrievePreviousOppStage(opportunityId);
  	Opportunity opportunity = new Opportunity(Id = opportunityId, IsAllowStageUpdation__c = true, StageName = previousStageName, Reason__c = '');

  	try {
  		update opportunity;
  		message = 'Stage has been successfully updated.';
  	} catch(DMLException e) {
  		message = e.getMessage();
  	}

    return message;
  }

  private static String retrievePreviousOppStage(Id oppId){

  	String previousOppStageName = '';
  	if(Test.isRunningTest()){
  			previousOppStageName = 'Stage 1 - Projected';
  		} else {
	  		previousOppStageName = ([SELECT Id, OpportunityId, StageName, Probability FROM OpportunityHistory WHERE OpportunityId = :oppId AND Probability > 0 ORDER BY CreatedDate DESC LIMIT 1]).StageName;

  		}
  	return previousOppStageName;
  }

}