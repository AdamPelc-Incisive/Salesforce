/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class DocumentWrapperEV2 extends pandadoc.DocumentWrapper.BaseDocumentWrapper {
    global pandadoc.DocumentWrapperEV2.DocumentData data {
        get;
        set;
    }
    global String event {
        get;
        set;
    }
    global DocumentWrapperEV2() {

    }
    global static pandadoc.DocumentWrapperEV2.DocumentData parseDetailsFromJson(String jsonData) {
        return null;
    }
    global static pandadoc.DocumentWrapperEV2 parseFromJson(String jsonData) {
        return null;
    }
global class DocumentData extends pandadoc.PandaDocHelper.CanBeParsed {
    global pandadoc.DocumentWrapper.DocumentPerson action_by {
        get;
        set;
    }
    global String autonumbering_sequence_name_prefix {
        get;
        set;
    }
    global pandadoc.DocumentWrapper.PandaDocUser created_by {
        get;
        set;
    }
    global String date_completed {
        get;
        set;
    }
    global String date_created {
        get;
        set;
    }
    global String date_sent {
        get;
        set;
    }
    global String expiration_date {
        get;
        set;
    }
    global List<pandadoc.DocumentWrapper.DocumentField> fields {
        get;
        set;
    }
    global pandadoc.DocumentWrapper.GrandTotal grand_total {
        get;
        set;
    }
    global String id {
        get;
        set;
    }
    global Map<String,String> metadata {
        get;
        set;
    }
    global String name {
        get;
        set;
    }
    global pandadoc.Pricing pricing {
        get;
        set;
    }
    global List<pandadoc.DocumentWrapper.DocumentProducts> products {
        get;
        set;
    }
    global List<pandadoc.DocumentWrapper.DocumentRecipient> recipients {
        get;
        set;
    }
    global String ref_number {
        get;
        set;
    }
    global pandadoc.DocumentWrapper.PandaDocUser sent_by {
        get;
        set;
    }
    global pandadoc.SourceNode source_node {
        get;
        set;
    }
    global String status {
        get;
        set;
    }
    global pandadoc.DocumentWrapper.TemplateData template {
        get;
        set;
    }
    global List<pandadoc.DocumentWrapper.DocumentToken> tokens {
        get;
        set;
    }
    global String workspace_uuid {
        get;
        set;
    }
    global DocumentData() {

    }
}
}
