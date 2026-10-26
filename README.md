# AlienHouse Employee Hub

An ERPNext/Frappe-backed employee operations app with a responsive React web client and Flutter mobile client.

## Implemented modules

- **Team feed:** company updates, questions, recognition and announcements.
- **EOD reporting:** daily submissions, history, HR review statuses and review queue.
- **Employee directory:** search/listing and HR-controlled employee create/update API.
- **Attendance:** employee self-service IN/OUT events via ERPNext Employee Checkin, plus Attendance and check-in history.
- **Leave:** leave application submission and HR review endpoint.
- **Tasks:** create/assign tasks, list assigned/open tasks and update task status.
- **Documents:** employee document requests, HR status updates and attachment reference.
- **AI work assistant:** configured OpenAI-compatible chat-completions endpoint with a drafting agent and independent safety/evidence review agent; returns NOT_CONFIGURED rather than fabricating an answer and marks output for human review.
- **WhatsApp Business:** outbound Cloud API text messages by Employee record; signed webhook verification; incoming messages persisted to an HR inbox and matched against active Employee cell numbers; unmatched numbers are flagged for manual review. Configure a currently supported Meta Graph API version.
- **Dashboards:** user-level activity counts (not misleading company-wide totals).

This is an employee operations foundation built on ERPNext's existing Employee, Employee Checkin, Attendance, Leave Application, Task, ToDo and File records. It is not a replacement for ERPNext payroll, statutory compliance, a full document-template engine, or a complete autonomous HR platform.

## Repository layout

- `alienhouse_employee_hub/`: custom Frappe app, APIs, DocTypes and tests.
- `web/`: React + TypeScript + Vite.
- `mobile/employee_hub_app/`: Flutter client with committed Android and iOS platform runners.
- `erpnext-develop/`: vendored upstream ERPNext source snapshot for inspection/reference; it is not a Frappe bench, is not installed by the custom app, and should not be edited to add Employee Hub features. Keep Employee Hub in the custom app so upstream upgrades remain manageable.
- `docs/ERPNext_HRMS_INTEGRATION.md`: native DocType ownership, dependency requirements and staging integration gates.
- `.github/workflows/employee-hub-ci.yml`: web, Flutter and Python syntax CI.

## Install on a staging ERPNext bench

Use a clean, supported Frappe + ERPNext + HRMS bench and a dedicated test site. The checked-in `erpnext-develop/` directory is an upstream source snapshot, not a running installation and not the installed app root. The custom Frappe app lives at the repository root. `hooks.py` declares `erpnext` and `hrms` as required apps so an incomplete bench fails fast. Review [the integration guide](docs/ERPNext_HRMS_INTEGRATION.md) before installing.

```bash
bench get-app https://github.com/alienhousenetworks/employee-managemnt.git --branch feat/employee-hub-backend-frontend-flutter
bench --site your-staging-site list-apps  # verify frappe, erpnext and hrms are installed first
bench --site your-staging-site install-app alienhouse_employee_hub
bench --site your-staging-site migrate
bench build
bench --site your-staging-site run-tests --app alienhouse_employee_hub
```

If your bench already has this repository checked out as an app, do not install it twice. Back up the site and database before migrations. Confirm the app's DocTypes and role permissions after migrate.

## Web client

```bash
cd web
cp .env.example .env.local
# Set VITE_FRAPPE_URL to the HTTPS ERPNext origin in .env.local
npm install
npm run build
npm run dev
```

The client uses the ERPNext session cookie. For reliable CSRF/session behavior, preferably serve the web client behind the same HTTPS origin/reverse proxy as ERPNext. If using a separate origin, configure explicit CORS credentials, cookie SameSite/Secure policy and the Frappe CSRF token flow; do not use wildcard CORS with credentials.

## Flutter client

```bash
cd mobile/employee_hub_app
flutter create . --platforms=android,ios
flutter pub get
dart format lib
flutter analyze
flutter test
flutter run
```

Android and iOS runner files are committed. Before release, replace the example application ID, configure signing, app icons, secure session storage, privacy disclosures and platform permissions. Android debug APK builds are exercised in CI; iOS compilation/signing still requires a macOS runner. The current client holds the session cookie in memory and only saves site URL/username preferences; verify session expiry and logout behavior on target devices.

## Configure AI and WhatsApp on the server

Do not commit tokens or provider secrets. Configure these objects in the private site configuration (for example the site-specific `site_config.json`) and restart workers/web processes after changes.

AI example (OpenAI-compatible chat-completions endpoint):

```json
{
  "employee_hub_ai": {
    "endpoint": "https://YOUR-APPROVED-PROVIDER/v1/chat/completions",
    "model": "YOUR-APPROVED-MODEL",
    "api_key": "SET-SECRET-OUTSIDE-GIT"
  }
}
```

WhatsApp Cloud API example:

```json
{
  "employee_hub_whatsapp": {
    "phone_number_id": "YOUR-META-PHONE-NUMBER-ID",
    "graph_api_version": "v23.0",
    "access_token": "SET-SECRET-OUTSIDE-GIT",
    "app_secret": "YOUR-META-APP-SECRET",
    "verify_token": "YOUR-RANDOM-WEBHOOK-VERIFY-TOKEN"
  }
}
```

Configure the Meta webhook callback as `https://YOUR-ERP-HOST/api/method/alienhouse_employee_hub.api.whatsapp_webhook`, subscribe to WhatsApp message events, and use the GET challenge verification. The POST handler validates `X-Hub-Signature-256`. Inbound matching compares the sender's international phone number with active Employee `cell_number`; keep these numbers normalized in international format. Messages from unmatched senders remain flagged in the HR inbox. Provider delivery, template messaging, media downloads, retries and operational alerting need a production integration review.

## Permissions and behavior

- Guest access is denied for employee APIs except the signed WhatsApp webhook endpoint.
- Employee directory writes, report review, leave review, WhatsApp sending and inbox access are role-gated to HR Manager/System Manager where applicable.
- Employees can only see their own EOD reports, attendance, leave requests and assigned tasks through the self-service endpoints.
- AI is a drafting assistant only; it must not make hiring, payroll, leave or disciplinary decisions.
- Empty/missing integration configuration returns an explicit NOT_CONFIGURED/UNAVAILABLE status. No live AI or WhatsApp success is fabricated.
- The WhatsApp inbox persists text messages and a marker for non-text messages; media ingestion and employee-to-phone mappings beyond the Employee cell number are not implemented.
- HRMS is a required separate app; the repository does not currently vendor HRMS source. Leave types, attendance policies, Employee required fields, roles and DocType permissions depend on your installed HRMS version and site configuration.
- The vendored ERPNext snapshot currently declares Frappe `>=17.0.0-dev,<18.0.0` and Python `>=3.14`; this does not prove the custom app is compatible with every bench. Use matching versions and run the site migration/test gates in the integration guide before rollout.

## Staging API smoke test

After installing the app on a disposable staging site and linking an Employee record to the test user's ERPNext account, run the read-only endpoint smoke test:

```bash
python -m pip install -r requirements.txt
export ERPNEXT_BASE_URL="https://your-staging-erp.example.com"
export ERPNEXT_USER="employee-test@example.com"
read -s ERPNEXT_PASSWORD
export ERPNEXT_PASSWORD
python scripts/smoke_test_employee_hub.py
unset ERPNEXT_PASSWORD
```

The script logs in and checks the self-service endpoints without creating business records. Use a dedicated test account and never put passwords in shell history, CI logs or Git. It does not replace role-based negative tests, real Meta webhook tests or the site-specific Frappe test suite.

## CI and release gates

GitHub Actions runs the web TypeScript/Vite build, Flutter formatting/analyzer/widget test, Android debug APK build, and Python syntax compilation. Platform runner files are committed. The read-only staging smoke test can be run against a configured ERPNext site. These CI checks are not a substitute for testing on a real supported Frappe/ERPNext site.

Before production:
1. Run migrations and Frappe tests on a disposable staging site.
2. Verify each role with employee, HR Manager, System Manager and Guest accounts.
3. Test CORS/CSRF/session expiry, duplicate webhook deliveries, Meta signature failures and WhatsApp unmatched numbers.
4. Verify Employee Checkin/Attendance behavior against your shift and auto-attendance configuration.
5. Verify leave allocation/holiday rules and approval workflow in your ERPNext version.
6. Run dependency/security scans, backup/restore test, error monitoring and rate limits.
7. Do not merge/deploy until CI is green and staging acceptance tests pass.

## Current limits

The app does not yet implement payroll, biometric-device integration, GPS/geofence policy enforcement, push notifications, full employee document-template generation/e-signature, a complete CRM, workflow builder, AI agent orchestration, or an autonomous HR decision system. Those require separate scoped implementation and site-specific policy decisions.
