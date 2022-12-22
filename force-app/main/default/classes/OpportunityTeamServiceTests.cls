@isTest (SeeAllData = true)
private class OpportunityTeamServiceTests {
	
	@isTest static void testOppTeamInsert() {
		
		Id workingUserId = null;
		try {
			workingUserId =[SELECT OwnerId FROM UserTeamMember WHere User.IsActive = True LIMIT 1].OwnerId;
		System.debug('User Id: ' + workingUserId);
		} catch (Exception e) {
			System.debug('No Active USderTeamMember found: '); 
		}
		if (workingUserId!=null) {
			User workingUser = [Select Id, Name FROM User WHERE Id = :workingUserId];
	
			List<UserTeamMember> users = [Select OwnerId, UserId, OpportunityAccessLevel, TeamMemberRole From UserTeamMember WHERE OwnerId = :workingUserId];
			System.debug('userTeam: ' + users);
	
			Integer size = users.size();
			System.debug('User - ' + workingUser);
	
			BypassRulesandTriggers__c ProfileCustomSettings = new BypassRulesandTriggers__c (Trigger_Objects__c = 'Lead;Account;Contact;Opportunity;Applicant__c;Attachment;Charter_Term__c;CSC_Action_Item__c;CSC_Action_List__c;Opp_School__c;Related_Contact__c;RPA__c;Terms_Letter__c',
			                                        Triggers_Disabled__c = true,
			                                        Validation_Rules_Disabled__c = true,
			                                        Workflow_Rules_Disabled__c = true,
			                                        SetupOwnerId = workingUserId);
			insert ProfileCustomSettings;
	
	
			Account acc = new Account();
			acc.Name = 'Test Account';
			acc.OwnerId = workingUserId;
			insert acc;
	
			Opportunity opp = new Opportunity();
			opp.Name = 'Test Opp';
			opp.AccountId = acc.Id;
			opp.StageName = 'Stage 1';
			opp.CloseDate = Date.today();
			opp.OwnerId = workingUserId;
			insert opp;
	
			Test.startTest();
			System.runAs(workingUser){
				String result = OpportunityTeamService.addOpportunityTeam(opp.Id, workingUserId);
				System.debug('result: ' + result);
			}
			Test.stopTest();
			
			AggregateResult afterOppUpdate = [Select count(id) team from OpportunityTeamMember WHERE OpportunityId = :opp.Id][0];
			System.debug(afterOppUpdate);
			System.assertEquals(size, afterOppUpdate.get('team'));
		}
	}


	
}