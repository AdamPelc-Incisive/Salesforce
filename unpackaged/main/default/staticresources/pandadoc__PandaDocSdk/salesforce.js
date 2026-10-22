(function(){

  var SALESFORCE_CUSTOM_CSS_URL = 'https://s3.amazonaws.com/pd-js-sdk/'+PandaDoc.Version+'/connectors/salesforce.css';

  var SalesforceConnector = function(){

    /** this meta data used to create and filter
     * documents related to a specific object
     * passed as pandaDocMetadata object, can contain multiple
     * key/value pairs
     *
     * @param objectData - a JSON object with all information from a related object in SFDC
     * @returns Object with meta data
     */
    this.getMetadata = function(objectData){
      return objectData && objectData.pandaDocMetadata ? objectData.pandaDocMetadata : {};
    };

    /**
     * Transforms objectData JSON object to a format
     * used by PandaDoc editor to pass pre-populated data
     * like tokens, widgets, etc.
     *
     * @param objectData - a JSON object with all information to pass to JS SDK
     */
    this.getDocumentExtraData = function(objectData) {
      var documentExtraData = {};

      if(objectData) {
        documentExtraData.metadata = this.getMetadata(objectData);

        //copy docName if passed
        if(objectData.docName) {
          documentExtraData.docName = objectData.docName;
        }

        if(objectData.redirectUrl) {
          documentExtraData.redirectUrl = objectData.redirectUrl;
        }

        //filling in tokens and widgets values
        documentExtraData.widgets = {
          '__widgets': true
        };
        documentExtraData.tokens = {
          '__tokens': true
        };
        if (objectData.variables) {
          documentExtraData.variables = objectData.variables;
        } else if(objectData.extraData) {
          for (var label in objectData.extraData) {
            //if token a number then convertion to string to nor loose 0 value (0 should be "0". not empty string).
            var _value = ((typeof objectData.extraData[label] != 'number') ? (objectData.extraData[label] || '') : objectData.extraData[label])  + '';
            documentExtraData.tokens[label] = _value;
            documentExtraData.widgets[label] = _value;
          }
        }

        //adding document roles
        documentExtraData.recipients = objectData.recipients ? objectData.recipients : [];

        //adding products if passed
        if(objectData.items) {
          documentExtraData.items = objectData.items;
        }
      }

      // fix null properties bug, there is but in jschannel library
      var replaceNullByEmptyString = function(object) {
        for (var property in object) {
          if (object.hasOwnProperty(property)) {
            if (object[property] === null) {
              object[property] = '';
            } else if (typeof object[property] === 'object') {
              object[property] = replaceNullByEmptyString(object[property]);
            }
          }
        }
        return object;
      };

      documentExtraData = replaceNullByEmptyString(documentExtraData);
      documentExtraData.sourceEntity = objectData.sourceEntity;

      return documentExtraData;
    };

    /**
     * Setting up a document list.
     *
     * @param elementId - element UD where you want to add it to
     * @param objectData - SF Opportunity JSON
     */
    this.setupDocList = function(elementId, objectData){
      var self = this;
      var extraData = self.getDocumentExtraData(objectData);
      var doclist = new PandaDoc.DocList({mode: PandaDoc.DOC_LIST_MODE.LIST});
      doclist.init({
        el: elementId,
        data: {
            metadata: this.getMetadata(objectData),
            sourceEntity: extraData.sourceEntity
        },
        cssClass: 'pandadoc-doc-list',
        initOptions: {
          customCss: SALESFORCE_CUSTOM_CSS_URL,
          showTokens: true,
          //editor is not used in doclist, but it's better to keep it
          //as external, this way it won't be rendered in the list
          externalEditor: true,
          isExtension: true,
          provider: {
            name: objectData.provider,
            version: objectData.version
          }
        },
        events: {
          onDocumentOpen: function(documentData) {
            //open a document in a new window
            if(documentData.documentUrl) {
              window.open(documentData.documentUrl, '_blank');
            }
          },
          onTokensOpen: function() {
            doclist.showAvailableTokens(extraData ? extraData : {});
          }
        }
      });

    };

    /**
     * Setting up a document list.
     *
     * @param elementId - element UD where you want to add it to
     * @param objectData - SF Opportunity JSON
     */
    this.setupEditor = function(elementId, objectData){
      var editor = new PandaDoc.DocEditor();
      editor.show({
        el: elementId,
        data: this.getDocumentExtraData(objectData),
        cssClass: 'pandadoc-doc-editor',
        initOptions: {
          provider: {
            name: objectData.provider,
            version: objectData.version
          },
          hideCloseButton: true
        }
      });
    };

  };

  PandaDoc.Salesforce = new SalesforceConnector();
})();
