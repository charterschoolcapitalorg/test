/**
* This class contains methods for using the ExceptionLogger to perform dml and log errors when they happen.
*
* @author  Dan Cobb/Fortimize
* @version 1.0
* @since   Sept 16, 2022
*/
public inherited sharing class DMLOperation {
	
	// Upsert currently not supported
	public enum OperationType {INS, UPD, DEL} 
	public static final String CLASS_NAME = 'DMLOperation';

	private OperationType opType { get; set; }
	private List<sObject> sObjs { get; set; }
	private List<Database.SaveResult> svResults { get; set; }
	private Options operationOptions { get; set; }
	private String objType { get; set; }

	private Boolean opSuccessful { get; set; }
	private Boolean anyDMLErrors { get; set; } 


/*
 * Constructors start
*/
	/*
	 * Constructor used when performing dml on a single sobject using the default dml options.
	 * @param sObject sObj 		 					The single sobject to perform the dml operation on.
	 * @param OperationType opType 					Type of operation to be performed.
	 * @return DMLOperation 					An instance of the DMLOperation class after the dml operation has been performed. 
	 *													Call the instance getResult() method to get the results. 
	*/
	public DMLOperation(sObject sObj, OperationType opType) {
		operation( new List<SObject>{sObj}, opType, DMLOperation.getDefaultOptions() );
	}

	/*
	 * Constructor used when performing dml on a list of sobjects using the default dml options.
	 * @param List<sObject> sObjs		 			The list of sobjects to perform the dml operation on
	 * @param OperationType opType 					Type of operation to be performed
	 * @return DMLOperation 					An instance of the DMLOperation class after the dml operation has been performed. 
	 *													Call the instance getResult() method to get the results. 
	*/
	public DMLOperation(List<sObject> sObjs, OperationType opType) {
		operation( sObjs, opType, DMLOperation.getDefaultOptions() );
	}

	/*
	 * Constructor used when performing dml on a single sobject and setting dml options.
	 * @param sObject sObj 		 					The single sobject to perform the dml operation on.
	 * @param OperationType opType 					Type of operation to be performed.
	 * @param Options operationOptions 				Instance of the DMLOperation.Options class specifying the behavior of the dml operation.
	 * @return DMLOperation 					An instance of the DMLOperation class after the dml operation has been performed. 
	 *													Call the instance getResult() method to get the results. 
	*/
	public DMLOperation(sObject sObj, OperationType opType, Options operationOptions) {
		operation( new List<SObject>{sObj}, opType, operationOptions );
	}

	/*
	 * Constructor used when performing dml on a list of sobjects and setting dml options.
	 * @param List<sObject> sObjs		 			The list of sobjects to perform the dml operation on
	 * @param OperationType opType 					Type of operation to be performed.
	 * @param Options operationOptions 				Instance of the DMLOperation.Options class specifying the behavior of the dml operation.
	 * @return DMLOperation 					An instance of the DMLOperation class after the dml operation has been performed. 
	 *													Call the instance getResult() method to get the results. 
	*/
	public DMLOperation(List<sObject> sObjs, OperationType opType, Options operationOptions) {
		operation( sObjs, opType, operationOptions );
	}
/*
 * Constructors end
*/

	/*
	 * Method used for controlling the actual dml operation. 
	 * @param List<sObject> sObjs 					List of records to perform dml on
	 * @param OperationType opType 					Type of operation to be performed
	 * @param Options operationOptions 				Instance of the DMLOperation.Options class describing the options to use while performing the operation
	 * @return
	*/
	private void operation(List<sObject> sObjs, OperationType opType, Options operationOptions) {
		if (opType==null||sObjs==null||sObjs.size()==0||operationOptions==null) {
			throw new DMLOpException('OperationType, Options, and a list of SObjects are all required to invoke this class.');
		}

		ExceptionLogger.flushable = operationOptions.flushable;
		this.opType = opType;
		this.sObjs = sObjs;
		Schema.SObjectType tp = sObjs[0].getSObjectType();
		Schema.DescribeSObjectResult dr = tp.getDescribe();
		String nm = dr.getName();
		this.objType = nm;
		//this.objType = sObjs.getSObjectType().getDescribe().getName();

		if (operationOptions.className==null) operationOptions.className = CLASS_NAME;
		if (operationOptions.methodName==null) operationOptions.methodName = 'operation';

		if (operationOptions.optns==null) {
			operationOptions.optns = new Database.DMLOptions();
			operationOptions.optns.optAllOrNone = true;
		}

		this.operationOptions = operationOptions;
		this.opSuccessful = performOperation();
	}

	/*
	 * Method used for controlling the actual dml operation. 
	 * @param 
	 * @return Boolean 								Indicator of whether or not the operation as a whole was a success. 
	*/
	private Boolean performOperation() {
		Boolean isSuccess;
		if (this.opType==OperationType.INS) {
			isSuccess = performInsert();
		}
		else if (this.opType==OperationType.UPD) {
			isSuccess = performUpdate();
		}
		/*
		else if (this.opType==OperationType.UPS) {
			isSuccess = performUpsert();
		}
		*/
		else if (this.opType==OperationType.DEL) {
			isSuccess = performDelete();
		}
		return isSuccess;
	}

	private Boolean performInsert() {
		Boolean isSuccess;
		try {
			svResults = Database.insert(this.sObjs, this.operationOptions.optns);

			Boolean allSuccess = DMLService.processSaveErrors(svResults, this.sObjs, this.operationOptions.className, this.operationOptions.methodName);
			this.anyDMLErrors = !allSuccess;

			isSuccess = true;
		} catch(Exception e) {
			ExceptionLogger.log(e, this.objType, this.operationOptions.className, this.operationOptions.methodName);
			isSuccess = false;
		}
		return isSuccess;
	}

	private Boolean performUpdate() {
		Boolean isSuccess;
		try {
			svResults = Database.update(this.sObjs, this.operationOptions.optns);

			Boolean allSuccess = DMLService.processSaveErrors(svResults, this.sObjs, this.operationOptions.className, this.operationOptions.methodName);
			this.anyDMLErrors = !allSuccess;

			isSuccess = true;
		} catch(Exception e) {
			ExceptionLogger.log(e, this.objType, this.operationOptions.className, this.operationOptions.methodName);
			isSuccess = false;
		}
		return isSuccess;
	}

/*
	private Boolean performUpsert() {
		Boolean isSuccess;
		try {
			List<Database.UpsertResult> urstResults = Database.upsert(this.sObjs, this.operationOptions.externalIDField, this.operationOptions.optns.optAllOrNone);


			isSuccess = true;
		} catch(Exception e) {
			ExceptionLogger.log(e, this.objType, this.operationOptions.className, this.operationOptions.methodName);
			isSuccess = false;
		}
		return isSuccess;
	}
*/
	private Boolean performDelete() {
		Boolean isSuccess;
		try {
			List<Database.DeleteResult> dlResults = Database.delete(this.sObjs, this.operationOptions.optns.optAllOrNone);

			Boolean allSuccess = DMLService.processDeleteErrors(dlResults, this.sObjs, this.operationOptions.className, this.operationOptions.methodName);
			this.anyDMLErrors = !allSuccess;

			isSuccess = true;
		} catch(Exception e) {
			ExceptionLogger.log(e, this.objType, this.operationOptions.className, this.operationOptions.methodName);
			isSuccess = false;
		}
		return isSuccess;
	}

	/*
	 * Method used for getting the results of the dml operation after it's been performed.
	 * @param 
	 * @return Result 								Instance of the DMLOperation.Result class describing how the dml operation turned out.
	*/
	public Result getResult() {
		Result res = new Result();

		res.wasSuccess = this.opSuccessful;
		res.anyDMLErrors = this.anyDMLErrors;
		res.svResults = this.svResults;

		return res;
	}

	/*
	 * Method used for getting the default options.
	 * @param 
	 * @return Result 								Instance of the DMLOperation.Options class with the properties set to the default values.
	*/
	public static Options getDefaultOptions() {
		Options optns = new Options();

		Database.DMLOptions dmlOptns = new Database.DMLOptions();
		dmlOptns.optAllOrNone = false;
		dmlOptns.allowFieldTruncation = true;
		optns.optns = dmlOptns;

		optns.flushable = ExceptionLogger.flushable;

		return optns;
	}


	/**
	* This class contains properties for performing a dml operation using the parent DMLOperation class.
	*
	* @author  Dan Cobb/Fortimize
	* @version 1.0
	* @since   Sept 16, 2022
	*/
	public class Options {
		public Database.DMLOptions optns { get; set; }
		public Schema.SObjectField externalIDField { get; set; }
		public Boolean flushable { get; set; }
		public String className { get; set; }
		public String methodName { get; set; }
	}

	/**
	* This class contains properties for determining the results after a dml operation has been performed by the parent DMLOperation class.
	*
	* @author  Dan Cobb/Fortimize
	* @version 1.0
	* @since   Sept 16, 2022
	*/
	public class Result {
		public Boolean wasSuccess { get; set; }
		public Boolean anyDMLErrors { get; set; }
		public List<Database.SaveResult> svResults { get; set; }
	}

	public class DMLOpException extends Exception {}
}