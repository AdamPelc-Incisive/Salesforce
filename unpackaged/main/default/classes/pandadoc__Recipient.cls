/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class Recipient {
    global static Map<String,pandadoc.Recipient.RecipientSettings> RECIPIENT_SETTINGS_MAP {
        get;
        set;
    }
    global Recipient(pandadoc.Recipient.RecipientSettings settings, SObject sObj) {

    }
    global Recipient(String first_name, String last_name, String email, String company, String roleName) {

    }
    global Recipient(String first_name, String last_name, String email, String company, String roleName, String phone, String title, String country, String state, String street_address, String city, String postal_code) {

    }
    global static pandadoc.Recipient.RecipientSettings getDefaultSettingForObject(String objectName) {
        return null;
    }
    global Boolean isShouldBeFiltered() {
        return null;
    }
    global Boolean isValid() {
        return null;
    }
    global static pandadoc.Recipient.RecipientSettings parseSettingsFromJson(String jsonData) {
        return null;
    }
    global static pandadoc.Recipient sObjectToRecipient(SObject sObj) {
        return null;
    }
    global Map<String,Object> toJson() {
        return null;
    }
global class RecipientSettings extends pandadoc.MapperUtils.BaseMapperSettings {
    global String cityField {
        get;
        set;
    }
    global String companyField {
        get;
        set;
    }
    global String countryField {
        get;
        set;
    }
    global String emailField {
        get;
        set;
    }
    global Boolean filterIfChecked {
        get;
        set;
    }
    global String filteringField {
        get;
        set;
    }
    global String firstNameField {
        get;
        set;
    }
    global String lastNameField {
        get;
        set;
    }
    global String objectName {
        get;
        set;
    }
    global String phoneField {
        get;
        set;
    }
    global String postalCodeField {
        get;
        set;
    }
    global String roleField {
        get;
        set;
    }
    global String stateField {
        get;
        set;
    }
    global String streetAddressField {
        get;
        set;
    }
    global String titleField {
        get;
        set;
    }
    global RecipientSettings() {

    }
    global Set<String> getSoqlFields() {
        return null;
    }
}
}
