import { LightningElement, wire} from 'lwc';
import getAccountData from '@salesforce/apex/AcademicRatingReportCtrl.getSchoolData';
import { refreshApex } from '@salesforce/apex';

export default class FacilitiesAttendanceReport extends LightningElement {
  data;
  filteredData = [];
  columns;
  sortDirection;
  sortedBy;
  value;
  ownerFilter;
  wiredData;
  accordianSection = '';

  @wire(getAccountData) accountList(result){
    console.log('getting data...');
    this.wiredData = result;
    if (result.data) {
        this.data = result.data;
        // this.filteredData = result.data;
        this.filteredData = this.getFilterData(this.value || 'All');
        this.ownerFilter = this.getOwnerList(this.data);
        this.error = undefined;

        var currentFY = new Date().getFullYear().toString().substr(-2);
        var previousFY = parseInt(currentFY)-1;
        var previous2FY = previousFY-1;
        var previous3FY = previous2FY-1;
        console.log('currentFY == '+ currentFY);

        var currentYear = new Date().getFullYear().toString();

        //Set a static date of August 1st of the current year
        var GivenDate = currentYear+'-08-01';
        var CurrentDate = new Date();
        GivenDate = new Date(GivenDate);

        console.log('Given Date == '+GivenDate);
        console.log('Current Date == '+CurrentDate);

        if(CurrentDate >= GivenDate){
          console.log('Given Date is in or after August');
          this.columns = [
            { label: 'State', fieldName: 'StateName', sortable: true, initialWidth: 60, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'School', fieldName: 'SchoolUrl', type: 'url', sortable: true, initialWidth: 300, typeAttributes: {
                  label: { fieldName: 'SchoolName' },
                        target: '_blank'
                    }, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'Property', fieldName: 'PropertyNickName', sortable: true, initialWidth: 110, hideDefaultActions: true, cellAttributes: { alignment: 'left'}},
            { label: 'Owner', fieldName: 'PropertyOwner', sortable: true, initialWidth: 110, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'Charter Exp.', fieldName: 'CharterExpirationDate', sortable: true, type:'date-local', initialWidth: 150, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'Grades Served', fieldName: 'GradeServed', initialWidth: 220, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'FY'+currentFY+' Color', fieldName: 'CRCurrentYear', sortable: false, initialWidth: 120, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'FY'+currentFY+' Actual', fieldName: 'TGCurrentYear', sortable: true, initialWidth: 275, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            { label: 'FY'+previousFY+' Color', fieldName: 'CRPreviousYear', sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            { label: 'FY'+previousFY+' Actual', fieldName: 'TGPreviousYear', sortable: true, initialWidth: 275, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            { label: 'FY'+previous2FY+' Color', fieldName: 'CRTwoYearsAgo', sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            { label: 'FY'+previous2FY+' Actual', fieldName: 'TGTwoYearsAgo', sortable: true, initialWidth: 275, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            
          ];
        }else{
          console.log('Given Date is before August');
          this.columns = [
            { label: 'State', fieldName: 'StateName', sortable: true, initialWidth: 60, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'School', fieldName: 'SchoolUrl', type: 'url', sortable: true, initialWidth: 300, typeAttributes: {
                  label: { fieldName: 'SchoolName' },
                        target: '_blank'
                    }, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'Property', fieldName: 'PropertyNickName', sortable: true, initialWidth: 110, hideDefaultActions: true, cellAttributes: { alignment: 'left'}},
            { label: 'Owner', fieldName: 'PropertyOwner', sortable: true, initialWidth: 110, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'Charter Exp.', fieldName: 'CharterExpirationDate', sortable: true, type:'date-local', initialWidth: 150, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'Grades Served', fieldName: 'GradeServed', initialWidth: 220, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'FY'+previousFY+' Color', fieldName: 'CRPreviousYear', sortable: false, initialWidth: 120, hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
            { label: 'FY'+previousFY+' Actual', fieldName: 'TGPreviousYear', sortable: true, initialWidth: 275, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            { label: 'FY'+previous2FY+' Color', fieldName: 'CRTwoYearsAgo', sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            { label: 'FY'+previous2FY+' Actual', fieldName: 'TGTwoYearsAgo', sortable: true, initialWidth: 275, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            { label: 'FY'+previous3FY+' Color', fieldName: 'CRThreeYearsAgo', sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            { label: 'FY'+previous3FY+' Actual', fieldName: 'TGThreeYearsAgo', sortable: true, initialWidth: 275, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' } },
            
          ];
        }
    } else if (result.error) {
        this.error = result.error;
        this.data = undefined;
    }
  }

  sortBy(field, reverse, primer) {
    const key = primer
        ? function(x) {
              return primer(x[field]);
          }
        : function(x) {
              return x[field];
          };

    return function(a, b) {
        a = key(a);
        b = key(b);
        return reverse * ((a > b) - (b > a));
    };
  }

  onHandleSort(event) {
      const { fieldName: sortedBy, sortDirection } = event.detail;
      const cloneData = [...this.filteredData];

      if (event.detail.fieldName === "SchoolUrl") {
        cloneData.sort(this.sortBy("SchoolName", sortDirection === 'asc' ? 1 : -1));
        // this.sortBy = "SchoolName";
      } else {
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
      }

      // cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
      this.filteredData = cloneData;
      this.sortDirection = sortDirection;
      this.sortedBy = sortedBy;
  }

  getOwnerList(arr){
    let ownerSet = new Set();
    let ownerArray;
    let ownerFilter = [];
    arr.forEach(element => {
      ownerSet.add(element.PropertyOwner);
    });

    ownerArray = Array.from(ownerSet);
    ownerArray.sort();
    ownerArray.unshift('All');
    ownerArray.forEach(element => {
      ownerFilter.push({value: element, label: element});
    });
    return ownerFilter;
  }

  getFilterData(filterValue){
    let filteredData = [];
    if (filterValue !== 'All') {
        filteredData = this.data.filter((row) =>
        row.PropertyOwner == filterValue
      );
    } else {
        filteredData = this.data;
    }
    return filteredData;
  }

  handleChange(event){
    if(event) {
      this.value = event.detail.value;
    }
    this.filteredData = this.getFilterData(this.value);
  }

  handleToggleSection(event) {
      if(this.accordianSection.length === 0){
        this.accordianSection =''
      }
      else{
        this.accordianSection ='Blank'
      }
  }

  handleRefresh(){
    console.log('clicked refresh...');
    console.log('filter...' + this.value);
    refreshApex(this.wiredData);
  }

}