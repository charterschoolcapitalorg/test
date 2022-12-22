public with sharing class ExpeditedDiligenceAlertController {
    
    @AuraEnabled
    public static List<Contact> getRelatedUsers(Id accountId) {
        //get all contacts assoicated with this account
        List<Contact> accountContacts = Send_Community_Invite_Controller.getAccountContacts(accountId);

        //get portal enabled users from the account contacts
        return [
            SELECT Id, Name, FirstName, LastName, Email
            FROM Contact
            WHERE Id IN (
                SELECT ContactId 
                FROM User
                WHERE ContactId IN :accountContacts
                AND IsPortalEnabled = true
                AND IsActive = true
            )
        ];
    }

    @AuraEnabled
    public static Boolean sendAlerts(Id accountId, List<Contact> users) {
        CreateWeeklyClientStatusEmail.sendClientStatusEmailForAccount(accountId, users);
        return true;
    }
}