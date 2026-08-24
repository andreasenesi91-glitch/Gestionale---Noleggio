-- Rentix customer-form information content.
-- Run once in the existing Supabase SQL editor.
-- The admin editor seeds the two existing default items for each operator
-- when that operator's new table is empty.

CREATE TABLE IF NOT EXISTS public.rentix_customer_form_info (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    TEXT NOT NULL,
  title      TEXT NOT NULL,
  content    TEXT NOT NULL,
  enabled    BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS rentix_customer_form_info_user_order_idx
  ON public.rentix_customer_form_info (user_id, sort_order, created_at);

-- Preserve the two information sections already shown by request.html
-- for every existing operator. Safe to re-run.
INSERT INTO public.rentix_customer_form_info (user_id, title, content, enabled, sort_order)
SELECT s.user_id, defaults.title, defaults.content, TRUE, defaults.sort_order
FROM public.rentix_account_setup AS s
CROSS JOIN (VALUES
  ('Riconsegna a negozio chiuso',
   'Per la riconsegna a negozio chiuso, ossia il sabato pomeriggio e la domenica, sarà applicato un supplemento di €5 per ogni bicicletta. Questo supplemento non è incluso nel preventivo mostrato in fondo alla pagina e, se dovuto, sarà aggiunto separatamente.',
   0),
  ('Lucchetti standard',
   'I lucchetti standard sono gratuiti. In caso di smarrimento del lucchetto o della chiave, sarà applicato un supplemento di €5 al momento della riconsegna della bicicletta.',
   1)
) AS defaults(title, content, sort_order)
WHERE NOT EXISTS (
  SELECT 1 FROM public.rentix_customer_form_info AS i WHERE i.user_id = s.user_id
);

ALTER TABLE public.rentix_customer_form_info ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Operators manage own customer form info"
  ON public.rentix_customer_form_info;
CREATE POLICY "Operators manage own customer form info"
  ON public.rentix_customer_form_info
  FOR ALL TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

CREATE OR REPLACE FUNCTION public.get_public_customer_form_info(operator_id TEXT)
RETURNS TABLE (
  id UUID,
  title TEXT,
  content TEXT,
  enabled BOOLEAN,
  sort_order INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT i.id, i.title, i.content, i.enabled, i.sort_order
  FROM public.rentix_customer_form_info AS i
  WHERE i.user_id = operator_id
    AND i.enabled = TRUE
  ORDER BY i.sort_order ASC, i.created_at ASC;
$$;

REVOKE ALL ON FUNCTION public.get_public_customer_form_info(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_public_customer_form_info(TEXT) TO anon, authenticated;