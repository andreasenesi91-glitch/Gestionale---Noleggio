-- Run this once in the Supabase SQL editor for the existing rentix_rentals table.
-- The application does not execute this migration automatically.
ALTER TABLE public.rentix_rentals
  ADD COLUMN IF NOT EXISTS revenue_at TIMESTAMPTZ NULL;