#!/bin/bash
set -euo pipefail

usage() {
  echo "Uso: $0 [dev|qua|pro]" >&2
  exit 1
}

ENVIRONMENT=${1:-}

if [[ -z "$ENVIRONMENT" ]]; then
  CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || true)
  case "$CURRENT_PROJECT" in
    platform-partners-des) ENVIRONMENT=dev ;;
    platform-partners-qua) ENVIRONMENT=qua ;;
    constant-height-455614-i0) ENVIRONMENT=pro ;;
    *) usage ;;
  esac
fi

case "$ENVIRONMENT" in
  dev)
    PROJECT_ID=platform-partners-des
    SERVICE_NAME=works-index-dev
    SERVICE_ACCOUNT=streamlit-bigquery-sa@platform-partners-des.iam.gserviceaccount.com
    ;;
  qua)
    PROJECT_ID=platform-partners-qua
    SERVICE_NAME=works-index-qua
    SERVICE_ACCOUNT=streamlit-bigquery-sa@platform-partners-qua.iam.gserviceaccount.com
    ;;
  pro)
    PROJECT_ID=constant-height-455614-i0
    SERVICE_NAME=works-index
    SERVICE_ACCOUNT=streamlit-bigquery-sa@constant-height-455614-i0.iam.gserviceaccount.com
    ;;
  *)
    usage
    ;;
esac

REGION=us-east1
PORT=${PORT:-8080}
IMAGE_TAG="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "${ENVIRONMENT^^} -> ${PROJECT_ID}/${SERVICE_NAME}"

gcloud config set project "$PROJECT_ID" >/dev/null

gcloud builds submit --tag "$IMAGE_TAG"

RUN_FLAGS=(--region "$REGION" --project "$PROJECT_ID")
SERVICE_FLAGS=(--service-account "$SERVICE_ACCOUNT" --memory 2Gi --cpu 2 --timeout 300 --max-instances 10 --min-instances 0 --concurrency 80 --port "$PORT")

if gcloud run services describe "$SERVICE_NAME" "${RUN_FLAGS[@]}" >/dev/null 2>&1; then
  gcloud run services update "$SERVICE_NAME" --image "$IMAGE_TAG" "${RUN_FLAGS[@]}" "${SERVICE_FLAGS[@]}"
else
  gcloud run deploy "$SERVICE_NAME" --image "$IMAGE_TAG" --platform managed --allow-unauthenticated "${RUN_FLAGS[@]}" "${SERVICE_FLAGS[@]}"
fi   