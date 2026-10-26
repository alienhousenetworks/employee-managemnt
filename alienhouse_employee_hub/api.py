import hashlib, hmac, json
from datetime import date
import frappe
from frappe import _
from frappe.utils import now_datetime, today

def _user():
    user=frappe.session.user
    if not user or user=='Guest': frappe.throw(_('Authentication required'),frappe.PermissionError)
    return user

def _employee(user):
    rows=frappe.get_all('Employee',filters={'user_id':user,'status':'Active'},fields=['name','employee_name','department','designation'],limit=1)
    return rows[0] if rows else None

def _reviewer():
    if not set(frappe.get_roles(frappe.session.user)).intersection({'HR Manager','System Manager','Employee Hub Reviewer'}): frappe.throw(_('Reviewer role required'),frappe.PermissionError)

@frappe.whitelist()
def get_dashboard():
    user=_user(); reviewer=bool(set(frappe.get_roles(user)).intersection({'HR Manager','System Manager','Employee Hub Reviewer'}))
    return {'employee':_employee(user),'feed_posts_today':frappe.db.count('Employee Hub Feed Post',{'owner':user,'creation':['>=',today()]}),'my_reports_today':frappe.db.count('Employee Hub EOD Report',{'employee_user':user,'report_date':today()}),'pending_reports':frappe.db.count('Employee Hub EOD Report',{'status':'Submitted'}) if reviewer else None,'server_time':str(now_datetime())}

@frappe.whitelist()
def get_feed(limit=30,before=None):
    _user(); limit=max(1,min(int(limit),100)); filters={'visibility':'Company'}
    if before: filters['creation']=['<',before]
    return frappe.get_list('Employee Hub Feed Post',filters=filters,fields=['name','author_name','content','post_type','creation','department'],order_by='creation desc',limit_page_length=limit)

@frappe.whitelist()
def create_feed_post(content,post_type='Update'):
    user=_user(); content=(content or '').strip()
    if not content or len(content)>5000: frappe.throw(_('Post content must contain 1–5000 characters'))
    if post_type not in {'Update','Question','Recognition','Announcement'}: frappe.throw(_('Unsupported post type'))
    employee=_employee(user); doc=frappe.get_doc({'doctype':'Employee Hub Feed Post','author':user,'author_name':employee.employee_name if employee else user,'department':employee.department if employee else None,'content':content,'post_type':post_type,'visibility':'Company'}); doc.insert()
    return {'name':doc.name,'creation':str(doc.creation)}

@frappe.whitelist()
def submit_eod_report(report_date=None,accomplishments=None,blockers=None,next_day_plan=None,hours_worked=0):
    user=_user()
    try: day=date.fromisoformat(str(report_date or today())[:10]); hours=float(hours_worked or 0)
    except (ValueError,TypeError): frappe.throw(_('Invalid date or hours'))
    if day>date.today(): frappe.throw(_('A report cannot be submitted for a future date'))
    if not 0<=hours<=24: frappe.throw(_('Hours worked must be between 0 and 24'))
    accomplishments=(accomplishments or '').strip()
    if not accomplishments: frappe.throw(_('Please describe at least one accomplishment'))
    day=day.isoformat(); existing=frappe.db.get_value('Employee Hub EOD Report',{'employee_user':user,'report_date':day},'name')
    values={'employee_user':user,'report_date':day,'accomplishments':accomplishments[:10000],'blockers':(blockers or '').strip()[:5000],'next_day_plan':(next_day_plan or '').strip()[:5000],'hours_worked':hours,'status':'Submitted','submitted_at':now_datetime()}
    if existing:
        doc=frappe.get_doc('Employee Hub EOD Report',existing)
        if doc.status=='Approved': frappe.throw(_('Approved reports cannot be edited'))
        doc.update(values); doc.save()
    else: doc=frappe.get_doc({'doctype':'Employee Hub EOD Report',**values}); doc.insert()
    return {'name':doc.name,'status':doc.status,'report_date':str(doc.report_date)}

@frappe.whitelist()
def get_my_eod_reports(limit=30):
    user=_user()
    return frappe.get_list('Employee Hub EOD Report',filters={'employee_user':user},fields=['name','report_date','accomplishments','blockers','next_day_plan','hours_worked','status','submitted_at'],order_by='report_date desc',limit_page_length=max(1,min(int(limit),100)))

@frappe.whitelist()
def review_eod_report(name,status,reviewer_notes=''):
    _user(); _reviewer()
    if status not in {'In Review','Approved','Needs Update'}: frappe.throw(_('Unsupported review status'))
    doc=frappe.get_doc('Employee Hub EOD Report',name); doc.status=status; doc.reviewer_notes=(reviewer_notes or '').strip()[:5000]; doc.save()
    return {'name':doc.name,'status':doc.status}

@frappe.whitelist(allow_guest=True,methods=['POST'])
def whatsapp_webhook():
    secret=(frappe.conf.get('employee_hub_whatsapp') or {}).get('app_secret')
    if not secret: frappe.local.response['http_status_code']=503; return {'ok':False,'error':'WhatsApp integration is not configured'}
    raw=frappe.request.get_data() or b''; signature=frappe.get_request_header('X-Hub-Signature-256') or ''; expected='sha256='+hmac.new(secret.encode(),raw,hashlib.sha256).hexdigest()
    if not hmac.compare_digest(signature,expected): frappe.local.response['http_status_code']=401; return {'ok':False,'error':'Invalid signature'}
    try: payload=json.loads(raw.decode('utf-8') or '{}')
    except (UnicodeDecodeError,json.JSONDecodeError): frappe.local.response['http_status_code']=400; return {'ok':False,'error':'Invalid JSON'}
    frappe.logger('employee_hub').info('Verified WhatsApp webhook accepted'); return {'ok':True,'received':bool(payload)}
