import { LightningElement, api, wire} from 'lwc';
import getVersionData from '@salesforce/apex/ContentDocumentHelper.getLatestVersionId';

export default class PropertyImage extends LightningElement {

  @api recordId;
  contentVersionId

  @wire(getVersionData, {accountId: '$recordId'})
  wiredContentVersion({ error, data }) {
      if (data) {
          this.record = data;
          for(let key in data) {
            if(data.hasOwnProperty(key)) {
              if(key == "Id"){
                this.contentVersionId = data[key];
              }
            }
        }
      } else if (error) {
          console.log('Something went wrong:', error);
      }
  }

  get previewId() {
    return '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Png&versionId=' + this.contentVersionId;
  }  
}