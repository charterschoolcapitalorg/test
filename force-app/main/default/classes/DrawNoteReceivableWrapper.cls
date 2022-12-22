/**=====================================================================
 * Appirio, Inc
 * Name: DrawNoteReceivableWrapper
 * Description: T-271501 : Custom Wrapper class to store list of information about receivables
 * Created Date: [05/06/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [05/28/2014]                [Rajeev Arya]               [T-275387 - Create Lien Display]
 * [06/16/2014]                [Rajeev Arya]               [I-118193 - Draw Note will not save Funded Receivables correctly]
 
 =====================================================================*/
global class DrawNoteReceivableWrapper implements Comparable{
	 	public ID RecID {get;set;}
        public String RecName {get;set;}
        public String LienHolder {get;set;}
        public String School {get;set;}
        public String FinanceableFlag {get;set;}
        public String DrwNoteTX {get;set;}
        public String DrwNoteTXStatus {get;set;}
        public String DrawNote {get;set;}
        public Date PurchaseDate {get;set;}
        public Date ExpPayDate {get;set;}
        public Date DistributionDate {get;set;}
        //public String Description {get;set;}
        public Decimal FVAmountDue {get;set;}
        public Decimal FVAmount {get;set;}
        public Decimal UpfrontPurchasePrice {get;set;}
        public Boolean checkbox {get;set;}
        public Integer RowID {get;set;}
        public Boolean Assigned {get;set;}
        
        public enum SORT_BY {
            //ByAccountName,ByBillingCountry,ByBillingStreet
            ByLienHolder,ByPurchaseDate,ByName,BySchool,ByExpectedPayDate,ByDistributionDate,ByFVAmount, ByFVAmountDue, 
            /*ByDescription*/ ByFinanceableFlag, ByUpfrontPurchasePrice, ByDrawNote
        }
        public enum SORT_ORDER {
            ByAsc,ByDesc
        }

    //Variable to decide the member on which sorting should be performed
        public static SORT_BY sortBy = SORT_BY.BySchool;
    //Variable to decide the type of sorting (asc/desc)
        public static SORT_ORDER  sortOrder = SORT_ORDER.ByAsc;
        
       
        public DrawNoteReceivableWrapper(ID RecID, String RecName, String LienHolder, String School,String FinanceableFlag, String DrwNoteTX,
        								String DrwNoteTXStatus, String DrawNote, Date PurchaseDate, Date ExpPayDate, Date DistributionDate,/*String Description,*/ 
        								Decimal FVAmountDue, Decimal FVAmount, Decimal UpfrontPurchasePrice, Boolean checkbox, 
        								Integer RowID, Boolean Assigned){
            
            this.RecID = RecID;
            this.RecName = RecName;
            this.LienHolder = LienHolder;
            this.School = School;
            this.FinanceableFlag = FinanceableFlag;
            this.DrwNoteTX = DrwNoteTX;
            this.DrwNoteTXStatus = DrwNoteTXStatus;
            this.DrawNote = DrawNote;
            this.PurchaseDate = PurchaseDate;
            this.ExpPayDate = ExpPayDate;
            this.DistributionDate = DistributionDate;
            //this.Description = Description;
            this.FVAmountDue = FVAmountDue;
            this.FVAmount = FVAmount;
            this.UpfrontPurchasePrice = UpfrontPurchasePrice;
            this.checkbox = checkbox;
            this.RowID = RowID;
            this.Assigned = Assigned;

        }
		global Integer compareTo(Object objToCompare) {
        //Sort by BookName Alphabetically
        //if(sortBy == SORT_BY.ByAccountName)
        //ByLienHolder,ByPurchaseDate,ByName,BySchool,ByExpectedPayDate,ByDistributionDate,ByFVAmount, ByFVAmountDue, ByDescription, ByFinanceableFlag
        system.debug('m here' + objToCompare);
        
        if(sortBy == SORT_BY.ByLienHolder)
        {   //String LienHolderName = (((DrawNoteReceivableWrapper)objToCompare).LienHolder != null) ?
                       //     ((DrawNoteReceivableWrapper)objToCompare).LienHolder : '';
        	if(sortOrder == SORT_ORDER.ByAsc){
                return LienHolder.compareTo(((DrawNoteReceivableWrapper)objToCompare).LienHolder);
            }
            else{
                return ((DrawNoteReceivableWrapper)objToCompare).LienHolder.compareTo(LienHolder);
            }
        }
        else if(sortBy == SORT_BY.ByDrawNote)
        {   if(sortOrder == SORT_ORDER.ByAsc){
                return DrawNote.compareTo(((DrawNoteReceivableWrapper)objToCompare).DrawNote);
            }
            else{
                return ((DrawNoteReceivableWrapper)objToCompare).DrawNote.compareTo(DrawNote);
            }
        }
        else if(sortBy == SORT_BY.BySchool)
        {   if(sortOrder == SORT_ORDER.ByAsc){
                return School.compareTo(((DrawNoteReceivableWrapper)objToCompare).School);
            }
            else{
                return ((DrawNoteReceivableWrapper)objToCompare).School.compareTo(School);
            }
        }
        else if(sortBy == SORT_BY.ByFinanceableFlag)
        {   if(sortOrder == SORT_ORDER.ByAsc){
                return FinanceableFlag.compareTo(((DrawNoteReceivableWrapper)objToCompare).FinanceableFlag);
            }
            else{
                return ((DrawNoteReceivableWrapper)objToCompare).FinanceableFlag.compareTo(FinanceableFlag);
            }
        }
        else if(sortBy == SORT_BY.ByName)
        {
            if(sortOrder == SORT_ORDER.ByAsc){
                return RecName.compareTo(((DrawNoteReceivableWrapper)objToCompare).RecName);
            }
            else{
                return ((DrawNoteReceivableWrapper)objToCompare).RecName.compareTo(RecName);
            }
        }
        
        /*else if(sortBy == SORT_BY.ByDescription)
        {
            if(sortOrder == SORT_ORDER.ByAsc){
                return Description.compareTo(((DrawNoteReceivableWrapper)objToCompare).Description);
            }
            else{
                return ((DrawNoteReceivableWrapper)objToCompare).Description.compareTo(Description);
            }
        }*/
        else if(sortBy == SORT_BY.ByPurchaseDate){   
        	Date otherPurDate = objToCompare != null ? ((DrawNoteReceivableWrapper)objToCompare).PurchaseDate : System.today();
        	if(sortOrder == SORT_ORDER.ByAsc){
                //Date otherExpPDate = objToCompare != null ? ((ReceivableWrapper)objToCompare).ExpPayDate : System.today();
                return otherPurDate.daysBetween(this.PurchaseDate);
            }
            else{
                return this.PurchaseDate.daysBetween(otherPurDate);
            }
        }
        else if(sortBy == SORT_BY.ByExpectedPayDate){   
        	Date otherExpPDate = objToCompare != null ? ((DrawNoteReceivableWrapper)objToCompare).ExpPayDate : System.today();
        	if(sortOrder == SORT_ORDER.ByAsc){
                //Date otherExpPDate = objToCompare != null ? ((ReceivableWrapper)objToCompare).ExpPayDate : System.today();
                return otherExpPDate.daysBetween(this.ExpPayDate);
            }
            else{
                return this.ExpPayDate.daysBetween(otherExpPDate);
            }
        }
        else if(sortBy == SORT_BY.ByDistributionDate){   
        	Date otherDistDate = objToCompare != null ? ((DrawNoteReceivableWrapper)objToCompare).DistributionDate : System.today();
        	if(sortOrder == SORT_ORDER.ByAsc){
                return otherDistDate.daysBetween(this.DistributionDate);
            }
            else{
                return this.DistributionDate.daysBetween(otherDistDate);
            }
        }
        else if(sortBy == SORT_BY.ByFVAmount){
			Decimal otherFVAmount = objToCompare != null ? ((DrawNoteReceivableWrapper)objToCompare).FVAmount : 0.00;          
			if(sortOrder == SORT_ORDER.ByAsc){
            	return (this.FVAmount - otherFVAmount).intvalue();
            }
            else{
                return (otherFVAmount - this.FVAmount).intValue();
            }
        }
		else if(sortBy == SORT_BY.ByFVAmountDue){
			Decimal otherFVAmountDue = objToCompare != null ? ((DrawNoteReceivableWrapper)objToCompare).FVAmountDue : 0.00;          
			if(sortOrder == SORT_ORDER.ByAsc){
            	return (this.FVAmountDue - otherFVAmountDue).intValue();
            }
            else{
                return (otherFVAmountDue - this.FVAmountDue).intValue();
            }
        }
        else if(sortBy == SORT_BY.ByUpfrontPurchasePrice){
			Decimal otherUpfrontPurchasePrice = objToCompare != null ? ((DrawNoteReceivableWrapper)objToCompare).UpfrontPurchasePrice : 0.00;          
			if(sortOrder == SORT_ORDER.ByAsc){
            	return (this.UpfrontPurchasePrice - otherUpfrontPurchasePrice).intValue();
            }
            else{
                return (otherUpfrontPurchasePrice - this.UpfrontPurchasePrice).intValue();
            }
        }
        return null;
    }
	
}