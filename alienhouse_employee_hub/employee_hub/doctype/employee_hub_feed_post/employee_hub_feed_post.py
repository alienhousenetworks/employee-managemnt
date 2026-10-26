import frappe
from frappe.model.document import Document
class EmployeeHubFeedPost(Document):
    def validate(self):
        self.content=(self.content or '').strip()
        if not self.content: frappe.throw('Post content is required')
        if len(self.content)>5000: frappe.throw('Post content cannot exceed 5000 characters')
