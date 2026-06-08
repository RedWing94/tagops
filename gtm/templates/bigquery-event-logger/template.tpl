___INFO___

{
  "type": "TAG",
  "id": "cvt_tagops_bq_event_logger",
  "version": 1,
  "securityGroups": [],
  "displayName": "BigQuery Event Logger",
  "categories": ["ANALYTICS"],
  "brand": {
    "id": "tagops",
    "displayName": "TagOps"
  },
  "description": "Logs all incoming sGTM events to a BigQuery table via streaming insert. Uses getAllEventData() and adds a server-side timestamp.",
  "containerContexts": ["SERVER"]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "projectId",
    "displayName": "GCP Project ID",
    "simpleValueType": true,
    "defaultValue": "tagops-498522",
    "valueValidators": [{ "type": "NON_EMPTY" }],
    "help": "The Google Cloud project that contains the BigQuery dataset."
  },
  {
    "type": "TEXT",
    "name": "datasetId",
    "displayName": "BigQuery Dataset ID",
    "simpleValueType": true,
    "defaultValue": "tagops_analytics",
    "valueValidators": [{ "type": "NON_EMPTY" }],
    "help": "The BigQuery dataset to write events into."
  },
  {
    "type": "TEXT",
    "name": "tableId",
    "displayName": "BigQuery Table ID",
    "simpleValueType": true,
    "defaultValue": "events",
    "valueValidators": [{ "type": "NON_EMPTY" }],
    "help": "The BigQuery table to write rows into. Created automatically on first insert if it does not exist."
  }
]


___SANDBOXED_JS_FOR_SERVER___

const BigQuery = require('BigQuery');
const getAllEventData = require('getAllEventData');
const getTimestampMillis = require('getTimestampMillis');
const isConsentGranted = require('isConsentGranted');
const JSON = require('JSON');
const logToConsole = require('logToConsole');

// Consent gate: only write to BigQuery when analytics_storage consent is
// granted. The consent default (granted vs denied) is set per the client's
// policy profile (see policies/*.yml). If consent has not been granted,
// the tag succeeds silently without writing a row.
if (!isConsentGranted('analytics_storage')) {
  logToConsole('BigQuery Event Logger: skipped — analytics_storage not granted');
  data.gtmOnSuccess();
  return;
}

const eventData = getAllEventData();

const row = {
  event_name: eventData.event_name,
  event_timestamp: getTimestampMillis(),
  client_id: eventData.client_id,
  page_location: eventData.page_location,
  page_referrer: eventData.page_referrer,
  page_title: eventData.page_title,
  user_agent: eventData.user_agent,
  ip_override: eventData.ip_override,
  event_data: JSON.stringify(eventData)
};

const connectionInfo = {
  projectId: 'tagops-498522',
  datasetId: 'tagops_analytics',
  tableId: 'events'
};

BigQuery.insert(connectionInfo, [row], {ignoreUnknownValues: true, skipInvalidRows: false})
  .then(() => {
    logToConsole('BigQuery insert OK: ' + eventData.event_name);
    data.gtmOnSuccess();
  }, (err) => {
    logToConsole('BigQuery insert FAILED: ' + JSON.stringify(err));
    data.gtmOnFailure();
  });


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_bigquery",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedTables",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "projectId" },
                  { "type": 1, "string": "datasetId" },
                  { "type": 1, "string": "tableId" },
                  { "type": 1, "string": "operation" }
                ],
                "mapValue": [
                  { "type": 1, "string": "tagops-498522" },
                  { "type": 1, "string": "tagops_analytics" },
                  { "type": 1, "string": "events" },
                  { "type": 1, "string": "write" }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": { "type": 1, "string": "any" }
        }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  { "type": 1, "string": "consentType" },
                  { "type": 1, "string": "read" },
                  { "type": 1, "string": "write" }
                ],
                "mapValue": [
                  { "type": 1, "string": "analytics_storage" },
                  { "type": 8, "boolean": true },
                  { "type": 8, "boolean": false }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": { "type": 1, "string": "debug" }
        }
      ]
    },
    "clientAnnotations": { "isEditedByUser": true },
    "isRequired": true
  }
]


___TESTS___

[]
