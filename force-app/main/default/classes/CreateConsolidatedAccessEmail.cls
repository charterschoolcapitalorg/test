global class CreateConsolidatedAccessEmail implements  Database.Batchable<SObject>, Database.Stateful {

    public static Id EMAIL_FROM_ID;

    @testVisible
    private Map<Id,EmailData> queuedEmails = new Map<Id,EmailData>();
    
    static {
        try {
            if (Client_Portal_Email_Settings__c.getOrgDefaults() != null &&  Client_Portal_Email_Settings__c.getOrgDefaults().ConsolidatedOppEmailFromAddress__c != null) {
                OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:Client_Portal_Email_Settings__c.getOrgDefaults().ConsolidatedOppEmailFromAddress__c];
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                if ( owea.size() > 0 ) {
                    EMAIL_FROM_ID = owea.get(0).Id;
                }  
            }
        } catch (Exception e) {}
    }
    
    global CreateConsolidatedAccessEmail() {
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        //2019.06.28 J Caughie - changed filter to look for dates greater than yesterday - filter of today only picked up those created before the job ran
        //STring query = 'Select Id, Client_Notifications_Sent__c, opportunity__r.Owner.Name, opportunity__r.Owner.Phone, opportunity__r.Owner.MobilePhone, opportunity__r.Owner.Email, Opportunity__r.Name, Contact__r.FirstName, Contact__r.Email, Contact__c, Opportunity__c, ROle__c from Community_Contact_Role__c where CreatedDate = TODAY and Client_Notifications_Sent__c = false ORDER BY Contact__c DESC';
        //2021.06.08 - Team Fortimize - updated query to include Account fields
        String query = 'Select Id, Client_Notifications_Sent__c, Account__c, Account__r.Name, Account__r.Owner.Name, Account__r.Owner.Phone, Account__r.Owner.MobilePhone, Account__r.Owner.Email, opportunity__r.Owner.Name, opportunity__r.Owner.Phone, opportunity__r.Owner.MobilePhone, opportunity__r.Owner.Email, Opportunity__r.Name, Contact__r.Id, Contact__r.FirstName, Contact__r.Email, Contact__c, Opportunity__c, Role__c from Community_Contact_Role__c where CreatedDate >= YESTERDAY and Client_Notifications_Sent__c = false ORDER BY Contact__c DESC';     
        System.debug('Executing query: ' + query);

        return Database.getQueryLocator(query);
    }


    global void execute(Database.BatchableContext BC, List<Community_Contact_Role__c> scope) {
        EmailTemplate tpl = [SELECT Id, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName ='DailyClientAccessEmail'];
        
        for (Community_Contact_Role__c c: scope) {
            //at end, send last email
            if (!c.Contact__r.Email.endswith('.cscfull')) {
                EmailData email = queuedEmails.get(c.Contact__c);
                if (email == null) {
                    email = new EmailData(c.Contact__r, tpl);
                    queuedEmails.put(c.Contact__c, email);
                }

                email.addItem(c);
            }

            c.Client_Notifications_Sent__c = true;
        }
        
        update scope;
    }

    global void finish(Database.BatchableContext BC) {
        new QueueableEmails(queuedEmails.values()).enqueueJob();
    }

    public static String formatListHtml(List<String> items) {
        return items.isEmpty() ? '' : '<ul><li>'+String.join(items, '</li><li>')+'</li></ul>';
    }

    public static String formatListText(List<String> items) {
        return items.isEmpty() ? '' : ' * '+String.join(items, '\n * ')+'\n\n';
    }

    private class EmailData implements QueueableEmails.QueueableEmail {
        private final Contact con;
        private final EmailTemplate tpl;
        private final Map<Id,Community_Contact_Role__c> items = new Map<Id,Community_Contact_Role__c>();
        private User owner;

        public EmailData(Contact con, EmailTemplate tpl) {
            this.tpl = tpl;
            this.con = con;
        }

        public void addItem(Community_Contact_Role__c ccr) {
            this.items.put(ccr.Id, ccr);

            if (this.owner == null) {
                this.owner = ccr.Opportunity__c == null ? ccr.Account__r.Owner : ccr.Opportunity__r.Owner;
            }
        }

        public List<String> renderOpps() {
            List<String> opps = new List<String>();
            for (Community_Contact_Role__c ccr: items.values()) {
                if (ccr.Opportunity__c != null) {
                    opps.add(ccr.Opportunity__r.Name);
                }
            }
            return opps;
        }

        public List<String> renderAccts() {
            List<String> opps = new List<String>();
            for (Community_Contact_Role__c ccr: items.values()) {
                if (ccr.Account__c != null) {
                    opps.add(ccr.Account__r.Name);
                }
            }
            return opps;
        }

        public Messaging.SingleEmailMessage render() {
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(tpl.Id, con.Id, null);
            String htmlBody = email.getHtmlBody();
            String textBody = email.getPlainTextBody();

            String ownerEmail = null;
            String ownerName = null;
            String ownerPhone = null;

            if (owner != null) {
                ownerEmail = owner.Email;
                ownerName = owner.Name;
                ownerPhone = owner.Phone == null ? owner.MobilePhone : owner.Phone;
            }

            List<String> oppList = renderOpps();
            List<String> acctList = renderAccts();

            if (htmlBody != null) {
                htmlBody = htmlBody.replace('{FirstName}', (con.FirstName!=null) ? con.FirstName : '');
                htmlBody = htmlBody.replace('{OppList}', formatListHtml(oppList));
                htmlBody = htmlBody.replace('{AcctList}', formatListHtml(acctList));
                htmlBody = htmlBody.replace('{OwnerName}', (ownerName!=null) ? ownerName : '');
                htmlBody = htmlBody.replace('{OwnerEmail}', (ownerEmail!=null) ? ownerEmail : '');
                htmlBody = htmlBody.replace('{OwnerPhone}', (ownerPhone!=null) ? ownerPhone : '');
            }

            if (textBody != null) {
                textBody = textBody.replace('{FirstName}', (con.FirstName!=null) ? con.FirstName : '');
                textBody = textBody.replace('{OppList}', formatListText(oppList));
                textBody = textBody.replace('{AcctList}', formatListText(acctList));
                textBody = textBody.replace('{OwnerName}', (ownerName!=null) ? ownerName : '');
                textBody = textBody.replace('{OwnerEmail}', (ownerEmail!=null) ? ownerEmail : '');
                textBody = textBody.replace('{OwnerPhone}', (ownerPhone!=null) ? ownerPhone : '');
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            mail.setReplyTo(ownerEmail);
            //mail.setCcAddresses(new List<String> { ownerEmail });
            
            if (EMAIL_FROM_ID != null){
                mail.setOrgWideEmailAddressId(EMAIL_FROM_ID);
            } else {
                mail.setSenderDisplayName('Charter School Capital');
            }

            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setSaveAsActivity(true);
            mail.setTargetObjectId(con.Id); //set target to any Contact from COntact Roles
            mail.setSubject(tpl.Subject);
            mail.setHtmlBody(htmlBody);
            mail.setPlainTextBody(textBody);

            return mail;
        }
    }
}