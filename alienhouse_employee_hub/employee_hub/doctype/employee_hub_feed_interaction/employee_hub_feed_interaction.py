import frappe
from frappe import _


class EmployeeHubFeedInteraction(frappe.model.document.Document):
    def validate(self):
        if self.interaction_type == "Comment":
            self.content = (self.content or "").strip()
            if not self.content or len(self.content) > 3000:
                frappe.throw(_("Comments must contain 1–3000 characters"))
            self.reaction = None
        elif self.interaction_type == "Reaction":
            if self.reaction not in {"Like", "Love", "Celebrate", "Support", "Insightful"}:
                frappe.throw(_("Choose a supported reaction"))
            self.content = None
            self.parent_interaction = None
        else:
            frappe.throw(_("Unsupported feed interaction type"))
