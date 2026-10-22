public class GetFilteredAssets {

    public class Request {
        @InvocableVariable(label='Asset Status' description='Semicolon-delimited status values from multi-select picklist')
        public String status;

        @InvocableVariable(label='Account Ids' description='Collection of Account Ids - matches both AccountId and Corporate_Parent__c')
        public List<Id> accountIdList;

        @InvocableVariable(label='Product Family' description='Semicolon-delimited Product Family values from multi-select picklist')
        public String productFamily;

        @InvocableVariable(label='Product Ids' description='Collection of Product Ids to filter by')
        public List<Id> productIdList;
    }

    public class Result {
        @InvocableVariable(label='Filtered Assets')
        public List<Asset> assets;
    }

    @InvocableMethod(label='Get Filtered Assets' category='Lock 8 Actions' description='Dynamically queries Assets based on optional filter criteria.')
    public static List<Result> getAssets(List<Request> requests) {
        Request req = requests[0];

        // Build field list dynamically, excluding heavy field types
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Asset.fields.getMap();
        List<String> fields = new List<String>();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DisplayType fieldType = fieldMap.get(fieldName).getDescribe().getType();
            if (fieldType != Schema.DisplayType.TEXTAREA && fieldType != Schema.DisplayType.BASE64) {
                fields.add(fieldName);
            }
        }

        // Add relationship fields for display purposes
        fields.add('Product2.Name');
        fields.add('Product2.Family');

        // Build dynamic query with conditional WHERE clauses
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Asset';
        List<String> conditions = new List<String>();

        // Parse semicolon-delimited picklist strings into lists
        List<String> statusList = new List<String>();
        List<String> productFamilyList = new List<String>();

        if (String.isNotBlank(req.status)) {
            statusList = req.status.split(';');
            conditions.add('Status IN :statusList');
        }
        if (req.accountIdList != null && !req.accountIdList.isEmpty()) {
            conditions.add('(AccountId IN :accountIdList OR Corporate_Parent__c IN :accountIdList)');
        }
        if (String.isNotBlank(req.productFamily)) {
            productFamilyList = req.productFamily.split(';');
            conditions.add('Product2.Family IN :productFamilyList');
        }
        if (req.productIdList != null && !req.productIdList.isEmpty()) {
            conditions.add('Product2Id IN :productIdList');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        query += ' ORDER BY Name ASC LIMIT 2000';

        // Bind variables must be in scope for dynamic SOQL
        List<Id> accountIdList = req.accountIdList;
        List<Id> productIdList = req.productIdList;

        Result res = new Result();
        res.assets = Database.query(query);
        return new List<Result>{ res };
    }
}