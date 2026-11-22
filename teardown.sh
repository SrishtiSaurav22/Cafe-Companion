#!/usr/bin/env bash
# Removes everything deploy.sh created, so nothing keeps billing.
set -euo pipefail
PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-asia-south1}"
SA_EMAIL="cafe-companion-run@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud run services delete cafe-companion --region "$REGION" --project "$PROJECT_ID" --quiet || true
# Container images built by source deploy live here
gcloud artifacts repositories delete cloud-run-source-deploy --location "$REGION" --project "$PROJECT_ID" --quiet || true
gcloud projects remove-iam-policy-binding "$PROJECT_ID" --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/aiplatform.user" --condition=None --quiet >/dev/null || true
gcloud iam service-accounts delete "$SA_EMAIL" --project "$PROJECT_ID" --quiet || true
echo "Done. (Simplest full cleanup: delete the whole project in the console.)"
