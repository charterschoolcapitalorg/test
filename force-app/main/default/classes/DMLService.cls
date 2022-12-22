/**
* This class contains methods for using the ExceptionLogger class to log errors encountered during dml operations.
*
* @author  Dan Cobb/Fortimize
* @version 1.0
* @since   Sept 16, 2022
*/
public inherited sharing class DMLService {

	private static final String FORWARD_SLASH = '/';
	public static final String CLASS_NAME = 'DMLService';

	/*
	 * Log any errors that may have happened from either a Database Insert or Database Update. 
	 * @param List<Database.SaveResult> saveResult 		List of results after a database.insert or database.update call.
	 * @param List<SObject> listOfObjects 				List of records that the delete was attempted on.
	 * @param String className  						Optional Parameter - Name of apex class where dml operation occured.
	 * @param String methodName 						Optional Parameter - Name of apex method where dml operation occured.
	 * @return Boolean  								Returns true if no errors occur, false if any. 
	*/
	public static Boolean processSaveErrors(List<Database.SaveResult> saveResult, List<SObject> listOfObjects, String className, String methodName) {
		Boolean allSuccess = true;

		List<Log__c> errorsList = new List<Log__c>();
		// Loop over the results and find errors
		for (Integer i = 0; i < saveResult.size(); i++) {
			SObject obj = listOfObjects[i];
			Database.SaveResult result = saveResult[i];
			//If result not a success
			if ( !result.isSuccess() ) {
				allSuccess = false;
				for (Database.Error err : result.getErrors()) {
					System.debug('Record save error: '+err.getMessage());
					errorsList.add( createLogForError(obj, err, className, methodName) );
				}
			}
		}
		if (!errorsList.isEmpty()) {
			DMLOperation.Options optns = DMLOperation.getDefaultOptions();
			optns.className = CLASS_NAME;
			optns.methodName = 'processSaveErrors';

			DMLOperation dmlOperation = new DMLOperation( errorsList, DMLOperation.OperationType.INS, optns );
		}

		return allSuccess;
	}

	/*
	 * Log any errors that may have happened from a Database Upsert. 
	 * @param List<Database.UpsertResult> upsertResult 		List of results after a database.upsert.
	 * @param List<SObject> listOfObjects 					List of records that the upsert was attempted on.
	 * @param String className  							Optional Parameter - Name of apex class where dml operation occured.
	 * @param String methodName 							Optional Parameter - Name of apex method where dml operation occured.
	 * @return Boolean  									Returns true if no errors occur, false if any. 
	*/
	public static Boolean processUpsertErrors(List<Database.UpsertResult> upsertResult, List<SObject> listOfObjects, String className, String methodName) {
		Boolean allSuccess = true;

		List<Log__c> errorsList = new List<Log__c>();
		// Loop over the results and find errors
		for (Integer i = 0; i < upsertResult.size(); i++) {
			SObject obj = listOfObjects[i];
			Database.UpsertResult result = upsertResult[i];
			//If result not a success
			if ( !result.isSuccess() ) {
				allSuccess = false;
				for (Database.Error err : result.getErrors()) {
					System.debug('Record save error: '+err.getMessage());
					errorsList.add( createLogForError(obj, err, className, methodName) );
				}
			}
		}
		if (!errorsList.isEmpty()) {
			DMLOperation.Options optns = DMLOperation.getDefaultOptions();
			optns.className = CLASS_NAME;
			optns.methodName = 'processSaveErrors';

			DMLOperation dmlOperation = new DMLOperation( errorsList, DMLOperation.OperationType.INS, optns );
		}

		return allSuccess;
	}

	/*
	 * Log any errors that may have happened from a Database Delete. 
	 * @param List<Database.DeleteResult> dlResult 		List of results after a database.delete call.
	 * @param List<SObject> listOfObjects  				List of records that the delete was attempted on.
	 * @param String className  						Optional Parameter - Name of apex class where dml operation occured.
	 * @param String methodName 						Optional Parameter - Name of apex method where dml operation occured.
	 * @return Boolean  								Returns true if no errors occur, false if any. 
	*/
	public static Boolean processDeleteErrors(List<Database.DeleteResult> dlResult, List<SObject> listOfObjects, String className, String methodName) {
		Boolean allSuccess = true;

		List<Log__c> errorsList = new List<Log__c>();
		// Loop over the results and find errors
		for (Integer i = 0; i < dlResult.size(); i++) {
			SObject obj = listOfObjects[i];
			Database.DeleteResult result = dlResult[i];
			//If result not a success
			if ( !result.isSuccess() ) {
				allSuccess = false;
				for (Database.Error err : result.getErrors()) {
					errorsList.add( createLogForError(obj, err, className, methodName) );
				}
			}
		}
		if (!errorsList.isEmpty()) {
			DMLOperation.Options optns = DMLOperation.getDefaultOptions();
			optns.className = CLASS_NAME;
			optns.methodName = 'processDeleteErrors';

			DMLOperation dmlOperation = new DMLOperation( errorsList, DMLOperation.OperationType.INS, optns );
		}

		return allSuccess;
	}

	/*
	 * Method that turns a Database.Error object into a Log__c record.
	 * @param SObject obj 						The object that encountered the error during dml
	 * @param Database.Error err 				The error object
	 * @param String className  				Optional Parameter - Name of apex class where dml operation occured.
	 * @param String methodName 				Optional Parameter - Name of apex method where dml operation occured.
	 * @return Log__c 							New log record
	*/
	private static Log__c createLogForError(SObject obj, Database.Error err, String className, String methodName) {
		String errDets = obj.Id!=null 
						? URL.getSalesforceBaseUrl().toExternalForm() + FORWARD_SLASH + obj.Id 
								+ ExceptionLogger.NEW_LINE_CHARACTER + ExceptionLogger.NEW_LINE_CHARACTER 
						: '';
		errDets += err.getMessage();

		if (String.isEmpty(className)) className = ''; 
		if (String.isEmpty(methodName)) methodName = ''; 

		return new Log__c(
			Record_ID__c = ExceptionLogger.getValueToStore(obj.Id, 18), 
			Body__c = ExceptionLogger.getValueToStore(JSON.serializePretty(obj), ExceptionLogger.LOG_FIELD_SIZE_BODY),
			Object_Type__c = ExceptionLogger.getValueToStore(obj.getSObjectType().getDescribe().getName(), ExceptionLogger.LOG_FIELD_SIZE_OBJ), 
			Error__c = ExceptionLogger.getValueToStore(err.getMessage(), ExceptionLogger.LOG_FIELD_SIZE_ERROR),
			Error_Details__c = ExceptionLogger.getValueToStore(errDets, ExceptionLogger.LOG_FIELD_SIZE_ERROR_DET),
			Class_Name__c = ExceptionLogger.getValueToStore(className, ExceptionLogger.LOG_FIELD_SIZE_CLASS),
			Method_Name__c = ExceptionLogger.getValueToStore(methodName, ExceptionLogger.LOG_FIELD_SIZE_APEX_METH),
			Type__c = ExceptionLogger.LOG_TYPE_ERROR
		);
	}
}