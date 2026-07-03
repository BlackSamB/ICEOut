-- ═══════════════════════════════════════════════════════
-- I.C.E Out — Supabase Schema
-- Run this in your Supabase SQL Editor after creating a project
-- ═══════════════════════════════════════════════════════

-- 1. Reports table (anonymous, insert-only public access)
CREATE TABLE IF NOT EXISTS reports (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lat         DOUBLE PRECISION NOT NULL,
  lng         DOUBLE PRECISION NOT NULL,
  address     TEXT,                              -- optional manual address entry
  report_type TEXT NOT NULL CHECK (report_type IN (
    'raid', 'checkpoint', 'surveillance', 'patrol', 'detention_transport', 'other'
  )),
  description TEXT,
  severity    TEXT DEFAULT 'unverified' CHECK (severity IN (
    'unverified', 'confirmed', 'resolved'
  )),
  created_at  TIMESTAMPTZ DEFAULT now(),
  expires_at  TIMESTAMPTZ DEFAULT (now() + INTERVAL '72 hours')  -- auto-expire old reports
);

-- Index for spatial + time queries
CREATE INDEX idx_reports_location ON reports (lat, lng);
CREATE INDEX idx_reports_created  ON reports (created_at DESC);
CREATE INDEX idx_reports_type     ON reports (report_type);

-- 2. Facilities table (static data, read-only public access)
CREATE TABLE IF NOT EXISTS facilities (
  id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name     TEXT NOT NULL,
  fac_type TEXT NOT NULL CHECK (fac_type IN (
    'field_office', 'sub_office', 'detention_center',
    'processing_center', 'checkpoint', 'other'
  )),
  address  TEXT NOT NULL,
  lat      DOUBLE PRECISION NOT NULL,
  lng      DOUBLE PRECISION NOT NULL,
  phone    TEXT,
  hours    TEXT,
  notes    TEXT
);

CREATE INDEX idx_facilities_location ON facilities (lat, lng);

-- 3. Row Level Security (RLS)
-- Enable RLS on both tables
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE facilities ENABLE ROW LEVEL SECURITY;

-- Reports: anyone can INSERT (anonymous reporting)
CREATE POLICY "Anyone can submit reports"
  ON reports FOR INSERT
  WITH CHECK (true);

-- Reports: anyone can SELECT (public visibility)
CREATE POLICY "Anyone can view reports"
  ON reports FOR SELECT
  USING (true);

-- Reports: nobody can UPDATE or DELETE via API
-- (only admin via dashboard/service role)

-- Facilities: anyone can SELECT (public directory)
CREATE POLICY "Anyone can view facilities"
  ON facilities FOR SELECT
  USING (true);

-- Facilities: only admin can INSERT/UPDATE
-- (managed via Supabase dashboard or service role key)

-- 4. Enable Realtime for reports (new reports push to all clients)
ALTER PUBLICATION supabase_realtime ADD TABLE reports;

-- ═══════════════════════════════════════════════════════
-- SEED DATA: Colorado ICE facilities (public information)
-- Source: ice.gov/contact/ero
-- ═══════════════════════════════════════════════════════

INSERT INTO facilities (name, fac_type, address, lat, lng, phone, hours, notes) VALUES
  ('ICE Denver Field Office', 'field_office',
   '12445 E Caley Ave, Centennial, CO 80111',
   39.5977, -104.8535, '(303) 695-7921',
   'Mon-Fri 7:00 AM - 4:00 PM',
   'ERO Denver AOR covers Colorado, Wyoming, Utah'),

  ('ICE Denver Contract Detention Facility (GEO)', 'detention_center',
   '3130 N Oakland St, Aurora, CO 80010',
   39.7392, -104.8384, '(303) 361-0645',
   '24/7', 'GEO Group operated. ~1500 bed capacity.'),

  ('ICE Colorado Springs Sub-Office', 'sub_office',
   '1 S Cascade Ave, Colorado Springs, CO 80903',
   38.8339, -104.8253, '(719) 471-6186',
   'Mon-Fri 8:00 AM - 4:30 PM', NULL),

  ('ICE Grand Junction Sub-Office', 'sub_office',
   '400 Rood Ave, Grand Junction, CO 81501',
   39.0639, -108.5506, NULL,
   'Mon-Fri 8:00 AM - 4:30 PM', NULL),

  ('ICE Salt Lake City Field Office', 'field_office',
   '2975 S Decker Lake Dr, West Valley City, UT 84119',
   40.7007, -111.9388, '(801) 886-7400',
   'Mon-Fri 7:30 AM - 4:00 PM',
   'Covers Utah operations');
