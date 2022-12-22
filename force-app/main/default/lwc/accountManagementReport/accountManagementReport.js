import { LightningElement, wire, track} from 'lwc';
import getAccountData from '@salesforce/apex/AccountManagementReportCtrl.getAccountData';
import { refreshApex } from '@salesforce/apex';

const actions = [
  { label: 'Show latest info.', name: 'show_details' },
];

const columns = [
  { label: 'State', fieldName: 'accState', sortable: true, initialWidth: 60, hideDefaultActions: true},
  { label: 'Charter Holder', fieldName: 'accUrl', type: 'url', sortable: true, initialWidth: 400, typeAttributes: {
    label: { fieldName: 'accName' },
          target: '_blank'
      }, hideDefaultActions: true},
  { label: '# O/S Recs', fieldName: 'repUrl', type: 'url', initialWidth: 90,
        typeAttributes: {
          label: { fieldName: 'recCount' },
          target: '_blank'
      }, hideDefaultActions: true
  },
  { label: 'FV Due', fieldName: 'faceValueDue', type: 'currency', typeAttributes: { minimumFractionDigits: '0', maximumFractionDigits: '0'}, sortable: true, initialWidth: 110, hideDefaultActions: true},
  { label: 'Last Eff. Rate', fieldName: 'lastEffectiveRate', initialWidth: 120, cellAttributes: { alignment: 'right' }, hideDefaultActions: true},
  { label: 'Bought through', fieldName: 'boughtUntil', initialWidth: 140, hideDefaultActions: true},
  { label: 'Next WB Opp', fieldName: 'nextWhiteboardOpp', initialWidth: 120, hideDefaultActions: true},
  { label: 'Owner', fieldName: 'accOwner', sortable: true, initialWidth: 120, hideDefaultActions: true},
  { label: 'Strategy', fieldName: 'latestStrategy', sortable: false, initialWidth: 200, hideDefaultActions: false, wrapText: true, },
  { label: 'Update', fieldName: 'latestUpdate', sortable: false, initialWidth: 200, hideDefaultActions: false, wrapText: true },
  {
    label: 'View', initialWidth: 60, type: 'action',
    typeAttributes: { rowActions: actions },
  },
];

export default class AccountManagementReport extends LightningElement {
  data;
  filteredData = [];
  columns = columns;
  sortDirection;
  sortedBy;
  total;
  value;
  ownerFilter;
  wiredData;
  accordianSection = '';
  latestUpdate = 'n/a';
  latestStrategy = 'n/a';
  rowAccName = '';
  @track isModalOpen = false;

  @wire(getAccountData) accountList(result){
    console.log('getting data...');
    this.wiredData = result;
    if (result.data) {
        this.data = result.data;
        // this.filteredData = result.data;
        this.filteredData = this.getFilterData(this.value || 'All');
        this.total = this.getTotal(this.filteredData);
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

      if (event.detail.fieldName === "accUrl") {
        cloneData.sort(this.sortBy("accName", sortDirection === 'asc' ? 1 : -1));
        // this.sortBy = "SchoolName";
      } else {
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
      }

      // cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
      this.filteredData = cloneData;
      this.sortDirection = sortDirection;
      this.sortedBy = sortedBy;
  }

  getTotal(arr){
    let total = 0;
    arr.forEach(element => {
      total += element.faceValueDue;
    });
    return total;
  }

  getOwnerList(arr){
    let ownerSet = new Set();
    let ownerArray;
    let ownerFilter = [];
    arr.forEach(element => {
      ownerSet.add(element.accOwner);
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
        row.accOwner == filterValue
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
    this.total = this.getTotal(this.filteredData);
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

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
        case 'show_details':
            this.displayUpdatesPopUp(row);
            break;
        default:
    }
}

  displayUpdatesPopUp(tableRow){
    this.latestStrategy = tableRow.latestStrategy || 'not listed';
    this.latestUpdate = tableRow.latestUpdate || 'not listed';
    this.rowAccName = tableRow.accName;
    this.openModal();
  }

  openModal() {
    // to open modal set isModalOpen track value as true
    this.isModalOpen = true;
  }
  closeModal() {
      // to close modal set isModalOpen track value as false
      this.isModalOpen = false;
  }


};