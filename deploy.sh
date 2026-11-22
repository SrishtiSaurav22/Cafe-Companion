#!/usr/bin/env bash
# Deploys Café Companion to Cloud Run. Safe to re-run.
# Usage (in Cloud Shell, inside this folder):  bash deploy.sh            # uses current gcloud project
#                                              bash deploy.sh MY_PROJECT # or pass a project ID
set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-asia-south1}"            # Mumbai. Gemini itself is called via the "global" endpoint.
SERVICE="cafe-companion"
SA_NAME="cafe-companion-run"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
MODEL="${GEMINI_MODEL:-gemini-3.5-flash}"

if [[ -z "$PROJECT_ID" ]]; then
  echo "No project set. Run: gcloud config set project YOUR_PROJECT_ID"; exit 1
fi
echo "==> Project: $PROJECT_ID | Region: $REGION | Model: $MODEL"

# Point gcloud at the project
gcloud config set project "$PROJECT_ID" --quiet

# Turn on the APIs we use: Cloud Run, Cloud Build, Artifact Registry, Vertex AI (Gemini)
gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com aiplatform.googleapis.com

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"

# Dedicated runtime identity for the app (not the default compute account)
if ! gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" --display-name="Café Companion runtime"
fi

# Least privilege: the app may only call Gemini
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" --role="roles/aiplatform.user" --condition=None --quiet >/dev/null

# Source deploys build with the Compute Engine default account; it needs the Cloud Run Builder role
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/run.builder" --condition=None --quiet >/dev/null

echo "==> Waiting 45s for permissions to propagate…"
sleep 45

# Build the Dockerfile with Cloud Build and deploy. Scales to zero; max 1 instance keeps cost and the demo queue in check.
gcloud run deploy "$SERVICE" \
  --source . \
  --region "$REGION" \
  --service-account "$SA_EMAIL" \
  --allow-unauthenticated \
  --min-instances 0 \
  --max-instances 1 \
  --memory 512Mi \
  --set-env-vars "GOOGLE_CLOUD_PROJECT=${PROJECT_ID},GOOGLE_CLOUD_LOCATION=global,GEMINI_MODEL=${MODEL}" \
  --quiet

URL="$(gcloud run services describe "$SERVICE" --region "$REGION" --format='value(status.url)')"
echo
echo "==> Live!"
echo "    Customer app: $URL"
echo "    Staff board:  $URL/staff"
