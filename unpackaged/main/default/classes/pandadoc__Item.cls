/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class Item {
    global static Map<String,pandadoc.Item.ItemSettings> PRICING_ITEM_SETTINGS_MAP {
        get;
        set;
    }
    global Item(pandadoc.Item.ItemSettings setting, SObject sObj) {

    }
    global Item(String sku, String name, Decimal price, Decimal qty, String description) {

    }
    global Item(String sku, String name, Decimal price, Decimal qty, String description, Decimal discount) {

    }
    global Item(String sku, String name, Decimal price, Decimal qty, String description, Decimal discount, Object customFields) {

    }
    global Item(String sku, String name, Decimal price, Decimal qty, String description, Decimal discount, Decimal taxFirst, Decimal taxSecond, Object customFields) {

    }
    global Item(String id, String sku, String name, Decimal price, Decimal qty, String description, Decimal discount, Decimal taxFirst, Decimal taxSecond, Object customFields) {

    }
    global Item(String id, String sku, String name, Decimal price, Decimal qty, String description, Decimal discount, String discountFieldType, Decimal taxFirst, String firstTaxFieldType, Decimal taxSecond, String secondTaxFieldType, Object customFields) {

    }
    global static pandadoc.Item.ItemSettings getDefaultSettingForObject(String objectName) {
        return null;
    }
    global static pandadoc.Item.ItemSettings parseSettingsFromJson(String jsonData) {
        return null;
    }
    global static pandadoc.Item sObjectToItem(SObject sObj) {
        return null;
    }
global class ItemSettings extends pandadoc.MapperUtils.BaseMapperSettings {
    global String descriptionField {
        get;
        set;
    }
    global String discountField {
        get;
        set;
    }
    global String discountFieldType {
        get;
        set;
    }
    global String firstTaxField {
        get;
        set;
    }
    global String firstTaxFieldType {
        get;
        set;
    }
    global String nameField {
        get;
        set;
    }
    global String objectName {
        get;
        set;
    }
    global String priceField1 {
        get;
        set;
    }
    global String priceField2 {
        get;
        set;
    }
    global String quantityField {
        get;
        set;
    }
    global String secondTaxField {
        get;
        set;
    }
    global String secondTaxFieldType {
        get;
        set;
    }
    global String skuField {
        get;
        set;
    }
    global ItemSettings() {

    }
    global Set<String> getSoqlFields() {
        return null;
    }
    global Set<String> getTokenFields() {
        return null;
    }
}
}
