-- =============================================================================
-- SkillwisE — Row-Level Security (RLS) สำหรับข้อมูลของผู้ใช้แต่ละคน
-- =============================================================================
-- สถานะ: [DIRECTION] ชั้นป้องกันที่สองต่อจาก guard ของ NestJS ไม่ได้ใช้แทน guard
--   ถ้าโค้ด API ลืมใส่เงื่อนไข "ของผู้ใช้คนนี้" ฐานข้อมูลยังกันไม่ให้ครูเห็นคำสั่งซื้อ ที่อยู่
--   สิทธิ์ เครดิต หรือที่นั่งของคนอื่น (Context ข้อ 60.11.3)
--
-- กติกาที่ใช้
--   - ผู้ใช้เห็นและแก้ได้เฉพาะแถวของตัวเอง
--   - ทีมงานเห็นได้ทั้งหมด เมื่อ API ตรวจสิทธิ์ทีมงานแล้ว (API ตั้ง app.is_staff = 'on')
--   - ข้อมูลเด็ก (Phase 2) จะเพิ่ม policy ของตัวเองเมื่อสร้างตาราง: เห็นเฉพาะครูที่ดูแลห้อง (ข้อ 60.13.4)
--
-- วิธีใช้ใน API (ทุก transaction):
--   SET LOCAL app.user_id = '<uuid ของผู้ใช้>';
--   SET LOCAL app.is_staff = 'on';   -- เฉพาะทีมงานที่ guard ตรวจสิทธิ์แล้ว
-- API ต้องเชื่อมฐานด้วย role ที่ไม่ใช่เจ้าของตาราง (เช่น skillwise_app) เพราะเจ้าของตารางข้าม RLS ได้
--
-- วิธีรัน: หลัง schema.sql และ seed.sql
-- =============================================================================

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skillwise_app') THEN
    CREATE ROLE skillwise_app NOLOGIN;
  END IF;
END $$;

-- ไม่ให้สิทธิ์ DELETE เป็นค่าเริ่มต้น เพราะข้อมูลเงินและสิทธิ์ห้ามลบอยู่แล้ว · ให้เฉพาะตารางที่ลบได้จริง
GRANT USAGE ON SCHEMA public TO skillwise_app;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO skillwise_app;
GRANT DELETE ON addresses, product_waitlist TO skillwise_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO skillwise_app;

CREATE FUNCTION app_current_user_id() RETURNS uuid LANGUAGE sql STABLE AS
$$ SELECT nullif(current_setting('app.user_id', true), '')::uuid $$;

CREATE FUNCTION app_is_staff() RETURNS boolean LANGUAGE sql STABLE AS
$$ SELECT coalesce(current_setting('app.is_staff', true), '') = 'on' $$;

-- view อ่านตารางด้วยสิทธิ์ของคนที่เรียก จึงติด RLS ด้วย (ค่าเริ่มต้นของ view ใช้สิทธิ์เจ้าของซึ่งข้าม RLS)
ALTER VIEW grant_statuses       SET (security_invoker = true);
ALTER VIEW active_entitlements  SET (security_invoker = true);
ALTER VIEW credit_lots          SET (security_invoker = true);
ALTER VIEW order_payment_totals SET (security_invoker = true);
ALTER VIEW quotation_statuses   SET (security_invoker = true);

-- trigger ที่ต้องนับแถวของทุกคน (ที่นั่งเต็มหรือยัง) ต้องเห็นทุกแถว จึงรันด้วยสิทธิ์เจ้าของ
ALTER FUNCTION seat_bookings_capacity() SECURITY DEFINER SET search_path = public;

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY orders_owner_or_staff ON orders
  USING (buyer_user_id = app_current_user_id() OR app_is_staff());

ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;
CREATE POLICY addresses_owner_or_staff ON addresses
  USING (user_id = app_current_user_id() OR app_is_staff());

ALTER TABLE grants ENABLE ROW LEVEL SECURITY;
CREATE POLICY grants_owner_or_staff ON grants
  USING (holder_user_id = app_current_user_id() OR app_is_staff());

ALTER TABLE credit_ledger ENABLE ROW LEVEL SECURITY;
CREATE POLICY credit_ledger_owner_or_staff ON credit_ledger
  USING (holder_user_id = app_current_user_id() OR app_is_staff());

ALTER TABLE seat_bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY seat_bookings_owner_or_staff ON seat_bookings
  USING (user_id = app_current_user_id() OR booked_by = app_current_user_id() OR app_is_staff());

COMMIT;
