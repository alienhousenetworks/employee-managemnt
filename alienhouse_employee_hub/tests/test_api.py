from unittest.mock import patch
import frappe
from frappe.tests.utils import FrappeTestCase
from alienhouse_employee_hub import api
class TestEmployeeHubAPI(FrappeTestCase):
    def test_guest_cannot_read_feed(self):
        with patch.object(frappe.session,'user','Guest'):
            with self.assertRaises(frappe.PermissionError): api.get_feed()
    def test_empty_post_rejected(self):
        with patch.object(frappe.session,'user','test@example.com'):
            with self.assertRaises(Exception): api.create_feed_post(content='   ')
    def test_invalid_post_type_rejected(self):
        with patch.object(frappe.session,'user','test@example.com'):
            with self.assertRaises(Exception): api.create_feed_post(content='hello',post_type='invalid')
