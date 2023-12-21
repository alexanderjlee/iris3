#!/usr/bin/env bash

#set -x
set -u
set -e

SCHEDULELABELING_TOPIC=iris_schedulelabeling_topic
DEADLETTER_TOPIC=iris_deadletter_topic
DEADLETTER_SUB=iris_deadletter
DO_LABEL_SUBSCRIPTION=do_label
LABEL_ONE_SUBSCRIPTION=label_one

project_number=$(gcloud projects describe $PROJECT_ID --format json|jq -r '.projectNumber')
PUBSUB_SERVICE_ACCOUNT="service-${project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"

gcloud pubsub topics remove-iam-policy-binding $DEADLETTER_TOPIC \
        --member="serviceAccount:$PUBSUB_SERVICE_ACCOUNT"\
         --role="roles/pubsub.publisher" --project $PROJECT_ID >/dev/null || true

gcloud pubsub subscriptions remove-iam-policy-binding $DO_LABEL_SUBSCRIPTION \
    --member="serviceAccount:$PUBSUB_SERVICE_ACCOUNT"\
    --role="roles/pubsub.subscriber" --project $PROJECT_ID || true

gcloud pubsub subscriptions remove-iam-policy-binding $LABEL_ONE_SUBSCRIPTION \
      --member="serviceAccount:$PUBSUB_SERVICE_ACCOUNT"\
      --role="roles/pubsub.subscriber" --project $PROJECT_ID ||true

gcloud pubsub subscriptions delete $DEADLETTER_SUB --project="$PROJECT_ID" -q || true
gcloud pubsub subscriptions delete "$DO_LABEL_SUBSCRIPTION" -q --project="$PROJECT_ID" ||true
gcloud pubsub subscriptions delete "$LABEL_ONE_SUBSCRIPTION" --project="$PROJECT_ID" 2>/dev/null || true

gcloud pubsub topics delete "$SCHEDULELABELING_TOPIC" --project="$PROJECT_ID" -q ||true
gcloud pubsub topics delete "$DEADLETTER_TOPIC" --project="$PROJECT_ID" -q || true
gcloud pubsub topics delete "$LOGS_TOPIC" --project="$PROJECT_ID" 2>/dev/null || true

gcloud app services delete --project $PROJECT_ID -q iris3  ||true

pushd ./uninstall_scripts
  # Need to have a blank-config file with the name cron.yaml, so need to cd to this dir
  gcloud app deploy -q cron.yaml -q --project $PROJECT_ID  || true
popd



