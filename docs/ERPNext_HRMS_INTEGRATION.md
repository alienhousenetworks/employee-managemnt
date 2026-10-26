# ERPNext + HRMS integration design

## Decision

Build AlienHouse Employee Hub as a **separate Frappe custom app installed into the same bench as ERPNext and HRMS**. Do not fork or add agency-specific features directly to the vendored `erpnext-develop/` source tree. This keeps upstream upgrades possible and gives the agency a clean install/uninstall boundary.

The repository's `erpnext-develop/` folder is an upstream source snapshot. It is not a bench, database, site, or installed application. A folder being present in Git does not mean its DocTypes are available at runtime.

## Native ownership

| Capability | Native owner / record | Employee Hub responsibility |
|---|---|---|
| Employee profile, reporting line, department, designation | HRMS: `Employee` | Self-service/profile presentation and carefully permissioned HR workspace |
| Check-in / attendance | HRMS: `Employee Checkin`, `Attendance` | Employee Hub UI/API only; must respect shift, check-in, auto-attendance and attendance policy |
| Leave requests and approvals | HRMS: `Leave Application`, Leave Type, Leave Allocation and configured workflows | Submit and present requests; native HRMS remains source of truth for validation, balances and approvals |
| Work assignments | ERPNext/Frappe: `Task`, `ToDo` | Employee-friendly views; no parallel task database |
| Files | Frappe: `File` and private-file permission rules | Attachments linked to a request; never expose a private file by guessing its URL |
| User authentication and roles | Frappe session, User and Role | Reuse session, CSRF protections and server-side role checks |
| Company social feed | Custom Employee Hub DocTypes | Posts, questions, recognition and announcements |
| End-of-day reports | Custom Employee Hub DocType | Daily outcomes, blockers, next-day plan and review history |
| WhatsApp inbox/outbound routing | Custom message DocType + Meta Cloud API | Signature verification, idempotent webhook ingestion, mapping and human handling |
| AI drafting | Custom service + approved provider | Draft/summary assistance with explicit unavailable state and human review; no autonomous employment decisions |

## Required dependencies and versioning

- The custom app declares `required_apps = ["erpnext", "hrms"]` in `hooks.py`.
- ERPNext v17 source separates HR features into the HRMS app. The repository does **not** contain a `hrms-develop/` source tree, so HRMS must be installed separately on the target bench.
- The vendored ERPNext snapshot's `pyproject.toml` declares Frappe `>=17.0.0-dev,<18.0.0` and Python `>=3.14`. Treat that as snapshot metadata, not as proof that an arbitrary existing site matches it.
- Do not install a develop-branch source snapshot into a production site just because it is checked into this repository. First inventory the actual bench versions and select a matching supported release set.

## Install and validate on a disposable staging site

1. Back up the site and database; use a separate disposable staging site.
2. Record versions from the actual bench: `bench version`, `bench --site <site> list-apps`, Python version, database version and installed HRMS revision.
3. Confirm `frappe`, `erpnext` and `hrms` are installed before Employee Hub.
4. Install the custom app from its branch, migrate, build assets, then run `bench --site <site> run-tests --app alienhouse_employee_hub`.
5. Verify native DocType names and required fields against the installed HRMS version before exercising attendance and leave endpoints.
6. Test as Guest, ordinary employee, HR Manager and System Manager. Confirm an employee can only access their own reports, leave, attendance and tasks; HR-only operations reject ordinary employees.
7. Test native leave allocation/holiday/overlap rules, shift/auto-attendance behavior, duplicate and invalid WhatsApp webhook signatures, duplicate provider message IDs, private attachments and AI-unavailable behavior.
8. Run a backup/restore rehearsal and only then consider production.

## Integration constraints

- Employee Hub must not create replacement Employee, Leave Application, Attendance, Employee Checkin, Task, ToDo or File tables.
- Do not bypass HRMS validation or approval workflows to make a UI action appear successful.
- Never expose sensitive employee fields in the company-wide directory by default. Add fields only when required for a documented HR purpose and enforce access server-side.
- Keep provider credentials in site configuration or a secrets manager, never source control.
- WhatsApp webhook handlers must validate Meta signatures against the exact raw request body and deduplicate provider message IDs.
- AI outputs are suggestions, not facts. Display the review state and never auto-approve leave, payroll, hiring, discipline or other consequential employment actions.
- If a native feature or integration is missing, return an explicit unavailable/configuration state; do not silently simulate success.