#!/usr/bin/env python3
"""
gemini-intake: monitors Google Drive root for Gemini chat exports,
downloads all Google Docs from root to ~/inbox/gemini/.

Convention: the Drive root is kept clean and contains only Gemini chat
exports. All other documents have been moved to subfolders. No content
detection is performed; every document in root is downloaded.
"""

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import google_auth_httplib2
import httplib2
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]
CONFIG_DIR = Path.home() / ".config" / "gemini-intake"
CREDENTIALS_FILE = CONFIG_DIR / "credentials.json"
TOKEN_FILE = CONFIG_DIR / "token.json"
PROCESSED_FILE = CONFIG_DIR / "processed.json"
INBOX_DIR = Path.home() / "inbox" / "gemini"
REQUEST_TIMEOUT_SECONDS = 300


def get_credentials():
    creds = None
    if TOKEN_FILE.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_FILE), SCOPES
            )
            creds = flow.run_local_server(port=8085, open_browser=False)
        TOKEN_FILE.write_text(creds.to_json())
    return creds


def load_processed():
    if PROCESSED_FILE.exists():
        return json.loads(PROCESSED_FILE.read_text())
    return {}


def save_processed(processed):
    PROCESSED_FILE.write_text(json.dumps(processed, indent=2))


def export_as_markdown(service, file_id):
    """Export Google Doc as Markdown text."""
    try:
        content = (
            service.files()
            .export(fileId=file_id, mimeType="text/markdown")
            .execute()
        )
    except Exception as e:
        # Fallback to plain text if markdown export fails or times out
        print(f"  Warning: markdown export failed ({type(e).__name__}: {e}), falling back to text/plain...", file=sys.stderr)
        content = (
            service.files()
            .export(fileId=file_id, mimeType="text/plain")
            .execute()
        )
    if isinstance(content, bytes):
        content = content.decode("utf-8", errors="replace")
    return content


def safe_filename(name):
    """Convert a Google Doc title to a safe filename."""
    name = re.sub(r"[^\w\s\-.]", "", name)
    name = re.sub(r"\s+", "-", name.strip())
    return name[:120] + ".md"


def main():
    if not CREDENTIALS_FILE.exists():
        print(f"ERROR: credentials.json not found at {CREDENTIALS_FILE}")
        sys.exit(1)

    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    creds = get_credentials()
    http = httplib2.Http(timeout=REQUEST_TIMEOUT_SECONDS)
    auth_http = google_auth_httplib2.AuthorizedHttp(creds, http=http)
    service = build("drive", "v3", http=auth_http)
    processed = load_processed()

    results = (
        service.files()
        .list(
            q="mimeType='application/vnd.google-apps.document' and 'root' in parents and trashed=false",
            fields="files(id, name, modifiedTime, createdTime)",
            orderBy="createdTime desc",
            pageSize=50,
        )
        .execute()
    )

    files = results.get("files", [])
    new_count = 0
    skipped_count = 0

    for f in files:
        file_id = f["id"]
        name = f["name"]

        if file_id in processed and processed[file_id].get("status") == "downloaded":
            skipped_count += 1
            continue

        try:
            print(f"Downloading: {name} ...")
            content = export_as_markdown(service, file_id)
            filename = safe_filename(name)
            output_path = INBOX_DIR / filename

            counter = 1
            while output_path.exists():
                stem = safe_filename(name).replace(".md", "")
                output_path = INBOX_DIR / f"{stem}-{counter}.md"
                counter += 1

            output_path.write_text(content, encoding="utf-8")
            print(f"  -> saved to {output_path}")

            processed[file_id] = {
                "name": name,
                "status": "downloaded",
                "output": str(output_path),
                "downloaded_at": datetime.now(timezone.utc).isoformat(),
            }
            save_processed(processed)
            new_count += 1
        except Exception as e:
            print(f"  ERROR: Failed to download {name} ({file_id}): {e}", file=sys.stderr)

    print(f"\nDone. {new_count} new Gemini exports downloaded, {skipped_count} already processed.")


if __name__ == "__main__":
    main()
