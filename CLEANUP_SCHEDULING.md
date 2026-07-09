# Temp File & Session Cleanup Scheduling

## Overview
A new management command `cleanup_temp_files` has been created to clean up:
- Orphaned temporary files in `temp/` directory (from failed/expired purchase sessions)
- Expired purchase sessions that were not completed

## Usage

### Manual Cleanup
```bash
# Dry-run (see what would be deleted without making changes)
python manage.py cleanup_temp_files --dry-run

# Actual cleanup (delete orphaned files older than 24 hours)
python manage.py cleanup_temp_files

# Custom retention period (delete files older than 72 hours)
python manage.py cleanup_temp_files --temp-hours 72
```

### Scheduled Cleanup

#### Option 1: Linux/macOS Cron Job
Add to crontab (run daily at 2 AM):
```bash
0 2 * * * cd /path/to/project/backend && python manage.py cleanup_temp_files >> /var/log/everwall_cleanup.log 2>&1
```

#### Option 2: Windows Task Scheduler
Create a scheduled task:
1. Open Task Scheduler
2. Create Basic Task → "Everwall Cleanup"
3. Trigger: Daily at 02:00 AM
4. Action: Run batch script with content:
```batch
@echo off
cd C:\path\to\project\backend
python manage.py cleanup_temp_files >> C:\logs\everwall_cleanup.log 2>&1
```

#### Option 3: Celery Beat (If added to project)
Add to `celery.py` or beat schedule:
```python
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    'cleanup_temp_files': {
        'task': 'pixels.tasks.cleanup_temp_files',
        'schedule': crontab(hour=2, minute=0),  # Daily at 2 AM
    },
}
```

Then create `pixels/tasks.py`:
```python
from celery import shared_task
from django.core.management import call_command

@shared_task
def cleanup_temp_files():
    call_command('cleanup_temp_files')
```

## Behavior

### Session Cleanup
- Deletes `PixelPurchaseSession` records where:
  - `is_completed=False`
  - `expires_at < now()`

### Temp File Cleanup
- Deletes files from `temp/` directory where:
  - File is NOT referenced in any active (non-expired, incomplete) session
  - File is older than `--temp-hours` (default: 24 hours)

## Recommendations

**Frequency:** Run daily at off-peak hours (e.g., 2 AM)
**Retention:** Default 24 hours is reasonable; adjust if users often resume interrupted sessions later

## Logs

The command logs its actions to Django's logger (app `pixels`):
- Successful cleanups: INFO level
- Failures: WARNING level
- Errors: ERROR level

Configure Django logging to monitor these logs in production.
