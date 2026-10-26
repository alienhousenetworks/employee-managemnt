# AlienHouse Employee Hub

ERPNext-backed employee operations scaffold with a Frappe backend, React web frontend and Flutter mobile client.

Features: authenticated team feed, daily EOD reports, report history, reviewer status endpoint and fail-closed WhatsApp webhook placeholder. Existing upstream ERPNext source remains untouched.

- Backend: `alienhouse_employee_hub/`
- Web: `web/`
- Flutter: `mobile/employee_hub_app/`
- `erpnext-develop/` is an upstream snapshot, not the custom app.

This monorepo is not directly installable by `bench get-app` without packaging the Frappe app as a dedicated repository/build artifact. On a compatible staging bench, install the packaged app, run migrations/build and run its test suite.

Web: `cd web && npm install && npm run dev`; copy `.env.example` to `.env.local` and set `VITE_FRAPPE_URL` to your HTTPS ERPNext origin. Flutter: `cd mobile/employee_hub_app && flutter pub get && flutter run`.

Keep credentials out of Git. Configure HTTPS, role permissions, backups and WhatsApp Business credentials out of band. Validate migrations, cookies/CORS and permissions on staging before production. This code has not been tested against your live ERPNext site.
