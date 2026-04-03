"""
Lambda Function: contact-handler
Site: ceo.grouperms.com
Handles: POST /contact and POST /newsletter

Architecture:
  API Gateway → Lambda → SES (email) + DynamoDB (audit log)
  reCAPTCHA v3 verified before any processing

Environment Variables Required:
  RECAPTCHA_SECRET_KEY     - reCAPTCHA v3 secret key
  SES_FROM_EMAIL           - verified SES sender (e.g. no-reply@grouperms.com)
  SES_TO_EMAIL             - recipient (modeste.agonnoude@grouperms.com)
  DYNAMODB_TABLE           - DynamoDB table name for audit logging
  ALLOWED_ORIGIN           - CORS origin (https://ceo.grouperms.com)
  RECAPTCHA_MIN_SCORE      - minimum score to accept (default: 0.5)
"""

import json
import os
import re
import uuid
import logging
from datetime import datetime, timezone

import boto3
import urllib.request
import urllib.parse

# ── Logging ──────────────────────────────────────────────────────────────────
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# ── AWS clients ───────────────────────────────────────────────────────────────
ses = boto3.client('ses', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

# ── Config from environment ───────────────────────────────────────────────────
RECAPTCHA_SECRET  = os.environ.get('RECAPTCHA_SECRET_KEY', '')
SES_FROM          = os.environ.get('SES_FROM_EMAIL', 'no-reply@grouperms.com')
SES_TO            = os.environ.get('SES_TO_EMAIL', 'modeste.agonnoude@grouperms.com')
TABLE_NAME        = os.environ.get('DYNAMODB_TABLE', 'ceo-contact-submissions')
ALLOWED_ORIGIN    = os.environ.get('ALLOWED_ORIGIN', 'https://ceo.grouperms.com')
MIN_SCORE         = float(os.environ.get('RECAPTCHA_MIN_SCORE', '0.5'))

# ── CORS headers ──────────────────────────────────────────────────────────────
CORS_HEADERS = {
    'Access-Control-Allow-Origin':  ALLOWED_ORIGIN,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json'
}


# =============================================================================
# HELPERS
# =============================================================================

def response(status_code: int, body: dict) -> dict:
    return {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json.dumps(body)
    }


def sanitize(value: str, max_len: int = 500) -> str:
    """Strip HTML tags and limit length."""
    if not value:
        return ''
    clean = re.sub(r'<[^>]+>', '', str(value))
    return clean.strip()[:max_len]


def is_valid_email(email: str) -> bool:
    pattern = r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email or ''))


def verify_recaptcha(token: str) -> tuple[bool, float]:
    """
    Verify reCAPTCHA v3 token with Google.
    Returns (is_valid, score).
    Score: 1.0 = very likely human, 0.0 = very likely bot.
    """
    if not token or not RECAPTCHA_SECRET:
        logger.warning("reCAPTCHA token or secret missing — skipping verification")
        return True, 0.9  # Allow through in dev/misconfigured environments

    try:
        data = urllib.parse.urlencode({
            'secret': RECAPTCHA_SECRET,
            'response': token
        }).encode('utf-8')

        req = urllib.request.Request(
            'https://www.google.com/recaptcha/api/siteverify',
            data=data,
            method='POST'
        )

        with urllib.request.urlopen(req, timeout=5) as resp:
            result = json.loads(resp.read().decode('utf-8'))

        success = result.get('success', False)
        score   = result.get('score', 0.0)
        action  = result.get('action', '')

        logger.info(f"reCAPTCHA result: success={success}, score={score}, action={action}")
        return success and score >= MIN_SCORE, score

    except Exception as e:
        logger.error(f"reCAPTCHA verification error: {e}")
        return False, 0.0


def log_to_dynamodb(table_name: str, item: dict) -> None:
    """Write submission to DynamoDB for audit trail."""
    try:
        table = dynamodb.Table(table_name)
        table.put_item(Item=item)
        logger.info(f"Logged to DynamoDB: {item.get('submission_id')}")
    except Exception as e:
        logger.error(f"DynamoDB write error: {e}")
        # Non-fatal — do not block the email send


def send_contact_email(data: dict) -> None:
    """Send formatted contact notification via SES."""
    name     = data['name']
    email    = data['email']
    company  = data.get('company', 'Not provided')
    interest = data.get('interest', 'Not specified')
    message  = data['message']
    page     = data.get('page', 'Unknown')
    ts       = data.get('timestamp', datetime.now(timezone.utc).isoformat())

    interest_labels = {
        'advisory':      'Executive Advisory Session',
        'due-diligence': 'Due Diligence Support',
        'deep-dive':     'Strategic Deep Dive',
        'platform':      'Digital Platform',
        'academy':       'Training Program',
        'speaking':      'Speaking Engagement',
        'other':         'Other'
    }
    interest_label = interest_labels.get(interest, interest)

    subject = f"[ceo.grouperms.com] New enquiry from {name} — {interest_label}"

    body_text = f"""
New contact form submission from ceo.grouperms.com

─────────────────────────────────────
FROM:     {name}
EMAIL:    {email}
COMPANY:  {company}
INTEREST: {interest_label}
PAGE:     {page}
TIME:     {ts}
─────────────────────────────────────

MESSAGE:
{message}

─────────────────────────────────────
Reply directly to: {email}
"""

    body_html = f"""
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family: 'DM Sans', Arial, sans-serif; color: #0d1b2a; max-width: 600px; margin: 0 auto; padding: 24px;">
  <div style="background: #0d1b2a; padding: 24px 32px; border-radius: 8px 8px 0 0;">
    <h2 style="color: #c9903a; margin: 0; font-size: 1.1rem; letter-spacing: 0.05em;">NEW ENQUIRY — ceo.grouperms.com</h2>
  </div>
  <div style="background: #ffffff; padding: 32px; border: 1px solid #e9ecef; border-top: none; border-radius: 0 0 8px 8px;">
    <table style="width: 100%; border-collapse: collapse; font-size: 0.9rem;">
      <tr><td style="padding: 8px 0; color: #6c757d; width: 120px;">Name</td><td style="padding: 8px 0; font-weight: 600;">{name}</td></tr>
      <tr><td style="padding: 8px 0; color: #6c757d;">Email</td><td style="padding: 8px 0;"><a href="mailto:{email}" style="color: #c9903a;">{email}</a></td></tr>
      <tr><td style="padding: 8px 0; color: #6c757d;">Company</td><td style="padding: 8px 0;">{company}</td></tr>
      <tr><td style="padding: 8px 0; color: #6c757d;">Interest</td><td style="padding: 8px 0;"><strong style="color: #c9903a;">{interest_label}</strong></td></tr>
      <tr><td style="padding: 8px 0; color: #6c757d;">Page</td><td style="padding: 8px 0; font-size: 0.8rem;">{page}</td></tr>
      <tr><td style="padding: 8px 0; color: #6c757d;">Time</td><td style="padding: 8px 0; font-size: 0.8rem;">{ts}</td></tr>
    </table>
    <hr style="border: none; border-top: 1px solid #e9ecef; margin: 24px 0;">
    <h3 style="font-size: 0.9rem; color: #6c757d; margin-bottom: 12px; text-transform: uppercase; letter-spacing: 0.08em;">Message</h3>
    <p style="font-size: 1rem; line-height: 1.7; white-space: pre-wrap;">{message}</p>
    <hr style="border: none; border-top: 1px solid #e9ecef; margin: 24px 0;">
    <a href="mailto:{email}?subject=Re: {interest_label}"
       style="display: inline-block; background: #c9903a; color: #0d1b2a; padding: 12px 28px; border-radius: 6px; font-weight: 600; text-decoration: none;">
      Reply to {name}
    </a>
  </div>
  <p style="font-size: 0.75rem; color: #adb5bd; text-align: center; margin-top: 16px;">
    Sent via ceo.grouperms.com contact form
  </p>
</body>
</html>
"""

    ses.send_email(
        Source=f"ceo.grouperms.com <{SES_FROM}>",
        Destination={'ToAddresses': [SES_TO]},
        ReplyToAddresses=[email],
        Message={
            'Subject': {'Data': subject, 'Charset': 'UTF-8'},
            'Body': {
                'Text': {'Data': body_text, 'Charset': 'UTF-8'},
                'Html': {'Data': body_html, 'Charset': 'UTF-8'}
            }
        }
    )
    logger.info(f"Contact email sent to {SES_TO}")


def send_newsletter_confirmation(email: str) -> None:
    """Send subscription confirmation via SES."""
    ses.send_email(
        Source=f"Modeste Agonnoudé <{SES_FROM}>",
        Destination={'ToAddresses': [email]},
        Message={
            'Subject': {'Data': 'Newsletter subscription confirmed — Modeste Agonnoudé', 'Charset': 'UTF-8'},
            'Body': {
                'Text': {
                    'Data': (
                        "Thank you for subscribing to my newsletter.\n\n"
                        "You will receive my latest insights on energy transition, digital transformation, "
                        "cybersecurity, and cloud strategy — straight from the field.\n\n"
                        "— Modeste Agonnoudé\n"
                        "   Former ENGIE Group CDIO | MIT CTO Certified\n"
                        "   https://ceo.grouperms.com\n\n"
                        "To unsubscribe, reply with 'unsubscribe' in the subject."
                    ),
                    'Charset': 'UTF-8'
                }
            }
        }
    )
    logger.info(f"Newsletter confirmation sent to {email}")


# =============================================================================
# ROUTE HANDLERS
# =============================================================================

def handle_contact(body: dict) -> dict:
    """Process contact form submission."""

    # ── Validate required fields ──────────────────────────────────────────────
    name    = sanitize(body.get('name', ''), 100)
    email   = sanitize(body.get('email', ''), 200)
    message = sanitize(body.get('message', ''), 2000)
    company = sanitize(body.get('company', ''), 200)
    interest = sanitize(body.get('interest', ''), 100)
    recaptcha_token = body.get('recaptcha_token', '')
    page    = sanitize(body.get('page', ''), 200)
    timestamp = body.get('timestamp', datetime.now(timezone.utc).isoformat())

    if not name or len(name) < 2:
        return response(400, {'success': False, 'error': 'Name is required (min 2 characters)'})

    if not is_valid_email(email):
        return response(400, {'success': False, 'error': 'Valid email address is required'})

    if not message or len(message) < 10:
        return response(400, {'success': False, 'error': 'Message is required (min 10 characters)'})

    # ── reCAPTCHA verification ────────────────────────────────────────────────
    is_human, score = verify_recaptcha(recaptcha_token)

    if not is_human:
        logger.warning(f"reCAPTCHA rejected: score={score}, email={email}")
        return response(400, {
            'success': False,
            'error': 'Submission flagged as suspicious. Please contact us directly by email.',
            'score': score
        })

    # ── Build submission record ───────────────────────────────────────────────
    submission_id = str(uuid.uuid4())
    submission = {
        'submission_id': submission_id,
        'type':          'contact',
        'name':          name,
        'email':         email,
        'company':       company,
        'interest':      interest,
        'message':       message,
        'page':          page,
        'timestamp':     timestamp,
        'recaptcha_score': str(score),
        'site':          'ceo.grouperms.com',
        'created_at':    datetime.now(timezone.utc).isoformat()
    }

    # ── Log to DynamoDB ───────────────────────────────────────────────────────
    log_to_dynamodb(TABLE_NAME, submission)

    # ── Send email via SES ────────────────────────────────────────────────────
    try:
        send_contact_email(submission)
    except Exception as e:
        logger.error(f"SES send error: {e}")
        return response(500, {'success': False, 'error': 'Failed to send message. Please try again or contact us directly.'})

    return response(200, {
        'success': True,
        'message': 'Message sent successfully. I will respond within 24 hours.',
        'submission_id': submission_id
    })


def handle_newsletter(body: dict) -> dict:
    """Process newsletter subscription."""

    email = sanitize(body.get('email', ''), 200)
    source = sanitize(body.get('source', ''), 200)
    timestamp = body.get('timestamp', datetime.now(timezone.utc).isoformat())

    if not is_valid_email(email):
        return response(400, {'success': False, 'error': 'Valid email address is required'})

    submission_id = str(uuid.uuid4())
    subscription = {
        'submission_id': submission_id,
        'type':          'newsletter',
        'email':         email,
        'source':        source,
        'timestamp':     timestamp,
        'site':          'ceo.grouperms.com',
        'created_at':    datetime.now(timezone.utc).isoformat()
    }

    # ── Log to DynamoDB ───────────────────────────────────────────────────────
    log_to_dynamodb(TABLE_NAME, subscription)

    # ── Send confirmation to subscriber ──────────────────────────────────────
    try:
        send_newsletter_confirmation(email)
    except Exception as e:
        logger.error(f"Newsletter confirmation error: {e}")
        # Non-fatal — subscription is recorded

    # ── Notify Modeste of new subscriber ─────────────────────────────────────
    try:
        ses.send_email(
            Source=f"ceo.grouperms.com <{SES_FROM}>",
            Destination={'ToAddresses': [SES_TO]},
            Message={
                'Subject': {'Data': f'[Newsletter] New subscriber: {email}', 'Charset': 'UTF-8'},
                'Body': {'Text': {'Data': f"New newsletter subscriber:\n{email}\nSource: {source}\nTime: {timestamp}", 'Charset': 'UTF-8'}}
            }
        )
    except Exception as e:
        logger.error(f"Subscriber notification error: {e}")

    return response(200, {
        'success': True,
        'message': 'Subscription confirmed. Thank you!'
    })


# =============================================================================
# MAIN HANDLER
# =============================================================================

def lambda_handler(event, context):
    logger.info(f"Event: {json.dumps({k: v for k, v in event.items() if k != 'body'})}")

    # ── Handle CORS preflight ─────────────────────────────────────────────────
    if event.get('httpMethod') == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': ''}

    # ── Only accept POST ──────────────────────────────────────────────────────
    if event.get('httpMethod') != 'POST':
        return response(405, {'success': False, 'error': 'Method not allowed'})

    # ── Parse body ────────────────────────────────────────────────────────────
    try:
        raw_body = event.get('body', '{}') or '{}'
        body = json.loads(raw_body)
    except json.JSONDecodeError:
        return response(400, {'success': False, 'error': 'Invalid JSON body'})

    # ── Route by path ─────────────────────────────────────────────────────────
    path = event.get('path', '') or event.get('rawPath', '')

    if '/newsletter' in path:
        return handle_newsletter(body)
    elif '/contact' in path:
        return handle_contact(body)
    else:
        return response(404, {'success': False, 'error': 'Endpoint not found'})
