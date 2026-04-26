-- Migration: Add AI summary fields to complaints table
-- This migration adds support for caching AI-generated summaries

ALTER TABLE complaints
ADD COLUMN IF NOT EXISTS summary TEXT,
ADD COLUMN IF NOT EXISTS summarized_at TIMESTAMPTZ;

-- Index for efficient query of complaints with cached summaries
CREATE INDEX IF NOT EXISTS idx_complaints_summarized_at ON complaints(summarized_at);
