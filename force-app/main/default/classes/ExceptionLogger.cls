/**
* This class contains methods for logging exceptions, integration requests and responses, and errors occured during apex execution.
* 		Logs are stored in the Log__c object. Exceptions can be logged right away or stored in a list to be "flushed" after a rollback.
*
* @author  Dan Cobb/Fortimize
* @version 1.0
* @since   Sept 16, 2022
*/
public without sharing class ExceptionLogger {

	public static final String NEW_LINE_CHARACTER = '\n';
	public static final String LOG_TYPE_REQUEST = 'Request';
	public static final String LOG_TYPE_RESPONSE = 'Response';
	public static final String LOG_TYPE_ERROR = 'Error';
	public static final String LOG_TYPE_PAGE_REFERENCE = 'Page Reference';

	public static final Integer LOG_FIELD_SIZE_BODY;
	public static final Integer LOG_FIELD_SIZE_CLASS;
	public static final Integer LOG_FIELD_SIZE_END_P;
	public static final Integer LOG_FIELD_SIZE_ERROR;
	public static final Integer LOG_FIELD_SIZE_ERROR_DET;
	public static final Integer LOG_FIELD_SIZE_HEAD_DESC;
	public static final Integer LOG_FIELD_SIZE_INT_METH;
	public static final Integer LOG_FIELD_SIZE_APEX_METH;
	public static final Integer LOG_FIELD_SIZE_OBJ;
	public static final Integer LOG_FIELD_SIZE_REC_ID;
	public static final Integer LOG_FIELD_SIZE_STATUS;
	public static final Integer LOG_FIELD_SIZE_STATUS_CODE;

	private static final Set<String> HEADERS_TO_LOG;

	//Boolean used to determine whether to log immediately or not. If set to false, Log__c records will not be saved unless the flushLogCache() method is called
	public static Boolean flushable = false;
	//List to store error logs when not inserted immediately.
	private static List<Log__c> logsToFlush = new List<Log__c>();

	static {
		LOG_FIELD_SIZE_BODY = Log__c.Body__c.getDescribe().getLength();
		LOG_FIELD_SIZE_CLASS = Log__c.Class_Name__c.getDescribe().getLength();
		LOG_FIELD_SIZE_END_P = Log__c.Endpoint__c.getDescribe().getLength();
		LOG_FIELD_SIZE_ERROR = Log__c.Error__c.getDescribe().getLength();
		LOG_FIELD_SIZE_ERROR_DET = Log__c.Error_Details__c.getDescribe().getLength();
		LOG_FIELD_SIZE_HEAD_DESC = Log__c.Integration_Headers__c.getDescribe().getLength();
		LOG_FIELD_SIZE_INT_METH = Log__c.Method__c.getDescribe().getLength();
		LOG_FIELD_SIZE_APEX_METH = Log__c.Method_Name__c.getDescribe().getLength();
		LOG_FIELD_SIZE_OBJ = Log__c.Object_Type__c.getDescribe().getLength();
		LOG_FIELD_SIZE_REC_ID = Log__c.Record_Id__c.getDescribe().getLength();
		LOG_FIELD_SIZE_STATUS = Log__c.Status__c.getDescribe().getLength();
		LOG_FIELD_SIZE_STATUS_CODE = Log__c.Status_Code__c.getDescribe().getLength();

		HEADERS_TO_LOG = new Set<String>();
		for (Header_To_Log__mdt header : [SELECT Label FROM Header_To_Log__mdt]) {
			HEADERS_TO_LOG.add(header.Label);
		}
	}

	/*
	 * Method used for logging a single exception that is thrown during apex execution. Specifies object, class and method on log record.
	 * @param System.Exception exceptionToLog 			The exception to log.
	 * @param String objectName 						Optional parameter - The name of the object type that the exception occured while handeling.
	 * @param String className 							Optional parameter - The name of the apex class where the exception was thrown.
	 * @param String methodName 						Optional parameter - The name of the apex method where the exception was thrown.
	 * @return
	*/
	public static void log(System.Exception exceptionToLog, String objectName, String className, String methodName) {
		log(new List<System.Exception>{exceptionToLog}, objectName, className, methodName);
	}
	
	/*
	 * Method used for logging a list of exceptions that are thrown during apex execution. Specifies object, class and method on log record.
	 * @param List<System.Exception> exceptionsToLog 	The list of exceptions to log.
	 * @param String objectName 						Optional parameter - The name of the object type that the exception occured while handeling.
	 * @param String className 							Optional parameter - The name of the apex class where the exception was thrown.
	 * @param String methodName 						Optional parameter - The name of the apex method where the exception was thrown.
	 * @return
	*/
	public static void log(List<System.Exception> exceptionsToLog, String objectName, String className, String methodName) {
		List<Log__c> exLogsToSave = loggedExceptionFactory(exceptionsToLog, objectName, className, methodName);
		saveLog(exLogsToSave);
	}
	
	/*
	 * Error record generation method; converts apex exceptions to Log__c records.
	 * @param List<System.Exception> exceptionsToLog 	The list of exceptions to log.
	 * @param String objectName 						Optional parameter - The name of the object type that the exception occured while handeling.
	 * @param String className 							Optional parameter - The name of the apex class where the exception was thrown.
	 * @param String methodName 						Optional parameter - The name of the apex method where the exception was thrown.
	 * @return List<Log__c> 							List of new Log__c records representing each Exception in the exceptionsToLog list parameter. 
	*/
	private static List<Log__c> loggedExceptionFactory(List<System.Exception> exceptionsToLog, String objectName, String className, String methodName) {
		List<Log__c> logs = new List<Log__c>();
		for (System.Exception e : exceptionsToLog) {
			String description = createExDescription( e );
			logs.add(
				new Log__c(
					Error__c = getValueToStore(e.getMessage(), LOG_FIELD_SIZE_ERROR),
					Error_Details__c = getValueToStore(description, LOG_FIELD_SIZE_ERROR_DET),
					Object_Type__c = getValueToStore(objectName, LOG_FIELD_SIZE_OBJ),
					Class_Name__c = getValueToStore(className, LOG_FIELD_SIZE_CLASS),
					Method_Name__c = getValueToStore(methodName, LOG_FIELD_SIZE_APEX_METH),
					Type__c = LOG_TYPE_ERROR
				)
			);
		}
		return logs;
	}

	/*
	 * Method that builds an integration Log__c record for an RestRequest object
	 * @param RestRequest req 							The request to log
	 * @param String className 							Optional parameter - The name of the apex class where the request was sent.
	 * @param String methodName 						Optional parameter - The name of the apex method where the request was sent.
	 * @return
	*/
	public static void log(RestRequest req, String className, String methodName) {
		List<Log__c> logs = new List<Log__c>();
		String headers = createHeaderDescriptions(req.headers);
		String reqBdy = req.requestBody!=null ? req.requestBody.toString() : '';
		logs.add( 
			new Log__c(
				Body__c = getValueToStore(reqBdy, LOG_FIELD_SIZE_BODY),
				Method__c = getValueToStore(req.httpMethod, LOG_FIELD_SIZE_INT_METH),
				Class_Name__c = getValueToStore(className, LOG_FIELD_SIZE_CLASS),
				Method_Name__c = getValueToStore(methodName, LOG_FIELD_SIZE_APEX_METH),
				Endpoint__c = getValueToStore(req.requestURI, LOG_FIELD_SIZE_END_P),
				Integration_Headers__c = getValueToStore(headers, LOG_FIELD_SIZE_HEAD_DESC),
				Type__c = LOG_TYPE_REQUEST
			)	
		);
		saveLog(logs);
	}

	/*
	 * Method that builds an integration Log__c record for an RestResponse object
	 * @param HttpResponse resp 						The response to log
	 * @param String className 							Optional parameter - The name of the apex class where the response was received. 
	 * @param String methodName 						Optional parameter - The name of the apex method where the response was received. 
	 * @return
	*/
	public static void log(RestResponse resp, String className, String methodName) {
		List<Log__c> logs = new List<Log__c>();
		String headers = createHeaderDescriptions( resp.headers );
		logs.add( 
			new Log__c(
				Body__c = getValueToStore(resp.responseBody.toString(), LOG_FIELD_SIZE_BODY),
				Status__c = getValueToStore(String.valueOf(resp.statusCode), LOG_FIELD_SIZE_STATUS),
				Class_Name__c = getValueToStore(className, LOG_FIELD_SIZE_CLASS),
				Method_Name__c = getValueToStore(methodName, LOG_FIELD_SIZE_APEX_METH),
				Integration_Headers__c = getValueToStore(headers, LOG_FIELD_SIZE_HEAD_DESC),
				Type__c = LOG_TYPE_RESPONSE
			)	
		);
		saveLog(logs);
	}

	/*
	 * Method that builds an integration Log__c record for an HTTPRequest object
	 * @param HttpRequest req 							The request to log
	 * @param String className 							Optional parameter - The name of the apex class where the request was sent.
	 * @param String methodName 						Optional parameter - The name of the apex method where the request was sent.
	 * @return
	*/
	public static void log(HttpRequest req, String className, String methodName) {
		List<Log__c> logs = new List<Log__c>();
		String headers = createHeaderDescriptions( req );
		logs.add( 
			new Log__c(
				Body__c = getValueToStore(req.getBody(), LOG_FIELD_SIZE_BODY),
				Method__c = getValueToStore(req.getMethod(), LOG_FIELD_SIZE_INT_METH),
				Class_Name__c = getValueToStore(className, LOG_FIELD_SIZE_CLASS),
				Method_Name__c = getValueToStore(methodName, LOG_FIELD_SIZE_APEX_METH),
				Endpoint__c = getValueToStore(req.getEndpoint(), LOG_FIELD_SIZE_END_P),
				Integration_Headers__c = getValueToStore(headers, LOG_FIELD_SIZE_HEAD_DESC),
				Type__c = LOG_TYPE_REQUEST
			)	
		);
		saveLog(logs);
	}

	/*
	 * Method that builds an integration Log__c record for an HttpResponse object
	 * @param HttpResponse resp 						The response to log
	 * @param String className 							Optional parameter - The name of the apex class where the response was received. 
	 * @param String methodName 						Optional parameter - The name of the apex method where the response was received. 
	 * @return
	*/
	public static void log(HttpResponse resp, String className, String methodName) {
		List<Log__c> logs = new List<Log__c>();
		String headers = createHeaderDescriptions( resp );
		logs.add( 
			new Log__c(
				Body__c = getValueToStore(resp.getBody(), LOG_FIELD_SIZE_BODY),
				Status__c = getValueToStore(resp.getStatus(), LOG_FIELD_SIZE_STATUS),
				Status_Code__c = getValueToStore(String.valueOf(resp.getStatusCode()), LOG_FIELD_SIZE_STATUS_CODE),
				Class_Name__c = getValueToStore(className, LOG_FIELD_SIZE_CLASS),
				Method_Name__c = getValueToStore(methodName, LOG_FIELD_SIZE_APEX_METH),
				Integration_Headers__c = getValueToStore(headers, LOG_FIELD_SIZE_HEAD_DESC),
				Type__c = LOG_TYPE_RESPONSE
			)	
		);
		saveLog(logs);
	}

	/*
	 * Method that builds a Log__c record for an PageReference object
	 * @param PageReference pRef 						The PageReference to log
	 * @param String className 							Optional parameter - The name of the apex class where the response was received. 
	 * @param String methodName 						Optional parameter - The name of the apex method where the response was received. 
	 * @return
	*/
	public static void log(PageReference pRef, String className, String methodName) {
		List<Log__c> logs = new List<Log__c>();
		String pageParams = createHeaderDescriptions( pRef.getParameters() );
		String headers = createHeaderDescriptions( pRef.getHeaders() );
		logs.add( 
			new Log__c(
				Endpoint__c = getValueToStore(pRef.getUrl(), LOG_FIELD_SIZE_END_P),
				Body__c = getValueToStore(pageParams, LOG_FIELD_SIZE_BODY),
				Integration_Headers__c = getValueToStore(headers, LOG_FIELD_SIZE_HEAD_DESC),
				Class_Name__c = getValueToStore(className, LOG_FIELD_SIZE_CLASS),
				Method_Name__c = getValueToStore(methodName, LOG_FIELD_SIZE_APEX_METH),
				Type__c = LOG_TYPE_PAGE_REFERENCE
			)
		);
		saveLog(logs);
	}
	
	/*
	 * Method that uses takes in a value and a field size, and determines what to log.
	 * @param String val 					 			Original value.
	 * @return String 									Value to store.
	*/
	public static String getValueToStore(String val, Integer fldSize) {
		String retStr = '';
		if (String.isNotBlank(val)) {
			retStr = val.length()>fldSize ? val.left(fldSize) : val;
		}
		return retStr;
	}

	/*
	 * Method that uses Salesforce standard exception methods, generate a usable description of the exception.
	 * @param System.Exception exceptionToLog 			Exception to build a description of.
	 * @return String 									The description of the parameter exceptionToLog.
	*/
	private static String createExDescription(System.Exception exceptionToLog) {
		String exDescription = exceptionToLog.getTypeName() + NEW_LINE_CHARACTER + exceptionToLog.getStackTraceString();
		if (exceptionToLog.getCause() != null)
			exDescription += NEW_LINE_CHARACTER + createExDescription( exceptionToLog.getCause() );
		return exDescription;
	}

	/*
	 * Iterate over all possible header key/values in request and add them to a consolidated string if they exist. 
	 * @param HttpRequest req 							The HTTPRequest instanace to log the headers for
	 * @return String 									The string of the headers formatted for logging.
	*/
	private static String createHeaderDescriptions(HttpRequest req) {
		String headerDesc = '';
		for (String key : HEADERS_TO_LOG) {
			if (req.getHeader(key)!=null) headerDesc += createHeaderDescription(key, req.getHeader(key));
		}
		return headerDesc;
	}

	/*
	 * Iterate over all header key/values in response and add them to a consolidated string. 
	 * @param HttpResponse res 							The HTTPResponse instance to log the headers for
	 * @return String 									The string of the headers formatted for logging.
	*/
	private static String createHeaderDescriptions(HttpResponse res) {
		String headerDesc = '';
		for (String key : res.getHeaderKeys()) {
			headerDesc += createHeaderDescription(key, res.getHeader(key));
		}
		return headerDesc;
	}

	/*
	 * Iterate over all header key/values in a map and add them to a consolidated string. 
	 * @param Map<String, String> hMap 					The map to log the headers for
	 * @return String 									The string of the headers formatted for logging.
	*/
	private static String createHeaderDescriptions(Map<String, String> hMap) {
		String headerDesc = '';
		for (String key : hMap.keySet()) {
			headerDesc += createHeaderDescription(key, hMap.get(key));
		}
		return headerDesc;
	}

	/*
	 * Add a header key/value pair to a consolidated string to store on a log record. 
	 * @param String key 								The key of a particular header
	 * @param String value 								The value of a particular header
	 * @return String 									The formatted string of a key/value header to log.
	*/
	private static String createHeaderDescription(String key, String value) {
		return key + ' : ' + value + NEW_LINE_CHARACTER;
	}

	/*
	 * Perform and insert to logs if flushable set to false. If flushable true, just store Log__c records in list to "flush" later.
	 * @param List<Log__c> logsToSave 					List of Log__c records to save. 
	 * 														If flushable is true, store logs in logsToSave class variable.
	 * 														If flushable is false, insert logs into the databse immediately. 
	 * @return
	*/
	private static void saveLog(List<Log__c> logsToSave) {
		if (flushable)
			logsToFlush.addAll(logsToSave);
		else
			insert logsToSave;
	}

	/*
	 * Method used during rollback/integration scenarios to log all exceptions stored in class variable list at one time.
	 * @param 
	 * @return 
	*/
	public static void flushLogCache() {
		if (!logsToFlush.isEmpty()) {
			insert logsToFlush;
			logsToFlush.clear();
		}
	}
}