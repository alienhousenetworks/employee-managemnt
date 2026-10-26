import frappe
from frappe.model.document import Document
class EmployeeHubEODReport(Document):
    def validate(self):
        if not (self.accomplishments or '').strip(): frappe.throw('Accomplishments are required')
        if self.hours_worked is not None and not 0<=float(self.hours_worked)<=24: frappe.throw('Hours worked must be between 0 and 24')
