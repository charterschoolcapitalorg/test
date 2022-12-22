public class Send_Community_Invite_Controller {
    
    public List<Contact> cons {get;set;}
    public Id objectId {get;set;}
    private Map<String,STring> internalRoleProfileMap = new Map<String,STring>();
    
    public List<selectOption> roleOptions {get;set;}
    public String roleOption {get;set;}
    private Boolean isFromOpportunity;
    private Boolean isFromAccount;
 
    public void loadRoleOptions() {
        roleOptions = New List<selectOption>(); 
        List<DiligenceRoleMap__mdt> drm = [Select Role__c, Profile_name__c, Order__c from DiligenceRoleMap__mdt ORDER BY Order__c ];  
            
        for (DiligenceRoleMap__mdt d : drm) {
            System.debug(d);
        roleOptions.add( new selectOption(d.Role__c, d.Profile_name__c));
        internalRoleProfileMap.put(d.Role__c, d.Profile_name__c);   
        }          
    }

    public Send_Community_Invite_Controller(ApexPages.StandardController thecontroller) {
        
        SObject record = thecontroller.getRecord();
        if (record.getSObjectType() == Schema.Opportunity.getSObjectType()) {
            isFromAccount = false;
            isFromOpportunity = true;
            loadOpportunity((Opportunity)record);
        } else {
            isFromAccount = true;
            isFromOpportunity = false;
            loadAccount((Account)record);
        }
        
    }

    public Boolean isFromOpportunity() {
        return this.isFromOpportunity;
    }

    public Boolean isFromAccount() {
        return this.isFromAccount;
    }

    private void loadOpportunity(Opportunity opp) {
        opp = [Select Id, AccountId, Account.ParentId  From Opportunity Where Id=:opp.Id];
        objectId = opp.Id;
        consWrapper = new List<ConWrapper>();
        Map<Id,Contact> allCons = handleAccountContacts(opp.AccountId);
        
        Set<Id> ocrConIds = new Set<Id>();
        for (OpportunityContactRole ocr : [Select Id, ContactId from OpportunityContactRole where OpportunityId=:opp.Id]) {
            ocrConIds.add(ocr.ContactId);
        }
        //get the list fo COntacts from the Opportunity Contact Role
        List<Contact> ocrCons = [Select Id, Name , FirstName, LastName, AccountId, Email from Contact where ID IN:ocrConIds AND Leaver__c = false];
        for (Contact c : ocrCons) {
            allCons.put(c.Id,c);
        }
        
        for (Contact c : allCOns.values()) {
            conswrapper.add(new Conwrapper(c)); 
        }
        
        loadRoleOptions();
    }

    private void loadAccount(Account acct) {
        acct = [Select Id, Account.ParentId  From Account Where Id=:acct.Id];
        objectId = acct.Id;
        consWrapper = new List<ConWrapper>();
        Map<Id,Contact> allCons = handleAccountContacts(acct.Id);
        
        for (Contact c : allCOns.values()) {
            conswrapper.add(new Conwrapper(c)); 
        }
        
        loadRoleOptions();
    }

    public static List<Contact> getAccountContacts(Id acctId) {
        return handleAccountContacts(acctId).values();
    }

    private static Map<Id,Contact> handleAccountContacts(Id acctId) {
        Account acct = [
            SELECT Id, ParentId, Parent.ParentId
            FROM Account
            WHERE Id = :acctId
        ];
        Map<Id,Contact> allCons = new Map<Id,Contact>();

        //get account heirarchy
        Map<Id,Id> acctIds = new Map<Id,Id>();
        acctIds.put(acct.Id,acct.Id);
        //parent
        if (acct.ParentId != null) {
            acctIds.put(acct.ParentId,acct.ParentId); 
        }
        if (acct.Parent.ParentId != null) {
            acctIds.put(acct.Parent.ParentId,acct.Parent.ParentId); 
        }

        //children
        for (Account a :[Select Id, Name from Account where ParentId=:acct.Id]) {
            acctIds.put(a.Id,a.Id); 
        }
        
        //show contact related to account
        List<Contact> cons = [Select Id, Name , FirstName, LastName, AccountId, Email from Contact where AccountId IN:acctIds.keyset() AND Leaver__c = false];
        for (Contact c : cons) {
            allCons.put(c.Id,c);
        }

        //show contacts related to account through related contact object
        LIst<Related_Contact__c> relcons = [Select Id, Contact__c from Related_Contact__c where Account__c IN:acctIds.keyset() AND Inactive__c = false];
        Map<Id,Id> conIds = new Map<Id,Id>();
        for (Related_Contact__c c : relcons) {
            conIds.put(c.Contact__c, c.Contact__c);
        }
        List<Contact> consRelated = [Select Id, Name , FirstName, LastName, AccountId, Email from Contact where ID IN:conIds.keyset() AND Leaver__c = false];
        for (Contact c : consRelated) {
            allCons.put(c.Id,c);
        }

        return allCons;
    }
    
    private string getRelationshipField() {
        return (isFromOpportunity ? 'Opportunity__c' : 'Account__c');
    }

    public void createContactRoles(Map<Id,String> conRoleMap) {
        QueryUtil.QueryCondition roleMapCondition = QueryUtil.getIn('contact__c', conRoleMap.keySet());
        QueryUtil.QueryCondition objectIdCondition = QueryUtil.getEq(getRelationshipField(), objectId);
        QueryUtil.Query soqlStatement = QueryUtil.getSelect(new List<String> {'Id', getRelationshipField(), 'contact__c', 'role__c'}, 'Community_Contact_Role__c').withCondition(roleMapCondition).withCondition(objectIdCondition);
        
        List<Community_Contact_Role__c> ocrs = Database.query(soqlStatement.toSoql());
        //Orignal query: [Select Id, Opportunity__c, contact__c, role__c from Community_Contact_Role__c where contact__c in:conRoleMap.keyset() and Opportunity__c=:objectId];

        List<Community_Contact_Role__c> ocrsFOrInsert = new List<Community_Contact_Role__c>();
        for (Id i : conrolemap.keyset()) {
                System.debug('**** role keyset: ' + i);
                boolean found = false;
                for (Community_Contact_Role__c ocr:ocrs) {
                    System.debug('**** role: ' + conRoleMap.get(i) + ' &&& ocr.role__c: ' + ocr.role__c);
                    if (ocr.contact__c==i && ocr.role__c==conRoleMap.get(i)) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    System.debug('**** creating role: ' + conRoleMap.get(i));
                    Community_Contact_Role__c ccr = new Community_Contact_Role__c();
                    ccr.Contact__c = i;
                    ccr.Role__c = conRoleMap.get(i);
                    ccr.put(getRelationshipField(), objectId);
                    ocrsFOrInsert.add(ccr); 
                    }
        }
        if (ocrsFOrInsert.size() > 0) {insert ocrsFOrInsert;}
    }

    private List<Id> getRoleMapIds(Map<Id,String> conRoleMap) {
        return null;
    }
   
    public List<Id> createCommunityUsers(boolean fromVFPage) {
        List<User> users = new List<User>();
        List<Id> userIds = new List<Id>();
        List<Id> existingContactIds = new List<Id>();
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail= true;
            
        for (ConWrapper c : consWrapper) {
            if (c.selected) {
                String objectName = isFromAccount ? 'Account' : 'Opportunity';
                //make sure user doesnt already exist
                try {
                    //user found, dont do anything
                    User u = [Select Id, FirstName, LastName, Email from User where email=:c.con.email and IsActive = true LIMIT 1];
                    userIds.add(u.Id);
                    System.debug('User already exists: ' + u.email);
                    //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'User ' + u.email + ' already exists.  Created Contact Role');
                    //ApexPages.addMessage(myMsg);
                    
                    //existingContactIds.add(c.con.Id);
                    String message = String.format('{0} {1} already has access to the Client Portal, but has been added to the Community Contact Roles for this {2}.', 
                        new List<Object> {u.FirstName, u.LastName, objectName});
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, message);
                    if (fromVFPage) ApexPages.addMessage(myMsg);
                    
                } catch (Exception e) {
                    //user not found
                    //now look to see if Contact already has a Portal account (in case contact emal has changed
                    try {
                        User u = [Select Id, FirstName, LastName, Email from User where ContactId=:c.con.Id LIMIT 1];
                        userIds.add(u.Id);

                        //existingContactIds.add(c.con.Id);
                        String message = String.format('{0} {1} already has access to the Client Portal, but has been added to the Community Contact Roles for this {2}.',
                                                        new List<Object> {u.FirstName, u.LastName, objectName});
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, message);
                        if (fromVFPage) ApexPages.addMessage(myMsg);
                    } catch (Exception e2) {
                        // if (test.isrunningtest()) { c.role='School'; internalRoleProfileMap.put('School', 'Partner Community User');    }
                        if (test.isrunningtest()) { c.role='School'; internalRoleProfileMap.put('School', 'Partner Community User School/Tenant');    }
                        System.debug('LOOKING for profile for role: ' + internalRoleProfileMap.get(c.role));
                        Profile pf = [Select id,name from Profile where name =:internalRoleProfileMap.get(c.role) limit 1];
                        Account acc = [select name from Account where id=:c.con.AccountId];
                        Contact con = c.con;
                        boolean isSb = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
                        String userSuffix = '';
                        if (isSb) userSuffix = 'test';
                        User u = new User(contactId=con.Id, username=con.Email+'.csc'+userSuffix, firstname=con.FirstName,
                        lastname=con.LastName, email=con.Email,communityNickname = (con.Email+'.csc'+userSuffix).length() > 40 ? (con.Email+'.csc'+userSuffix).substring(0,40) : con.Email+'.csc'+userSuffix,
                        alias = string.valueof(con.FirstName.substring(0,1) + con.LastName.substring(0,1)), profileid = pf.Id, emailencodingkey='UTF-8',
                        languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles');
                        
                        System.debug('User for creation: ' + u);
                        users.add(u);
                        
                    }
                }
            }
        }
        
        if (users.size()>0) {
            
            LIst<Database.saveresult> sr = Database.insert(users,dlo);
            for (Database.saveresult s : sr) {
                System.debug('***s: ' + s);
                USer u;
                if (s.getId()!=null) {
                    u = [Select Id, FIrstName, LastName from USer where Id=:s.getId()];
                }
                    
                if (s.issuccess()) {
                    userIds.add(s.getId());
                    System.debug('Success creating user: ' + s.getId());

                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'You\'ve successfully added  ' +
                     u.firstName + ' ' + u.LastName + ' to the Client Portal.');
                     
                    if (fromVFPage) ApexPages.addMessage(myMsg);
                } else {
                        System.debug('Exception: ' + s.getErrors());
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Exception adding user(s): ' + s.geterrors());
                        if (fromVFPage) ApexPages.addMessage(myMsg);
                    
                }
            }
        }

        if(existingContactIds.size() > 0){
            System.debug('Existing cons: ' + existingContactIds);
            System.debug(objectId);
            EmailTemplate template =  [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = 'CSC_Client_Portal' LIMIT 1];
            EmailUtils.sendSingleEmailNotification(existingContactIds, template.Id, objectId);
        }

        return userIds;
    }

    public PageReference save() {
        
        //create Community USer with correct Profile
        List<Id> insertedUserIds = createCommunityUsers(true);
        if (insertedUserIds==null||insertedUserIds.size()==0) { return null; }
        
        //grant permissions
        if(isFromOpportunity) {
            //link the PQ and PQ Form
            for (Intake_item__c i : [Select Id, Is_Pre_Qual__c , Opportunity__c from Intake_item__c where Is_Pre_Qual__c = true and Opportunity__c=:objectId]) {
                try {
                        System.debug('***setting pq intake item to : ' + i.Id);
                        PQ_Form__c pq = [Select Id, Intake_Item__c from PQ_Form__c where Opportunity__c=:i.Opportunity__c LIMIT 1];
                        pq.Intake_Item__c = i.Id;
                        update pq;
                    } catch (Exception e) {
                        System.debug('***exception:  ' + e.getstacktracestring() + ' - ' + e.getmessage());
                    }
            }
        }

        //add Contact Role if it doesnt exist
        Map<Id,STring> conRoleMap = new Map<Id,String>();
        for (ConWrapper c : consWrapper) {
            if (c.selected) {
                conRoleMap.put(c.con.Id, c.Role);
            }
        }
        createContactRoles(conRoleMap);
        
        
        return null;
    }
    
    public PageReference back() {
        PageReference page = new PageReference('/'+objectId);
        page.setRedirect(true);            
        return page;
    }
    
    public List<ConWrapper> consWrapper {get;set;}
    
    public class ConWrapper {
        public ConWrapper(Contact c) {
            this.con = c;   
            this.conName = c.name;  
        }
        public boolean selected {get;set;}
        public String conName {get;set;}   
        public String role {get;set;} 
        public String profile {get;set;}
        public Contact con {get;set;}  
    }
 
}