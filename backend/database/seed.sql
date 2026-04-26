-- DU Alert seed data
-- Uses deterministic UUIDs for predictable local development.

-- Requested hardcoded login users:
-- 1) proctor / proctor123 (admin role for same access as admin)
-- 2) admin / admin123
-- 3) sabbir / sabbir123 (proctorial team role)
INSERT INTO users (
  id,
  full_name,
  department,
  registration_number,
  university_email,
  phone,
  username,
  password_hash,
  role,
  created_at
)
VALUES
  (
    'd1f4b6c2-8e11-4f12-a9d1-1b0aa1000001',
    'Proctor User',
    'Proctorial Team',
    'PR-2026-001',
    'proctor@du.edu.bd',
    '01700000010',
    'proctor',
    '$2b$12$McRb9/ry6NPwVfqMZ1M7KOLFqBm6Xt0ijimcPRVJfVH1MO3J7CxqO',
    'admin',
    NOW()
  ),
  (
    'd1f4b6c2-8e11-4f12-a9d1-1b0aa1000002',
    'Admin User',
    'Administration',
    'AD-2026-001',
    'admin@du.edu.bd',
    '01700000011',
    'admin',
    '$2b$12$4TjxpT4NG8m1zXLAkWmtUuiScmrE6hURueTWETsKST4zTOqpogHRm',
    'admin',
    NOW()
  ),
  (
    'd1f4b6c2-8e11-4f12-a9d1-1b0aa1000003',
    'Sabbir Hossain',
    'Proctorial Team',
    'PR-2026-002',
    'sabbir@du.edu.bd',
    '01700000012',
    'sabbir',
    '$2b$12$s6tLM8brv/8KvPA./blx5uD63t85PPwO8TrphgaB6/3AyPkPwlTbO',
    'proctor',
    NOW()
  )
ON CONFLICT (username) DO UPDATE
SET
  full_name = EXCLUDED.full_name,
  department = EXCLUDED.department,
  registration_number = EXCLUDED.registration_number,
  university_email = EXCLUDED.university_email,
  phone = EXCLUDED.phone,
  password_hash = EXCLUDED.password_hash,
  role = EXCLUDED.role;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'incidents'
  ) THEN
    INSERT INTO incidents (id, user_id, title, description, location, status)
    VALUES
      (
        '44444444-4444-4444-4444-444444444444',
        'd1f4b6c2-8e11-4f12-a9d1-1b0aa1000003',
        'Suspicious Activity Near Gate 2',
        'A person has been loitering near Gate 2 for over an hour and recording videos of students.',
        'Gate 2, DU Campus',
        'open'
      ),
      (
        '55555555-5555-5555-5555-555555555555',
        'd1f4b6c2-8e11-4f12-a9d1-1b0aa1000003',
        'Bike Theft in Parking Area',
        'A black bicycle was stolen from the engineering parking lot between 10:00 and 11:00.',
        'Engineering Parking, DU Campus',
        'in_progress'
      )
    ON CONFLICT (id) DO NOTHING;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'alerts'
  ) THEN
    INSERT INTO alerts (id, title, message, priority)
    VALUES
      (
        '66666666-6666-6666-6666-666666666666',
        'Heavy Rainfall Warning',
        'The weather office predicts heavy rainfall this evening. Please avoid waterlogged zones.',
        'high'
      ),
      (
        '77777777-7777-7777-7777-777777777777',
        'Campus Drill Notice',
        'A safety drill will be conducted tomorrow at 11:00 AM in all major buildings.',
        'medium'
      )
    ON CONFLICT (id) DO NOTHING;
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'emergency_contacts'
  ) THEN
    INSERT INTO emergency_contacts (id, name, phone, type)
    VALUES
      ('88888888-8888-8888-8888-888888888888', 'Campus Security', '+8801700000001', 'security'),
      ('99999999-9999-9999-9999-999999999999', 'Local Police Control Room', '999', 'police'),
      ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Emergency Ambulance', '1994', 'ambulance'),
      ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Fire Service', '16163', 'fire')
    ON CONFLICT (id) DO NOTHING;
  END IF;
END $$;
