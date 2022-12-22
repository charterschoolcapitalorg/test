import { LightningElement, wire, api } from 'lwc';
import getCustomSettings from '@salesforce/apex/ZenComponentCtrl.getCustomSettings';


export default class Zen extends LightningElement {
    zenHeading
    zenURL;
    zenText;
    zenTextColor;
    wiredData;
    @api styleAttr;

    @wire(getCustomSettings) zenString(result){
        console.log('getting data...');
        this.wiredData = result;
        if (result.data) {
            this.data = result.data;
            this.zenHeading = result.data[0];
            this.zenURL = result.data[1];
            this.zenText = result.data[2];
            this.zenTextColor = result.data[3];
            
        } else if (result.error) {
            this.error = result.error;
            this.data = undefined;
        }
      }

    get styleAttr() {
        return `color: ${this.zenTextColor}`;
    }

}