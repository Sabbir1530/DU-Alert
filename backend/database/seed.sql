-- DU Alert seed data
-- Uses deterministic UUIDs for predictable local development.

INSERT INTO users (id, name, email, password, role)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Admin User', 'admin@dualert.local', '$2b$10$wSk5iD9M9h9qvJ7sABj7Yej0hD8e5Ko0VhQJviU1WmV4h6S4jvWjm', 'admin'),
  ('22222222-2222-2222-2222-222222222222', 'Test Student', 'student@dualert.local', '$2b$10$wSk5iD9M9h9qvJ7sABj7Yej0hD8e5Ko0VhQJviU1WmV4h6S4jvWjm', 'student'),
  ('33333333-3333-3333-3333-333333333333', 'Test Proctor', 'proctor@dualert.local', '$2b$10$wSk5iD9M9h9qvJ7sABj7Yej0hD8e5Ko0VhQJviU1WmV4h6S4jvWjm', 'proctor')
ON CONFLICT (email) DO NOTHING;

INSERT INTO incidents (id, user_id, title, description, location, status)
VALUES
  (
    '44444444-4444-4444-4444-444444444444',
    '22222222-2222-2222-2222-222222222222',
    'Suspicious Activity Near Gate 2',
    'A person has been loitering near Gate 2 for over an hour and recording videos of students.',
    'Gate 2, DU Campus',
    'open'
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    '22222222-2222-2222-2222-222222222222',
    'Bike Theft in Parking Area',
    'A black bicycle was stolen from the engineering parking lot between 10:00 and 11:00.',
    'Engineering Parking, DU Campus',
    'in_progress'
  )
ON CONFLICT (id) DO NOTHING;

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

INSERT INTO emergency_contacts (id, name, phone, type)
VALUES
  ('88888888-8888-8888-8888-888888888888', 'Campus Security', '+8801700000001', 'security'),
  ('99999999-9999-9999-9999-999999999999', 'Local Police Control Room', '999', 'police'),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Emergency Ambulance', '1994', 'ambulance'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Fire Service', '16163', 'fire')
ON CONFLICT (id) DO NOTHING;
