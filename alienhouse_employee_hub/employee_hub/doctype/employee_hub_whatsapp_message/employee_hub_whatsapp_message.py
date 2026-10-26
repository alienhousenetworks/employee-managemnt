import frappe
from frappe.model.document import Document

class EmployeeHubWhatsAppMessage(Document):
    def validate(self):
        if not (self.provider_message_id or '').strip():
            frappe.throw('Provider message ID is required')
        if self.status not in {'Received', 'Unmatched', 'Handled'}:
            frappe.throw('Invalid WhatsApp message status')
