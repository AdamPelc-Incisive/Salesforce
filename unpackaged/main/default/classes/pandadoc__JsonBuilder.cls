/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global abstract class JsonBuilder {
    global JsonBuilder(Schema.SObjectType recordsObjectType, Map<String,Set<String>> childRelationshipsToLoad) {

    }
    global JsonBuilder(Schema.SObjectType recordsObjectType, Map<String,Set<String>> childRelationshipsToLoad, Map<String,String> childSorting) {

    }
    global virtual Map<String,Object> getAttributes(SObject record) {
        return null;
    }
    global virtual String getDocName(SObject record) {
        return null;
    }
    global abstract List<pandadoc.Item> getItems(SObject param0);
    global String getJSON(Id recordId) {
        return null;
    }
    global virtual Map<String,String> getPandaDocMetadata(Id recordId, SObject record) {
        return null;
    }
    global abstract List<pandadoc.Recipient> getRecipients(SObject param0);
    global virtual String getRedirectUrl(SObject record, String sObjectName) {
        return null;
    }
    global virtual pandadoc.SourceNode getSourceNode(SObject record) {
        return null;
    }
}
