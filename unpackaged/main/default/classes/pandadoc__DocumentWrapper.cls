/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class DocumentWrapper extends pandadoc.DocumentWrapper.BaseDocumentWrapper {
    global pandadoc.DocumentWrapper.DocumentData data {
        get;
        set;
    }
    global String event {
        get;
        set;
    }
    global DocumentWrapper() {

    }
    global static List<pandadoc.DocumentWrapper> parseFromJson(String jsonData) {
        return null;
    }
global class Discount extends pandadoc.DocumentWrapper.TypeAndValue {
    global Discount() {

    }
}
global class DocumentData extends pandadoc.PandaDocHelper.CanBeParsed {
    global pandadoc.DocumentWrapper.DocumentPerson action_by {
        get;
        set;
    }
    global pandadoc.DocumentWrapper.PandaDocUser created_by {
        get;
        set;
    }
    global Datetime date_created {
        get;
        set;
    }
    global Datetime date_modified {
        get;
        set;
    }
    global List<pandadoc.DocumentWrapper.DocumentField> fields {
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
    global List<pandadoc.DocumentWrapper.DocumentProducts> products {
        get;
        set;
    }
    global List<pandadoc.DocumentWrapper.DocumentRecipient> recipients {
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
    global DocumentData() {

    }
}
global class DocumentField extends pandadoc.PandaDocHelper.CanBeParsed {
    global String field {
        get;
        set;
    }
    global Object value {
        get;
        set;
    }
    global DocumentField() {

    }
}
global virtual class DocumentPerson extends pandadoc.PandaDocHelper.CanBeParsed {
    global String email {
        get;
        set;
    }
    global String first_name {
        get;
        set;
    }
    global String id {
        get;
        set;
    }
    global String last_name {
        get;
        set;
    }
    global DocumentPerson() {

    }
    global String toLabel() {
        return null;
    }
}
global class DocumentProducts extends pandadoc.PandaDocHelper.CanBeParsed {
    global Object cost {
        get;
        set;
    }
    global Map<String,Object> custom_columns {
        get;
        set;
    }
    global Map<String,Object> custom_fields {
        get;
        set;
    }
    global String description {
        get;
        set;
    }
    global pandadoc.DocumentWrapper.Discount discount {
        get;
        set;
    }
    global Map<String,pandadoc.DocumentWrapper.Discount> discounts {
        get;
        set;
    }
    global String id {
        get;
        set;
    }
    global Map<String,Object> merged_data {
        get;
        set;
    }
    global String name {
        get;
        set;
    }
    global pandadoc.DocumentWrapper.Options options {
        get;
        set;
    }
    global String price {
        get;
        set;
    }
    global Integer qty {
        get;
        set;
    }
    global Decimal qtyDecimal {
        get;
        set;
    }
    global String sku {
        get;
        set;
    }
    global String subtotal {
        get;
        set;
    }
    global Decimal totalQty {
        get;
        set;
    }
    global DocumentProducts() {

    }
}
global class DocumentRecipient extends pandadoc.DocumentWrapper.DocumentPerson {
    global Boolean has_completed {
        get;
        set;
    }
    global String recipient_type {
        get;
        set;
    }
    global String role {
        get;
        set;
    }
    global DocumentRecipient() {

    }
}
global class DocumentToken extends pandadoc.PandaDocHelper.CanBeParsed {
    global String name {
        get;
        set;
    }
    global Object value {
        get;
        set;
    }
    global DocumentToken() {

    }
}
global class GrandTotal extends pandadoc.PandaDocHelper.CanBeParsed {
    global String amount {
        get;
        set;
    }
    global String currency_x {
        get;
        set;
    }
    global GrandTotal() {

    }
}
global class Options extends pandadoc.PandaDocHelper.CanBeParsed {
    global Boolean multichoice_enabled {
        get;
        set;
    }
    global Boolean multichoice_selected {
        get;
        set;
    }
    global Boolean optional {
        get;
        set;
    }
    global Boolean optional_selected {
        get;
        set;
    }
    global Boolean qty_editable {
        get;
        set;
    }
    global Boolean selected {
        get;
        set;
    }
    global Options() {

    }
}
global class PandaDocUser extends pandadoc.DocumentWrapper.DocumentPerson {
    global String avatar {
        get;
        set;
    }
    global PandaDocUser() {

    }
}
global virtual class TypeAndValue extends pandadoc.PandaDocHelper.CanBeParsed {
    global String type {
        get;
        set;
    }
    global String value {
        get;
        set;
    }
    global TypeAndValue() {

    }
}
}
