import { LightningElement, wire} from 'lwc';
import getAccountData from '@salesforce/apex/FacilitiesSchoolReportCtrl.getSchoolData';
import { refreshApex } from '@salesforce/apex';

var currentMonth = new Date().getMonth();
var currentFY;
var previousFY;
var previous2FY;

if(currentMonth >= 6) {
    currentFY = new Date().getFullYear() + 1;
    previousFY = currentFY - 1;
    previous2FY = previousFY - 1;
} else {
    currentFY = new Date().getFullYear();
    previousFY = currentFY - 1;
    previous2FY = previousFY - 1;
}
// var previousFY = parseInt(currentFY)-1;
// var previous2FY = previousFY-1;

const columns = [
  { label: 'State', fieldName: 'StateName', sortable: true, initialWidth: 60, hideDefaultActions: true},
  // { label: 'School', fieldName: 'SchoolName', sortable: true, initialWidth: 400, hideDefaultActions: true},
  { label: 'School', fieldName: 'SchoolUrl', type: 'url', sortable: true, initialWidth: 400, typeAttributes: {
        label: { fieldName: 'SchoolName' },
              target: '_blank'
          }, hideDefaultActions: true},
  { label: 'Property', fieldName: 'PropertyNickName', sortable: true, initialWidth: 110, hideDefaultActions: true},
  { label: 'Owner', fieldName: 'PropertyOwner', sortable: true, initialWidth: 110, hideDefaultActions: true},
  { label: 'Charter Exp.', fieldName: 'CharterExpirationDate', sortable: true, type:'date-local', initialWidth: 150, hideDefaultActions: true},
  // { label: 'Remaining Days', fieldName: 'RemainingCharterTerms', initialWidth: 100, hideDefaultActions: true},
  { label: 'Grades Served', fieldName: 'GradeServed', initialWidth: 220, hideDefaultActions: true},
  { label: 'Charter Cap', fieldName: 'CharterCapacity', sortable: false, initialWidth: 120, hideDefaultActions: true},
  { label: 'FY'+currentFY, fieldName: 'EnrollmentCurrentYear', sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true, },
  { label: 'FY'+previousFY, fieldName: 'EnrollmentPreviousYear', sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true },
  { label: 'FY'+previous2FY, fieldName: 'EnrollmentTwoYearsAgo', sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true },
  { label: '% Change CvP', fieldName: 'EnrollmentDiffCurrPrev', type: 'percent', typeAttributes: { 
        step: '0.00001', minimumFractionDigits: '0', maximumFractionDigits: '3'
      }, sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' }
  },
  { label: '% Change Pv2', fieldName: 'EnrollmentDiffPrevTwo', type: 'percent', typeAttributes: { 
        step: '0.00001', minimumFractionDigits: '0', maximumFractionDigits: '3'
      }, sortable: true, initialWidth: 120, hideDefaultActions: false, wrapText: true, cellAttributes: { alignment: 'left' }
  },
];

export default class FacilitiesAttendanceReport extends LightningElement {
  data;
  filteredData = [];
  columns = columns;
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