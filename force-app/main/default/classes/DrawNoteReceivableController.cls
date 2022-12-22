/**=====================================================================
 * Appirio, Inc
 * Name: DrawNoteReceivableController
 * Description: T-271501 : Custom Controller Class for the DrawNoteReceivable VF Page
 * Created Date: [05/06/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [05/12/2014]               [Noopur Sundriyal]          [T-277641 - Create a Custom Setting for Page Size]
 * [05/28/2014]               [Rajeev Arya]               [T-275387 - Create Lien Display]
 * [05/29/2014]               [Rajeev Arya]               [T-275388 - Create Lien transfer action]
 * [06/16/2014]               [Rajeev Arya]               [I-118193 - Draw Note will not save Funded Receivables correctly]
 * [06/23/2014]               [Rajeev Arya]               [I-118064 - Replace the DrawNote LKP field on Funded Receivable]
 * [01/18/2018]					[John Caughie]				[Updates for new EWB credit line]
  =====================================================================*/
public with sharing class DrawNoteReceivableController {
    public account acc { get; set; }
	public draw_note__c draw { get; set; }
	public draw_note__c draw1 { get; set; }
	public Boolean BeforeDrawNoteSaved { get; set; }
	public Boolean NewDraw { get; set; }
	public Boolean FromInvestor { get; set; }
    public Boolean AfterDrawNoteSaved { get; set; }
    public Boolean LienFilterSelected { get; set; }
    public Boolean DrawFilterSelected { get; set; }
    public Boolean PartialPaid {get;set;}
    public Boolean Unassigned {get;set;}
    public Boolean SelectAll {get;set;}
    public Boolean AssignDrawBtn {get;set;}
    public String selectedHolder {get;set;}
	public String selectedHolderDrawNote {get;set;}
	public Double TotalAmountBorrowed {get;set;}
	public Integer rID {get;set;}
	public Integer selectedPageNumber{get;set;} // Page number of form table
  	public PaginationUtility formListPagination{get;set;}
  	public List<DrawNoteReceivableWrapper> RowListPage {get; set;}
	public List<DrawNoteReceivableWrapper> RowListSelected {get; set;}
	
	public list<Funded_Receivable__c> receiveList = new List<Funded_Receivable__c>();
	public set<ID> setLienHolderIds = new set<ID>();
	public set<ID> setDrawNoteIds = new set<ID>();
	public String sortDirection = 'DESC'; //Sort Order
    public String sortExp = 'School'; //initial sort field
	public List<DrawNoteReceivableWrapper> RowList = new List<DrawNoteReceivableWrapper>();
	public Map<Integer,DrawNoteReceivableWrapper> ReceivablesMap = new Map<Integer,DrawNoteReceivableWrapper>();
	public Map<Integer,DrawNoteReceivableWrapper> SelectedReceivablesMap = new Map<Integer,DrawNoteReceivableWrapper>();
	public Map<String,list<DrawNoteReceivableWrapper>> LienToAllReceivablesMap = new Map<String,list<DrawNoteReceivableWrapper>>();
	public Map<String,list<DrawNoteReceivableWrapper>> DrawNoteToAllReceivablesMap = new Map<String,list<DrawNoteReceivableWrapper>>();

	/**=====================================================================
	Controller Class for the VF Page to display and assign Funded Receivables to a Draw Note
	=====================================================================*/
	public DrawNoteReceivableController() {
   		RowListPage = new List<DrawNoteReceivableWrapper>();
   		draw = new Draw_Note__c();
        draw1 = new Draw_Note__c();
   		Integer i = 0;
   		TotalAmountBorrowed = 0.00;
        BeforeDrawNoteSaved = true;
        AfterDrawNoteSaved = false;
        AssignDrawBtn = true;
        FromInvestor = false;
        NewDraw = true;
        PartialPaid = false;
        Unassigned = true;
        LienFilterSelected = Unassigned;
        DrawFilterSelected = Unassigned;
        if (ApexPages.currentPage().getParameters().containsKey('DrawNoteid')){

	        draw = [select name, Id, investor__c, Note_Rate__c, Borrow_Date__c, Status__c, Note_Description__c, Total_Amount_Borrowed__c, Operating_State__c, Payment_Type__c
	        from draw_note__c where id =: ApexPages.currentPage().getParameters().get('DrawNoteid')];
	        if(draw.investor__c != null){
		        TotalAmountBorrowed = draw.Total_Amount_Borrowed__c;
		       	draw1 = [select name, status__c from draw_note__c where id=: draw.id];
		        acc = [select name, accountnumber from account where id =: draw.investor__c];
		        NewDraw = false;
		        FromInvestor = true;
		        AfterDrawNoteSaved = true;
		        BeforeDrawNoteSaved = false;
		        Set<ID> NotIncludedReceivablesIDs = new Set<ID>();
		        map<ID, Draw_Note_TX__c> RecToActiveDRTXMap = new map<ID, Draw_Note_TX__c>();
	        	for(Draw_Note_TX__c drtx : [select id, Funded_Receivable__c,name,status__c,Draw_Note__r.name, draw_note__c 
	        								from Draw_Note_TX__c 
	        								where status__c in ('Draft','Active') ]){
	       			if(drtx.status__c == 'Draft'){
	       				NotIncludedReceivablesIDs.add(drtx.Funded_Receivable__c);
	       			}
	       			if(!NotIncludedReceivablesIDs.contains(drtx.Funded_Receivable__c) && drtx.status__c == 'Active'){
	       				RecToActiveDRTXMap.put(drtx.Funded_Receivable__c, drtx);
	       			}
	        	}
	        	if(draw.Operating_State__c == null){
	        		receiveList = [select lien_holder__c, /*Draw_Note_TX__r.name, Draw_Note_TX__r.status__c, Draw_Note_TX__r.Draw_Note__r.name,*/
	        				Financeable__c,	lien_holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c,
       						Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c, Upfront_Purchase_Price__c
        					from Funded_Receivable__c
        					where Status__c = 'Active' 
        					//and School__r.Operating_State__c =: draw.Operating_State__c
        					//and Draw_Note_TX__r.Draw_Note__c !=: draw.Id
        					and id not in : NotIncludedReceivablesIDs];
	        	} else {
	        		receiveList = [select lien_holder__c, /*Draw_Note_TX__r.name, Draw_Note_TX__r.status__c, Draw_Note_TX__r.Draw_Note__r.name,*/
	        				Financeable__c,	lien_holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c,
       						Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c, Upfront_Purchase_Price__c
        					from Funded_Receivable__c
        					where Status__c = 'Active' 
        					and School__r.Operating_State__c =: draw.Operating_State__c
        					//and Draw_Note_TX__r.Draw_Note__c !=: draw.Id
        					and id not in : NotIncludedReceivablesIDs];
	        	}
		        /*receiveList = [select lien_holder__c, /*Draw_Note_TX__r.name, Draw_Note_TX__r.status__c, Draw_Note_TX__r.Draw_Note__r.name,*//*
		        				Financeable__c,	lien_holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c,
	       						Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c, Upfront_Purchase_Price__c
	        					from Funded_Receivable__c
	        					where Status__c = 'Active' 
	        					and School__r.Operating_State__c =: draw.Operating_State__c
	        					//and Draw_Note_TX__r.Draw_Note__c !=: draw.Id
	        					and id not in : NotIncludedReceivablesIDs] ;*/
			    RowListSelected = new List<DrawNoteReceivableWrapper>();
			    RowList = new List<DrawNoteReceivableWrapper>();
			    DrawNoteReceivableWrapper tr;
			    for(Funded_Receivable__c receive : receiveList) {
			        Draw_Note_TX__c DnTx = new Draw_Note_TX__c();
			        if( RecToActiveDRTXMap.containsKey(receive.Id)){
			           	DnTx = RecToActiveDRTXMap.get(receive.Id);
			          
			           	tr = new DrawNoteReceivableWrapper(receive.ID, receive.name, receive.lien_holder__r.name, receive.School__r.name,receive.Financeable__c,
			           									DnTx.name, DnTx.status__c,DnTx.Draw_Note__r.name,receive.Purchase_Date__c,receive.Expected_Pay_Date__c,
			           									receive.Distribution_Date__c,receive.FV_Amount_Due__c,receive.FV_Amount__c,receive.Upfront_Purchase_Price__c,false,i,false);
			        }else{
			           	tr = new DrawNoteReceivableWrapper(receive.ID, receive.name, receive.lien_holder__r.name, receive.School__r.name,receive.Financeable__c,
			           									null,null,null,receive.Purchase_Date__c,receive.Expected_Pay_Date__c,receive.Distribution_Date__c,
			           									receive.FV_Amount_Due__c,receive.FV_Amount__c,receive.Upfront_Purchase_Price__c,false,i,false);
			        }
			        if(tr.LienHolder == null){
		        		tr.LienHolder = '-';
		        	}
		        	//if(tr.School == null){
		        	//	tr.School = '-';
		        	//}
		        	if(tr.FinanceableFlag == null){
		        		tr.FinanceableFlag = '-';
		        	}
		        	if(tr.DrwNoteTX == null){
		        		tr.DrwNoteTX = '-';
		        	}
		        	if(tr.DrwNoteTXStatus == null){
		        		tr.DrwNoteTXStatus = '-';
		        	}
		        	if(tr.DrawNote == null){
		        		tr.DrawNote = '-';
		        	}
			        i=i+1;
			      
			       	if(tr.DrawNote != draw.Name){
				       	RowList.add(tr);
				       	ReceivablesMap.put(tr.RowID,tr);
				       	if(tr.LienHolder != '-'){
				       		setLienHolderIds.add(receive.lien_holder__c);
				       		if(LienToAllReceivablesMap.containsKey(tr.LienHolder)){
			        			LienToAllReceivablesMap.get(tr.LienHolder).add(tr);
			        		}
			        		else{
			        			LienToAllReceivablesMap.put(tr.LienHolder,new list<DrawNoteReceivableWrapper>{tr});
			        		}
				       	}
				    	if(tr.DrawNote != '-'){
				    		setDrawNoteIds.add(DnTx.draw_note__c);
				    		if(DrawNoteToAllReceivablesMap.containsKey(tr.DrawNote)){
			        			DrawNoteToAllReceivablesMap.get(tr.DrawNote).add(tr);
			        		}
			        		else{
			        			DrawNoteToAllReceivablesMap.put(tr.DrawNote,new list<DrawNoteReceivableWrapper>{tr});
			        		}
				    	}
			       	}
			    }
				
				RowList.sort();
				filteredByCheckbox();
				addPaginationOnFormList();
	        }
	        else{
	        	BeforeDrawNoteSaved = false;
	        	AfterDrawNoteSaved = true;
	        	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This Draw Note is not related to any Investor. Please link it to an Investor');
                ApexPages.addMessage(myMsg);
	        }
        }
        else if(ApexPages.currentPage().getParameters().containsKey('AccountId')){
        	acc = [select name, accountnumber from account where id =: ApexPages.currentPage().getParameters().get('AccountId')];
	    	FromInvestor =  true;
	    	NewDraw = false;

        }
    	else{
    		NewDraw = true;
    	}

	}

	/**=====================================================================
	VF Page Action Function to save the newly created Draw Note and render the Receivable Section of the Page, 
	displaying the list of active Funded Receivables with the same Operating State as the Draw Note
	=====================================================================*/
	public PageReference SaveDrawNote()
	{
			if (draw.id == null){
				draw.investor__c = acc.id;
				draw.Status__c = 'Draft';
				insert draw;
				draw1 = [select id, Total_Amount_Borrowed__c, name, status__c, investor__c, investor__r.name, investor__r.accountnumber from draw_note__c where id =:draw.id limit 1];
				TotalAmountBorrowed = draw1.Total_Amount_Borrowed__c;
				BeforeDrawNoteSaved = false;
		        AfterDrawNoteSaved = true;
		        NewDraw = false;
	        	FromInvestor = true;
	        	Integer i = 0;
	        	Set<ID> NotIncludedReceivablesIDs = new Set<ID>();
	        	map<ID, Draw_Note_TX__c> RecToActiveDRTXMap = new map<ID, Draw_Note_TX__c>();
        		for(Draw_Note_TX__c drtx : [select id, Funded_Receivable__c,name,status__c,Draw_Note__r.name, draw_note__c 
        									from Draw_Note_TX__c 
        									where status__c in ('Draft','Active') ]){
       				if(drtx.status__c == 'Draft'){
       					NotIncludedReceivablesIDs.add(drtx.Funded_Receivable__c);
       				}
       				if(!NotIncludedReceivablesIDs.contains(drtx.Funded_Receivable__c) && drtx.status__c == 'Active'){
       					RecToActiveDRTXMap.put(drtx.Funded_Receivable__c,drtx);
       				}
        		}
	        	if(draw.Operating_State__c == null){
	        		receiveList = [select lien_holder__c, /*Draw_Note_TX__r.name, Draw_Note_TX__r.status__c, Draw_Note_TX__r.Draw_Note__r.name,*/
	        				Financeable__c,	lien_holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c,
       						Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c, Upfront_Purchase_Price__c
        					from Funded_Receivable__c
        					where Status__c = 'Active' 
        					//and School__r.Operating_State__c =: draw.Operating_State__c
        					//and Draw_Note_TX__r.Draw_Note__c !=: draw.Id
        					and id not in : NotIncludedReceivablesIDs];
	        	} else {
	        		receiveList = [select lien_holder__c, /*Draw_Note_TX__r.name, Draw_Note_TX__r.status__c, Draw_Note_TX__r.Draw_Note__r.name,*/
	        				Financeable__c,	lien_holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c,
       						Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c, Upfront_Purchase_Price__c
        					from Funded_Receivable__c
        					where Status__c = 'Active' 
        					and School__r.Operating_State__c =: draw.Operating_State__c
        					//and Draw_Note_TX__r.Draw_Note__c !=: draw.Id
        					and id not in : NotIncludedReceivablesIDs];
	        	}
	        	/*
	        	receiveList = [select lien_holder__c, /*Draw_Note_TX__r.name, Draw_Note_TX__r.status__c, Draw_Note_TX__r.Draw_Note__r.name,*//*
	        				Financeable__c,	lien_holder__r.name,Id,name,Purchase_Date__c,School__r.name,Expected_Pay_Date__c,
       						Distribution_Date__c, FV_Amount_Due__c, FV_Amount__c, Upfront_Purchase_Price__c
        					from Funded_Receivable__c
        					where Status__c = 'Active' 
        					and School__r.Operating_State__c =: draw.Operating_State__c
        					//and Draw_Note_TX__r.Draw_Note__c !=: draw.Id
        					and id not in : NotIncludedReceivablesIDs] ;
        		*/
		        RowListSelected = new List<DrawNoteReceivableWrapper>();
		        RowList = new List<DrawNoteReceivableWrapper>();
		        DrawNoteReceivableWrapper tr;
		        for(Funded_Receivable__c receive : receiveList) {
		            Draw_Note_TX__c DnTx = new Draw_Note_TX__c();
		            if( RecToActiveDRTXMap.containsKey(receive.Id)){
		            	DnTx = RecToActiveDRTXMap.get(receive.Id);
		           
		            	tr = new DrawNoteReceivableWrapper(receive.ID, receive.name, receive.lien_holder__r.name, receive.School__r.name,receive.Financeable__c,
		            									DnTx.name, DnTx.status__c,DnTx.Draw_Note__r.name,receive.Purchase_Date__c,receive.Expected_Pay_Date__c,
		            									receive.Distribution_Date__c,receive.FV_Amount_Due__c,receive.FV_Amount__c,receive.Upfront_Purchase_Price__c,false,i,false);
		            }else{
		            	tr = new DrawNoteReceivableWrapper(receive.ID, receive.name, receive.lien_holder__r.name, receive.School__r.name,receive.Financeable__c,
		            									null,null,null,receive.Purchase_Date__c,receive.Expected_Pay_Date__c,receive.Distribution_Date__c,
		            									receive.FV_Amount_Due__c,receive.FV_Amount__c,receive.Upfront_Purchase_Price__c,false,i,false);
		            }
		            
		            if(tr.LienHolder == null){
	            		tr.LienHolder = '-';
	           		}
	           		//if(tr.School == null){
	            	//	tr.School = '-';
	           		//}
	           		if(tr.FinanceableFlag == null){
	            		tr.FinanceableFlag = '-';
	           		}
	           		if(tr.DrwNoteTX == null){
	            		tr.DrwNoteTX = '-';
	           		}
	           		if(tr.DrwNoteTXStatus == null){
	            		tr.DrwNoteTXStatus = '-';
	           		}
	           		if(tr.DrawNote == null){
	            		tr.DrawNote = '-';
	           		}
		            i=i+1;
		            
		            if(tr.DrawNote != draw1.Name){
			            RowList.add(tr);
			            ReceivablesMap.put(tr.RowID,tr);
			            if(tr.LienHolder != '-'){
			            	setLienHolderIds.add(receive.lien_holder__c);
			            	if(LienToAllReceivablesMap.containsKey(tr.LienHolder)){
			        			LienToAllReceivablesMap.get(tr.LienHolder).add(tr);
			        		}
			        		else{
			        			LienToAllReceivablesMap.put(tr.LienHolder,new list<DrawNoteReceivableWrapper>{tr});
			        		}
			            }
			            if(tr.DrawNote != '-'){
			            	setDrawNoteIds.add(DnTx.draw_note__c);
			            	if(DrawNoteToAllReceivablesMap.containsKey(tr.DrawNote)){
			        			DrawNoteToAllReceivablesMap.get(tr.DrawNote).add(tr);
			        		}
			        		else{
			        			DrawNoteToAllReceivablesMap.put(tr.DrawNote,new list<DrawNoteReceivableWrapper>{tr});
			        		}
			            }
		            }
		        }
				RowList.sort();
				filteredByCheckbox();
				addPaginationOnFormList();
			}
		return null;
	}

	/**=====================================================================
	VF Page Action Function which is called when the Unassigned Checkbox or/and the Patial Paid Checkbox on the Page
	are checked or unchecked
	=====================================================================*/
	public PageReference filteredByCheckbox()
	{
			system.debug('unassigned is '+unassigned);
						system.debug('partial paid is '+PartialPaid);
			if (Unassigned == true && PartialPaid == false){
				LienFilterSelected = true;
				DrawFilterSelected = true;
				RowList.clear();
				system.debug('unassigned true');
				for(DrawNoteReceivableWrapper drRecWrap : ReceivablesMap.values()){
					system.debug('filtering by unassigned '+ drRecWrap);
					if(drRecWrap.DrwNoteTX == '-' && drRecWrap.LienHolder == '-'){
						system.debug('filtered this one '+ drRecWrap);
						RowList.add(drRecWrap);
					}
				}
				addPaginationOnFormList();
			}
			else if(Unassigned == true && PartialPaid == true){
				LienFilterSelected = true;
				DrawFilterSelected = true;
				system.debug('both true');
				RowList.clear();
				for(DrawNoteReceivableWrapper drRecWrap2 : ReceivablesMap.values()){
					if((drRecWrap2.FVAmountDue < drRecWrap2.FVAmount) && (drRecWrap2.DrwNoteTX == '-' || drRecWrap2.LienHolder == '-')){
						system.debug('both true record is');
						RowList.add(drRecWrap2);
					}
				}
				addPaginationOnFormList();
			}
			else if(Unassigned == false){
				LienFilterSelected = false;
				DrawFilterSelected = false;
				system.debug('no true');
				RowList.clear();
				RowList.addAll(ReceivablesMap.values());
				Integer j = RowList.size() - 1;
				system.debug('row list is ' +RowList);
				
				while(j >= 0){
					system.debug('row list record is ' +RowList.get(j).RecName);
					if(RowList.get(j).DrwNoteTXStatus == 'Active'){
						system.debug('removing '+RowList.get(j).RecName);
						if(RowList.get(j).FVAmount != RowList.get(j).FVAmountDue){
							system.debug('removed '+RowList.get(j).RecName);
							RowList.remove(j);
						}
					}
					j--;
				}
				addPaginationOnFormList();
			}
		return null;
	}

	/**=====================================================================
	VF Page Action Function to select/deselect all the displayed Funded Receivables for the assignment to the new Draw Note
	=====================================================================*/
	public PageReference SelectAllReceivables(){
		if(SelectAll){
			//RowListSelected.Clear();
			RowListSelected = new list<DrawNoteReceivableWrapper>();
			AssignDrawBtn = false;
			SelectedReceivablesMap.clear();

			if(draw.Total_Amount_Borrowed__c != null){
				TotalAmountBorrowed = draw.Total_Amount_Borrowed__c;
			}
			else{
				TotalAmountBorrowed = draw1.Total_Amount_Borrowed__c;
			}
			system.debug('total amount borrowed is ' + TotalAmountBorrowed);
			system.debug('row list is  ' + RowList);
			for(DrawNoteReceivableWrapper drNoteRecWrap : RowList){
				drNoteRecWrap.checkbox = true;
				RowListSelected.add(drNoteRecWrap);
				system.debug('check 1   ');
				SelectedReceivablesMap.put(drNoteRecWrap.RowID, drNoteRecWrap);
				system.debug('check 2   ' + drNoteRecWrap.FVAmount);
				if(drNoteRecWrap.UpfrontPurchasePrice!=null){
					TotalAmountBorrowed = TotalAmountBorrowed + drNoteRecWrap.UpfrontPurchasePrice;
				}
				system.debug('check 1   ' + TotalAmountBorrowed);
			}
			system.debug('total amount borrowed now ' + TotalAmountBorrowed);
		}
		else if(!SelectAll){
			system.debug('check1');
			for(DrawNoteReceivableWrapper drNoteRecWrapRemove1 : RowList){
				drNoteRecWrapRemove1.checkbox = false;
			}
			for(DrawNoteReceivableWrapper drNoteRecWrapRemove : RowListSelected){
				if(drNoteRecWrapRemove.UpfrontPurchasePrice!=null){
					TotalAmountBorrowed = TotalAmountBorrowed - drNoteRecWrapRemove.UpfrontPurchasePrice;
				}
			}
			RowListSelected.Clear();
			SelectedReceivablesMap.clear();
		}
		return null;
	}

	/**=====================================================================
	VF Page Action Function to show all the Lien Holder values for the displayed Funded Receivables on the Lien Holder Filter List
    for selection by the user
	=====================================================================*/
	public List<SelectOption> getListOfLienHolder()
    {
         List<Account> liens = [select id ,name from account where id in:setLienHolderIds ] ;
         List<SelectOption> LienOptionList = new List<SelectOption>();
         LienOptionList.add(new SelectOption( '---Select---' ,'---Select---'));
         for(Account lien : liens)
         {
             LienOptionList.add(new SelectOption(lien.Id , lien.Name));
         }
         return LienOptionList ;
    }
    
    /**=====================================================================
	VF Page Action Function to filter out the Funded Receivable List and display only those which have the same Lien Holder
	as selected on the Lien Holder Filter List 
	=====================================================================*/
    public PageReference filteredByLien(){
    	system.debug('select option1 ' +selectedHolder);
    	if(selectedHolder != '---Select---'){
    		DrawFilterSelected = true;
	        Account tempAcc = [select name from account where id=: selectedHolder];
	    	system.debug('lien holder is ' +tempAcc);
	    	List<DrawNoteReceivableWrapper> LienFilteredList = LienToAllReceivablesMap.get(tempAcc.name);
	    	system.debug('select option2' +LienFilteredList);
	    	system.debug('select option3' +RowList);
	    	RowList.clear();
	    	if(PartialPaid == true){
				system.debug('partial true');
				for(DrawNoteReceivableWrapper drRecWrap1 : LienFilteredList){
					if(drRecWrap1.FVAmountDue < drRecWrap1.FVAmount){
						RowList.add(drRecWrap1);
					}
				}
				addPaginationOnFormList();
			}
	    	else{
	    		RowList.addAll(LienFilteredList);
	    		addPaginationOnFormList();
	    	}
	    	system.debug('select option3' +RowList);
    	}
    	else{
    		DrawFilterSelected = false;
    		RowList.clear();
    		list<DrawNoteReceivableWrapper> lstAllReceivables = ReceivablesMap.values();
    		if(PartialPaid == true){
				system.debug('partial true');
				for(DrawNoteReceivableWrapper drRecWrap1 : lstAllReceivables){
					if(drRecWrap1.FVAmountDue < drRecWrap1.FVAmount){
						RowList.add(drRecWrap1);
					}
				}
				addPaginationOnFormList();
			}
    		else{
    			RowList.addAll(lstAllReceivables);
    			addPaginationOnFormList();
    		}
    	}
    	return null;
    }

  /**=====================================================================
	VF Page Action Function to show all the Draw Note values for the displayed Funded Receivables on the Draw Note Filter List
    for selection by the user
	=====================================================================*/
	public List<SelectOption> getListOfDrawNotes(){
         List<Draw_Note__c> draws = [select id ,name from Draw_Note__c where id in:setDrawNoteIds ] ;
         List<SelectOption> DrawOptionList = new List<SelectOption>();
         DrawOptionList.add(new SelectOption( '---Select---' ,'---Select---'));
         for(Draw_Note__c draw : draws)
         {
             DrawOptionList.add(new SelectOption(draw.Id , draw.Name));
         }
         return DrawOptionList ;
    }

  	/**=====================================================================
	VF Page Action Function to filter out the Funded Receivable List and display only those which are assigned to
	the same Draw Note as selected on the Draw Note Filter List 
	=====================================================================*/
  	public PageReference filteredByDrawNote(){
    	system.debug('select option1 for draw ' +selectedHolderDrawNote);
    	if(selectedHolderDrawNote != '---Select---'){
	        LienFilterSelected = true;
	        Draw_Note__c tempDraw = [select name from Draw_Note__c where id=: selectedHolderDrawNote];
	    	system.debug('draw note is ' +tempDraw);
	    	List<DrawNoteReceivableWrapper> DrawNoteFilteredList = DrawNoteToAllReceivablesMap.get(tempDraw.name);
	    	system.debug('select option2 for draw ' +DrawNoteFilteredList);
	    	system.debug('select option3 for draw ' +RowList);
	    	RowList.clear();
	    	if(PartialPaid == true){
				system.debug('partial true for draw ');
				for(DrawNoteReceivableWrapper drRecWrap2 : DrawNoteFilteredList){
					if(drRecWrap2.FVAmountDue < drRecWrap2.FVAmount){
						RowList.add(drRecWrap2);
					}
				}
				addPaginationOnFormList();
			}
	    	else{
	    		RowList.addAll(DrawNoteFilteredList);
	    		addPaginationOnFormList();
	    	}
	    	system.debug('select option3 for draw ' +RowList);
    	}
    	else{
    		LienFilterSelected = false;
    		RowList.clear();
    		list<DrawNoteReceivableWrapper> lstAllDrawReceivables = ReceivablesMap.values();
    		if(PartialPaid == true){
				system.debug('partial true');
				for(DrawNoteReceivableWrapper drRecWrap2 : lstAllDrawReceivables){
					if(drRecWrap2.FVAmountDue < drRecWrap2.FVAmount){
						RowList.add(drRecWrap2);
					}
				}
				addPaginationOnFormList();
			}
    		else{
    			RowList.addAll(lstAllDrawReceivables);
    			addPaginationOnFormList();
    		}
    	}
    	return null;
    }

  	/***************************************************************
  	* Initalize sorting order based on previous value.
 	***************************************************************/
  	public String sortExpression {
	    get {
	        return sortExp;
	    }
	    set {
        	if (value == sortExp)
            sortDirection = (sortDirection == 'ASC')? 'DESC' : 'ASC';
            else
            sortDirection = 'ASC';
            sortExp = value;
    	}
  	}

  	/***************************************************************
  	* Return Sorting order
  	***************************************************************/
 	public String getSortDirection() {
    	if (sortExpression == null || sortExpression == '')
        	return 'ASC';
    	else
       		return sortDirection;
  	}

    /**=====================================================================
	VF Page Action Function used to call the compareTo method defined in the Comparable Interface 
	to sort out the Funded Receivable Wrapper List based on the column/field clicked
	=====================================================================*/
  	public void sortWrapper()
  	{
  		system.debug('==========' + RowList);
  		if(sortExp=='RecName'){
        	DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByName;
        }
        else if(sortExp=='School'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.BySchool;
        }
        else if(sortExp=='LienHolder'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByLienHolder;
        }
        else if(sortExp=='UpfrontPurchasePrice'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByUpfrontPurchasePrice;
        }
        else if(sortExp=='DrawNote'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByDrawNote;
        }
        else if(sortExp=='FinanceableFlag'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByFinanceableFlag;
        }
        else if(sortExp=='FVAmount'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByFVAmount;
        }
        else if(sortExp=='ExpPayDate'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByExpectedPayDate;
        }
        else if(sortExp=='DistributionDate'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByDistributionDate;
        }
        else if(sortExp=='PurchaseDate'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByPurchaseDate;
        }
        else if(sortExp=='FVAmountDue'){
            DrawNoteReceivableWrapper.sortBy = DrawNoteReceivableWrapper.SORT_BY.ByFVAmountDue;
        }
        if(sortDirection == 'ASC'){
            DrawNoteReceivableWrapper.sortOrder = DrawNoteReceivableWrapper.SORT_ORDER.ByAsc;
        }
        else{
            DrawNoteReceivableWrapper.sortOrder = DrawNoteReceivableWrapper.SORT_ORDER.ByDesc;
        }
        RowList.sort();
		addPaginationOnFormList();
        system.debug('========' + rowList);
 	}

  	/***************************************************************
  	* Add pagination on Form list
  	* PaginationUtility class to used for pagination.
  	***************************************************************/
    public void addPaginationOnFormList() {
    	RowListPage.clear();
    	formListPagination = new PaginationUtility();
    	selectedPageNumber = 1;
    	RowListPage.addAll(RowList);
    	//fetch the pagination setting for this page  (Added for task T-277641)
      	PaginationSettings__c pageSetting = PaginationSettings__c.getValues('DrawNoteReceivable');

    	if(RowListPage.size() > 0) {
      		formListPagination.pageSize = (pageSetting != null && pageSetting.PageSize__c != null)? Integer.valueOf(pageSetting.PageSize__c) :5;
      		List<Object> tempList = formListPagination.setPagination(RowListPage);
      		RowListPage = getWrapperList(tempList);
    	}
   	}
  	/************************************************************
  	* Method to cast object into forms
  	************************************************************/
  	private List<DrawNoteReceivableWrapper> getWrapperList(List<Object> currentList) {
    	RowListPage.clear();
    	for(Object obj : currentList) {
        	RowListPage.add((DrawNoteReceivableWrapper)obj);
    	}
    	return RowListPage;
  	}

  	/************************************************************
  	* Method to get pagination list of forms
  	************************************************************/
  	public PageReference getList() {
    	RowListPage = getWrapperList(formListPagination.getPage(selectedPageNumber));
    	return null;
  	}

	/**=====================================================================
	VF Page Action Function which is executed when the user selected/deselects a Funded Receivable wrapper record 
	from the displayed list, by checking/unchecking the checbox next to it.
	It is basically used to display the selected receivable record in the bottom section of the page 'Selected Receivables'
	add to/subtract from the Borrowed Amount of the Draw Note to display to the user.
	=====================================================================*/
	public PageReference SelectReceivables()
	{
		AssignDrawBtn = false;
		String a = Apexpages.currentPage().getParameters().get('myParam');
		Integer WrapperRowID = Integer.ValueOf(a);
		system.debug('row id is ' +a);
		DrawNoteReceivableWrapper recWrap = ReceivablesMap.get(WrapperRowID);
		if (recWrap.checkbox == true){
			RowListSelected.add(recWrap);
			SelectedReceivablesMap.put(recWrap.RowID, recWrap);
			if(recWrap.UpfrontPurchasePrice!=null){
				TotalAmountBorrowed = TotalAmountBorrowed + recWrap.UpfrontPurchasePrice;
			}
		}
		else{
			Integer m = 0;
			while(m<RowListSelected.size()){
				if(recWrap.RowID == RowListSelected.get(m).RowID){
					RowListSelected.remove(m);
					SelectedReceivablesMap.remove(recWrap.RowID);
					if(recWrap.UpfrontPurchasePrice!=null){
						TotalAmountBorrowed = TotalAmountBorrowed - recWrap.UpfrontPurchasePrice;
					}
					break;
				}
				m++;
			}
		}
		return null;
	}
	
	/**=====================================================================
	VF Page Action Function which is executed when the user clicks the X sign next to the selected Receivable record from the
	bottom section of the Page.
	It is basically used to remove the selected receivable record from the bottom section of the page 'Selected Receivables',
	and to reduce the displayed amount borrowed on the Draw Note by that value.
	=====================================================================*/
	public PageReference RemoveReceivable()
	{
		DrawNoteReceivableWrapper recWrap = SelectedReceivablesMap.get(rID);
		Integer m = 0;
		while(m<RowListSelected.size()){
			if(recWrap.RowID == RowListSelected.get(m).RowID){
				RowListSelected.remove(m);
				if(recWrap.UpfrontPurchasePrice!=null){
					TotalAmountBorrowed = TotalAmountBorrowed - recWrap.UpfrontPurchasePrice;
				}
				ReceivablesMap.get(recWrap.RowID).Checkbox = false;
				break;
			}
			m++;
		}
		return null;
	}
	
	/**=====================================================================
	VF Page Action Function which is executed when the user clicks on the button 'Assign Draw' to
	assign/reassign(refinance) the selected receivables to the new Draw Note.
	This results in the creation of new Draw Note TX record for each and every selected Receivable to be assigned ot the Draw Note.
	Also updates the Lien Holder value of the selected Receivable.
	=====================================================================*/
	public PageReference AssignDraw()
	{
		String drawStatus = ApexPages.currentPage().getParameters().get('Additions');
		System.debug('Draw Status: ' + drawStatus);

		list<Funded_Receivable__c> frlist = new list<Funded_Receivable__c>();
		list<DrawNoteReceivableWrapper> drnlist = new list<DrawNoteReceivableWrapper>();
		Map<ID,Funded_Receivable__c> IdToSelectedReceivable = new Map<ID,Funded_Receivable__c>();
		//Map<ID,ID> RectoDrx = new Map<ID,ID>();
		Set<ID> RecIds = new set<ID>();
		list<Draw_Note_TX__c> drxlist = new list<Draw_Note_TX__c>();
		for(DrawNoteReceivableWrapper recWrap : RowListSelected){
			
			if(recWrap.Assigned != true){
				system.debug('if assigned already' + recWrap.Assigned);
				RecIds.add(recWrap.RecID);
				
			}

		}
		system.debug('selected wrapper list is ' + RowListSelected);
		list<Funded_Receivable__c> freclist = [select id, FV_Amount__c, FV_Amount_Due__c, Upfront_Purchase_Price__c
		 										from Funded_Receivable__c
		 										where id in: RecIds];
		for(Funded_Receivable__c fr : freclist){
			IdToSelectedReceivable.put(fr.Id, fr);
		}

		for(DrawNoteReceivableWrapper recWrap : RowListSelected){
			system.debug('if assigned already' + recWrap.Assigned);
			if(recWrap.Assigned != true){
				Funded_Receivable__c frnew = IdToSelectedReceivable.get(recWrap.RecID);
				/*if(frnew.Draw_Note_TX__c != null){
				oldDrXIDs.add(frnew.Draw_Note_TX__c);
				}*/
				Draw_Note_TX__c drx = new Draw_Note_TX__c();
				drx.status__c = 'Draft';
				//drx.Amount_Borrowed__c = frnew.FV_Amount__c;
				drx.Amount_Borrowed__c = frnew.Upfront_Purchase_Price__c;
				drx.FV_Amount_TX__c = frnew.FV_Amount__c;
				system.debug('draw id is '+ draw.Id);
				drx.Draw_Note__c = draw.Id;
				drx.Funded_Receivable__c = frnew.id;
				drxlist.add(drx);
				recWrap.Assigned = true;
			}
			
		}

		insert drxlist;
		/*for(Draw_Note_TX__c drx1 : drxlist){
			RectoDrx.put(drx1.Funded_Receivable__c, drx1.ID);
		}
		//because lien holder and draw note tx of the receivable will be updated only when the new Draw gets activated-discuss please
		for(Funded_Receivable__c frnew1 : IdToSelectedReceivable.values()){
			system.debug('frs to be updated is ' + frnew1);
			if(frnew1.Draw_Note_TX__c == null || frnew1.Draw_Note_TX__r.Draw_Note__c == null || 
			frnew1.Draw_Note_TX__r.Draw_Note__c != draw.Id){
				frnew1.Draw_Note_TX__c = RectoDrx.get(frnew1.Id);
				frnew1.lien_holder__c = draw.investor__c;
				system.debug('drtx value on fr is ' + frnew1.Draw_Note_TX__c);
				frlist.add(frnew1);
			}
		}
		update frlist;*/
		//update oldDrXList;
		if(drawStatus == 'True'){
				String draw = ApexPages.currentPage().getParameters().get('DrawNoteid');
				ActivateDraw.AddDrawNoteTX(draw);
				PageReference drawRecord = new PageReference('/' + draw);
				return drawRecord;
			} else {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,System.Label.Receivables_Assigned_to_Draw);
				ApexPages.addMessage(myMsg);
				AssignDrawBtn = true;
				return null;
			}

	}
}