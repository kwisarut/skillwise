-- =============================================================================
-- SkillwisE — ตรวจว่ากฎในฐานข้อมูลทำงานจริง
-- =============================================================================
-- รันหลัง schema.sql → seed.sql → rls.sql ทุกข้อ (35 ข้อ) ต้องขึ้น NOTICE "OK"
-- ถ้าข้อไหนไม่เป็นตามคาด จะขึ้น ERROR "FAIL ..." แล้วหยุด
-- ไฟล์นี้ ROLLBACK ตอนจบ จึงไม่เปลี่ยนข้อมูลในฐาน
--
-- ข้อในวงเล็บ [5.7 #n] / [6.9 #n] คือกรณีทดสอบบังคับในแผนระบบที่ข้อนี้ครอบคลุมในชั้นฐานข้อมูล
-- กรณีที่เหลือ (เช่น ตรวจลายเซ็นข้อความจากระบบรับเงิน, ส่ง LINE) ต้องเทสใน apps/api ดู README หัวข้อ 4
--
-- วิธีรัน: psql -v ON_ERROR_STOP=1 -f checks.sql
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- ก. สิทธิ์และเครดิต
-- ---------------------------------------------------------------------------

-- 1. บัญชีใหม่ได้สมาชิกฟรีพร้อมเครดิต 2 + 2 [5.7 #1]
DO $$ BEGIN
  IF credit_balance('a1000000-0000-4000-8000-000000000001', NULL, 'coach_session') <> 2
     OR credit_balance('a1000000-0000-4000-8000-000000000001', NULL, 'canvas_analysis') <> 2 THEN
    RAISE EXCEPTION 'FAIL 1: เครดิตตั้งต้นของสมาชิกฟรีไม่ใช่ 2 + 2';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM active_entitlements
                  WHERE holder_user_id = 'a1000000-0000-4000-8000-000000000001'
                    AND entitlement_code = 'classroom.limit' AND entitlement_value = 1) THEN
    RAISE EXCEPTION 'FAIL 1: สมาชิกฟรีไม่ได้ห้องเรียน 1 ห้อง';
  END IF;
  RAISE NOTICE 'OK 1: บัญชีใหม่ได้สมาชิกฟรี ห้องเรียน 1 ห้อง และเครดิตโค้ช 2 + วิเคราะห์ 2';
END $$;

-- 2. กดรหัสก่อนเปิด Pro → Pro รอเริ่ม (ไม่มีวันเริ่ม) · วิดีโอและคู่มือใช้ได้ทันที [5.7 #2]
DO $$ BEGIN
  IF (SELECT status FROM grant_statuses WHERE id = 'c5000000-0000-4000-8000-000000000022') <> 'pending'
     OR (SELECT starts_at FROM grants WHERE id = 'c5000000-0000-4000-8000-000000000022') IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL 2: Pro จากรหัสไม่อยู่ในสถานะรอเริ่ม';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM active_entitlements
                  WHERE holder_user_id = 'a1000000-0000-4000-8000-000000000003' AND entitlement_code = 'cards.teacher_edition')
     OR EXISTS (SELECT 1 FROM active_entitlements
                 WHERE holder_user_id = 'a1000000-0000-4000-8000-000000000003' AND entitlement_code = 'pro') THEN
    RAISE EXCEPTION 'FAIL 2: สิทธิ์ส่วนได้ทันที / ส่วน Pro ไม่ถูกต้อง';
  END IF;
  RAISE NOTICE 'OK 2: กดรหัสก่อนเปิด Pro → Pro รอเริ่ม ส่วนวิดีโอและคู่มือใช้ได้ทันที';
END $$;

-- 3. วันเปิด Pro มาถึง → Pro ที่รอเริ่มนับ 3 เดือนจากวันเปิด [5.7 #3]
DO $$
DECLARE
  launch timestamptz := now() - interval '1 minute';
BEGIN
  UPDATE system_settings SET value = to_jsonb(launch) WHERE key = 'pro_launch_at';
  UPDATE grants g
     SET starts_at = launch, ends_at = launch + make_interval(months => p.duration_months)
    FROM plan_version_parts p
   WHERE p.id = g.part_id AND g.starts_at IS NULL AND g.start_condition = 'pro_launch' AND g.cancelled_at IS NULL;
  IF (SELECT status FROM grant_statuses WHERE id = 'c5000000-0000-4000-8000-000000000022') <> 'active'
     OR (SELECT ends_at FROM grants WHERE id = 'c5000000-0000-4000-8000-000000000022') <> launch + interval '3 months' THEN
    RAISE EXCEPTION 'FAIL 3: Pro ที่รอเริ่มไม่เริ่มนับจากวันเปิด';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM active_entitlements
                  WHERE holder_user_id = 'a1000000-0000-4000-8000-000000000003' AND entitlement_code = 'pro') THEN
    RAISE EXCEPTION 'FAIL 3: ยังไม่ได้สิทธิ์ pro หลังเปิดระบบ';
  END IF;
  RAISE NOTICE 'OK 3: เปิดระบบ Pro → Pro ที่รอเริ่มได้ 3 เดือนนับจากวันเปิด';
END $$;

-- 4. วันเริ่มที่กรอกแล้วแก้ไม่ได้ (การเปลี่ยนสิทธิ์ต้องเป็นรายการใหม่)
DO $$ BEGIN
  UPDATE grants SET starts_at = now() WHERE id = 'c5000000-0000-4000-8000-000000000022';
  RAISE EXCEPTION 'FAIL 4: แก้วันเริ่มของการได้สิทธิ์ได้';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK 4: วันเริ่มที่กรอกแล้วแก้ไม่ได้';
END $$;

-- 5. การได้สิทธิ์ลบไม่ได้ ต้องบันทึกการยกเลิกแทน
DO $$ BEGIN
  DELETE FROM grants WHERE id = 'c5000000-0000-4000-8000-000000000021';
  RAISE EXCEPTION 'FAIL 5: ลบการได้สิทธิ์ได้';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK 5: การได้สิทธิ์ลบไม่ได้';
END $$;

-- 6. หักเครดิตจากก้อนที่หมดอายุก่อนก่อน และหักข้ามก้อนได้ [5.7 #14]
DO $$
DECLARE
  first_use  credit_ledger;
  used_lots  integer;
BEGIN
  SELECT * INTO first_use FROM use_credit('a1000000-0000-4000-8000-000000000002', NULL, 'coach_session', 1, 'canvas', 'check-6', NULL);
  IF (SELECT expires_at FROM credit_ledger WHERE id = first_use.lot_id) IS DISTINCT FROM
     (SELECT min(expires_at) FROM credit_lots
       WHERE holder_user_id = 'a1000000-0000-4000-8000-000000000002' AND credit_type_code = 'coach_session' AND NOT is_expired) THEN
    RAISE EXCEPTION 'FAIL 6: ไม่ได้หักจากก้อนที่หมดอายุก่อน';
  END IF;
  -- ก้อนรายเดือนเหลือ 6 · หัก 8 = ก้อนรายเดือน 6 + ชุดเติม 2
  SELECT count(*) INTO used_lots FROM use_credit('a1000000-0000-4000-8000-000000000002', NULL, 'coach_session', 8, 'canvas', 'check-6b', NULL);
  IF used_lots <> 2 OR credit_balance('a1000000-0000-4000-8000-000000000002', NULL, 'coach_session') <> 10 THEN
    RAISE EXCEPTION 'FAIL 6: หักข้ามก้อนไม่ถูกต้อง';
  END IF;
  RAISE NOTICE 'OK 6: หักเครดิตจากก้อนที่หมดอายุก่อนก่อน และหักข้ามก้อนได้';
END $$;

-- 7. หักเกินยอดไม่ได้ และไม่หักไปบางส่วน [5.7 #12]
DO $$ BEGIN
  BEGIN
    PERFORM use_credit('a1000000-0000-4000-8000-000000000001', NULL, 'coach_session', 3, 'canvas', 'check-7', NULL);
    RAISE EXCEPTION 'FAIL 7: หักเกินยอดได้';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF credit_balance('a1000000-0000-4000-8000-000000000001', NULL, 'coach_session') <> 2 THEN
    RAISE EXCEPTION 'FAIL 7: หักไม่สำเร็จแต่ยอดลดไปบางส่วน';
  END IF;
  RAISE NOTICE 'OK 7: หักเกินยอดไม่ได้ และยอดไม่ลดไปบางส่วน';
END $$;

-- 8. เหลือ 1 แล้วหักครั้งละ 2 (ร่างทั้งใบ) ไม่ได้ [5.7 #12]
DO $$ BEGIN
  PERFORM use_credit('a1000000-0000-4000-8000-000000000001', NULL, 'coach_session', 1, 'canvas', 'check-8', NULL);
  BEGIN
    PERFORM use_credit('a1000000-0000-4000-8000-000000000001', NULL, 'coach_session', 2, 'canvas', 'check-8b', NULL);
    RAISE EXCEPTION 'FAIL 8: หัก 2 ได้ทั้งที่เหลือ 1';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  IF credit_balance('a1000000-0000-4000-8000-000000000001', NULL, 'coach_session') <> 1 THEN
    RAISE EXCEPTION 'FAIL 8: ยอดคงเหลือไม่ใช่ 1';
  END IF;
  RAISE NOTICE 'OK 8: เหลือ 1 แล้วหักครั้งละ 2 ไม่ได้';
END $$;

-- 9. ก้อนที่หมดอายุแล้วไม่นับในยอด และหักจากก้อนนั้นตรง ๆ ไม่ได้ [5.7 #14]
DO $$
DECLARE
  expired_lot bigint;
BEGIN
  SELECT id INTO expired_lot FROM credit_lots
   WHERE holder_user_id = 'a1000000-0000-4000-8000-000000000002' AND credit_type_code = 'coach_session' AND is_expired;
  INSERT INTO credit_ledger (holder_user_id, credit_type_code, entry_type, amount, lot_id)
  VALUES ('a1000000-0000-4000-8000-000000000002', 'coach_session', 'use', -1, expired_lot);
  RAISE EXCEPTION 'FAIL 9: หักจากก้อนที่หมดอายุได้';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK 9: ก้อนที่หมดอายุไม่นับในยอด และหักไม่ได้';
END $$;

-- 10. งาน AI ผิดพลาด → คืนเครดิตได้ และคืนได้ครั้งเดียว [5.7 #13]
DO $$
DECLARE
  used credit_ledger;
BEGIN
  SELECT * INTO used FROM use_credit('a1000000-0000-4000-8000-000000000001', NULL, 'canvas_analysis', 1, 'canvas', 'check-10', NULL);
  INSERT INTO credit_ledger (holder_user_id, credit_type_code, entry_type, amount, lot_id, reverses_id, reason)
  VALUES (used.holder_user_id, used.credit_type_code, 'return', 1, used.lot_id, used.id, 'งาน AI ผิดพลาด');
  IF credit_balance('a1000000-0000-4000-8000-000000000001', NULL, 'canvas_analysis') <> 2 THEN
    RAISE EXCEPTION 'FAIL 10: คืนเครดิตแล้วยอดไม่กลับมา';
  END IF;
  BEGIN
    INSERT INTO credit_ledger (holder_user_id, credit_type_code, entry_type, amount, lot_id, reverses_id, reason)
    VALUES (used.holder_user_id, used.credit_type_code, 'return', 1, used.lot_id, used.id, 'คืนซ้ำ');
    RAISE EXCEPTION 'FAIL 10: คืนเครดิตซ้ำได้';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  RAISE NOTICE 'OK 10: งาน AI ผิดพลาดคืนเครดิตได้ และคืนได้ครั้งเดียว';
END $$;

-- 11. คูปองผู้ซื้อการ์ดได้ครั้งเดียวต่อบัญชี (กดรหัสภายหลังไม่ได้ซ้ำ) [5.7 #10]
DO $$ BEGIN
  INSERT INTO credit_ledger (holder_user_id, credit_type_code, entry_type, amount, expires_at, reason)
  VALUES ('a1000000-0000-4000-8000-000000000003', 'voucher.zoom30', 'grant', 1, now() + interval '12 months', 'ทดสอบได้คูปองซ้ำ');
  RAISE EXCEPTION 'FAIL 11: ได้คูปองซ้ำ';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'OK 11: คูปองผู้ซื้อการ์ดได้ครั้งเดียวต่อบัญชี';
END $$;

-- 12. สมุดเครดิตแก้ไม่ได้
DO $$ BEGIN
  UPDATE credit_ledger SET amount = 100 WHERE holder_user_id = 'a1000000-0000-4000-8000-000000000001';
  RAISE EXCEPTION 'FAIL 12: แก้สมุดเครดิตได้';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK 12: สมุดเครดิตแก้ไม่ได้';
END $$;

-- 13. รายการในแพ็กเกจที่ออกแล้วแก้ไม่ได้ ต้องสร้างเวอร์ชันใหม่
DO $$ BEGIN
  UPDATE plan_version_items SET credit_amount = 99 WHERE credit_type_code = 'coach_session';
  RAISE EXCEPTION 'FAIL 13: แก้แพ็กเกจเวอร์ชันเดิมได้';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK 13: แพ็กเกจเวอร์ชันเดิมแก้ไม่ได้';
END $$;

-- 14. Pro รายเดือนไม่มี seat.free_zoom · Pro รายปีมี [5.7 #8]
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM plan_version_items WHERE part_id = 'c3000000-0000-4000-8000-000000000003' AND entitlement_code = 'seat.free_zoom')
     OR NOT EXISTS (SELECT 1 FROM plan_version_items WHERE part_id = 'c3000000-0000-4000-8000-000000000002' AND entitlement_code = 'seat.free_zoom') THEN
    RAISE EXCEPTION 'FAIL 14: สิทธิ์ที่นั่งฟรีของ Pro รายเดือน/รายปีไม่ถูกต้อง';
  END IF;
  RAISE NOTICE 'OK 14: Pro รายเดือนไม่มีที่นั่งฟรี Pro รายปีมี';
END $$;

-- 15. ห้องเรียน: สมาชิกฟรี 1 + โบนัสสมุด 1 = 2 ห้อง (ค่ามากสุดของพื้นฐาน + ผลรวมโบนัส) [5.7 #11]
DO $$
DECLARE
  rooms numeric;
BEGIN
  INSERT INTO grants (holder_user_id, plan_version_id, part_id, source_type, source_batch_id, starts_at, ends_at, reason, created_by)
  VALUES ('a1000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000008', 'c3000000-0000-4000-8000-000000000009',
          'staff', gen_random_uuid(), now(), now() + interval '12 months', 'ทดสอบโบนัสห้องเรียน', 'a1000000-0000-4000-8000-000000000014');
  SELECT coalesce(max(entitlement_value) FILTER (WHERE entitlement_code = 'classroom.limit'), 0)
       + coalesce(sum(entitlement_value) FILTER (WHERE entitlement_code = 'classroom.bonus'), 0)
    INTO rooms
    FROM active_entitlements WHERE holder_user_id = 'a1000000-0000-4000-8000-000000000001';
  IF rooms <> 2 THEN
    RAISE EXCEPTION 'FAIL 15: จำนวนห้องเรียนได้ % ไม่ใช่ 2', rooms;
  END IF;
  RAISE NOTICE 'OK 15: สมาชิกฟรี 1 + โบนัสสมุด 1 = 2 ห้อง';
END $$;


-- ---------------------------------------------------------------------------
-- ข. ซื้อขาย รับเงิน และสต็อก
-- ---------------------------------------------------------------------------

-- 16. ราคาขั้นจำนวน (4 ชุดราคาปกติ, 5 ชุดราคาโรงเรียน) และราคาช่วงโปรโมชัน [6.9 #7]
DO $$ BEGIN
  IF unit_price('d1000000-0000-4000-8000-000000000001', 4) <> 50000
     OR unit_price('d1000000-0000-4000-8000-000000000001', 5) <> 45000 THEN
    RAISE EXCEPTION 'FAIL 16: ราคาขั้นจำนวนไม่ถูกต้อง';
  END IF;
  INSERT INTO prices (product_id, price_satang, min_quantity, valid_from, valid_until)
  VALUES ('d1000000-0000-4000-8000-000000000001', 39000, 1, now() - interval '1 hour', now() + interval '1 day');
  IF unit_price('d1000000-0000-4000-8000-000000000001', 1) <> 39000
     OR unit_price('d1000000-0000-4000-8000-000000000001', 1, now() + interval '2 days') <> 50000
     OR unit_price('d1000000-0000-4000-8000-000000000001', 5) <> 45000 THEN
    RAISE EXCEPTION 'FAIL 16: ราคาช่วงโปรโมชันไม่ถูกต้อง';
  END IF;
  RAISE NOTICE 'OK 16: ราคาขั้นจำนวนและราคาช่วงโปรโมชันถูกต้อง';
END $$;

-- 17. ยอดคำสั่งซื้อต้องตรงสูตร: ยอดรวม = ก่อนส่วนลด − ส่วนลด + ค่าส่ง
DO $$ BEGIN
  INSERT INTO orders (order_number, buyer_user_id, subtotal_satang, discount_satang, shipping_satang, total_satang, amount_due_satang)
  VALUES ('CHECK-17', 'a1000000-0000-4000-8000-000000000001', 50000, 0, 5000, 50000, 50000);
  RAISE EXCEPTION 'FAIL 17: บันทึกยอดที่ไม่ตรงสูตรได้';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK 17: ยอดคำสั่งซื้อต้องตรงสูตร';
END $$;

-- 18. สถานะเดินตามลูกศรเท่านั้น: หลังแพ็กยกเลิกไม่ได้ · ก่อนแพ็กยกเลิกได้และบันทึกประวัติพร้อมผู้ทำ [6.9 #9]
DO $$ BEGIN
  BEGIN
    UPDATE orders SET status = 'cancelled' WHERE order_number = 'SW-000001';
    RAISE EXCEPTION 'FAIL 18: ยกเลิกคำสั่งซื้อที่ส่งของแล้วได้';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    UPDATE orders SET status = 'shipped' WHERE order_number = 'SW-000002';
    RAISE EXCEPTION 'FAIL 18: ข้ามขั้นจากรอตรวจเงินไปส่งแล้วได้';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  PERFORM set_config('app.actor_user_id', 'a1000000-0000-4000-8000-000000000012', true);
  PERFORM set_config('app.status_reason', 'ลูกค้าขอยกเลิก', true);
  UPDATE orders SET status = 'cancelled' WHERE order_number = 'SW-000002';
  IF NOT EXISTS (SELECT 1 FROM order_status_history h JOIN orders o ON o.id = h.order_id
                  WHERE o.order_number = 'SW-000002' AND h.to_status = 'cancelled'
                    AND h.actor_user_id = 'a1000000-0000-4000-8000-000000000012' AND h.reason = 'ลูกค้าขอยกเลิก') THEN
    RAISE EXCEPTION 'FAIL 18: ไม่ได้บันทึกประวัติการเปลี่ยนสถานะ';
  END IF;
  PERFORM set_config('app.actor_user_id', '', true);
  PERFORM set_config('app.status_reason', '', true);
  RAISE NOTICE 'OK 18: สถานะเดินตามลูกศร หลังแพ็กยกเลิกไม่ได้ และบันทึกประวัติพร้อมผู้ทำ';
END $$;

-- 19. คำสั่งซื้อที่ชำระแล้วแก้ยอดเงินไม่ได้
DO $$ BEGIN
  UPDATE orders SET shipping_satang = 0, total_satang = 58000, amount_due_satang = 58000 WHERE order_number = 'SW-000005';
  RAISE EXCEPTION 'FAIL 19: แก้ยอดคำสั่งซื้อที่ชำระแล้วได้';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK 19: คำสั่งซื้อที่ชำระแล้วแก้ยอดเงินไม่ได้';
END $$;

-- 20. ระบบรับเงินส่งข้อความเดิมซ้ำ → บันทึกซ้ำไม่ได้ จึงไม่เปิดสิทธิ์ซ้ำ [6.9 #2]
DO $$ BEGIN
  INSERT INTO payment_events (provider, provider_event_id, event_type, payload)
  VALUES ('opn', 'evnt_test_000005', 'charge.complete', '{}');
  RAISE EXCEPTION 'FAIL 20: บันทึกข้อความซ้ำได้';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'OK 20: ข้อความจากระบบรับเงินซ้ำบันทึกซ้ำไม่ได้';
END $$;

-- 21. รายการจ่ายเงินที่สำเร็จแล้วแก้ยอดหรือเปลี่ยนสถานะไม่ได้
DO $$ BEGIN
  BEGIN
    UPDATE payments SET amount_satang = 1 WHERE id = '63000000-0000-4000-8000-000000000005';
    RAISE EXCEPTION 'FAIL 21: แก้ยอดรายการจ่ายเงินได้';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    UPDATE payments SET status = 'failed' WHERE id = '63000000-0000-4000-8000-000000000005';
    RAISE EXCEPTION 'FAIL 21: เปลี่ยนสถานะรายการที่จ่ายสำเร็จแล้วได้';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  RAISE NOTICE 'OK 21: รายการจ่ายเงินที่สำเร็จแล้วแก้ยอดหรือสถานะไม่ได้';
END $$;

-- 22. โอนแนบสลิปจะเป็น "จ่ายสำเร็จ" ได้ต้องมีทีมงานยืนยัน [6.9 #6]
DO $$ BEGIN
  INSERT INTO payments (order_id, provider, method, amount_satang, status)
  VALUES ('61000000-0000-4000-8000-000000000003', 'bank_transfer', 'transfer', 5000, 'succeeded');
  RAISE EXCEPTION 'FAIL 22: ยืนยันการโอนโดยไม่มีผู้ตรวจได้';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK 22: การโอนต้องมีทีมงานยืนยันก่อนเป็นจ่ายสำเร็จ';
END $$;

-- 23. คืนเงินรวมเกินยอดที่จ่ายไม่ได้ [6.9 #13]
DO $$ BEGIN
  INSERT INTO refunds (payment_id, amount_satang, method, reason, requested_by)
  VALUES ('63000000-0000-4000-8000-000000000005', 60000, 'manual_transfer', 'ยกเลิกที่นั่ง', 'a1000000-0000-4000-8000-000000000012');
  BEGIN
    INSERT INTO refunds (payment_id, amount_satang, method, reason, requested_by)
    VALUES ('63000000-0000-4000-8000-000000000005', 3001, 'manual_transfer', 'คืนเพิ่ม', 'a1000000-0000-4000-8000-000000000012');
    RAISE EXCEPTION 'FAIL 23: คืนเงินรวมเกินยอดที่จ่ายได้';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  RAISE NOTICE 'OK 23: คืนเงินรวมเกินยอดที่จ่ายไม่ได้';
END $$;

-- 24. สต็อกเหลือ 1 ชิ้น 2 คำสั่งซื้อกันของพร้อมกัน → ได้คำสั่งซื้อเดียว · กันของที่หมดเวลาคืนสต็อกเอง [6.9 #10]
DO $$
DECLARE
  first_hold uuid;
BEGIN
  INSERT INTO products (id, code, product_type, name, tracks_stock, is_on_sale)
  VALUES ('d1000000-0000-4000-8000-000000000099', 'check_last_item', 'physical', 'สินค้าทดสอบชิ้นสุดท้าย', true, true);
  INSERT INTO inventory_movements (product_id, quantity, movement_type) VALUES ('d1000000-0000-4000-8000-000000000099', 1, 'receive');
  first_hold := hold_stock('d1000000-0000-4000-8000-000000000099', '61000000-0000-4000-8000-000000000002', 1, now() + interval '1 hour');
  BEGIN
    PERFORM hold_stock('d1000000-0000-4000-8000-000000000099', '61000000-0000-4000-8000-000000000003', 1, now() + interval '1 hour');
    RAISE EXCEPTION 'FAIL 24: ชิ้นสุดท้ายถูกกันได้ 2 ครั้ง';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  UPDATE inventory_holds SET expires_at = now() - interval '1 second' WHERE id = first_hold;
  IF (SELECT available FROM product_stock WHERE product_id = 'd1000000-0000-4000-8000-000000000099') <> 1 THEN
    RAISE EXCEPTION 'FAIL 24: กันของที่หมดเวลาแล้วไม่คืนสต็อก';
  END IF;
  RAISE NOTICE 'OK 24: ชิ้นสุดท้ายกันได้คำสั่งซื้อเดียว และกันของที่หมดเวลาคืนสต็อกเอง';
END $$;

-- 25. กองที่นั่งเต็มแล้วจองเพิ่มไม่ได้ (กองทดสอบนี้ใช้ต่อในข้อ 35)
INSERT INTO seat_pools (id, event_id, name, capacity)
VALUES ('f2000000-0000-4000-8000-000000000099', 'f1000000-0000-4000-8000-000000000001', 'กองทดสอบ 1 ที่', 1);
INSERT INTO seat_bookings (seat_pool_id, user_id, booked_by, status)
VALUES ('f2000000-0000-4000-8000-000000000099', 'a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'booked');
DO $$ BEGIN
  INSERT INTO seat_bookings (seat_pool_id, user_id, booked_by, status)
  VALUES ('f2000000-0000-4000-8000-000000000099', 'a1000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-000000000002', 'booked');
  RAISE EXCEPTION 'FAIL 25: จองเกินจำนวนที่นั่งได้';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK 25: กองที่นั่งเต็มแล้วจองเพิ่มไม่ได้';
END $$;


-- ---------------------------------------------------------------------------
-- ค. เอกสารการเงินและรหัสในกล่อง
-- ---------------------------------------------------------------------------

-- 26. เลขที่เอกสารเรียงต่อเนื่องและไม่ซ้ำ [6.9 #14]
DO $$
DECLARE
  n1 integer := next_document_number('credit_note', 2599);
  n2 integer := next_document_number('credit_note', 2599);
BEGIN
  IF n1 <> 1 OR n2 <> 2 THEN
    RAISE EXCEPTION 'FAIL 26: เลขที่เอกสารไม่ต่อเนื่อง (% , %)', n1, n2;
  END IF;
  BEGIN
    INSERT INTO financial_documents (doc_type, seq_year, seq_number, doc_number, order_id, buyer_snapshot, items_snapshot,
                                     subtotal_satang, total_satang, amount_in_words)
    SELECT doc_type, seq_year, seq_number, doc_number || '-dup', order_id, buyer_snapshot, items_snapshot,
           subtotal_satang, total_satang, amount_in_words
      FROM financial_documents WHERE id = '65000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'FAIL 26: ออกเลขที่เอกสารซ้ำได้';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
  RAISE NOTICE 'OK 26: เลขที่เอกสารเรียงต่อเนื่องและไม่ซ้ำ';
END $$;

-- 27. เอกสารที่ออกแล้วแก้ยอดไม่ได้ · ยกเลิกได้ครั้งเดียวพร้อมเหตุผล
DO $$ BEGIN
  BEGIN
    UPDATE financial_documents SET total_satang = 1 WHERE id = '65000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'FAIL 27: แก้ยอดเอกสารที่ออกแล้วได้';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  UPDATE financial_documents
     SET voided_at = now(), voided_by = 'a1000000-0000-4000-8000-000000000012', void_reason = 'ทดสอบยกเลิก'
   WHERE id = '65000000-0000-4000-8000-000000000002';
  BEGIN
    UPDATE financial_documents SET void_reason = 'แก้เหตุผล' WHERE id = '65000000-0000-4000-8000-000000000002';
    RAISE EXCEPTION 'FAIL 27: แก้เหตุผลการยกเลิกได้';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK 27: เอกสารที่ออกแล้วแก้ไม่ได้ ยกเลิกได้ครั้งเดียว';
END $$;

-- 28. ใบเสนอราคาครบ 7 วันขึ้นในกล่องงาน "ควรโทรตาม" · โทรแล้วเปลี่ยนเป็น "โทรตามแล้ว" [6.9 #16]
DO $$ BEGIN
  IF (SELECT status FROM quotation_statuses WHERE id = '65000000-0000-4000-8000-000000000003') <> 'followup_due' THEN
    RAISE EXCEPTION 'FAIL 28: ใบเสนอราคาที่ออกมา 8 วันไม่ขึ้นว่าควรโทรตาม';
  END IF;
  INSERT INTO quotation_followups (quotation_id, called_by, outcome)
  VALUES ('65000000-0000-4000-8000-000000000003', 'a1000000-0000-4000-8000-000000000012', 'โรงเรียนรอเสนอผู้อำนวยการ');
  IF (SELECT status FROM quotation_statuses WHERE id = '65000000-0000-4000-8000-000000000003') <> 'called' THEN
    RAISE EXCEPTION 'FAIL 28: โทรตามแล้วสถานะไม่เปลี่ยน';
  END IF;
  RAISE NOTICE 'OK 28: ใบเสนอราคาเตือนให้โทรตาม และเปลี่ยนสถานะเมื่อโทรแล้ว';
END $$;

-- 29. รหัสที่กดแล้วกดซ้ำไม่ได้ · รหัสที่ยกเลิกแล้วกดไม่ได้
DO $$ BEGIN
  BEGIN
    UPDATE redeem_codes SET redeemed_by = 'a1000000-0000-4000-8000-000000000001'
     WHERE id = 'e2000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'FAIL 29: กดรหัสที่ใช้แล้วซ้ำได้';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    UPDATE redeem_codes
       SET redeemed_by = 'a1000000-0000-4000-8000-000000000001', redeemed_at = now(), grant_batch_id = gen_random_uuid()
     WHERE id = 'e2000000-0000-4000-8000-000000000003';
    RAISE EXCEPTION 'FAIL 29: กดรหัสที่ยกเลิกแล้วได้';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  RAISE NOTICE 'OK 29: รหัสที่กดแล้วกดซ้ำไม่ได้ และรหัสที่ยกเลิกแล้วกดไม่ได้';
END $$;

-- 30. ส่งออกรหัสให้โรงพิมพ์ได้ครั้งเดียว (ส่งซ้ำต้องผ่านสิทธิ์พิเศษและบันทึกใน audit_logs)
DO $$ BEGIN
  UPDATE code_batches SET exported_at = now() WHERE id = 'e1000000-0000-4000-8000-000000000001';
  RAISE EXCEPTION 'FAIL 30: บันทึกวันส่งออกทับได้';
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'OK 30: วันส่งออกรหัสให้โรงพิมพ์บันทึกได้ครั้งเดียว';
END $$;

-- 31. สลิปรับเฉพาะรูปภาพหรือ PDF
DO $$ BEGIN
  INSERT INTO files (purpose, storage_key, content_type, size_bytes)
  VALUES ('payment_slip', 'slips/check-31.txt', 'text/plain', 10);
  RAISE EXCEPTION 'FAIL 31: รับสลิปที่เป็นไฟล์ข้อความได้';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK 31: สลิปรับเฉพาะรูปภาพหรือ PDF';
END $$;

-- 32. บันทึกการเปลี่ยนแปลงและบันทึกการเปิดดูข้อมูลส่วนบุคคลลบหรือแก้ไม่ได้
DO $$ BEGIN
  BEGIN
    DELETE FROM audit_logs;
    RAISE EXCEPTION 'FAIL 32: ลบ audit_logs ได้';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    UPDATE pii_access_logs SET field = 'phone';
    RAISE EXCEPTION 'FAIL 32: แก้ pii_access_logs ได้';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RAISE NOTICE 'OK 32: บันทึกการเปลี่ยนแปลงและการเปิดดูข้อมูลส่วนบุคคลลบหรือแก้ไม่ได้';
END $$;


-- ---------------------------------------------------------------------------
-- ง. Row-Level Security (ต้องรัน rls.sql ก่อน)
-- ---------------------------------------------------------------------------

SET LOCAL ROLE skillwise_app;

-- 33. ครูเห็นเฉพาะคำสั่งซื้อของตัวเอง · ทีมงานที่ผ่านการตรวจสิทธิ์เห็นทั้งหมด
DO $$
DECLARE
  mine integer;
  all_orders integer;
BEGIN
  PERFORM set_config('app.user_id', 'a1000000-0000-4000-8000-000000000003', true);
  SELECT count(*) INTO mine FROM orders;
  PERFORM set_config('app.is_staff', 'on', true);
  SELECT count(*) INTO all_orders FROM orders;
  PERFORM set_config('app.is_staff', '', true);
  IF mine <> 2 OR all_orders <> 4 THEN
    RAISE EXCEPTION 'FAIL 33: ครูเห็นคำสั่งซื้อ % รายการ ทีมงานเห็น % รายการ', mine, all_orders;
  END IF;
  RAISE NOTICE 'OK 33: ครูเห็นเฉพาะคำสั่งซื้อของตัวเอง ทีมงานเห็นทั้งหมด';
END $$;

-- 34. ครูเห็นเฉพาะเครดิตของตัวเอง แม้จะอ่านผ่าน view
DO $$ BEGIN
  PERFORM set_config('app.user_id', 'a1000000-0000-4000-8000-000000000005', true);
  IF EXISTS (SELECT 1 FROM credit_lots WHERE holder_user_id <> 'a1000000-0000-4000-8000-000000000005')
     OR credit_balance('a1000000-0000-4000-8000-000000000002', NULL, 'coach_session') <> 0 THEN
    RAISE EXCEPTION 'FAIL 34: ครูเห็นเครดิตของคนอื่น';
  END IF;
  RAISE NOTICE 'OK 34: ครูเห็นเฉพาะเครดิตของตัวเอง แม้อ่านผ่าน view';
END $$;

-- 35. ที่นั่งเต็มยังกันได้ แม้ครูมองไม่เห็นการจองของคนอื่น
DO $$ BEGIN
  PERFORM set_config('app.user_id', 'a1000000-0000-4000-8000-000000000006', true);
  INSERT INTO seat_bookings (seat_pool_id, user_id, booked_by, status)
  VALUES ('f2000000-0000-4000-8000-000000000099', 'a1000000-0000-4000-8000-000000000006', 'a1000000-0000-4000-8000-000000000006', 'booked');
  RAISE EXCEPTION 'FAIL 35: จองเกินจำนวนที่นั่งได้เมื่อมองไม่เห็นการจองของคนอื่น';
EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK 35: ที่นั่งเต็มยังกันได้แม้มองไม่เห็นการจองของคนอื่น';
END $$;

RESET ROLE;

ROLLBACK;
