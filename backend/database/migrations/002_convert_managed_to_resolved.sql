-- Migration: Convert legacy complaint statuses from Managed to Resolved
-- Safe for repeated runs.

UPDATE complaints
SET status = 'Resolved'
WHERE LOWER(status::text) = 'managed';

UPDATE complaint_status_log
SET status = 'Resolved'
WHERE LOWER(status::text) = 'managed';
