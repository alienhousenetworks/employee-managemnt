app_name = "alienhouse_employee_hub"
app_title = "AlienHouse Employee Hub"
app_publisher = "AlienHouse Networks"
app_description = "Employee feed, EOD reports and workforce dashboard"
app_email = "connect@alienhousenetworks.com"
app_license = "MIT"

# ERPNext supplies core business records. HRMS is a separate Frappe app and
# owns Employee, Leave Application, Employee Checkin and Attendance.
# Fail installation clearly if the native dependency stack is incomplete.
required_apps = ["erpnext", "hrms"]
