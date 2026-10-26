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

    def test_guest_cannot_create_feed_comment(self):
        with patch.object(frappe.session, "user", "Guest"):
            with self.assertRaises(frappe.PermissionError):
                api.create_feed_comment(feed_post="not-a-post", content="hello")

    def test_feed_mentions_resolve_only_enabled_usernames(self):
        with patch.object(frappe, "get_all", return_value=[
            {"name": "alice@example.com", "full_name": "Alice"},
            {"name": "disabled-user@example.com", "full_name": "Disabled User"},
        ]) as get_all:
            result = api._resolve_feed_mentions("Please check this @alice@example.com and @unknown")
        get_all.assert_called_once()
        self.assertEqual(result, ["alice@example.com"])

    def test_feed_comment_validation_rejects_empty_content(self):
        from alienhouse_employee_hub.employee_hub.doctype.employee_hub_feed_interaction.employee_hub_feed_interaction import (
            EmployeeHubFeedInteraction,
        )
        doc = EmployeeHubFeedInteraction({"interaction_type": "Comment", "content": "   "})
        with self.assertRaises(Exception):
            doc.validate()

    def test_feed_reaction_rejects_unsupported_value(self):
        with patch.object(frappe.session, "user", "employee@example.com"), patch.object(
            api, "_feed_post_or_throw", return_value=type("Post", (), {"name": "EHF-TEST"})()
        ):
            with self.assertRaises(Exception):
                api.set_feed_reaction(feed_post="EHF-TEST", reaction="Dislike")
