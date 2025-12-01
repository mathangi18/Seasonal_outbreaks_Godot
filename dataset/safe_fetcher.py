#!/usr/bin/env python3
"""
safe_fetcher.py

Usage:
  python safe_fetcher.py urls.txt
or
  python safe_fetcher.py urls.txt D:\seasonal_outbreak_assets\raw_downloads

urls.txt should contain one URL per line (http/https).
This script:
 - checks robots.txt for the domain (refuses if disallowed)
 - does HEAD to check content-type (PDF/CSV)
 - downloads files with 2 retries
 - writes a simple log file in the target folder
"""

import sys
import os
import time
from urllib.parse import urlparse, urljoin
from urllib.robotparser import RobotFileParser
import requests

RETRIES = 2
TIMEOUT = 20  # seconds
ALLOWED_CT = ("application/pdf", "text/csv", "application/csv", "application/octet-stream")

def can_fetch_url(url, user_agent="*"):
    parsed = urlparse(url)
    robots_url = urljoin(f"{parsed.scheme}://{parsed.netloc}", "/robots.txt")
    rp = RobotFileParser()
    try:
        rp.set_url(robots_url)
        rp.read()
    except Exception as e:
        print(f"[WARN] couldn't read robots.txt at {robots_url}: {e} — proceeding cautiously")
        return True  # proceed if robots.txt not available
    return rp.can_fetch(user_agent, url)

def head_content_type(url):
    try:
        resp = requests.head(url, allow_redirects=True, timeout=TIMEOUT)
        ct = resp.headers.get("Content-Type", "").split(";")[0].lower()
        return ct, resp.status_code
    except Exception as e:
        return None, None

def download_file(url, target_folder):
    safe_name = url.split("/")[-1].split("?")[0] or "download"
    out_path = os.path.join(target_folder, safe_name)
    attempt = 0
    while attempt <= RETRIES:
        try:
            print(f"[INFO] downloading ({attempt+1}/{RETRIES+1}): {url}")
            with requests.get(url, stream=True, timeout=TIMEOUT) as r:
                r.raise_for_status()
                with open(out_path, "wb") as f:
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
            size = os.path.getsize(out_path)
            if size < 512:  # very small suspicious file
                print(f"[WARN] downloaded file is very small ({size} bytes): {out_path}")
            print(f"[OK] saved -> {out_path} ({size} bytes)")
            return True, out_path
        except Exception as e:
            print(f"[ERROR] download failed: {e}")
            attempt += 1
            time.sleep(1)
    print(f"[FAIL] giving up on {url}")
    return False, None

def main():
    if len(sys.argv) < 2:
        print("Usage: python safe_fetcher.py urls.txt [target_folder]")
        sys.exit(1)
    urls_file = sys.argv[1]
    target_folder = sys.argv[2] if len(sys.argv) > 2 else r"D:\seasonal_outbreak_assets\raw_downloads"
    os.makedirs(target_folder, exist_ok=True)
    with open(urls_file, "r", encoding="utf-8") as f:
        urls = [line.strip() for line in f if line.strip() and not line.startswith("#")]

    log_lines = []
    for url in urls:
        print("\n---")
        log = {"url": url, "status": "skipped", "note": None, "file": None}
        # check robots
        allowed = can_fetch_url(url, user_agent="*")
        if not allowed:
            log["note"] = "disallowed by robots.txt"
            print(f"[SKIP] robots.txt disallows fetching: {url}")
            log_lines.append(log)
            continue

        # HEAD check
        ct, status = head_content_type(url)
        print(f"[HEAD] status={status} content-type={ct}")
        if ct is None:
            log["note"] = "HEAD_failed"
            print(f"[WARN] HEAD failed, attempting GET test")
            # proceed cautiously to GET attempt
        else:
            if ct.startswith("text/html"):
                log["note"] = f"html_page ({ct})"
                print(f"[SKIP] URL appears to be an HTML page; skip downloading raw HTML: {url}")
                log_lines.append(log)
                continue
            # allow PDF and CSV and octet-stream
            if not any(ct.startswith(a) for a in ALLOWED_CT):
                print(f"[WARN] content-type {ct} not clearly allowed; proceeding but you might review")
        # attempt download
        ok, path = download_file(url, target_folder)
        if ok:
            log["status"] = "downloaded"
            log["file"] = path
        else:
            log["status"] = "failed"
        log_lines.append(log)

    # write log
    import json
    log_path = os.path.join(target_folder, "fetch_log.json")
    with open(log_path, "w", encoding="utf-8") as lf:
        json.dump(log_lines, lf, indent=2)
    print(f"\nDone. Fetch log: {log_path}")
    print(f"Downloaded files are in: {target_folder}")

if __name__ == "__main__":
    main()
