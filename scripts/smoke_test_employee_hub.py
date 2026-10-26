#!/usr/bin/env python3
"""Read-only staging smoke test for an authenticated ERPNext Employee account.

Set ERPNEXT_BASE_URL, ERPNEXT_USER and ERPNEXT_PASSWORD in the shell environment.
This script creates no business records.
"""
import os
import sys
from urllib.parse import urlparse

import requests


def main():
    base = (os.environ.get("ERPNEXT_BASE_URL") or "").rstrip("/")
    username = os.environ.get("ERPNEXT_USER") or ""
    password = os.environ.get("ERPNEXT_PASSWORD") or ""
    if not base or not username or not password:
        print("Set ERPNEXT_BASE_URL, ERPNEXT_USER and ERPNEXT_PASSWORD.", file=sys.stderr)
        return 2
    parsed = urlparse(base)
    if parsed.scheme != "https" and parsed.hostname not in {"localhost", "127.0.0.1"}:
        print("Use HTTPS for non-local ERPNext sites.", file=sys.stderr)
        return 2

    session = requests.Session()
    login = session.post(base + "/api/method/login", data={"usr": username, "pwd": password}, timeout=20)
    if not login.ok:
        print(f"Login failed with HTTP {login.status_code}.", file=sys.stderr)
        return 1
    login_data = login.json()
    if login_data.get("exc"):
        print("ERPNext rejected the supplied credentials.", file=sys.stderr)
        return 1

    csrf = login_data.get("csrf_token") or session.cookies.get("csrf_token")
    if not csrf:
        try:
            response = session.get(base + "/api/method/frappe.sessions.get_csrf_token", timeout=10)
            if response.ok:
                csrf = response.json().get("message")
        except requests.RequestException:
            csrf = None
    headers = {"X-Frappe-CSRF-Token": csrf} if csrf else {}
    endpoints = [
        "get_dashboard",
        "get_feed",
        "get_my_eod_reports",
        "get_employee_directory",
        "get_employee_workspace",
        "get_attendance_history",
        "get_my_leave_applications",
        "get_my_tasks",
        "get_document_requests",
    ]
    failed = 0
    for endpoint in endpoints:
        try:
            response = session.post(
                base + "/api/method/alienhouse_employee_hub.api." + endpoint,
                headers=headers,
                timeout=20,
            )
            body = response.json()
            if not response.ok or body.get("exc"):
                failed += 1
                print(f"FAIL {endpoint}: HTTP {response.status_code} or API exception")
            else:
                print(f"PASS {endpoint}")
        except (requests.RequestException, ValueError):
            failed += 1
            print(f"FAIL {endpoint}: request/JSON error")
    print(f"\nSmoke test result: {len(endpoints) - failed}/{len(endpoints)} endpoints passed.")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
