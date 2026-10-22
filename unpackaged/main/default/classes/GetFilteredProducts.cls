public class GetFilteredProducts {

    public class Request {
        @InvocableVariable(label='Product Ids' description='Collection of Product Ids to filter by')
        public List<Id> productIdList;

        @InvocableVariable(label='Product Family' description='Semicolon-delimited Product Family values from multi-select picklist')
        public String productFamily;

        @InvocableVariable(label='Include Inactive' description='If true, returns both active and inactive products. If false or null, returns only active products.')
        public Boolean includeInactive;
    }

    public class Result {
        @InvocableVariable(label='Filtered Products')
        public List<Product2> products;
    }

    @InvocableMethod(label='Get Filtered Products' category='Lock 8 Actions' description='Dynamically queries Products based on optional filter criteria.')
    public static List<Result> getProducts(List<Request> requests) {
        Request req = requests[0];

        // Build field list dynamically, excluding heavy field types
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Product2.fields.getMap();
        List<String> fields = new List<String>();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DisplayType fieldType = fieldMap.get(fieldName).getDescribe().getType();
            if (fieldType != Schema.DisplayType.TEXTAREA && fieldType != Schema.DisplayType.BASE64) {
                fields.add(fieldName);
            }
        }

        // Build dynamic query with conditional WHERE clauses
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Product2';
        List<String> conditions = new List<String>();

        List<String> productFamilyList = new List<String>();

        if (req.productIdList != null && !req.productIdList.isEmpty()) {
            conditions.add('Id IN :productIdList');
        }
        if (String.isNotBlank(req.productFamily)) {
            productFamilyList = req.productFamily.split(';');
            conditions.add('Family IN :productFamilyList');
        }
        if (req.includeInactive == null || !req.includeInactive) {
            conditions.add('IsActive = true');
        }

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        query += ' ORDER BY Name ASC LIMIT 2000';

        // Bind variables must be in scope for dynamic SOQL
        List<Id> productIdList = req.productIdList;

        Result res = new Result();
        res.products = Database.query(query);
        return new List<Result>{ res };
    }
}