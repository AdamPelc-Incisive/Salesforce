/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class DeduplicateDocumentsBatch implements Database.Batchable<SObject>, System.Schedulable {
    global static String JOB_NAME;
    global static String SETTING_CRON_STRING;
    global static String SETTING_SCOPE_SIZE;
    global DeduplicateDocumentsBatch(Boolean processAllDocuments) {

    }
    global void execute(System.SchedulableContext context) {

    }
    global static void executeBatch(Boolean processAllDocuments) {

    }
    global void execute(Database.BatchableContext bc, List<pandadoc__PandaDocDocument__c> scope) {

    }
    global void finish(Database.BatchableContext bc) {

    }
    global static void scheduleDailyRun() {

    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
}
