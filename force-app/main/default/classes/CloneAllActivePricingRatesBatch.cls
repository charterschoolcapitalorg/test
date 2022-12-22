global without sharing class CloneAllActivePricingRatesBatch implements Database.Batchable<sObject> {

    private static final String CLASS_NAME = 'CloneAllActivePricingRatesBatch';
    private static final String FORWARD_SLASH = '/';

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String qryStr = buildQueryAllString();
        return Database.getQueryLocator(qryStr);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        ExceptionLogger.flushable = true;
        List<Pricing_Rate__c> existingRates = (List<Pricing_Rate__c>) scope;
        List<Pricing_Rate__c> clonedRates = new List<Pricing_Rate__c>();
        Map<Id, PricingRateConnection> oldIdToConnectionMap = new Map<Id, PricingRateConnection>();

        Market_Rate__c activeMR;
        try {
            activeMR = MarketRateService.getActiveMarketRate();
        } catch (Exception e) {
            ExceptionLogger.log(e, 'Market_Rate__c', CLASS_NAME, 'getActiveMarketRate');
            ExceptionLogger.flushLogCache();
        }
        if (activeMR==null) return;
        Boolean activateNew = shouldActivate();

        for (Pricing_Rate__c oldRate : existingRates) {
            Pricing_Rate__c clonedRate = createCloneRecord(oldRate, activeMR, activateNew);
            clonedRates.add(clonedRate);
            PricingRateConnection connection = new PricingRateConnection(oldRate, clonedRate);
            oldIdToConnectionMap.put(oldRate.Id, connection); 
        }

        List<Database.SaveResult> cloneSaveResults = Database.insert(clonedRates, false);

        List<Pricing_Rate__c> deactivateRates = connectCloneResults(cloneSaveResults, clonedRates, oldIdToConnectionMap, activateNew);

        List<Database.SaveResult> deactivateSaveResults = Database.update(deactivateRates, false);

        connectDeactivationResults(deactivateSaveResults, deactivateRates, oldIdToConnectionMap);

        try {
            handleErrors(oldIdToConnectionMap);
        } catch (Exception e) {
            ExceptionLogger.log(e, 'Pricing_Rate__c', CLASS_NAME, 'handleErrors');
        }
        ExceptionLogger.flushLogCache();
    }

    public void finish(Database.BatchableContext BC) {
        Boolean shouldRescore = !shouldActivate();
        if (shouldRescore) {
            RescoreAllCurrentPricingRatesBatch b = new RescoreAllCurrentPricingRatesBatch();
            Database.executeBatch(b, 1);
        } 
    }

    @TestVisible 
    private static void handleErrors(Map<Id, PricingRateConnection> oldIdToConnectionMap) {
        List<Log__c> errorsList = new List<Log__c>();
        for (PricingRateConnection con : oldIdToConnectionMap.values()) {

            if ( con.oldSR!=null && !con.oldSR.isSuccess() ) {
                errorsList.add(
                    createLogForError(
                        'After a new Market Rate was activated, this record failed to clone.',
                        con.oldPR,
                        con.oldSR.getErrors()
                    )
                );
            }

            if ( con.oldSR!=null && con.oldSR.isSuccess() && con.newSR!=null && !con.newSR.isSuccess() ) {
                errorsList.add(
                    createLogForError(
                        'After a new Market Rate was activated, and this record cloned, it failed to deactivate.',
                        con.oldPR,
                        con.newSR.getErrors()
                    )
                );
            }
        }

        if (!errorsList.isEmpty()) {
			DMLOperation.Options optns = DMLOperation.getDefaultOptions();
			optns.className = CLASS_NAME;
			optns.methodName = 'handleErrors';

			DMLOperation dmlOperation = new DMLOperation( errorsList, DMLOperation.OperationType.INS, optns );
		}
    }

    private static Log__c createLogForError(String msg, SObject obj, List<Database.Error> errs) {
		String errDets = obj.Id!=null ? URL.getSalesforceBaseUrl().toExternalForm() + FORWARD_SLASH + obj.Id : '';

        for (Database.Error err : errs) {
            if (String.isNotBlank(errDets)) errDets += ExceptionLogger.NEW_LINE_CHARACTER + ExceptionLogger.NEW_LINE_CHARACTER;
            errDets += err.getMessage();
        }

		return new Log__c(
			Record_ID__c = ExceptionLogger.getValueToStore(obj.Id, 18), 
			Body__c = ExceptionLogger.getValueToStore(JSON.serializePretty(obj), ExceptionLogger.LOG_FIELD_SIZE_BODY),
			Object_Type__c = ExceptionLogger.getValueToStore(obj.getSObjectType().getDescribe().getName(), ExceptionLogger.LOG_FIELD_SIZE_OBJ), 
			Error__c = ExceptionLogger.getValueToStore(msg, ExceptionLogger.LOG_FIELD_SIZE_ERROR),
			Error_Details__c = ExceptionLogger.getValueToStore(errDets, ExceptionLogger.LOG_FIELD_SIZE_ERROR_DET),
			Class_Name__c = ExceptionLogger.getValueToStore(CLASS_NAME, ExceptionLogger.LOG_FIELD_SIZE_CLASS),
			Method_Name__c = ExceptionLogger.getValueToStore('execute', ExceptionLogger.LOG_FIELD_SIZE_APEX_METH),
			Type__c = ExceptionLogger.LOG_TYPE_ERROR
		);
	}

    private static void connectDeactivationResults(List<Database.SaveResult> deactivateSaveResults, List<Pricing_Rate__c> deactivateRates, Map<Id, PricingRateConnection> oldIdToConnectionMap) {
        Integer i = 0;
        for (Database.SaveResult sr : deactivateSaveResults) { 
            Pricing_Rate__c oldRate = deactivateRates[i];
            PricingRateConnection connection = oldIdToConnectionMap.get(oldRate.Id);
            connection.oldSR = sr;
            i++;
        }
    }

    private static List<Pricing_Rate__c> connectCloneResults(List<Database.SaveResult> cloneSaveResults, List<Pricing_Rate__c> clonedRates, Map<Id, PricingRateConnection> oldIdToConnectionMap, Boolean deactivateOld) {
        List<Pricing_Rate__c> deactivateRates = new List<Pricing_Rate__c>();
        Integer i = 0;
        for (Database.SaveResult sr : cloneSaveResults) { 
            Pricing_Rate__c newRate = clonedRates[i];
            PricingRateConnection connection = oldIdToConnectionMap.get(newRate.Cloned_From__c);
            connection.newSR = sr;
            if (sr.isSuccess()) {
                if (deactivateOld) connection.oldPR.Active__c = false;
                deactivateRates.add(connection.oldPR);
            }
            i++;
        }
        return deactivateRates;
    }

    private static Pricing_Rate__c createCloneRecord(Pricing_Rate__c existingRate, Market_Rate__c activeMR, Boolean shouldActivate) {
        Pricing_Rate__c clonedRate = existingRate.clone(false, true, false, false);
        clonedRate.Market_Rate__c = activeMR.Id;
        clonedRate.Cloned_From__c = existingRate.Id;

        if (shouldActivate) clonedRate.Active__c = true;
        else clonedRate.Active__c = false;

        return clonedRate;
    }

    private static String buildQueryAllString() {
        String qryStr = 'SELECT ';
        for (String fldStr : QueryUtil.selectAllForObject('pricing_rate__c')) {
            qryStr += fldStr + ',';
        }
        qryStr = qryStr.removeEnd(',');
        qryStr += ' FROM Pricing_Rate__c WHERE Active__c = true';
        return qryStr;
    }

    private static Boolean shouldActivate() {
        if ( MarketRateService.getActiveMarketRate().Reporting_Date__c.month()==7 ) return false;
        else return true;
    }

    @TestVisible 
    private class PricingRateConnection {
        public Pricing_Rate__c oldPR { get; set; }
        public Database.SaveResult oldSR { get; set; }
        public Pricing_Rate__c newPR { get; set; }
        public Database.SaveResult newSR { get; set; }

        public PricingRateConnection(Pricing_Rate__c oldPR, Pricing_Rate__c newPR) {
            this.oldPR = oldPR;
            this.newPR = newPR;
        }
    }
}