/**=====================================================================
 * Name: OpportunityTeamService
 * Description: "Add Opp Team" button and functionality
 * Created Date: [10/16/2017]
 * Created By: John Caughie
 *
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
global class OpportunityTeamService {

	webservice static String addOpportunityTeam(Id opportunityId, Id userId){
		
		String message = '';

		List<OpportunityTeamMember> newOppTeam = new List<OpportunityTeamMember>();
		for(UserTeamMember utm : getUserTeam(userId)){
			OpportunityTeamMember otm = new OpportunityTeamMember();
			otm.OpportunityId = opportunityId;
			otm.UserId = utm.UserId;
			otm.OpportunityAccessLevel = utm.OpportunityAccessLevel;
			otm.TeamMemberRole = utm.TeamMemberRole;
			newOppTeam.add(otm);
		}

		try {
			insert newOppTeam;
			message = 'Opportunity team added.';
		} catch(DMLException e) {
			message = e.getMessage();
		}

		return message;

	}

	private static List<UserTeamMember> getUserTeam(Id userId){
		List<UserTeamMember> userTeam = [SELECT OwnerId, UserId, OpportunityAccessLevel, TeamMemberRole FROM UserTeamMember WHERE OwnerId = :userId];
		return userTeam;
	}


}