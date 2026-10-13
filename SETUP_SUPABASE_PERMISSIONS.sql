-- =========================================================================
-- K-MART SUPABASE PERMISSIONS FIX FOR ORDERS, CUSTOMERS & ADDRESSES
-- =========================================================================
-- How to apply this fix:
-- 1. Open your browser and go to: https://supabase.com/dashboard/project/rcrvqrmvzvjjsmvdezts
-- 2. Click "SQL Editor" in the left sidebar
-- 3. Click "New Query" (green button)
-- 4. Paste this entire script into the editor
-- 5. Click "Run" (or press Ctrl + Enter)
-- =========================================================================

-- 1. ORDERS TABLE
ALTER TABLE IF EXISTS orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon and auth all orders" ON orders;
CREATE POLICY "Allow anon and auth all orders"
  ON orders
  FOR ALL
  TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- 2. ORDER ITEMS TABLE
ALTER TABLE IF EXISTS order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon and auth all order_items" ON order_items;
CREATE POLICY "Allow anon and auth all order_items"
  ON order_items
  FOR ALL
  TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- 3. ORDER STATUS HISTORY TABLE
ALTER TABLE IF EXISTS order_status_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon and auth all order_status_history" ON order_status_history;
CREATE POLICY "Allow anon and auth all order_status_history"
  ON order_status_history
  FOR ALL
  TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- 4. CUSTOMERS TABLE
ALTER TABLE IF EXISTS customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon and auth all customers" ON customers;
CREATE POLICY "Allow anon and auth all customers"
  ON customers
  FOR ALL
  TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- 5. ADDRESSES TABLE
ALTER TABLE IF EXISTS addresses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon and auth all addresses" ON addresses;
CREATE POLICY "Allow anon and auth all addresses"
  ON addresses
  FOR ALL
  TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- 6. CARTS & CART ITEMS TABLES
ALTER TABLE IF EXISTS carts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon and auth all carts" ON carts;
CREATE POLICY "Allow anon and auth all carts"
  ON carts
  FOR ALL
  TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

ALTER TABLE IF EXISTS cart_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon and auth all cart_items" ON cart_items;
CREATE POLICY "Allow anon and auth all cart_items"
  ON cart_items
  FOR ALL
  TO anon, authenticated, service_role
  USING (true)
  WITH CHECK (true);

-- 7. PAYMENTS TABLE (if present)
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'payments') THEN
    EXECUTE 'ALTER TABLE payments ENABLE ROW LEVEL SECURITY;';
    EXECUTE 'DROP POLICY IF EXISTS "Allow anon and auth all payments" ON payments;';
    EXECUTE 'CREATE POLICY "Allow anon and auth all payments" ON payments FOR ALL TO anon, authenticated, service_role USING (true) WITH CHECK (true);';
    EXECUTE 'GRANT ALL ON TABLE payments TO anon, authenticated, service_role;';
  END IF;
END $$;

-- 8. GRANT FULL PERMISSIONS TO ALL ROLES
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
