public with sharing class Flags {
	public static Boolean SkipActionListOrderResequencing;
	public static Boolean SkipActionItemOrderResequencing;
	public static Boolean SyncingLeadWithApplicant;
	public static Boolean SyncingApplicantWithLead;
	public static Boolean SyncingOppSchoolData;
	public static Boolean SyncingAccountContacts;
	public static Boolean ForceCharterTermsUpdate;
	public static Boolean ForceOpportunitySchoolsUpdate;
	public static Boolean AllowLegalNoticeContactChange;
	public static Boolean UpdatingRPAHistoricValues;

	static {
		reset();
	}

	public static void reset() {
		SkipActionListOrderResequencing = false;
		SkipActionItemOrderResequencing = false;
		SyncingLeadWithApplicant = false;
		SyncingApplicantWithLead = false;
		SyncingOppSchoolData = false;
		SyncingAccountContacts = false;
		ForceCharterTermsUpdate = false;
		ForceOpportunitySchoolsUpdate = false;
		AllowLegalNoticeContactChange = false;
		UpdatingRPAHistoricValues = false;
	}
}