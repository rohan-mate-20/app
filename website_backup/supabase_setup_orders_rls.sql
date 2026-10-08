-- =========================================================================
-- K-MART SUPABASE ROW LEVEL SECURITY (RLS) POLICIES FOR ORDERS & CUSTOMERS
-- =========================================================================
-- Run this script in your Supabase Dashboard:
-- 1. Go to https://supabase.com/dashboard/project/rcrvqrmvzvjjsmvdezts
-- 2. Open "SQL Editor" in the left sidebar
-- 3. Click "New Query", paste this entire script, and click "Run" (or Ctrl + Enter)
-- =========================================================================

-- 1. CUSTOMERS TABLE
ALTER TABLE IF EXISTS customers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon and auth all customers" ON customers;
CREATE POLICY "Allow anon and auth all customers"
  ON customers
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 2. ORDERS TABLE
ALTER TABLE IF EXISTS orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon and auth all orders" ON orders;
CREATE POLICY "Allow anon and auth all orders"
  ON orders
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 3. ORDER ITEMS TABLE
ALTER TABLE IF EXISTS order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon and auth all order_items" ON order_items;
CREATE POLICY "Allow anon and auth all order_items"
  ON order_items
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 4. ORDER STATUS HISTORY TABLE
ALTER TABLE IF EXISTS order_status_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon and auth all order_status_history" ON order_status_history;
CREATE POLICY "Allow anon and auth all order_status_history"
  ON order_status_history
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 5. ADDRESSES TABLE
ALTER TABLE IF EXISTS addresses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon and auth all addresses" ON addresses;
CREATE POLICY "Allow anon and auth all addresses"
  ON addresses
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 6. CARTS & CART ITEMS
ALTER TABLE IF EXISTS carts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon and auth all carts" ON carts;
CREATE POLICY "Allow anon and auth all carts"
  ON carts
  FOR ALL
  USING (true)
  WITH CHECK (true);

ALTER TABLE IF EXISTS cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon and auth all cart_items" ON cart_items;
CREATE POLICY "Allow anon and auth all cart_items"
  ON cart_items
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 7. PAYMENTS TABLE (if present)
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'payments') THEN
    EXECUTE 'ALTER TABLE payments ENABLE ROW LEVEL SECURITY;';
    EXECUTE 'DROP POLICY IF EXISTS "Allow anon and auth all payments" ON payments;';
    EXECUTE 'CREATE POLICY "Allow anon and auth all payments" ON payments FOR ALL USING (true) WITH CHECK (true);';
  END IF;
END $$;
