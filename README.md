# AlienHouse Employee Hub

ERPNext-backed employee operations scaffold with a Frappe backend, React web frontend and Flutter mobile client.

Features: authenticated team feed, daily EOD reports, report history, reviewer status endpoint and fail-closed WhatsApp webhook placeholder. Existing upstream ERPNext source remains untouched.

- Backend: `alienhouse_employee_hub/`
- Web: `web/`
- Flutter: `mobile/employee_hub_app/`
- `erpnext-develop/` is an upstream snapshot, not the custom app.

The repository root includes packaging metadata for the custom app. On a compatible staging bench use `bench get-app alienhouse_employee_hub https://github.com/alienhousenetworks/employee-managemnt.git --branch feat/employee-hub-backend-frontend-flutter`, then `bench --site your-site install-app alienhouse_employee_hub`, `bench --site your-site migrate`, `bench build`, and `bench --site your-site run-tests --app alienhouse_employee_hub`. Because the repository also contains a large upstream ERPNext snapshot, verify packaging and app discovery on a clean staging bench before production.

Web: `cd web && npm install && npm run dev`; copy `.env.example` to `.env.local` and set `VITE_FRAPPE_URL` to your HTTPS ERPNext origin. Flutter: `cd mobile/employee_hub_app && flutter create . --platforms=android,ios && flutter pub get && flutter run` (the generated platform runner files are not committed in this initial scaffold).

Keep credentials out of Git. Configure HTTPS, role permissions, backups and WhatsApp Business credentials out of band. Validate migrations, cookies/CORS and permissions on staging before production. This code has not been tested against your live ERPNext site.


## Scope boundary
This first implementation is the feed/EOD/dashboard foundation, not the complete HRMS/CRM suite. Full leave, attendance, payroll, employee document workflows, task management, AI-agent orchestration and live WhatsApp send/receive still require dedicated implementation and tenant-specific integration.
