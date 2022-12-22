/**=====================================================================
 * Appirio, Inc
 * Name: FundedReceivableWrapper
 * Description: T-271502 : Custom Wrapper class to store list of information about receivables
 * Created Date: [04/27/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [06/23/2014]                 [Rajeev Arya]               [I-117958 - Allow Redemption of Unassigned Receivables]
 * [09/14/2016]                 John Caughie                Added item for interest due and paid
 * [09/20/2016]                 John Caughie                Added sort for interest payment
 =====================================================================*/
global class FundedReceivableWrapper implements Comparable{
        public ID RecID {get;set;}
        public String RecName {get;set;}
        public String CharterHolder {get;set;}
        public String School {get;set;}
        public String DrawNote {get;set;}
        public Date PurchaseDate {get;set;}
        public Date ExpPayDate {get;set;}
        public Date DistributionDate {get;set;}
        public String Description {get;set;}
        public Decimal FVAmountDue {get;set;}
        public Decimal FVAmount {get;set;}
        public Decimal IntDue {get;set;}
        public Decimal intPayment {get;set;}
        public String newPayment {get;set;}
        public Integer RowID {get;set;}
        public enum SORT_BY {
            //ByAccountName,ByBillingCountry,ByBillingStreet
            ByCharterHolder,ByPurchaseDate,ByName,BySchool,ByDrawNote,ByExpectedPayDate,ByDistributionDate,ByFVAmount, ByFVAmountDue, ByDescription, ByIntDue
        }
        public enum SORT_ORDER {
            ByAsc,ByDesc
        }

    //Variable to decide the member on which sorting should be performed
        public static SORT_BY sortBy = SORT_BY.BySchool;
    //Variable to decide the type of sorting (asc/desc)
        public static SORT_ORDER  sortOrder = SORT_ORDER.ByAsc;

        public FundedReceivableWrapper(ID RecID, String RecName, String CharterHolder, String School,String DrawNote,
        								Date PurchaseDate, Date ExpPayDate, Date DistributionDate,String Description, 
        								Decimal FVAmountDue, Decimal FVAmount, String newPayment, Integer RowID, Decimal IntDue, Decimal intPayment){
            
            this.RecID = RecID;
            this.RecName = RecName;
            this.CharterHolder = CharterHolder;
            this.School = School;
            this.DrawNote = DrawNote;
            this.PurchaseDate = PurchaseDate;
            this.ExpPayDate = ExpPayDate;
            this.DistributionDate = DistributionDate;
            this.Description = Description;
            this.FVAmountDue = FVAmountDue;
            this.FVAmount = FVAmount;
            this.newPayment = newPayment;
            this.RowID = RowID;
            this.IntDue = IntDue;
            this.intPayment = intPayment;

        }
//opp_school__r.school__r.Charter_Holder__c,Id,name,Purchase_Date__c,School__c,Expected_Pay_Date__c, Distribution_Date__c, FV_Amount__c, Description__c
        global Integer compareTo(Object objToCompare) {
        //Sort by BookName Alphabetically
        //if(sortBy == SORT_BY.ByAccountName)
        if(sortBy == SORT_BY.ByCharterHolder)
        {   if(sortOrder == SORT_ORDER.ByAsc){
                return CharterHolder.compareTo(((FundedReceivableWrapper)objToCompare).CharterHolder);
            }
            else{
                return ((FundedReceivableWrapper)objToCompare).CharterHolder.compareTo(CharterHolder);
            }
        }
        else if(sortBy == SORT_BY.BySchool)
        {   if(sortOrder == SORT_ORDER.ByAsc){
                return School.compareTo(((FundedReceivableWrapper)objToCompare).School);
            }
            else{
                return ((FundedReceivableWrapper)objToCompare).School.compareTo(School);
            }
        }
        else if(sortBy == SORT_BY.ByDrawNote)
        {   if(sortOrder == SORT_ORDER.ByAsc){
                return DrawNote.compareTo(((FundedReceivableWrapper)objToCompare).DrawNote);
            }
            else{
                return ((FundedReceivableWrapper)objToCompare).DrawNote.compareTo(DrawNote);
            }
        }
        else if(sortBy == SORT_BY.ByName)
        {
            if(sortOrder == SORT_ORDER.ByAsc){
                return RecName.compareTo(((FundedReceivableWrapper)objToCompare).RecName);
            }
            else{
                return ((FundedReceivableWrapper)objToCompare).RecName.compareTo(RecName);
            }
        }
        
        else if(sortBy == SORT_BY.ByDescription)
        {
            if(sortOrder == SORT_ORDER.ByAsc){
                return Description.compareTo(((FundedReceivableWrapper)objToCompare).Description);
            }
            else{
                return ((FundedReceivableWrapper)objToCompare).Description.compareTo(Description);
            }
        }
        else if(sortBy == SORT_BY.ByPurchaseDate){   
        	Date otherPurDate = objToCompare != null ? ((FundedReceivableWrapper)objToCompare).PurchaseDate : System.today();
        	if(sortOrder == SORT_ORDER.ByAsc){
                //Date otherExpPDate = objToCompare != null ? ((ReceivableWrapper)objToCompare).ExpPayDate : System.today();
                return otherPurDate.daysBetween(this.PurchaseDate);
            }
            else{
                return this.PurchaseDate.daysBetween(otherPurDate);
            }
        }
        else if(sortBy == SORT_BY.ByExpectedPayDate){   
        	Date otherExpPDate = objToCompare != null ? ((FundedReceivableWrapper)objToCompare).ExpPayDate : System.today();
        	if(sortOrder == SORT_ORDER.ByAsc){
                //Date otherExpPDate = objToCompare != null ? ((ReceivableWrapper)objToCompare).ExpPayDate : System.today();
                return otherExpPDate.daysBetween(this.ExpPayDate);
            }
            else{
                return this.ExpPayDate.daysBetween(otherExpPDate);
            }
        }
        else if(sortBy == SORT_BY.ByDistributionDate){   
        	Date otherDistDate = objToCompare != null ? ((FundedReceivableWrapper)objToCompare).DistributionDate : System.today();
        	if(sortOrder == SORT_ORDER.ByAsc){
                return otherDistDate.daysBetween(this.DistributionDate);
            }
            else{
                return this.DistributionDate.daysBetween(otherDistDate);
            }
        }
       
        else if(sortBy == SORT_BY.ByFVAmount){
			Decimal otherFVAmount = objToCompare != null ? ((FundedReceivableWrapper)objToCompare).FVAmount : 0.00;          
			if(sortOrder == SORT_ORDER.ByAsc){
            	return (this.FVAmount - otherFVAmount).intvalue();
            }
            else{
                return (otherFVAmount - this.FVAmount).intValue();
            }
        }
		else if(sortBy == SORT_BY.ByFVAmountDue){
			Decimal otherFVAmountDue = objToCompare != null ? ((FundedReceivableWrapper)objToCompare).FVAmountDue : 0.00;          
			if(sortOrder == SORT_ORDER.ByAsc){
            	return (this.FVAmountDue - otherFVAmountDue).intValue();
            }
            else{
                return (otherFVAmountDue - this.FVAmountDue).intValue();
            }
        }
        else if(sortBy == SORT_BY.ByIntDue){
            Decimal otherIntDue = objToCompare != null ? ((FundedReceivableWrapper)objToCompare).IntDue : 0.00;          
            if(sortOrder == SORT_ORDER.ByAsc){
                return (this.IntDue - otherIntDue).intValue();
            }
            else{
                return (otherIntDue - this.IntDue).intValue();
            }
        }
        return null;
    }
	
}