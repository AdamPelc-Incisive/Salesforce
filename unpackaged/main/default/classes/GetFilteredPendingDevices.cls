public class GetFilteredPendingDevices {

    public class Request {
        @InvocableVariable(label='Account Ids' description='Collection of Account Ids - matches both Practice_Account__c and Corporate_Account__c')
        public List<Id> accountIdList;

        @InvocableVariable(label='Product Ids' description='Collection of Product Ids to filter by (matched via Opportunity Product)')
        public List<Id> productIdList;

        @InvocableVariable(label='Product Family' description='Semicolon-delimited Product Family values from multi-select picklist')
        public String productFamily;

        @InvocableVariable(label='Statuses' description='Semicolon-delimited Status values to filter by. Defaults to Ordered if blank.')
        public String statuses;
    }

    public class Result {
        @InvocableVariable(label='Filtered Pending Devices')
        public List<Pending_Device__c> pendingDevices;
    }

    @InvocableMethod(label='Get Filtered Pending Devices' category='Lock 8 Actions' description='Dynamically queries Pending Devices based on optional filter criteria.')
    public static List<Result> getPendingDevices(List<Request> requests) {
        Request req = requests[0];

        // Build field list dynamically, excluding heavy field types
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Pending_Device__c.fields.getMap();
        List<String> fields = new List<String>();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DisplayType fieldType = fieldMap.get(fieldName).getDescribe().getType();
            if (fieldType != Schema.DisplayType.TEXTAREA && fieldType != Schema.DisplayType.BASE64) {
                fields.add(fieldName);
            }
        }

        // Add relationship fields for display purposes
        fields.add('Opportunity_Product__r.Product2.Name');
        fields.add('Opportunity_Product__r.Product2.Family');
        fields.add('Practice_Account__r.Name');
        fields.add('Corporate_Account__r.Name');

        // Build dynamic query with conditional WHERE clauses
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Pending_Device__c';
        List<String> conditions = new List<String>();

        List<String> productFamilyList = new List<String>();

        // Status filter -- defaults to Ordered if blank
        List<String> statusList = String.isNotBlank(req.statuses)
            ? req.statuses.split(';')
            : new List<String>{ 'Ordered' };
        conditions.add('Status__c IN :statusList');

        if (req.accountIdList != null && !req.accountIdList.isEmpty()) {
            conditions.add('(Practice_Account__c IN :accountIdList OR Corporate_Account__c IN :accountIdList)');
        }
        if (req.productIdList != null && !req.productIdList.isEmpty()) {
            conditions.add('Opportunity_Product__r.Product2Id IN :productIdList');
        }
        if (String.isNotBlank(req.productFamily)) {
            productFamilyList = req.productFamily.split(';');
            conditions.add('Opportunity_Product__r.Product2.Family IN :productFamilyList');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        query += ' ORDER BY Name ASC LIMIT 2000';

        // Bind variables must be in scope for dynamic SOQL
        List<Id> accountIdList = req.accountIdList;
        List<Id> productIdList = req.productIdList;

        Result res = new Result();
        res.pendingDevices = Database.query(query);
        return new List<Result>{ res };
    }
}