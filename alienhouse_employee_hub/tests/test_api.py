from unittest.mock import patch

import frappe
from frappe.tests.utils import FrappeTestCase

from alienhouse_employee_hub import api


class TestEmployeeHubAPI(FrappeTestCase):
    def test_guest_cannot_read_feed(self):
        with patch.object(frappe.session, "user", "Guest"):
            with self.assertRaises(frappe.PermissionError):
                api.get_feed()

    def test_empty_post_rejected(self):
        with patch.object(frappe.session, "user", "test@example.com"):
            with self.assertRaises(Exception):
                api.create_feed_post(content="   ")

    def test_invalid_post_type_rejected(self):
        with patch.object(frappe.session, "user", "test@example.com"):
            with self.assertRaises(Exception):
                api.create_feed_post(content="hello", post_type="invalid")

    def test_employee_cannot_create_or_edit_employee_records(self):
        with patch.object(frappe.session, "user", "employee@example.com"), patch(
            "frappe.get_roles", return_value=["Employee"]
        ):
            with self.assertRaises(frappe.PermissionError):
                api.save_employee(employee_name="Unauthorized Test")

    def test_employee_cannot_send_whatsapp_messages(self):
        with patch.object(frappe.session, "user", "employee@example.com"), patch(
            "frappe.get_roles", return_value=["Employee"]
        ):
            with self.assertRaises(frappe.PermissionError):
                api.send_whatsapp_message(to="+14155550123", message="test")

    def test_employee_cannot_review_eod_reports(self):
        with patch.object(frappe.session, "user", "employee@example.com"), patch(
            "frappe.get_roles", return_value=["Employee"]
        ):
            with self.assertRaises(frappe.PermissionError):
                api.review_eod_report(name="not-a-real-report", status="Approved")

    def test_invalid_eod_hours_are_rejected(self):
        with patch.object(frappe.session, "user", "employee@example.com"):
            with self.assertRaises(Exception):
                api.submit_eod_report(accomplishments="Test", hours_worked="not-a-number")
