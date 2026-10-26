import frappe
from frappe.model.document import Document

class EmployeeHubDocumentRequest(Document):
    def validate(self):
        if not (self.document_type or '').strip():
            frappe.throw('Document type is required')
        if self.status not in {'Requested', 'In Progress', 'Ready', 'Rejected'}:
            frappe.throw('Invalid document request status')
