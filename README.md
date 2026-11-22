# Café Companion (Brew & Bloom)

An AI ordering assistant for a café, built for the Google Cloud Builder Pop-Up "Café Companion" challenge.

**Challenge themes covered**
- **Smarter Ordering**: chat to build your order ("something cold, vegan, under ₹250"). Gemini recommends items from the menu and updates the cart.
- **Discovery**: recommendations respect preferences, allergens (from the menu's `contains` field), caffeine and budget.
- **Better Waits**: live "quiet / steady / busy" wait estimate in the header and a per-order countdown based on the order queue.
- **For café teams**: a `/staff` board shows incoming orders and has a "Mark ready" button.

**Google tech**: Cloud Run (hosting, scales to zero), Cloud Build + Artifact Registry (build), Gemini 3.5 Flash on Vertex AI / Gemini Enterprise Agent Platform (AI), IAM service account (security).

## Architecture
```
Browser ──> Cloud Run (FastAPI: UI + /api) ──> Gemini 3.5 Flash (Vertex AI, global endpoint)
                    │
                    └── in-memory order queue (demo only, max 1 instance)
```
- Gemini returns **structured JSON** (`reply`, `cart`, `suggested_replies`). The server drops unknown items, caps quantities and computes prices from `menu.json`, so the model can't invent items or change prices.
- Orders are only placed when the customer presses **Place order** and confirms. The AI cannot place orders.
- The app runs as a dedicated service account with only `roles/aiplatform.user`. There are no API keys or secrets.

## Deploy (Cloud Shell)
1. Open https://console.cloud.google.com, select or create a project with billing linked.
2. Click the Cloud Shell icon (`>_`, top right). Use the ⋮ menu → **Upload** to upload `cafe-companion.zip`.
3. Run:
   ```bash
   unzip cafe-companion.zip && cd cafe-companion
   gcloud config set project YOUR_PROJECT_ID
   bash deploy.sh
   ```
4. Open the printed URL. The staff board is at `URL/staff`.

Change region: `REGION=us-central1 bash deploy.sh`. Change model: `GEMINI_MODEL=... bash deploy.sh`.

## Run locally (optional)
```bash
pip install -r requirements.txt
gcloud auth application-default login
GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID uvicorn main:app --reload --port 8080
```

## Cost
Cloud Run scales to zero and is within the free tier for a demo. Gemini Flash costs fractions of a cent per chat turn. Expected: well under $1 for the event. Set a budget alert under Billing → Budgets & alerts.

## Clean up
`bash teardown.sh`, or delete the project.

## Limitations (demo scope)
- The order queue is held in memory, so it resets when the instance restarts or scales to zero. Next step: Firestore.
- The staff board has no login. Next step: Firebase Auth or IAP.
- No payments: customers pay at the counter.
