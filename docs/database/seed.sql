-- =============================================================================
-- SkillwisE — ข้อมูลตัวอย่าง (mock data) สำหรับ schema.sql
-- =============================================================================
-- ใช้ทดสอบ schema และให้ทีมเห็นข้อมูลของ Phase 1 ไหลครบ:
-- ซื้อการ์ด → ตรวจสลิป → แพ็กส่ง → กดรหัสในกล่อง → ใช้คูปองจองเวิร์กช็อป · ใบเสนอราคาโรงเรียน
--
-- > ราคาและตัวเลขทั้งหมดเป็นข้อมูลตัวอย่าง (mockup) เปลี่ยนแปลงได้ ค่าจริงตั้งในหลังบ้าน
--   ตัวเลขที่ยัง [OPEN] (เช่น ราคาการ์ดชุดโรงเรียน ค่าส่ง อัตราหัก ณ ที่จ่าย) เป็นค่าสมมติ
-- ข้อมูลทั้งหมดแต่งขึ้น: ชื่อคนและชื่อโรงเรียนเป็นชื่อสมมติ อีเมลใช้โดเมน example.com
-- รหัสในกล่องเป็นรหัสทดสอบ เลขผู้เสียภาษีเป็นเลขสมมติ
--
-- วันที่คิดจากวันที่รัน seed (เขตเวลา Asia/Bangkok) ข้อมูลจึงสมเหตุสมผลทุกครั้งที่รัน
-- id เป็น uuid ที่ตั้งตายตัว อ่านง่ายและอ้างถึงกันได้:
--   a1 users · b1 schools_directory · b2 organizations · 91 files · 92 policy_documents
--   c1 plans · c2 plan_versions · c3 plan_version_parts · c5 grants
--   d1 products · e1 code_batches · e2 redeem_codes · e3 ชุดที่มาของการกดรหัส
--   f1 events · f2 seat_pools · f3 seat_bookings
--   61 orders · 63 payments · 64 shipments · 65 financial_documents
--
-- วิธีรัน: psql -v ON_ERROR_STOP=1 -f schema.sql -f seed.sql
-- =============================================================================

BEGIN;

-- ตัวช่วยเฉพาะ session นี้
CREATE FUNCTION pg_temp.ts(offset_days integer, hhmm text) RETURNS timestamptz LANGUAGE sql AS
$$ SELECT ((now() AT TIME ZONE 'Asia/Bangkok')::date + offset_days + hhmm::time) AT TIME ZONE 'Asia/Bangkok' $$;
CREATE FUNCTION pg_temp.be_year() RETURNS integer LANGUAGE sql AS
$$ SELECT extract(year FROM now() AT TIME ZONE 'Asia/Bangkok')::integer + 543 $$;
CREATE FUNCTION pg_temp.code_hash(code text) RETURNS text LANGUAGE sql AS
$$ SELECT encode(sha256(convert_to(upper(code), 'UTF8')), 'hex') $$;


-- -----------------------------------------------------------------------------
-- 1. ค่าตั้งระบบ
-- -----------------------------------------------------------------------------

INSERT INTO system_settings (key, value, description) VALUES
  ('pro_launch_at',              'null', 'วันเปิดระบบ Pro · null = ยังไม่เปิด Pro ที่ได้จากรหัสในกล่องจึงรอเริ่ม'),
  ('order_payment_window_hours', '24',   'คำสั่งซื้อปกติหมดเวลาชำระกี่ชั่วโมง [ค่าตัวอย่าง]'),
  ('promptpay_qr_minutes',       '15',   'QR พร้อมเพย์มีอายุกี่นาที'),
  ('quotation_valid_days',       '30',   'ใบเสนอราคายืนราคากี่วัน'),
  ('quotation_followup_days',    '7',    'ออกใบเสนอราคาครบกี่วันจึงเตือนทีมให้โทรตาม'),
  ('redeem_max_failures',        '5',    'กดรหัสผิดได้กี่ครั้งก่อนต้องรอ'),
  ('redeem_lock_minutes',        '15',   'กดรหัสผิดครบแล้วต้องรอกี่นาที'),
  ('code_redeem_reminder_days',  '5',    'ส่งของแล้วกี่วันจึงเตือนให้เปิดใช้รหัส'),
  ('voucher_valid_months',       '12',   'คูปองของผู้ซื้อการ์ดมีอายุกี่เดือน [OPEN ค่าตัวอย่าง]'),
  ('line_monthly_push_cap',      '500',  'เพดานข้อความ LINE ที่ระบบส่งเองต่อเดือน [ค่าตัวอย่าง รอตรวจแพ็กเกจ LINE OA]');


-- -----------------------------------------------------------------------------
-- 2. ผู้ใช้ ช่องทางเข้าสู่ระบบ ความยินยอม และที่อยู่
-- -----------------------------------------------------------------------------

INSERT INTO users (id, display_name, email, last_login_at, created_at) VALUES
  ('a1000000-0000-4000-8000-000000000001', 'ครูฟ้า',   'fah@example.com',        pg_temp.ts(-1, '19:30'), pg_temp.ts(-60, '09:00')),
  ('a1000000-0000-4000-8000-000000000002', 'ครูนนท์',  'non@example.com',        pg_temp.ts(0, '07:10'),  pg_temp.ts(-60, '09:05')),
  ('a1000000-0000-4000-8000-000000000003', 'ครูมะลิ',  'mali@example.com',       pg_temp.ts(-2, '20:00'), pg_temp.ts(-30, '18:00')),
  ('a1000000-0000-4000-8000-000000000004', 'ครูบี',    'bee@example.com',        pg_temp.ts(-8, '13:00'), pg_temp.ts(-25, '13:00')),
  ('a1000000-0000-4000-8000-000000000005', 'ครูต้น',   NULL,                     pg_temp.ts(0, '08:00'),  pg_temp.ts(-1, '21:00')),
  ('a1000000-0000-4000-8000-000000000006', 'ครูแก้ว',  'kaew@example.com',       pg_temp.ts(0, '09:30'),  pg_temp.ts(-2, '10:00')),
  ('a1000000-0000-4000-8000-000000000011', 'ทีมงานแพ็กของ', 'packing@example.com',    NULL, pg_temp.ts(-90, '09:00')),
  ('a1000000-0000-4000-8000-000000000012', 'ทีมงานบัญชี',   'accounting@example.com', NULL, pg_temp.ts(-90, '09:00')),
  ('a1000000-0000-4000-8000-000000000013', 'ทีมงานอบรม',    'training@example.com',   NULL, pg_temp.ts(-90, '09:00')),
  ('a1000000-0000-4000-8000-000000000014', 'ผู้ดูแลระบบ',    'admin@example.com',      NULL, pg_temp.ts(-90, '09:00'));

INSERT INTO auth_accounts (user_id, provider, provider_user_id, email_at_provider, line_is_friend, linked_at) VALUES
  ('a1000000-0000-4000-8000-000000000001', 'line',   'Ufah000000000000000000000000000001', NULL, true,  pg_temp.ts(-60, '09:00')),
  ('a1000000-0000-4000-8000-000000000001', 'google', 'google-sub-fah',  'fah@example.com',  false, pg_temp.ts(-59, '09:00')),
  ('a1000000-0000-4000-8000-000000000002', 'google', 'google-sub-non',  'non@example.com',  false, pg_temp.ts(-60, '09:05')),
  ('a1000000-0000-4000-8000-000000000002', 'line',   'Unon000000000000000000000000000002', NULL, true,  pg_temp.ts(-60, '09:06')),
  ('a1000000-0000-4000-8000-000000000003', 'line',   'Umali00000000000000000000000000003', NULL, true,  pg_temp.ts(-30, '18:00')),
  ('a1000000-0000-4000-8000-000000000004', 'google', 'google-sub-bee',  'bee@example.com',  false, pg_temp.ts(-25, '13:00')),
  ('a1000000-0000-4000-8000-000000000005', 'line',   'Uton000000000000000000000000000005', NULL, true,  pg_temp.ts(-1, '21:00')),
  ('a1000000-0000-4000-8000-000000000006', 'line',   'Ukaew0000000000000000000000000006', NULL, true,  pg_temp.ts(-2, '10:00')),
  ('a1000000-0000-4000-8000-000000000011', 'google', 'google-sub-packing',    'packing@example.com',    false, pg_temp.ts(-90, '09:00')),
  ('a1000000-0000-4000-8000-000000000012', 'google', 'google-sub-accounting', 'accounting@example.com', false, pg_temp.ts(-90, '09:00')),
  ('a1000000-0000-4000-8000-000000000013', 'google', 'google-sub-training',   'training@example.com',   false, pg_temp.ts(-90, '09:00')),
  ('a1000000-0000-4000-8000-000000000014', 'google', 'google-sub-admin',      'admin@example.com',      false, pg_temp.ts(-90, '09:00'));

INSERT INTO user_roles (user_id, role) VALUES
  ('a1000000-0000-4000-8000-000000000001', 'teacher'),
  ('a1000000-0000-4000-8000-000000000002', 'teacher'),
  ('a1000000-0000-4000-8000-000000000003', 'teacher'),
  ('a1000000-0000-4000-8000-000000000004', 'teacher'),
  ('a1000000-0000-4000-8000-000000000004', 'coordinator'),
  ('a1000000-0000-4000-8000-000000000005', 'teacher'),
  ('a1000000-0000-4000-8000-000000000006', 'teacher');

INSERT INTO files (id, purpose, storage_key, content_type, size_bytes, uploaded_by) VALUES
  ('91000000-0000-4000-8000-000000000001', 'payment_slip',       'slips/2026/ton-order-0002.jpg',  'image/jpeg',      182345, 'a1000000-0000-4000-8000-000000000005'),
  ('91000000-0000-4000-8000-000000000002', 'payment_slip',       'slips/2026/kaew-order-0003.png', 'image/png',       201877, 'a1000000-0000-4000-8000-000000000006'),
  ('91000000-0000-4000-8000-000000000003', 'payment_slip',       'slips/2026/mali-order-0001.jpg', 'image/jpeg',      176002, 'a1000000-0000-4000-8000-000000000003'),
  ('91000000-0000-4000-8000-000000000004', 'financial_document', 'documents/receipt-0001.pdf',     'application/pdf', 58211,  NULL),
  ('91000000-0000-4000-8000-000000000005', 'policy_document',    'policies/privacy-v1.pdf',        'application/pdf', 91233,  'a1000000-0000-4000-8000-000000000014'),
  ('91000000-0000-4000-8000-000000000006', 'policy_document',    'policies/terms-v1.pdf',          'application/pdf', 88120,  'a1000000-0000-4000-8000-000000000014');

INSERT INTO policy_documents (id, kind, version, file_id, published_at) VALUES
  ('92000000-0000-4000-8000-000000000001', 'privacy', '1.0', '91000000-0000-4000-8000-000000000005', pg_temp.ts(-90, '09:00')),
  ('92000000-0000-4000-8000-000000000002', 'terms',   '1.0', '91000000-0000-4000-8000-000000000006', pg_temp.ts(-90, '09:00')),
  ('92000000-0000-4000-8000-000000000003', 'refund',  '1.0', NULL,                                   pg_temp.ts(-90, '09:00'));

-- ครูทุกคนยอมรับนโยบายและข้อกำหนดตอนสมัคร · ครูนนท์ยินยอมรับข่าวสารด้วย
INSERT INTO consents (user_id, kind, policy_document_id, granted_at)
SELECT u.id, p.kind, p.id, u.created_at
  FROM users u
 CROSS JOIN policy_documents p
 WHERE p.kind IN ('privacy', 'terms')
   AND u.id IN (SELECT user_id FROM user_roles WHERE role = 'teacher');
INSERT INTO consents (user_id, kind, granted_at) VALUES
  ('a1000000-0000-4000-8000-000000000002', 'marketing', pg_temp.ts(-60, '09:05'));

INSERT INTO addresses (user_id, recipient_name, phone, address_line, subdistrict, district, province, postal_code, is_default) VALUES
  ('a1000000-0000-4000-8000-000000000003', 'มะลิ ใจดี',  '0810000003', '99/1 หมู่ 2', 'ตำบลตัวอย่าง', 'อำเภอตัวอย่าง', 'เชียงใหม่', '50000', true),
  ('a1000000-0000-4000-8000-000000000005', 'ต้น รักเรียน', '0810000005', '12 ซอยตัวอย่าง', 'แขวงตัวอย่าง', 'เขตตัวอย่าง', 'กรุงเทพมหานคร', '10100', true),
  ('a1000000-0000-4000-8000-000000000006', 'แก้ว ใสสะอาด', '0810000006', '45 ถนนตัวอย่าง', 'ตำบลตัวอย่าง', 'อำเภอตัวอย่าง', 'ขอนแก่น', '40000', true);


-- -----------------------------------------------------------------------------
-- 3. สถานศึกษา โรงเรียน และทีมงาน
-- -----------------------------------------------------------------------------

INSERT INTO schools_directory (id, name, school_type, province, district, affiliation, source, status, added_by) VALUES
  ('b1000000-0000-4000-8000-000000000001', 'โรงเรียนบ้านทุ่งตัวอย่าง',     'ประถมศึกษา',   'เชียงใหม่', 'อำเภอตัวอย่าง', 'สพป. ตัวอย่าง', 'public_list', 'verified', NULL),
  ('b1000000-0000-4000-8000-000000000002', 'โรงเรียนเมืองตัวอย่างวิทยา',   'มัธยมศึกษา',  'ขอนแก่น',   'อำเภอเมือง',   'สพม. ตัวอย่าง', 'public_list', 'verified', NULL),
  ('b1000000-0000-4000-8000-000000000003', 'โรงเรียนท่าน้ำตัวอย่าง',       NULL,           'ขอนแก่น',   NULL,           NULL,            'user_added',  'pending',  'a1000000-0000-4000-8000-000000000006');

INSERT INTO organizations (id, org_type, school_directory_id, name, billing_name, tax_id, tax_branch, billing_address, created_by) VALUES
  ('b2000000-0000-4000-8000-000000000001', 'school', 'b1000000-0000-4000-8000-000000000002', 'โรงเรียนเมืองตัวอย่างวิทยา',
   'โรงเรียนเมืองตัวอย่างวิทยา', '0994000000001', 'สำนักงานใหญ่', '1 ถนนตัวอย่าง อำเภอเมือง จังหวัดขอนแก่น 40000',
   'a1000000-0000-4000-8000-000000000004');

INSERT INTO org_memberships (organization_id, user_id, role, status, joined_at) VALUES
  ('b2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000004', 'owner', 'active', pg_temp.ts(-25, '13:05'));

INSERT INTO staff_roles (code, name, description) VALUES
  ('packing',    'ฝ่ายแพ็กของ', 'แพ็กและส่งของ บันทึกรหัสในกล่องและเลขพัสดุ'),
  ('accounting', 'ฝ่ายบัญชี',   'ตรวจเงิน ออกเอกสารการเงิน คืนเงิน ตรวจยอด'),
  ('training',   'ฝ่ายอบรม',    'จัดรอบอบรม ที่นั่ง คิวสำรอง เช็กชื่อ'),
  ('content',    'ฝ่ายเนื้อหา',  'แม่แบบข้อความและเนื้อหาหน้าเว็บ'),
  ('admin',      'ผู้ดูแลระบบ',  'แพ็กเกจ สิทธิ์ รหัสในกล่อง ผู้ใช้ และค่าตั้งระบบ');

INSERT INTO staff_role_permissions (role_code, permission) VALUES
  ('packing',    'orders.view'), ('packing', 'orders.pack'), ('packing', 'shipments.create'),
  ('accounting', 'orders.view'), ('accounting', 'payments.verify'), ('accounting', 'refunds.request'),
  ('accounting', 'refunds.approve'), ('accounting', 'documents.issue'), ('accounting', 'quotations.followup'),
  ('accounting', 'reconciliation.resolve'), ('accounting', 'pii.view'),
  ('training',   'events.manage'), ('training', 'seats.manage'), ('training', 'seats.check_in'),
  ('content',    'templates.manage'),
  ('admin',      'plans.manage'), ('admin', 'grants.create'), ('admin', 'codes.manage'), ('admin', 'codes.transfer'),
  ('admin',      'codes.reexport'), ('admin', 'users.view'), ('admin', 'schools.merge'), ('admin', 'settings.manage'),
  ('admin',      'audit.view'), ('admin', 'pii.view');

INSERT INTO staff_members (user_id, two_factor_enabled_at) VALUES
  ('a1000000-0000-4000-8000-000000000011', pg_temp.ts(-90, '09:10')),
  ('a1000000-0000-4000-8000-000000000012', pg_temp.ts(-90, '09:10')),
  ('a1000000-0000-4000-8000-000000000013', pg_temp.ts(-90, '09:10')),
  ('a1000000-0000-4000-8000-000000000014', pg_temp.ts(-90, '09:10'));

INSERT INTO staff_member_roles (user_id, role_code, granted_by) VALUES
  ('a1000000-0000-4000-8000-000000000011', 'packing',    'a1000000-0000-4000-8000-000000000014'),
  ('a1000000-0000-4000-8000-000000000012', 'accounting', 'a1000000-0000-4000-8000-000000000014'),
  ('a1000000-0000-4000-8000-000000000013', 'training',   'a1000000-0000-4000-8000-000000000014'),
  ('a1000000-0000-4000-8000-000000000013', 'content',    'a1000000-0000-4000-8000-000000000014'),
  ('a1000000-0000-4000-8000-000000000014', 'admin',      'a1000000-0000-4000-8000-000000000014');


-- -----------------------------------------------------------------------------
-- 4. สิทธิ์ เครดิต และแพ็กเกจ (system-plan 5.2–5.3 · ตัวเลขเป็นค่าตัวอย่าง)
-- -----------------------------------------------------------------------------

INSERT INTO entitlement_defs (code, name, value_type, combine_rule, description) VALUES
  ('pro',                   'สมาชิก Pro',                     'flag',    NULL,  'ใช้แสดงป้าย Pro และเป็นเงื่อนไขกว้าง ๆ'),
  ('classroom.limit',       'จำนวนห้องเรียนพื้นฐาน',          'number',  'max', 'ฟรี 1 · Pro ไม่จำกัด (Phase 2)'),
  ('classroom.bonus',       'ห้องเรียนเพิ่มจากสมุด',           'number',  'sum', 'บวกเพิ่มจากค่าพื้นฐาน (Phase 3)'),
  ('course.intro',          'คอร์สบทแรก + เกียรติบัตร',        'flag',    NULL,  'Phase 2'),
  ('course.all',            'คอร์สออนไลน์ทุกบท',               'flag',    NULL,  'Phase 2'),
  ('media.sample',          'บทสื่อตัวอย่าง',                  'flag',    NULL,  'Phase 3'),
  ('media.all',             'บทสื่อทุกบท + PDF',               'flag',    NULL,  'Phase 3'),
  ('portfolio.export',      'ส่งออกแฟ้มผลงานเป็น PDF',         'flag',    NULL,  'Phase 2'),
  ('seat.free_zoom',        'จองที่นั่ง onZoom ฟรีได้',         'flag',    NULL,  'ยังต้องผ่านเงื่อนไขบทเรียน (Phase 2)'),
  ('discount.workshop.pro', 'ส่วนลดเวิร์กช็อปของ Pro',         'percent', 'max', 'ใช้ได้ทุกครั้งกับกองที่นั่งที่รับส่วนลดนี้'),
  ('cards.teacher_edition', 'คู่มือครูการ์ดจับดีฉบับเต็ม',      'flag',    NULL,  'PDF ใส่ชื่อครูทุกหน้า (Phase 1)'),
  ('cards.video',           'วิดีโอสาธิตการ์ดจับดี',            'flag',    NULL,  'Phase 1'),
  ('school.reports',        'รายงานโรงเรียน',                  'flag',    NULL,  'Phase 3'),
  ('school.share_external', 'แชร์ให้ผู้ชมภายนอก',              'flag',    NULL,  'Phase 3'),
  ('school.growth_day',     'วันเด็กเล่าการเติบโต',            'flag',    NULL,  'Phase 5');
-- game.access ยังไม่สร้างจนกว่าเกมพร้อม (Context ข้อ 60.13.3)

INSERT INTO credit_types (code, name, once_per_holder, description) VALUES
  ('coach_session',   'รอบปรึกษาโค้ช AI',                 false, '1 รอบ = 1 Canvas ไม่เกินราว 30 ข้อความ'),
  ('canvas_analysis', 'วิเคราะห์ Canvas',                  false, NULL),
  ('voucher.zoom30',  'คูปองลด 30% ที่นั่ง onZoom 1 ที่',    true,  'ของผู้ซื้อการ์ด ได้ครั้งเดียวต่อบัญชี (กติกา H)');

INSERT INTO plans (id, code, name, plan_type, is_active) VALUES
  ('c1000000-0000-4000-8000-000000000001', 'free',               'สมาชิกฟรี',                 'free',         true),
  ('c1000000-0000-4000-8000-000000000002', 'pro_yearly',         'Pro รายปี',                 'subscription', true),
  ('c1000000-0000-4000-8000-000000000003', 'pro_monthly',        'Pro รายเดือน',              'subscription', true),
  ('c1000000-0000-4000-8000-000000000004', 'card_box_code',      'รหัสในกล่องการ์ดจับดี',      'code',         true),
  ('c1000000-0000-4000-8000-000000000005', 'card_buyer_voucher', 'คูปองผู้ซื้อการ์ด',          'bundle',       true),
  ('c1000000-0000-4000-8000-000000000006', 'topup_coach_10',     'ชุดเติมโค้ช 10 รอบ',          'topup',        true),
  ('c1000000-0000-4000-8000-000000000007', 'topup_analysis_10',  'ชุดเติมวิเคราะห์ 10 ครั้ง',    'topup',        true),
  ('c1000000-0000-4000-8000-000000000008', 'journal_20',         'สมุดบันทึกความสุข 20 เล่มขึ้นไป', 'bundle',     true),
  ('c1000000-0000-4000-8000-000000000009', 'school_package',     'แพ็กเกจโรงเรียน',            'org',          false);

INSERT INTO plan_versions (id, plan_id, version, billing_cycle, available_from, created_by)
SELECT ('c2000000-0000-4000-8000-00000000000' || n)::uuid, ('c1000000-0000-4000-8000-00000000000' || n)::uuid, 1,
       CASE n WHEN 2 THEN 'year' WHEN 3 THEN 'month' ELSE 'once' END,
       pg_temp.ts(-90, '00:00'), 'a1000000-0000-4000-8000-000000000014'
  FROM generate_series(1, 9) AS n;

INSERT INTO plan_version_parts (id, plan_version_id, code, name, duration_months, start_condition) VALUES
  ('c3000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'main',    'สมาชิกฟรี',               NULL, NULL),
  ('c3000000-0000-4000-8000-000000000002', 'c2000000-0000-4000-8000-000000000002', 'main',    'Pro 12 เดือน',            12,   NULL),
  ('c3000000-0000-4000-8000-000000000003', 'c2000000-0000-4000-8000-000000000003', 'main',    'Pro 1 เดือน',             1,    NULL),
  ('c3000000-0000-4000-8000-000000000004', 'c2000000-0000-4000-8000-000000000004', 'instant', 'ได้ทันที ไม่หมดอายุ',       NULL, NULL),
  ('c3000000-0000-4000-8000-000000000005', 'c2000000-0000-4000-8000-000000000004', 'pro',     'Pro 3 เดือน',             3,    'pro_launch'),
  ('c3000000-0000-4000-8000-000000000006', 'c2000000-0000-4000-8000-000000000005', 'main',    'คูปองผู้ซื้อการ์ด',         NULL, NULL),
  ('c3000000-0000-4000-8000-000000000007', 'c2000000-0000-4000-8000-000000000006', 'main',    'เครดิตโค้ช 10 รอบ',        NULL, NULL),
  ('c3000000-0000-4000-8000-000000000008', 'c2000000-0000-4000-8000-000000000007', 'main',    'เครดิตวิเคราะห์ 10 ครั้ง',  NULL, NULL),
  ('c3000000-0000-4000-8000-000000000009', 'c2000000-0000-4000-8000-000000000008', 'main',    'ห้องเรียนเพิ่ม 1 ห้อง',     12,   NULL),
  ('c3000000-0000-4000-8000-000000000010', 'c2000000-0000-4000-8000-000000000009', 'main',    'สิทธิ์ระดับโรงเรียน',       12,   NULL);

-- สิทธิ์แบบ flag / ตัวเลข
INSERT INTO plan_version_items (part_id, entitlement_code, entitlement_value, is_unlimited)
SELECT part_id::uuid, code, value, unlimited
  FROM (VALUES
    -- สมาชิกฟรี
    ('c3000000-0000-4000-8000-000000000001', 'classroom.limit',       1,    false),
    ('c3000000-0000-4000-8000-000000000001', 'course.intro',          NULL, false),
    ('c3000000-0000-4000-8000-000000000001', 'media.sample',          NULL, false),
    -- Pro รายปี
    ('c3000000-0000-4000-8000-000000000002', 'pro',                   NULL, false),
    ('c3000000-0000-4000-8000-000000000002', 'classroom.limit',       NULL, true),
    ('c3000000-0000-4000-8000-000000000002', 'course.all',            NULL, false),
    ('c3000000-0000-4000-8000-000000000002', 'media.all',             NULL, false),
    ('c3000000-0000-4000-8000-000000000002', 'portfolio.export',      NULL, false),
    ('c3000000-0000-4000-8000-000000000002', 'seat.free_zoom',        NULL, false),
    ('c3000000-0000-4000-8000-000000000002', 'discount.workshop.pro', 30,   false),
    -- Pro รายเดือน: เหมือนรายปี ยกเว้น seat.free_zoom
    ('c3000000-0000-4000-8000-000000000003', 'pro',                   NULL, false),
    ('c3000000-0000-4000-8000-000000000003', 'classroom.limit',       NULL, true),
    ('c3000000-0000-4000-8000-000000000003', 'course.all',            NULL, false),
    ('c3000000-0000-4000-8000-000000000003', 'media.all',             NULL, false),
    ('c3000000-0000-4000-8000-000000000003', 'portfolio.export',      NULL, false),
    ('c3000000-0000-4000-8000-000000000003', 'discount.workshop.pro', 30,   false),
    -- รหัสในกล่อง: ส่วนได้ทันที
    ('c3000000-0000-4000-8000-000000000004', 'cards.video',           NULL, false),
    ('c3000000-0000-4000-8000-000000000004', 'cards.teacher_edition', NULL, false),
    -- รหัสในกล่อง: ส่วน Pro 3 เดือน (ไม่มี seat.free_zoom ตามที่แผนระบบตั้งไว้ รอยืนยัน)
    ('c3000000-0000-4000-8000-000000000005', 'pro',                   NULL, false),
    ('c3000000-0000-4000-8000-000000000005', 'classroom.limit',       NULL, true),
    ('c3000000-0000-4000-8000-000000000005', 'course.all',            NULL, false),
    ('c3000000-0000-4000-8000-000000000005', 'media.all',             NULL, false),
    ('c3000000-0000-4000-8000-000000000005', 'portfolio.export',      NULL, false),
    ('c3000000-0000-4000-8000-000000000005', 'discount.workshop.pro', 30,   false),
    -- สมุดบันทึกความสุข
    ('c3000000-0000-4000-8000-000000000009', 'classroom.bonus',       1,    false),
    -- แพ็กเกจโรงเรียน
    ('c3000000-0000-4000-8000-000000000010', 'school.reports',        NULL, false),
    ('c3000000-0000-4000-8000-000000000010', 'school.share_external', NULL, false),
    ('c3000000-0000-4000-8000-000000000010', 'school.growth_day',     NULL, false)
  ) AS v (part_id, code, value, unlimited);

-- เครดิต
INSERT INTO plan_version_items (part_id, credit_type_code, credit_amount, credit_refill, credit_valid_months)
SELECT part_id::uuid, code, amount, refill, valid_months
  FROM (VALUES
    ('c3000000-0000-4000-8000-000000000001', 'coach_session',   2,  'once',    NULL),
    ('c3000000-0000-4000-8000-000000000001', 'canvas_analysis', 2,  'once',    NULL),
    ('c3000000-0000-4000-8000-000000000002', 'coach_session',   10, 'monthly', NULL),
    ('c3000000-0000-4000-8000-000000000002', 'canvas_analysis', 5,  'monthly', NULL),
    ('c3000000-0000-4000-8000-000000000003', 'coach_session',   10, 'monthly', NULL),
    ('c3000000-0000-4000-8000-000000000003', 'canvas_analysis', 5,  'monthly', NULL),
    ('c3000000-0000-4000-8000-000000000004', 'voucher.zoom30',  1,  'once',    12),
    ('c3000000-0000-4000-8000-000000000005', 'coach_session',   10, 'monthly', NULL),
    ('c3000000-0000-4000-8000-000000000005', 'canvas_analysis', 5,  'monthly', NULL),
    ('c3000000-0000-4000-8000-000000000006', 'voucher.zoom30',  1,  'once',    12),
    ('c3000000-0000-4000-8000-000000000007', 'coach_session',   10, 'once',    12),
    ('c3000000-0000-4000-8000-000000000008', 'canvas_analysis', 10, 'once',    12)
  ) AS v (part_id, code, amount, refill, valid_months);


-- -----------------------------------------------------------------------------
-- 5. สินค้า ราคา และสต็อก (ราคาเป็นค่าตัวอย่าง เปลี่ยนแปลงได้)
-- -----------------------------------------------------------------------------

INSERT INTO products (id, code, product_type, name, description, plan_id, tracks_stock, buyer_type, is_on_sale) VALUES
  ('d1000000-0000-4000-8000-000000000001', 'cards_jabdee',      'physical',     'การ์ดจับดี',            '60 ใบ 4 หมวด 5 วิธีเล่น พร้อมรหัสในกล่อง', NULL, true, 'anyone', true),
  ('d1000000-0000-4000-8000-000000000002', 'journal_happiness', 'physical',     'สมุดบันทึกความสุข',      'สำหรับโรงเรียน ขั้นต่ำ 20 เล่ม เปิดจอง มี.ค.–เม.ย. 2570',
   'c1000000-0000-4000-8000-000000000008', true, 'organization', false),
  ('d1000000-0000-4000-8000-000000000003', 'pro_yearly',        'subscription', 'Pro รายปี',              'เปิดขาย Phase 2', 'c1000000-0000-4000-8000-000000000002', false, 'anyone', false),
  ('d1000000-0000-4000-8000-000000000004', 'pro_monthly',       'subscription', 'Pro รายเดือน',           'เปิดขาย Phase 2', 'c1000000-0000-4000-8000-000000000003', false, 'anyone', false),
  ('d1000000-0000-4000-8000-000000000005', 'topup_coach_10',    'topup',        'ชุดเติมโค้ช 10 รอบ',      'เปิดขาย Phase 2', 'c1000000-0000-4000-8000-000000000006', false, 'anyone', false),
  ('d1000000-0000-4000-8000-000000000006', 'topup_analysis_10', 'topup',        'ชุดเติมวิเคราะห์ 10 ครั้ง', 'เปิดขาย Phase 2', 'c1000000-0000-4000-8000-000000000007', false, 'anyone', false);

INSERT INTO prices (product_id, price_satang, min_quantity, valid_from, created_by) VALUES
  ('d1000000-0000-4000-8000-000000000001', 50000, 1, pg_temp.ts(-90, '00:00'), 'a1000000-0000-4000-8000-000000000014'),
  ('d1000000-0000-4000-8000-000000000001', 45000, 5, pg_temp.ts(-90, '00:00'), 'a1000000-0000-4000-8000-000000000014'),  -- ราคาชุดโรงเรียน [OPEN ค่าสมมติ]
  ('d1000000-0000-4000-8000-000000000003', 99000, 1, pg_temp.ts(-90, '00:00'), 'a1000000-0000-4000-8000-000000000014'),
  ('d1000000-0000-4000-8000-000000000004', 20000, 1, pg_temp.ts(-90, '00:00'), 'a1000000-0000-4000-8000-000000000014'),
  ('d1000000-0000-4000-8000-000000000005', 9900,  1, pg_temp.ts(-90, '00:00'), 'a1000000-0000-4000-8000-000000000014'),
  ('d1000000-0000-4000-8000-000000000006', 9900,  1, pg_temp.ts(-90, '00:00'), 'a1000000-0000-4000-8000-000000000014');

INSERT INTO inventory_movements (product_id, quantity, movement_type, note, created_by, created_at) VALUES
  ('d1000000-0000-4000-8000-000000000001', 200, 'receive', 'รับการ์ดล็อตแรกจากโรงพิมพ์', 'a1000000-0000-4000-8000-000000000011', pg_temp.ts(-45, '10:00'));


-- -----------------------------------------------------------------------------
-- 6. รหัสในกล่อง (รหัสทดสอบ ใช้จริงไม่ได้)
-- -----------------------------------------------------------------------------

INSERT INTO code_batches (id, name, plan_version_id, quantity, created_by, created_at,
                          exported_at, exported_by, boxed_at, boxed_by) VALUES
  ('e1000000-0000-4000-8000-000000000001', 'การ์ดจับดี ล็อต 1 (ตัวอย่าง)', 'c2000000-0000-4000-8000-000000000004', 3,
   'a1000000-0000-4000-8000-000000000014', pg_temp.ts(-60, '10:00'),
   pg_temp.ts(-58, '10:00'), 'a1000000-0000-4000-8000-000000000014',
   pg_temp.ts(-45, '10:00'), 'a1000000-0000-4000-8000-000000000011');

INSERT INTO redeem_codes (id, batch_id, code_hash, last4, created_at) VALUES
  ('e2000000-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', pg_temp.code_hash('SKW-7Q2K-M4PA'), 'M4PA', pg_temp.ts(-60, '10:00')),
  ('e2000000-0000-4000-8000-000000000002', 'e1000000-0000-4000-8000-000000000001', pg_temp.code_hash('SKW-7Q2K-R8TE'), 'R8TE', pg_temp.ts(-60, '10:00')),
  ('e2000000-0000-4000-8000-000000000003', 'e1000000-0000-4000-8000-000000000001', pg_temp.code_hash('SKW-7Q2K-W6HN'), 'W6HN', pg_temp.ts(-60, '10:00'));

-- การ์ดใบนี้ชำรุดก่อนขาย ทีมงานยกเลิกรหัส
UPDATE redeem_codes
   SET cancelled_at = pg_temp.ts(-44, '11:00'), cancelled_by = 'a1000000-0000-4000-8000-000000000014',
       cancel_reason = 'กล่องชำรุด ไม่ได้นำไปขาย'
 WHERE id = 'e2000000-0000-4000-8000-000000000003';


-- -----------------------------------------------------------------------------
-- 7. อบรม
-- -----------------------------------------------------------------------------

INSERT INTO events (id, event_type, title, starts_at, ends_at, join_url, status, created_by) VALUES
  ('f1000000-0000-4000-8000-000000000001', 'webinar', 'เวบินาร์ฟรี: รู้จักแนวคิด Unlock Potential',
   pg_temp.ts(10, '19:00'), pg_temp.ts(10, '20:30'), 'https://zoom.example.com/webinar-1', 'published', 'a1000000-0000-4000-8000-000000000013'),
  ('f1000000-0000-4000-8000-000000000002', 'zoom', 'เวิร์กช็อป onZoom รอบแรก',
   pg_temp.ts(30, '09:00'), pg_temp.ts(30, '16:00'), 'https://zoom.example.com/workshop-1', 'published', 'a1000000-0000-4000-8000-000000000013');

INSERT INTO seat_pools (id, event_id, name, capacity, price_satang, required_entitlement_code,
                        accepts_pro_discount, accepted_voucher_type, allocation,
                        prerequisite_note, prerequisite_enforcement, prerequisite_deadline, booking_opens_at) VALUES
  ('f2000000-0000-4000-8000-000000000001', 'f1000000-0000-4000-8000-000000000001', 'ที่นั่งเวบินาร์ฟรี', 300, 0,
   NULL, false, NULL, 'first_come', NULL, 'none', NULL, pg_temp.ts(-14, '09:00')),
  ('f2000000-0000-4000-8000-000000000002', 'f1000000-0000-4000-8000-000000000002', 'ที่นั่งจ่ายเงิน', 35, 90000,
   NULL, true, 'voucher.zoom30', 'first_come',
   'แนะนำให้เรียนบทออนไลน์ก่อนวันอบรม', 'warn', pg_temp.ts(27, '23:59'), pg_temp.ts(-14, '09:00')),
  ('f2000000-0000-4000-8000-000000000003', 'f1000000-0000-4000-8000-000000000002', 'ที่นั่งฟรีสมาชิกรายปี (Phase 2)', 35, 0,
   'seat.free_zoom', false, NULL, 'first_come',
   'ต้องเรียนบทออนไลน์และผ่านแบบทดสอบก่อนเส้นตาย', 'forfeit', pg_temp.ts(23, '23:59'), pg_temp.ts(5, '09:00'));

INSERT INTO seat_bookings (id, seat_pool_id, user_id, booked_by, status) VALUES
  ('f3000000-0000-4000-8000-000000000001', 'f2000000-0000-4000-8000-000000000001',
   'a1000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000001', 'booked');


-- -----------------------------------------------------------------------------
-- 8. การได้สิทธิ์และเครดิตตอนสมัคร (สมาชิกฟรี: โค้ช 2 + วิเคราะห์ 2 ไม่หมดอายุ)
-- -----------------------------------------------------------------------------

WITH g AS (
  INSERT INTO grants (holder_user_id, plan_version_id, part_id, source_type, source_ref, source_batch_id, starts_at, created_at)
  SELECT u.id, 'c2000000-0000-4000-8000-000000000001', 'c3000000-0000-4000-8000-000000000001',
         'signup', u.id::text, gen_random_uuid(), u.created_at, u.created_at
    FROM users u
   WHERE u.id IN (SELECT user_id FROM user_roles WHERE role = 'teacher')
  RETURNING id, holder_user_id, starts_at
)
INSERT INTO credit_ledger (holder_user_id, credit_type_code, entry_type, amount, grant_id, created_at)
SELECT g.holder_user_id, i.credit_type_code, 'grant', i.credit_amount, g.id, g.starts_at
  FROM g
  JOIN plan_version_items i ON i.part_id = 'c3000000-0000-4000-8000-000000000001' AND i.credit_type_code IS NOT NULL;


-- -----------------------------------------------------------------------------
-- 9. ครูนนท์: ทีมงานให้ Pro รายปีเพื่อทดสอบระบบก่อนเปิดขาย + ชุดเติมชดเชย
--    แสดงรอบเครดิตรายเดือนนับจากวันเริ่ม Pro: รอบที่ 1 หมดอายุแล้ว รอบที่ 2 กำลังใช้
-- -----------------------------------------------------------------------------

INSERT INTO grants (id, holder_user_id, plan_version_id, part_id, source_type, source_batch_id,
                    starts_at, ends_at, reason, created_by, created_at) VALUES
  ('c5000000-0000-4000-8000-000000000010', 'a1000000-0000-4000-8000-000000000002',
   'c2000000-0000-4000-8000-000000000002', 'c3000000-0000-4000-8000-000000000002', 'staff', gen_random_uuid(),
   pg_temp.ts(-40, '09:00'), pg_temp.ts(-40, '09:00') + interval '12 months',
   'ทดสอบระบบ Pro ก่อนเปิดขายจริง', 'a1000000-0000-4000-8000-000000000014', pg_temp.ts(-40, '09:00')),
  ('c5000000-0000-4000-8000-000000000011', 'a1000000-0000-4000-8000-000000000002',
   'c2000000-0000-4000-8000-000000000006', 'c3000000-0000-4000-8000-000000000007', 'staff', gen_random_uuid(),
   pg_temp.ts(-5, '14:00'), NULL,
   'ชดเชยกรณีงาน AI ขัดข้อง (ตัวอย่าง)', 'a1000000-0000-4000-8000-000000000014', pg_temp.ts(-5, '14:00'));

INSERT INTO credit_ledger (holder_user_id, credit_type_code, entry_type, amount, expires_at, grant_id, created_at)
SELECT 'a1000000-0000-4000-8000-000000000002', i.credit_type_code, 'grant', i.credit_amount,
       pg_temp.ts(-40, '09:00') + make_interval(months => cycle), 'c5000000-0000-4000-8000-000000000010',
       pg_temp.ts(-40, '09:00') + make_interval(months => cycle - 1)
  FROM plan_version_items i
 CROSS JOIN generate_series(1, 2) AS cycle
 WHERE i.part_id = 'c3000000-0000-4000-8000-000000000002' AND i.credit_refill = 'monthly'
 ORDER BY cycle;

INSERT INTO credit_ledger (holder_user_id, credit_type_code, entry_type, amount, expires_at, grant_id, created_at) VALUES
  ('a1000000-0000-4000-8000-000000000002', 'coach_session', 'grant', 10,
   pg_temp.ts(-5, '14:00') + interval '12 months', 'c5000000-0000-4000-8000-000000000011', pg_temp.ts(-5, '14:00'));

-- ใช้โค้ชไป 3 รอบในรอบเดือนปัจจุบัน: ระบบหักจากก้อนรายเดือน (หมดอายุก่อน) ก่อนชุดเติมและก้อนฟรี
SELECT use_credit('a1000000-0000-4000-8000-000000000002', NULL, 'coach_session', 1, 'canvas', 'demo-canvas-1', 'a1000000-0000-4000-8000-000000000002');
SELECT use_credit('a1000000-0000-4000-8000-000000000002', NULL, 'coach_session', 2, 'canvas', 'demo-canvas-2', 'a1000000-0000-4000-8000-000000000002');

INSERT INTO audit_logs (actor_user_id, action, resource_type, resource_id, after, reason, created_at) VALUES
  ('a1000000-0000-4000-8000-000000000014', 'grant.create', 'grant', 'c5000000-0000-4000-8000-000000000010',
   '{"plan": "pro_yearly", "holder": "a1000000-0000-4000-8000-000000000002"}', 'ทดสอบระบบ Pro ก่อนเปิดขายจริง', pg_temp.ts(-40, '09:00')),
  ('a1000000-0000-4000-8000-000000000014', 'grant.create', 'grant', 'c5000000-0000-4000-8000-000000000011',
   '{"plan": "topup_coach_10", "holder": "a1000000-0000-4000-8000-000000000002"}', 'ชดเชยกรณีงาน AI ขัดข้อง (ตัวอย่าง)', pg_temp.ts(-5, '14:00')),
  ('a1000000-0000-4000-8000-000000000014', 'code_batch.export', 'code_batch', 'e1000000-0000-4000-8000-000000000001',
   '{"format": "pdf_sticker", "codes": 3}', NULL, pg_temp.ts(-58, '10:00'));


-- -----------------------------------------------------------------------------
-- 10. ครูมะลิ: ซื้อการ์ด 1 ชุด โอนแนบสลิป → ทีมงานยืนยัน → แพ็กส่ง → กดรหัสก่อนเปิด Pro
--     สถานะคำสั่งซื้อเปลี่ยนทีละขั้น trigger บันทึกประวัติให้เอง
-- -----------------------------------------------------------------------------

SET LOCAL app.actor_user_id = 'a1000000-0000-4000-8000-000000000003';
INSERT INTO orders (id, order_number, buyer_user_id, subtotal_satang, shipping_satang, total_satang,
                    vat_satang, amount_due_satang, payment_due_at, shipping_snapshot, created_at) VALUES
  ('61000000-0000-4000-8000-000000000001', 'SW-000001', 'a1000000-0000-4000-8000-000000000003',
   50000, 5000, 55000, 3598, 55000, pg_temp.ts(-19, '10:00'),
   '{"recipient_name": "มะลิ ใจดี", "phone": "0810000003", "address": "99/1 หมู่ 2 ตำบลตัวอย่าง อำเภอตัวอย่าง เชียงใหม่ 50000"}',
   pg_temp.ts(-20, '10:00'));
INSERT INTO order_items (order_id, product_id, name_snapshot, unit_price_satang, quantity, line_total_satang) VALUES
  ('61000000-0000-4000-8000-000000000001', 'd1000000-0000-4000-8000-000000000001', 'การ์ดจับดี', 50000, 1, 50000);
SELECT hold_stock('d1000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000001', 1, now() + interval '24 hours');

INSERT INTO payments (id, order_id, provider, method, amount_satang, slip_file_id, created_at) VALUES
  ('63000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000001', 'bank_transfer', 'transfer',
   55000, '91000000-0000-4000-8000-000000000003', pg_temp.ts(-20, '10:20'));
UPDATE orders SET status = 'awaiting_verification' WHERE id = '61000000-0000-4000-8000-000000000001';

SET LOCAL app.actor_user_id = 'a1000000-0000-4000-8000-000000000012';
SET LOCAL app.status_reason = 'ตรวจสลิปแล้ว ยอดตรง';
UPDATE payments SET status = 'succeeded', verified_by = 'a1000000-0000-4000-8000-000000000012', verified_at = pg_temp.ts(-20, '13:00')
 WHERE id = '63000000-0000-4000-8000-000000000001';
UPDATE orders SET status = 'paid' WHERE id = '61000000-0000-4000-8000-000000000001';
UPDATE inventory_holds SET status = 'committed' WHERE order_id = '61000000-0000-4000-8000-000000000001';
INSERT INTO inventory_movements (product_id, quantity, movement_type, order_id, created_at) VALUES
  ('d1000000-0000-4000-8000-000000000001', -1, 'sale', '61000000-0000-4000-8000-000000000001', pg_temp.ts(-20, '13:00'));

-- ชำระค่าการ์ดสำเร็จ = ได้คูปองลด 30% ทันที (กติกา H) · กดรหัสภายหลังจะไม่ได้คูปองซ้ำ
INSERT INTO grants (id, holder_user_id, plan_version_id, part_id, source_type, source_ref, source_batch_id, starts_at, created_at) VALUES
  ('c5000000-0000-4000-8000-000000000020', 'a1000000-0000-4000-8000-000000000003',
   'c2000000-0000-4000-8000-000000000005', 'c3000000-0000-4000-8000-000000000006',
   'order', '61000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000001',
   pg_temp.ts(-20, '13:00'), pg_temp.ts(-20, '13:00'));
INSERT INTO credit_ledger (holder_user_id, credit_type_code, entry_type, amount, expires_at, grant_id, created_at) VALUES
  ('a1000000-0000-4000-8000-000000000003', 'voucher.zoom30', 'grant', 1,
   pg_temp.ts(-20, '13:00') + interval '12 months', 'c5000000-0000-4000-8000-000000000020', pg_temp.ts(-20, '13:00'));

INSERT INTO financial_documents (id, doc_type, seq_year, seq_number, doc_number, order_id, buyer_snapshot, items_snapshot,
                                 subtotal_satang, vat_satang, total_satang, amount_in_words, pdf_file_id, issued_at)
SELECT '65000000-0000-4000-8000-000000000001', 'receipt', pg_temp.be_year(), n,
       'RC' || pg_temp.be_year() || '-' || lpad(n::text, 5, '0'), '61000000-0000-4000-8000-000000000001',
       '{"name": "มะลิ ใจดี"}', '[{"name": "การ์ดจับดี", "qty": 1, "unit_satang": 50000}, {"name": "ค่าส่ง", "qty": 1, "unit_satang": 5000}]',
       55000, 3598, 55000, 'ห้าร้อยห้าสิบบาทถ้วน', '91000000-0000-4000-8000-000000000004', pg_temp.ts(-20, '13:01')
  FROM next_document_number('receipt', pg_temp.be_year()) AS n;

SET LOCAL app.actor_user_id = 'a1000000-0000-4000-8000-000000000011';
SET LOCAL app.status_reason = '';
UPDATE orders SET status = 'awaiting_packing' WHERE id = '61000000-0000-4000-8000-000000000001';
INSERT INTO shipments (id, order_id, carrier, tracking_number, shipped_at, created_by) VALUES
  ('64000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000001', 'ไปรษณีย์ไทย', 'EX000000001TH',
   pg_temp.ts(-18, '15:00'), 'a1000000-0000-4000-8000-000000000011');
INSERT INTO shipment_codes (shipment_id, redeem_code_id, added_by) VALUES
  ('64000000-0000-4000-8000-000000000001', 'e2000000-0000-4000-8000-000000000001', 'a1000000-0000-4000-8000-000000000011');
UPDATE orders SET status = 'shipped' WHERE id = '61000000-0000-4000-8000-000000000001';

-- ครูมะลิกดรหัสก่อนเปิดระบบ Pro: ส่วนได้ทันทีใช้ได้เลย · ส่วน Pro รอเริ่ม (ไม่มีวันเริ่ม)
-- คูปองในส่วนได้ทันทีไม่ให้ซ้ำ เพราะได้ไปแล้วตอนชำระค่าการ์ด
INSERT INTO grants (id, holder_user_id, plan_version_id, part_id, source_type, source_ref, source_batch_id,
                    start_condition, starts_at, created_at) VALUES
  ('c5000000-0000-4000-8000-000000000021', 'a1000000-0000-4000-8000-000000000003',
   'c2000000-0000-4000-8000-000000000004', 'c3000000-0000-4000-8000-000000000004',
   'redeem_code', 'e2000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000001',
   NULL, pg_temp.ts(-15, '20:00'), pg_temp.ts(-15, '20:00')),
  ('c5000000-0000-4000-8000-000000000022', 'a1000000-0000-4000-8000-000000000003',
   'c2000000-0000-4000-8000-000000000004', 'c3000000-0000-4000-8000-000000000005',
   'redeem_code', 'e2000000-0000-4000-8000-000000000001', 'e3000000-0000-4000-8000-000000000001',
   'pro_launch', NULL, pg_temp.ts(-15, '20:00'));
UPDATE redeem_codes
   SET redeemed_by = 'a1000000-0000-4000-8000-000000000003', redeemed_at = pg_temp.ts(-15, '20:00'),
       grant_batch_id = 'e3000000-0000-4000-8000-000000000001'
 WHERE id = 'e2000000-0000-4000-8000-000000000001';
INSERT INTO redeem_attempts (user_id, client_key, code_masked, result, created_at) VALUES
  ('a1000000-0000-4000-8000-000000000003', 'ip:203.0.113.10', 'SKW-7Q2K-M4P*', 'not_found', pg_temp.ts(-15, '19:58')),
  ('a1000000-0000-4000-8000-000000000003', 'ip:203.0.113.10', 'SKW-7Q2K-****', 'redeemed',  pg_temp.ts(-15, '20:00'));

RESET app.actor_user_id;  -- เปลี่ยนสถานะโดยระบบ
UPDATE orders SET status = 'code_redeemed' WHERE id = '61000000-0000-4000-8000-000000000001';


-- -----------------------------------------------------------------------------
-- 11. ครูมะลิใช้คูปองจองเวิร์กช็อป onZoom: 900 → 630 บาท จ่ายพร้อมเพย์ผ่านระบบรับเงิน
-- -----------------------------------------------------------------------------

SET LOCAL app.actor_user_id = 'a1000000-0000-4000-8000-000000000003';
INSERT INTO orders (id, order_number, buyer_user_id, subtotal_satang, discount_satang, total_satang,
                    vat_satang, amount_due_satang, payment_due_at, created_at) VALUES
  ('61000000-0000-4000-8000-000000000005', 'SW-000005', 'a1000000-0000-4000-8000-000000000003',
   90000, 27000, 63000, 4121, 63000, pg_temp.ts(-7, '10:00'), pg_temp.ts(-8, '10:00'));
INSERT INTO order_items (order_id, seat_pool_id, name_snapshot, unit_price_satang, quantity,
                         discount_satang, discount_source, seat_user_id, line_total_satang) VALUES
  ('61000000-0000-4000-8000-000000000005', 'f2000000-0000-4000-8000-000000000002', 'เวิร์กช็อป onZoom รอบแรก',
   90000, 1, 27000, 'voucher', 'a1000000-0000-4000-8000-000000000003', 63000);
INSERT INTO seat_bookings (id, seat_pool_id, user_id, booked_by, status, order_id, hold_expires_at) VALUES
  ('f3000000-0000-4000-8000-000000000002', 'f2000000-0000-4000-8000-000000000002',
   'a1000000-0000-4000-8000-000000000003', 'a1000000-0000-4000-8000-000000000003', 'pending_payment',
   '61000000-0000-4000-8000-000000000005', now() + interval '15 minutes');
INSERT INTO payments (id, order_id, provider, method, provider_payment_id, amount_satang, expires_at, created_at) VALUES
  ('63000000-0000-4000-8000-000000000005', '61000000-0000-4000-8000-000000000005', 'opn', 'promptpay',
   'chrg_test_000005', 63000, pg_temp.ts(-8, '10:15'), pg_temp.ts(-8, '10:00'));

RESET app.actor_user_id;
INSERT INTO payment_events (provider, provider_event_id, event_type, payload, received_at, processed_at) VALUES
  ('opn', 'evnt_test_000005', 'charge.complete', '{"charge": "chrg_test_000005", "amount": 63000, "currency": "thb"}',
   pg_temp.ts(-8, '10:03'), pg_temp.ts(-8, '10:03'));
UPDATE payments SET status = 'succeeded' WHERE id = '63000000-0000-4000-8000-000000000005';
UPDATE orders SET status = 'paid' WHERE id = '61000000-0000-4000-8000-000000000005';
-- หักคูปองตอนชำระเงินสำเร็จ แล้วผูกกับรายการในคำสั่งซื้อ
UPDATE order_items
   SET voucher_entry_id = (SELECT id FROM use_credit('a1000000-0000-4000-8000-000000000003', NULL, 'voucher.zoom30', 1,
                                                     'order', '61000000-0000-4000-8000-000000000005', NULL))
 WHERE order_id = '61000000-0000-4000-8000-000000000005';
UPDATE seat_bookings SET status = 'confirmed', hold_expires_at = NULL WHERE id = 'f3000000-0000-4000-8000-000000000002';
UPDATE orders SET status = 'completed' WHERE id = '61000000-0000-4000-8000-000000000005';

INSERT INTO financial_documents (id, doc_type, seq_year, seq_number, doc_number, order_id, buyer_snapshot, items_snapshot,
                                 subtotal_satang, discount_satang, vat_satang, total_satang, amount_in_words, issued_at)
SELECT '65000000-0000-4000-8000-000000000002', 'receipt', pg_temp.be_year(), n,
       'RC' || pg_temp.be_year() || '-' || lpad(n::text, 5, '0'), '61000000-0000-4000-8000-000000000005',
       '{"name": "มะลิ ใจดี"}', '[{"name": "เวิร์กช็อป onZoom รอบแรก", "qty": 1, "unit_satang": 90000, "discount_satang": 27000}]',
       90000, 27000, 4121, 63000, 'หกร้อยสามสิบบาทถ้วน', pg_temp.ts(-8, '10:04')
  FROM next_document_number('receipt', pg_temp.be_year()) AS n;


-- -----------------------------------------------------------------------------
-- 12. คำสั่งซื้อที่รอทีมงาน: ครูต้นแนบสลิปรอตรวจ · ครูแก้วโอนขาด
-- -----------------------------------------------------------------------------

SET LOCAL app.actor_user_id = 'a1000000-0000-4000-8000-000000000005';
INSERT INTO orders (id, order_number, buyer_user_id, subtotal_satang, shipping_satang, total_satang,
                    vat_satang, amount_due_satang, payment_due_at, shipping_snapshot, created_at) VALUES
  ('61000000-0000-4000-8000-000000000002', 'SW-000002', 'a1000000-0000-4000-8000-000000000005',
   100000, 5000, 105000, 6869, 105000, now() + interval '20 hours',
   '{"recipient_name": "ต้น รักเรียน", "phone": "0810000005", "address": "12 ซอยตัวอย่าง แขวงตัวอย่าง เขตตัวอย่าง กรุงเทพมหานคร 10100"}',
   now() - interval '4 hours');
INSERT INTO order_items (order_id, product_id, name_snapshot, unit_price_satang, quantity, line_total_satang) VALUES
  ('61000000-0000-4000-8000-000000000002', 'd1000000-0000-4000-8000-000000000001', 'การ์ดจับดี', 50000, 2, 100000);
SELECT hold_stock('d1000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000002', 2, now() + interval '20 hours');
INSERT INTO payments (order_id, provider, method, amount_satang, slip_file_id) VALUES
  ('61000000-0000-4000-8000-000000000002', 'bank_transfer', 'transfer', 105000, '91000000-0000-4000-8000-000000000001');
UPDATE orders SET status = 'awaiting_verification' WHERE id = '61000000-0000-4000-8000-000000000002';

SET LOCAL app.actor_user_id = 'a1000000-0000-4000-8000-000000000006';
INSERT INTO orders (id, order_number, buyer_user_id, subtotal_satang, shipping_satang, total_satang,
                    vat_satang, amount_due_satang, payment_due_at, shipping_snapshot, created_at) VALUES
  ('61000000-0000-4000-8000-000000000003', 'SW-000003', 'a1000000-0000-4000-8000-000000000006',
   50000, 5000, 55000, 3598, 55000, now() + interval '22 hours',
   '{"recipient_name": "แก้ว ใสสะอาด", "phone": "0810000006", "address": "45 ถนนตัวอย่าง ตำบลตัวอย่าง อำเภอตัวอย่าง ขอนแก่น 40000"}',
   now() - interval '1 day');
INSERT INTO order_items (order_id, product_id, name_snapshot, unit_price_satang, quantity, line_total_satang) VALUES
  ('61000000-0000-4000-8000-000000000003', 'd1000000-0000-4000-8000-000000000001', 'การ์ดจับดี', 50000, 1, 50000);
SELECT hold_stock('d1000000-0000-4000-8000-000000000001', '61000000-0000-4000-8000-000000000003', 1, now() + interval '22 hours');
INSERT INTO payments (id, order_id, provider, method, amount_satang, slip_file_id) VALUES
  ('63000000-0000-4000-8000-000000000003', '61000000-0000-4000-8000-000000000003', 'bank_transfer', 'transfer',
   50000, '91000000-0000-4000-8000-000000000002');
UPDATE orders SET status = 'awaiting_verification' WHERE id = '61000000-0000-4000-8000-000000000003';

SET LOCAL app.actor_user_id = 'a1000000-0000-4000-8000-000000000012';
SET LOCAL app.status_reason = 'สลิปยอด 500 บาท ขาด 50 บาท แจ้งยอดที่ขาดทาง LINE แล้ว';
UPDATE payments SET status = 'succeeded', verified_by = 'a1000000-0000-4000-8000-000000000012', verified_at = now() - interval '2 hours'
 WHERE id = '63000000-0000-4000-8000-000000000003';
UPDATE orders SET status = 'underpaid' WHERE id = '61000000-0000-4000-8000-000000000003';
RESET app.actor_user_id;
RESET app.status_reason;


-- -----------------------------------------------------------------------------
-- 13. ครูบีขอใบเสนอราคาในนามโรงเรียน 10 ชุด (ราคาชุดโรงเรียน) · ออกมา 8 วัน ยังไม่โทรตาม
-- -----------------------------------------------------------------------------

INSERT INTO financial_documents (id, doc_type, seq_year, seq_number, doc_number, requested_by, buyer_snapshot, items_snapshot,
                                 subtotal_satang, vat_satang, total_satang, amount_in_words, valid_until, issued_at)
SELECT '65000000-0000-4000-8000-000000000003', 'quotation', pg_temp.be_year(), n,
       'QT' || pg_temp.be_year() || '-' || lpad(n::text, 5, '0'), 'a1000000-0000-4000-8000-000000000004',
       '{"name": "โรงเรียนเมืองตัวอย่างวิทยา", "tax_id": "0994000000001", "branch": "สำนักงานใหญ่"}',
       '[{"name": "การ์ดจับดี (ราคาชุดโรงเรียน)", "qty": 10, "unit_satang": 45000}]',
       450000, 29439, 450000, 'สี่พันห้าร้อยบาทถ้วน', pg_temp.ts(22, '23:59'), pg_temp.ts(-8, '13:30')
  FROM next_document_number('quotation', pg_temp.be_year()) AS n;


-- -----------------------------------------------------------------------------
-- 14. ข้อความแจ้งเตือนและบันทึกการเปิดดูข้อมูลส่วนบุคคล
-- -----------------------------------------------------------------------------

INSERT INTO notification_templates (event_code, channel, body, is_required) VALUES
  ('order.confirmed',        'line',  'ได้รับคำสั่งซื้อ {order_number} แล้ว ยอด {total} บาท ดูใบเสร็จได้ที่ {link}', true),
  ('order.confirmed',        'email', 'ได้รับคำสั่งซื้อ {order_number} แล้ว แนบใบเสร็จมาในอีเมลนี้',            true),
  ('order.underpaid',        'line',  'ยอดที่โอนมายังขาดอีก {missing} บาท โอนเพิ่มแล้วแนบสลิปได้ที่ {link}',      true),
  ('shipment.tracking',      'line',  'ส่งของแล้ว เลขพัสดุ {tracking_number} ({carrier})',                     true),
  ('code.redeem_reminder',   'line',  'ได้รับการ์ดจับดีแล้วหรือยัง สแกนรหัสในกล่องเพื่อดูวิดีโอและคู่มือครูได้เลย', false),
  ('seat.booking_confirmed', 'line',  'ยืนยันที่นั่ง {event_title} วันที่ {date} แล้ว',                           false),
  ('seat.reminder',          'line',  'พรุ่งนี้มีอบรม {event_title} เข้าห้องได้ที่ {join_url}',                   false);

INSERT INTO notifications (recipient_user_id, event_code, channel, counts_line_quota, status, scheduled_for, sent_at, ref_type, ref_id) VALUES
  ('a1000000-0000-4000-8000-000000000003', 'order.confirmed',        'line',  true,  'sent', pg_temp.ts(-20, '13:01'), pg_temp.ts(-20, '13:01'), 'order', '61000000-0000-4000-8000-000000000001'),
  ('a1000000-0000-4000-8000-000000000003', 'order.confirmed',        'email', false, 'sent', pg_temp.ts(-20, '13:01'), pg_temp.ts(-20, '13:01'), 'order', '61000000-0000-4000-8000-000000000001'),
  ('a1000000-0000-4000-8000-000000000003', 'shipment.tracking',      'line',  true,  'sent', pg_temp.ts(-18, '15:05'), pg_temp.ts(-18, '15:05'), 'order', '61000000-0000-4000-8000-000000000001'),
  ('a1000000-0000-4000-8000-000000000003', 'seat.booking_confirmed', 'line',  true,  'sent', pg_temp.ts(-8, '10:04'),  pg_temp.ts(-8, '10:04'),  'seat_booking', 'f3000000-0000-4000-8000-000000000002'),
  ('a1000000-0000-4000-8000-000000000006', 'order.underpaid',        'line',  true,  'sent', now() - interval '2 hours', now() - interval '2 hours', 'order', '61000000-0000-4000-8000-000000000003'),
  ('a1000000-0000-4000-8000-000000000003', 'seat.reminder',          'line',  true,  'queued', pg_temp.ts(29, '09:00'), NULL, 'seat_booking', 'f3000000-0000-4000-8000-000000000002');

INSERT INTO pii_access_logs (staff_user_id, subject_user_id, field, created_at) VALUES
  ('a1000000-0000-4000-8000-000000000011', 'a1000000-0000-4000-8000-000000000003', 'address', pg_temp.ts(-18, '14:40'));

COMMIT;
