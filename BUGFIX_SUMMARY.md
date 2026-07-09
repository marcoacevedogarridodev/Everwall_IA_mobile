# Critical Bugs Fixed - Summary

## Overview
Three critical bugs have been resolved to prevent 500 errors in production and improve system stability.

---

## 🔴 BUG-1: Missing `is_completed` Check in `confirm_purchase`

### Issue
Line 268 in `pixels/views.py`:
```python
# BEFORE (vulnerable to IntegrityError 500 on retries)
session = PixelPurchaseSession.objects.get(session_id=session_id)
```

If `confirm_purchase` is called twice (network retry, double-click, or replay attack), the second call would:
1. Pass the session lookup (because session exists)
2. Create a duplicate Pixel with same (x, y) coordinates
3. Hit the `unique_together = ['x','y']` constraint
4. Throw `IntegrityError` → 500 response to user

### Fix Applied
```python
# AFTER (prevents double-processing)
session = PixelPurchaseSession.objects.get(session_id=session_id, is_completed=False)
```

Now:
- First call: Finds session with `is_completed=False`, completes it successfully, sets `is_completed=True`
- Second call: Raises `PixelPurchaseSession.DoesNotExist` → Returns controlled 404 error
- Error message updated to: "Sesión no encontrada o ya completada"

**Impact:** Prevents 500 errors on network retries during payment confirmation
**File:** `backend/pixels/views.py` (line 268)

---

## 🔴 BUG-2: Missing UUID Validation in `search_pixel`

### Issue
Lines 367-371 in `pixels/views.py`:
```python
# BEFORE (throws ValidationError 500 for invalid UUID)
pixel = Pixel.objects.get(
    django_models.Q(display_code=code) |
    django_models.Q(search_code=code) |
    django_models.Q(access_code=code),  # ← access_code is UUIDField
    status='sold',
    moderation_status='approved'
)
```

If a user sends an invalid UUID format (e.g., "not-a-uuid" or "12345") as the `code`:
1. Django tries to construct the query with `Q(access_code="not-a-uuid")`
2. UUIDField validation throws `ValidationError` during query construction
3. Exception is not caught by the `except Pixel.DoesNotExist` clause
4. Unhandled exception → 500 error

### Fix Applied
```python
# AFTER (gracefully handles invalid UUIDs)
query = django_models.Q(display_code=code) | django_models.Q(search_code=code)

# Pre-validate UUID format before adding to query
try:
    uuid.UUID(code)  # Throws ValueError if not valid UUID
    query |= django_models.Q(access_code=code)
except (ValueError, AttributeError):
    # Not a valid UUID, skip this search criterion
    pass

pixel = Pixel.objects.get(query, status='sold', moderation_status='approved')
```

**Impact:** Prevents 500 errors when invalid UUID formats are submitted in search
**File:** `backend/pixels/views.py` (lines 366-382)

---

## 🔴 BUG-3: Orphaned Temporary Files Not Cleaned Up

### Issue
When `initiate_purchase` moderates 5 images but image #3 fails moderation:
1. Images 1-2 are already saved to `temp/uuid_filename.jpg`
2. Return 400 error to user
3. Orphaned files left in `temp/` directory forever (never moved to permanent location, never deleted)

Also for expired sessions:
- If user starts purchase but abandons it, the `PixelPurchaseSession` expires after 30 minutes
- Temp files are never cleaned up
- DB keeps accumulating expired session records

**Result:** Disk space fills up, DB bloats, storage costs increase indefinitely

### Fix Applied
Created management command: `python manage.py cleanup_temp_files`

**New command features:**
- Deletes orphaned files in `temp/` that are:
  - NOT referenced in any active (non-expired, incomplete) session
  - Older than 24 hours (configurable with `--temp-hours`)
- Deletes expired purchase sessions where:
  - `is_completed=False`
  - `expires_at < now()`
- Provides `--dry-run` option to preview changes before deletion
- Logs all operations to Django logger (level: INFO/WARNING)

**Setup:**
```bash
# Manual cleanup (see what would be deleted)
python manage.py cleanup_temp_files --dry-run

# Actual cleanup (delete files older than 24h)
python manage.py cleanup_temp_files

# Custom retention period
python manage.py cleanup_temp_files --temp-hours 72
```

**For production:** Schedule daily execution via:
- **Cron** (Linux/Mac): `0 2 * * * cd /path && python manage.py cleanup_temp_files`
- **Task Scheduler** (Windows): Scheduled task running daily at 2 AM
- **Celery Beat** (if added later): See CLEANUP_SCHEDULING.md

**Files created:**
- `backend/pixels/management/commands/cleanup_temp_files.py` - Main command
- `backend/pixels/management/__init__.py` - Package marker
- `backend/pixels/management/commands/__init__.py` - Package marker
- `CLEANUP_SCHEDULING.md` - Detailed scheduling guide

**Impact:** Prevents disk space and DB bloat; enables automatic cleanup of failed/abandoned purchases
**Files:** New management command in `backend/pixels/management/commands/cleanup_temp_files.py`

---

## Summary Table

| Bug ID | Issue | Root Cause | Fix | Severity | Result |
|--------|-------|-----------|-----|----------|--------|
| BUG-1 | Double confirm_purchase → IntegrityError 500 | Missing is_completed check | Add is_completed=False to query | CRITICAL | Controlled 404 on retries |
| BUG-2 | Invalid UUID in search → ValidationError 500 | Missing pre-validation | Pre-validate UUID before query | CRITICAL | Controlled 404 for bad input |
| BUG-3 | Orphaned temp files accumulate | No cleanup mechanism | Management command + scheduling | CRITICAL | Auto-cleanup of orphaned files |

---

## Next Steps Recommended

1. **Test the fixes in dev:**
   ```bash
   cd backend
   python manage.py test  # (if tests are added)
   ```

2. **Schedule cleanup in production:**
   - Add cron job or Windows Task Scheduler (see CLEANUP_SCHEDULING.md)
   - Recommended: Daily at 2-3 AM (off-peak)

3. **Monitor:**
   - Check cleanup logs for errors
   - Verify temp directory disk usage stabilizes

4. **Optional improvements:**
   - Add Celery if periodic tasks become more complex
   - Create monitoring/alerting for failed cleanups

---

## Files Modified

- `backend/pixels/views.py`
  - Line 268: Added `is_completed=False` to confirm_purchase
  - Lines 366-382: Added UUID validation to search_pixel

## Files Created

- `backend/pixels/management/commands/cleanup_temp_files.py` (165 lines)
- `backend/pixels/management/__init__.py`
- `backend/pixels/management/commands/__init__.py`
- `CLEANUP_SCHEDULING.md`
- `backend/pixels/migrations/0001_initial.py` (auto-generated)

---

## Verification

✅ Django system checks: **PASSED** (0 issues)
✅ Management command: **WORKING** (tested --dry-run)
✅ No test breakage (tests.py is empty, no regressions)
✅ All imports valid
✅ No syntax errors
