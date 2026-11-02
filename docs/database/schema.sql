-- =============================================================================
-- SkillwisE — ฐานข้อมูล Phase 1
-- =============================================================================
-- ฐานข้อมูล : PostgreSQL 16 ขึ้นไป (Context ข้อ 60.5, 60.11.3)
-- สถานะ     : [DIRECTION] ร่างให้ทีมตรวจ ยังไม่ใช่ migration ที่ใช้จริง
--              เมื่อสร้าง apps/api ให้แปลงตารางเป็น schema.prisma แล้วให้ Prisma สร้าง migration
--              ส่วน trigger ฟังก์ชัน และ view (อยู่ทุกหมวด) ให้ใส่เป็น migration แบบ SQL ตรง
-- ที่มา     : ภาคผนวก ก. ของ docs/system-plan.md (Context ข้อ 60.13)
--              ออกแบบใหม่ทั้งหมด ไม่ต่อยอดจากร่างเดิมที่อิงระบบ Sila5School (ข้อ 60.13.2)
-- เอกสาร    : docs/database/README.md (ตารางเทียบภาคผนวก ก. และกรณีทดสอบ)
--
-- หลักที่ใช้ออกแบบ
--   1. ราคา แพ็กเกจ และกติกาสิทธิ์เป็น "ข้อมูล" ในตาราง ไม่ใช่ค่าคงที่ในโค้ด
--   2. เงินและสิทธิ์ห้ามแก้ทับ ห้ามลบ
--      - สมุดเครดิต ประวัติสถานะ และ log เป็นแบบเพิ่มอย่างเดียว
--      - ตารางที่ต้องกรอกภายหลัง (เช่น วันเริ่มของ Pro ที่รอเริ่ม, วันยกเลิก) กรอกได้ครั้งเดียว
--   3. เงินเป็นสตางค์ (bigint) ทั้งหมด
--   4. สถานะที่คำนวณจากวันที่ได้ ไม่เก็บซ้ำ ให้อ่านจาก view ในหมวด 10 ข้อมูลจึงไม่ขัดกันเอง
--   5. ส่วนที่ต้องล็อกแถวกันการกดพร้อมกัน (หักเครดิต กันสต็อก ออกเลขเอกสาร) เป็นฟังก์ชันในหมวด 9
--      เพราะ Prisma ยังไม่มีคำสั่งล็อกแถวในตัว (Context ข้อ 60.13.6)
--
-- ข้อตกลงในไฟล์นี้
--   - primary key เป็น uuid (gen_random_uuid) ยกเว้นตาราง log ที่โตเร็วใช้ bigint identity
--   - เวลาใช้ timestamptz ทั้งหมด เก็บเป็นเวลาสากล แสดงผลเป็นเวลาไทย
--   - สถานะใช้ text + CHECK (แก้ด้วย migration ได้ง่ายกว่า enum)
--   - ชื่อตารางเป็นพหูพจน์ snake_case · ตารางที่แก้ไม่ได้ไม่มี updated_at
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS citext;  -- อีเมลที่ไม่สนตัวพิมพ์ใหญ่/เล็ก


-- =============================================================================
-- 0. ฟังก์ชันกลาง
-- =============================================================================

-- อัปเดต updated_at อัตโนมัติ
CREATE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

-- ตารางแบบเพิ่มอย่างเดียว ห้ามแก้ ห้ามลบ
CREATE FUNCTION forbid_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'ตาราง % เป็นแบบเพิ่มอย่างเดียว ห้าม %', TG_TABLE_NAME, TG_OP
    USING ERRCODE = 'insufficient_privilege';
END $$;

-- ห้ามลบ และแก้ได้เฉพาะช่องที่ส่งชื่อมาใน trigger โดยกรอกได้ครั้งเดียว (จากว่างเป็นมีค่า)
-- ใช้กับตารางเงินและสิทธิ์ที่มีช่องกรอกภายหลัง เช่น วันยกเลิก
CREATE FUNCTION allow_fill_once() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  old_row jsonb := to_jsonb(OLD);
  new_row jsonb := to_jsonb(NEW);
  col     text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'ตาราง % ห้ามลบ ให้บันทึกการยกเลิกแทน', TG_TABLE_NAME
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  FOR col IN SELECT jsonb_object_keys(new_row) LOOP
    CONTINUE WHEN col = 'updated_at' OR old_row -> col IS NOT DISTINCT FROM new_row -> col;
    IF NOT (col = ANY (TG_ARGV)) OR old_row ->> col IS NOT NULL THEN
      RAISE EXCEPTION 'ตาราง % ช่อง % แก้ไม่ได้ (กรอกได้ครั้งเดียวเฉพาะช่องที่อนุญาต)', TG_TABLE_NAME, col
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END LOOP;
  RETURN NEW;
END $$;


-- =============================================================================
-- 1. บัญชีและองค์กร (system-plan ส่วนที่ 7)
-- =============================================================================

CREATE TABLE users (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name     text NOT NULL,
  email            citext,                      -- เข้าด้วย LINE อาจไม่มีอีเมล
  phone_encrypted  bytea,                       -- API เข้ารหัสก่อนบันทึก · หลังบ้านแสดงแบบปิดบางส่วน
  status           text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
  last_login_at    timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX users_email_key ON users (email) WHERE email IS NOT NULL AND status <> 'deleted';
COMMENT ON TABLE users IS '1 คน = 1 บัญชี ผูกได้ทั้ง Google และ LINE · ครูอิสระไม่ต้องอยู่องค์กรไหน';

CREATE TABLE auth_accounts (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            uuid NOT NULL REFERENCES users (id),
  provider           text NOT NULL CHECK (provider IN ('google', 'line')),
  provider_user_id   text NOT NULL,              -- sub ของ Google / userId ของ LINE
  email_at_provider  citext,
  line_is_friend     boolean NOT NULL DEFAULT false,  -- เพิ่มเพื่อน LINE OA แล้ว ส่งข้อความหาได้
  linked_at          timestamptz NOT NULL DEFAULT now(),
  unlinked_at        timestamptz
);
CREATE UNIQUE INDEX auth_accounts_provider_key ON auth_accounts (provider, provider_user_id) WHERE unlinked_at IS NULL;
CREATE UNIQUE INDEX auth_accounts_one_per_provider ON auth_accounts (user_id, provider) WHERE unlinked_at IS NULL;
COMMENT ON TABLE auth_accounts IS 'ช่องทางเข้าสู่ระบบของแต่ละบัญชี · อีเมลซ้ำกับบัญชีอื่นให้ถามยืนยันก่อนรวม ไม่รวมเอง';

CREATE TABLE user_roles (
  user_id     uuid NOT NULL REFERENCES users (id),
  role        text NOT NULL CHECK (role IN ('teacher', 'coordinator', 'executive', 'external_viewer')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role)
);
COMMENT ON TABLE user_roles IS 'บทบาทที่ผู้ใช้เลือกตอนสมัคร มีได้หลายค่า สลับมุมมองในบัญชีเดียว · ไม่ใช่สิทธิ์ทีมงาน';

CREATE TABLE files (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purpose       text NOT NULL CHECK (purpose IN (
                  'payment_slip', 'financial_document', 'withholding_certificate',
                  'teacher_manual', 'policy_document', 'product_image')),
  storage_key   text NOT NULL UNIQUE,            -- ที่อยู่ใน R2 · เปิดด้วยลิงก์ที่หมดอายุเท่านั้น
  content_type  text NOT NULL,
  size_bytes    bigint NOT NULL CHECK (size_bytes > 0),
  uploaded_by   uuid REFERENCES users (id),      -- NULL = ระบบสร้างเอง เช่น PDF ใบเสร็จ
  created_at    timestamptz NOT NULL DEFAULT now(),
  CHECK (purpose <> 'payment_slip' OR content_type IN ('image/jpeg', 'image/png', 'image/webp', 'application/pdf'))
);
COMMENT ON TABLE files IS '[ตารางเสริม] ไฟล์ทั้งหมดเป็นไฟล์ส่วนตัว · สลิปรับเฉพาะรูปภาพหรือ PDF (system-plan ส่วนที่ 10)';

CREATE TABLE policy_documents (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind          text NOT NULL CHECK (kind IN ('privacy', 'terms', 'refund', 'child_data')),
  version       text NOT NULL,
  file_id       uuid REFERENCES files (id),
  published_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (kind, version)
);
CREATE TRIGGER policy_documents_append_only BEFORE UPDATE OR DELETE ON policy_documents
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE policy_documents IS '[ตารางเสริม] นโยบายแต่ละเวอร์ชัน เพื่อให้ consents อ้างได้ว่ายอมรับฉบับไหน';

CREATE TABLE consents (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES users (id),
  kind                text NOT NULL CHECK (kind IN ('privacy', 'terms', 'marketing', 'child_data')),
  policy_document_id  uuid REFERENCES policy_documents (id),
  granted_at          timestamptz NOT NULL DEFAULT now(),
  withdrawn_at        timestamptz,
  CHECK (kind = 'marketing' OR policy_document_id IS NOT NULL)
);
CREATE INDEX consents_user_idx ON consents (user_id, kind, granted_at DESC);
CREATE TRIGGER consents_fill_once BEFORE UPDATE OR DELETE ON consents
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once('withdrawn_at');
COMMENT ON TABLE consents IS 'ใครยอมรับนโยบายเวอร์ชันไหนเมื่อไร · ยินยอมรับข่าวสาร (marketing) แยกจากการแจ้งเรื่องคำสั่งซื้อ';

CREATE TABLE addresses (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES users (id),
  recipient_name  text NOT NULL,
  phone           text NOT NULL,                 -- ใช้พิมพ์ใบปะหน้า · หลังบ้านแสดงแบบปิดบางส่วน
  address_line    text NOT NULL,
  subdistrict     text NOT NULL,
  district        text NOT NULL,
  province        text NOT NULL,
  postal_code     text NOT NULL CHECK (postal_code ~ '^[0-9]{5}$'),
  is_default      boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX addresses_one_default ON addresses (user_id) WHERE is_default;
COMMENT ON TABLE addresses IS 'ที่อยู่จัดส่งของผู้ใช้ · ถามตอนชำระเงิน (F8, F9) · คำสั่งซื้อเก็บสำเนาของตัวเอง';

CREATE TABLE schools_directory (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  school_type     text,                          -- ตามรายชื่อสาธารณะ ไม่ hard-code โครงสร้างโรงเรียนไทย
  province        text,
  district        text,
  affiliation     text,                          -- สังกัด
  source          text NOT NULL CHECK (source IN ('public_list', 'user_added')),
  status          text NOT NULL DEFAULT 'pending' CHECK (status IN ('verified', 'pending', 'merged')),
  merged_into_id  uuid REFERENCES schools_directory (id),
  added_by        uuid REFERENCES users (id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'merged') = (merged_into_id IS NOT NULL)),
  CHECK (source <> 'user_added' OR added_by IS NOT NULL)
);
CREATE INDEX schools_directory_search_idx ON schools_directory (province, name) WHERE status <> 'merged';
COMMENT ON TABLE schools_directory IS 'ฐานข้อมูลสถานศึกษา ตั้งต้นจากรายชื่อสาธารณะ · ชื่อที่ผู้ใช้พิมพ์เพิ่มรอทีมงานตรวจ (A4)';

CREATE TABLE organizations (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_type             text NOT NULL CHECK (org_type IN ('school', 'network')),
  school_directory_id  uuid REFERENCES schools_directory (id),
  name                 text NOT NULL,
  billing_name         text,                     -- ชื่อที่ใช้ออกเอกสารการเงิน
  tax_id               text CHECK (tax_id ~ '^[0-9]{13}$'),
  tax_branch           text,                     -- สำนักงานใหญ่ หรือเลขสาขา
  billing_address      text,
  created_by           uuid REFERENCES users (id),
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE organizations IS 'โรงเรียนหรือเครือข่าย · Phase 1 ใช้ผูกครูกับโรงเรียนและออกเอกสารในนามโรงเรียน · ทีมครูเปิดใช้ Phase 3';

CREATE TABLE org_memberships (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id  uuid NOT NULL REFERENCES organizations (id),
  user_id          uuid REFERENCES users (id),   -- NULL ระหว่างเชิญด้วยอีเมลที่ยังไม่มีบัญชี
  invited_email    citext,
  role             text NOT NULL CHECK (role IN ('owner', 'coordinator', 'member')),
  status           text NOT NULL CHECK (status IN ('invited', 'active', 'left')),
  has_pro_seat     boolean NOT NULL DEFAULT false,  -- ได้ที่นั่ง Pro จากแพ็กเกจโรงเรียน (Phase 3)
  invited_by       uuid REFERENCES users (id),
  joined_at        timestamptz,
  left_at          timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  CHECK (user_id IS NOT NULL OR invited_email IS NOT NULL),
  CHECK (status <> 'active' OR (user_id IS NOT NULL AND joined_at IS NOT NULL))
);
CREATE UNIQUE INDEX org_memberships_active_key ON org_memberships (organization_id, user_id) WHERE status = 'active';
COMMENT ON TABLE org_memberships IS 'ครูกับโรงเรียน · Phase 1 มีแค่ผูกครูกับโรงเรียน ส่วนคำเชิญและที่นั่งเปิดใช้ Phase 3';

-- ทีมงาน SkillwisE (Context ข้อ 60.7: บทบาทตามหน้าที่ ประกอบด้วยสิทธิ์ที่ตั้งชื่อชัดเจน)
CREATE TABLE staff_roles (
  code         text PRIMARY KEY,                 -- เช่น packing, accounting, training, content, admin
  name         text NOT NULL,
  description  text
);
COMMENT ON TABLE staff_roles IS '[ตารางเสริม] บทบาททีมงาน ปรับในหลังบ้านได้';

CREATE TABLE staff_role_permissions (
  role_code   text NOT NULL REFERENCES staff_roles (code),
  permission  text NOT NULL,                     -- ชื่อสิทธิ์ที่ endpoint ประกาศไว้ เช่น orders.verify_payment
  PRIMARY KEY (role_code, permission)
);
COMMENT ON TABLE staff_role_permissions IS '[ตารางเสริม] สิทธิ์ของแต่ละบทบาท · ชื่อสิทธิ์ต้องตรงกับที่ guard ของ API ตรวจ';

CREATE TABLE staff_members (
  user_id                uuid PRIMARY KEY REFERENCES users (id),
  two_factor_enabled_at  timestamptz,            -- ต้องเปิดก่อนเข้าหลังบ้าน
  is_active              boolean NOT NULL DEFAULT true,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE staff_members IS 'ทีมงาน เข้าด้วย Google ของบริษัท + ยืนยัน 2 ขั้น · เห็นเฉพาะเมนูของบทบาทตัวเอง';

CREATE TABLE staff_member_roles (
  user_id     uuid NOT NULL REFERENCES staff_members (user_id),
  role_code   text NOT NULL REFERENCES staff_roles (code),
  granted_by  uuid REFERENCES users (id),
  granted_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role_code)
);
COMMENT ON TABLE staff_member_roles IS '[ตารางเสริม] ทีมงาน 1 คนมีได้หลายบทบาท';


-- =============================================================================
-- 2. สิทธิ์และเครดิต — หัวใจ 1 (system-plan ส่วนที่ 5)
-- =============================================================================

CREATE TABLE system_settings (
  key          text PRIMARY KEY,                 -- เช่น pro_launch_at, quotation_valid_days
  value        jsonb NOT NULL,
  description  text NOT NULL,
  updated_by   uuid REFERENCES users (id),
  updated_at   timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE system_settings IS 'ค่ากติกาที่ทีมงานตั้งในหลังบ้าน · ทุกการแก้บันทึกลง audit_logs';

CREATE TABLE entitlement_defs (
  code          text PRIMARY KEY,                -- ต้องตรงกับที่โค้ดเช็ก จึงให้โปรแกรมเมอร์เพิ่ม
  name          text NOT NULL,
  value_type    text NOT NULL CHECK (value_type IN ('flag', 'number', 'percent')),
  combine_rule  text CHECK (combine_rule IN ('max', 'sum')),  -- หลายรายการรวมกันอย่างไร
  description   text,
  CHECK ((value_type = 'flag') = (combine_rule IS NULL))
);
COMMENT ON TABLE entitlement_defs IS 'รายการสิทธิ์ (system-plan 5.2) · flag = ใช้ได้/ไม่ได้ · number/percent ต้องบอกวิธีรวม';

CREATE TABLE credit_types (
  code             text PRIMARY KEY,             -- เช่น coach_session, canvas_analysis, voucher.zoom30
  name             text NOT NULL,
  once_per_holder  boolean NOT NULL DEFAULT false,  -- คูปองที่ได้ครั้งเดียวต่อบัญชี (กติกา H)
  description      text
);
COMMENT ON TABLE credit_types IS 'ชนิดเครดิต รวมคูปองใช้ครั้งเดียว';

CREATE TABLE plans (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text NOT NULL UNIQUE,
  name        text NOT NULL,
  plan_type   text NOT NULL CHECK (plan_type IN ('free', 'subscription', 'code', 'topup', 'bundle', 'org')),
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE plans IS 'แพ็กเกจ = ชุดของสิทธิ์ + เครดิต + ระยะเวลา ที่ทีมงานตั้งในหลังบ้าน (A7)';

CREATE TABLE plan_versions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id          uuid NOT NULL REFERENCES plans (id),
  version          integer NOT NULL CHECK (version > 0),
  billing_cycle    text NOT NULL CHECK (billing_cycle IN ('once', 'month', 'year')),  -- ราคาอยู่ที่ prices ของสินค้าที่ผูกแพ็กเกจนี้
  available_from   timestamptz NOT NULL DEFAULT now(),
  available_until  timestamptz,
  created_by       uuid REFERENCES users (id),
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (plan_id, version),
  CHECK (available_until IS NULL OR available_until > available_from)
);
CREATE TRIGGER plan_versions_fill_once BEFORE UPDATE OR DELETE ON plan_versions
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once('available_until');
COMMENT ON TABLE plan_versions IS 'แก้สิทธิ์ = สร้างเวอร์ชันใหม่ ผู้ที่ได้ไปแล้วได้ตามเวอร์ชันเดิม · เวอร์ชันเก่าปิดด้วย available_until · ราคาขายเก็บที่เดียวคือ prices';

CREATE TABLE plan_version_parts (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_version_id  uuid NOT NULL REFERENCES plan_versions (id),
  code             text NOT NULL,                -- เช่น main, instant, pro
  name             text NOT NULL,
  duration_months  integer CHECK (duration_months > 0),  -- NULL = ไม่หมดอายุ
  start_condition  text CHECK (start_condition IN ('pro_launch')),  -- รอเหตุการณ์ก่อนเริ่ม
  UNIQUE (plan_version_id, code),
  UNIQUE (id, plan_version_id)
);
CREATE TRIGGER plan_version_parts_append_only BEFORE UPDATE OR DELETE ON plan_version_parts
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE plan_version_parts IS '[ตารางเสริม] ส่วนของแพ็กเกจที่เริ่มหรือหมดไม่พร้อมกัน เช่น รหัสในกล่อง = ส่วนได้ทันที + ส่วน Pro 3 เดือนที่รอเปิดระบบ Pro (system-plan 5.5)';

CREATE TABLE plan_version_items (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  part_id              uuid NOT NULL REFERENCES plan_version_parts (id),
  entitlement_code     text REFERENCES entitlement_defs (code),
  entitlement_value    numeric CHECK (entitlement_value >= 0),  -- flag = NULL
  is_unlimited         boolean NOT NULL DEFAULT false,          -- เช่น ห้องเรียนไม่จำกัดของ Pro
  credit_type_code     text REFERENCES credit_types (code),
  credit_amount        integer CHECK (credit_amount > 0),
  credit_refill        text CHECK (credit_refill IN ('once', 'monthly')),  -- monthly = เติมทุกรอบเดือนนับจากวันเริ่ม
  credit_valid_months  integer CHECK (credit_valid_months > 0),  -- อายุของก้อนแบบ once · NULL = ไม่หมดอายุ
  CHECK (num_nonnulls(entitlement_code, credit_type_code) = 1),
  CHECK (NOT (is_unlimited AND entitlement_value IS NOT NULL)),
  CHECK ((credit_type_code IS NULL) = (credit_amount IS NULL)),
  CHECK ((credit_type_code IS NULL) = (credit_refill IS NULL)),
  CHECK (credit_refill IS DISTINCT FROM 'monthly' OR credit_valid_months IS NULL)
);
CREATE TRIGGER plan_version_items_append_only BEFORE UPDATE OR DELETE ON plan_version_items
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE plan_version_items IS 'สิทธิ์หรือเครดิตแต่ละรายการในส่วนของแพ็กเกจ · เครดิตรายเดือนหมดอายุสิ้นรอบเดือนของตัวเอง';

CREATE TABLE grants (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  holder_user_id   uuid REFERENCES users (id),
  holder_org_id    uuid REFERENCES organizations (id),
  plan_version_id  uuid NOT NULL REFERENCES plan_versions (id),
  part_id          uuid NOT NULL,
  source_type      text NOT NULL CHECK (source_type IN (
                     'signup', 'order', 'subscription', 'redeem_code', 'staff', 'transfer', 'backfill')),
  source_ref       text,                         -- id ของคำสั่งซื้อ รหัสในกล่อง หรือ subscription
  source_batch_id  uuid NOT NULL,                -- เลขชุดที่มา: ทุกรายการจากการซื้อหรือกดรหัสครั้งเดียวกันใช้เลขเดียวกัน
  start_condition  text CHECK (start_condition IN ('pro_launch')),
  starts_at        timestamptz,                  -- NULL = รอเริ่ม
  ends_at          timestamptz,                  -- NULL = ไม่หมดอายุ (หรือยังรอเริ่ม)
  is_grace         boolean NOT NULL DEFAULT false,  -- ช่วงผ่อนผันเมื่อตัดบัตรไม่ผ่าน (กติกา C)
  reason           text,                         -- ต้องกรอกเมื่อทีมงานให้เอง ย้ายสิทธิ์ หรือมอบย้อนหลัง
  created_by       uuid REFERENCES users (id),
  created_at       timestamptz NOT NULL DEFAULT now(),
  cancelled_at     timestamptz,
  cancelled_by     uuid REFERENCES users (id),
  cancel_reason    text,
  FOREIGN KEY (part_id, plan_version_id) REFERENCES plan_version_parts (id, plan_version_id),
  CHECK (num_nonnulls(holder_user_id, holder_org_id) = 1),
  CHECK (starts_at IS NOT NULL OR (start_condition IS NOT NULL AND ends_at IS NULL)),
  CHECK (ends_at IS NULL OR ends_at > starts_at),
  CHECK (source_type NOT IN ('staff', 'transfer', 'backfill') OR (reason IS NOT NULL AND created_by IS NOT NULL)),
  CHECK ((cancelled_at IS NULL) = (cancel_reason IS NULL))
);
CREATE INDEX grants_user_idx ON grants (holder_user_id) WHERE cancelled_at IS NULL;
CREATE INDEX grants_org_idx ON grants (holder_org_id) WHERE cancelled_at IS NULL;
CREATE INDEX grants_source_batch_idx ON grants (source_batch_id);
CREATE INDEX grants_waiting_idx ON grants (start_condition) WHERE starts_at IS NULL AND cancelled_at IS NULL;
CREATE TRIGGER grants_fill_once BEFORE UPDATE OR DELETE ON grants
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once('starts_at', 'ends_at', 'cancelled_at', 'cancelled_by', 'cancel_reason');
COMMENT ON TABLE grants IS 'การได้สิทธิ์ 1 รายการ: ใครได้ส่วนไหนของแพ็กเกจ จากไหน เมื่อไรถึงเมื่อไร · ห้ามแก้ทับ ห้ามลบ · สถานะอ่านจาก view grant_statuses';

CREATE TABLE credit_ledger (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  holder_user_id    uuid REFERENCES users (id),
  holder_org_id     uuid REFERENCES organizations (id),
  credit_type_code  text NOT NULL REFERENCES credit_types (code),
  entry_type        text NOT NULL CHECK (entry_type IN ('grant', 'use', 'return', 'revoke')),
  amount            integer NOT NULL CHECK (amount <> 0),
  lot_id            bigint REFERENCES credit_ledger (id),  -- use / return / revoke: ก้อนที่ถูกหักหรือคืน
  expires_at        timestamptz,                -- grant: ก้อนนี้หมดอายุเมื่อไร · NULL = ไม่หมดอายุ
  grant_id          uuid REFERENCES grants (id),  -- grant: มาจากการได้สิทธิ์รายการไหน
  reverses_id       bigint REFERENCES credit_ledger (id),  -- return: คืนรายการ use ไหน
  usage_ref_type    text,                        -- use: ใช้กับอะไร เช่น canvas, order
  usage_ref_id      text,
  reason            text,
  created_by        uuid REFERENCES users (id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  CHECK (num_nonnulls(holder_user_id, holder_org_id) = 1),
  CHECK ((entry_type = 'grant') = (lot_id IS NULL)),
  CHECK (entry_type = 'grant' OR (expires_at IS NULL AND grant_id IS NULL)),
  CHECK (entry_type IN ('use', 'revoke') OR amount > 0),
  CHECK (entry_type NOT IN ('use', 'revoke') OR amount < 0),
  CHECK ((entry_type = 'return') = (reverses_id IS NOT NULL)),
  CHECK (entry_type <> 'grant' OR grant_id IS NOT NULL OR reason IS NOT NULL)
);
CREATE INDEX credit_ledger_lots_idx ON credit_ledger (holder_user_id, credit_type_code, expires_at) WHERE entry_type = 'grant';
CREATE INDEX credit_ledger_org_lots_idx ON credit_ledger (holder_org_id, credit_type_code, expires_at) WHERE entry_type = 'grant';
CREATE INDEX credit_ledger_lot_entries_idx ON credit_ledger (lot_id) WHERE lot_id IS NOT NULL;
CREATE UNIQUE INDEX credit_ledger_return_once ON credit_ledger (reverses_id) WHERE reverses_id IS NOT NULL;
CREATE TRIGGER credit_ledger_append_only BEFORE UPDATE OR DELETE ON credit_ledger
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE credit_ledger IS 'สมุดเครดิต ห้ามแก้ ห้ามลบ · รายการ grant คือ "ก้อน" ที่มีวันหมดอายุ · รายการอื่นอ้างก้อนที่ถูกหักหรือคืน · หักผ่าน use_credit() เท่านั้น';

CREATE TABLE subscriptions (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                   uuid NOT NULL REFERENCES users (id),
  plan_version_id           uuid NOT NULL REFERENCES plan_versions (id),
  provider                  text NOT NULL CHECK (provider IN ('stripe', 'opn')),
  provider_subscription_id  text NOT NULL,
  status                    text NOT NULL CHECK (status IN ('active', 'past_due', 'canceled')),
  current_period_end        timestamptz NOT NULL,
  cancel_at_period_end      boolean NOT NULL DEFAULT false,
  created_at                timestamptz NOT NULL DEFAULT now(),
  updated_at                timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_subscription_id)
);
CREATE UNIQUE INDEX subscriptions_one_open ON subscriptions (user_id) WHERE status <> 'canceled';
COMMENT ON TABLE subscriptions IS 'Pro รายเดือนที่ตัดบัตรอัตโนมัติ (สถานะตามผู้ให้บริการ) · แต่ละรอบที่ตัดสำเร็จสร้าง grants ใหม่ 1 รายการ';


-- =============================================================================
-- 3. รหัสในกล่อง (system-plan 6.7)
-- =============================================================================

CREATE TABLE code_batches (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name             text NOT NULL,
  plan_version_id  uuid NOT NULL REFERENCES plan_versions (id),
  quantity         integer NOT NULL CHECK (quantity > 0),
  created_by       uuid NOT NULL REFERENCES users (id),
  created_at       timestamptz NOT NULL DEFAULT now(),
  exported_at      timestamptz,                  -- ส่งออกให้โรงพิมพ์ได้ครั้งเดียว · ส่งซ้ำต้องมีสิทธิ์พิเศษและบันทึกใน audit_logs
  exported_by      uuid REFERENCES users (id),
  boxed_at         timestamptz,                  -- ทีมงานบันทึกว่ารหัสชุดนี้อยู่ในกล่องพร้อมขายแล้ว
  boxed_by         uuid REFERENCES users (id),
  cancelled_at     timestamptz,
  cancelled_by     uuid REFERENCES users (id),
  cancel_reason    text,
  CHECK ((exported_at IS NULL) = (exported_by IS NULL)),
  CHECK ((boxed_at IS NULL) = (boxed_by IS NULL)),
  CHECK ((cancelled_at IS NULL) = (cancel_reason IS NULL))
);
CREATE TRIGGER code_batches_fill_once BEFORE UPDATE OR DELETE ON code_batches
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once(
    'exported_at', 'exported_by', 'boxed_at', 'boxed_by', 'cancelled_at', 'cancelled_by', 'cancel_reason');
COMMENT ON TABLE code_batches IS 'รหัสในกล่องสร้างเป็นชุด ผูกกับแพ็กเกจ "รหัสในกล่อง" เวอร์ชันที่กำหนด';

CREATE TABLE redeem_codes (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id         uuid NOT NULL REFERENCES code_batches (id),
  code_hash        text NOT NULL UNIQUE,          -- sha256 ของรหัส · ไม่เก็บรหัสจริง
  last4            text NOT NULL CHECK (length(last4) = 4),  -- ให้ทีมงานค้นหาและอ้างถึง
  redeemed_by      uuid REFERENCES users (id),
  redeemed_at      timestamptz,
  grant_batch_id   uuid,                          -- source_batch_id ของ grants ที่เกิดจากการกดรหัสนี้
  cancelled_at     timestamptz,
  cancelled_by     uuid REFERENCES users (id),
  cancel_reason    text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  CHECK ((redeemed_by IS NULL) = (redeemed_at IS NULL)),
  CHECK ((redeemed_at IS NULL) = (grant_batch_id IS NULL)),
  CHECK ((cancelled_at IS NULL) = (cancel_reason IS NULL))
);
CREATE INDEX redeem_codes_batch_idx ON redeem_codes (batch_id);
CREATE INDEX redeem_codes_redeemer_idx ON redeem_codes (redeemed_by) WHERE redeemed_by IS NOT NULL;
CREATE TRIGGER redeem_codes_fill_once BEFORE UPDATE OR DELETE ON redeem_codes
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once(
    'redeemed_by', 'redeemed_at', 'grant_batch_id', 'cancelled_at', 'cancelled_by', 'cancel_reason');
COMMENT ON TABLE redeem_codes IS 'รหัส 1 รหัสใช้ได้ 1 บัญชี · ย้ายสิทธิ์ = ยกเลิก grants เดิมแล้วสร้างใหม่ให้บัญชีปลายทาง (source_type = transfer)';

-- กดรหัสที่ถูกยกเลิกแล้ว หรืออยู่ในชุดที่ถูกยกเลิก ไม่ได้
CREATE FUNCTION redeem_codes_check_usable() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.redeemed_at IS NOT NULL AND OLD.redeemed_at IS NULL THEN
    IF OLD.cancelled_at IS NOT NULL
       OR (SELECT cancelled_at FROM code_batches WHERE id = NEW.batch_id) IS NOT NULL THEN
      RAISE EXCEPTION 'รหัสนี้ถูกยกเลิกแล้ว' USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER redeem_codes_check_usable BEFORE UPDATE ON redeem_codes
  FOR EACH ROW EXECUTE FUNCTION redeem_codes_check_usable();

CREATE TABLE redeem_attempts (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id      uuid REFERENCES users (id),
  client_key   text NOT NULL,                     -- ตัวแทนเครื่องหรือ IP สำหรับจำกัดจำนวนครั้ง
  code_masked  text NOT NULL,                     -- เก็บแบบปิดบัง ไม่เก็บรหัสเต็ม
  result       text NOT NULL CHECK (result IN (
                 'redeemed', 'not_found', 'already_used', 'cancelled', 'rule_blocked', 'rate_limited')),
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX redeem_attempts_user_idx ON redeem_attempts (user_id, created_at DESC);
CREATE INDEX redeem_attempts_client_idx ON redeem_attempts (client_key, created_at DESC);
CREATE TRIGGER redeem_attempts_append_only BEFORE UPDATE OR DELETE ON redeem_attempts
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE redeem_attempts IS 'กันการเดารหัส เช่น ผิด 5 ครั้งรอ 15 นาที (ค่าอยู่ใน system_settings)';


-- =============================================================================
-- 4. อบรม (Phase 1 แบบย่อ · system-plan ส่วนที่ 8–9)
-- =============================================================================

CREATE TABLE events (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type  text NOT NULL CHECK (event_type IN ('webinar', 'zoom', 'onsite')),
  title       text NOT NULL,
  starts_at   timestamptz NOT NULL,
  ends_at     timestamptz NOT NULL,
  join_url    text,                              -- ส่งให้เฉพาะผู้มีที่นั่ง
  location    text,
  status      text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'cancelled')),
  created_by  uuid REFERENCES users (id),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at > starts_at)
);
COMMENT ON TABLE events IS 'เวบินาร์ฟรี เวิร์กช็อป onZoom และ onSite';

CREATE TABLE seat_pools (
  id                         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id                   uuid NOT NULL REFERENCES events (id),
  name                       text NOT NULL,     -- เช่น ที่นั่งฟรีสมาชิกรายปี, ที่นั่งจ่ายเงิน
  capacity                   integer NOT NULL CHECK (capacity > 0),
  price_satang               bigint NOT NULL DEFAULT 0 CHECK (price_satang >= 0),
  required_entitlement_code  text REFERENCES entitlement_defs (code),  -- ใครจองได้ เช่น seat.free_zoom
  accepts_pro_discount       boolean NOT NULL DEFAULT false,
  accepted_voucher_type      text REFERENCES credit_types (code),     -- เช่น voucher.zoom30 · onSite ไม่รับ
  allocation                 text NOT NULL DEFAULT 'first_come' CHECK (allocation IN ('first_come', 'lottery')),
  prerequisite_note          text,              -- เงื่อนไขก่อนเข้า เช่น เรียนบทออนไลน์ผ่าน (Phase 2)
  prerequisite_enforcement   text NOT NULL DEFAULT 'none' CHECK (prerequisite_enforcement IN ('none', 'warn', 'forfeit')),
  prerequisite_deadline      timestamptz,
  booking_opens_at           timestamptz,
  booking_closes_at          timestamptz,
  created_at                 timestamptz NOT NULL DEFAULT now(),
  updated_at                 timestamptz NOT NULL DEFAULT now(),
  CHECK (prerequisite_enforcement = 'none' OR prerequisite_deadline IS NOT NULL)
);
COMMENT ON TABLE seat_pools IS 'กองที่นั่งของแต่ละรอบ · กองแต่ละกองบอกเองว่ารับส่วนลดแบบไหน (ส่วนลดไม่ซ้อนกัน)';


-- =============================================================================
-- 5. ซื้อขายและรับเงิน — หัวใจ 2 (system-plan ส่วนที่ 6)
-- =============================================================================

CREATE TABLE products (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code         text NOT NULL UNIQUE,
  product_type text NOT NULL CHECK (product_type IN ('physical', 'subscription', 'topup', 'org_package')),
  name         text NOT NULL,
  description  text,
  plan_id      uuid REFERENCES plans (id),       -- ได้สิทธิ์ตามแพ็กเกจนี้หลังจ่าย · การ์ดไม่มี เพราะได้สิทธิ์ผ่านรหัสในกล่อง
  tracks_stock boolean NOT NULL DEFAULT false,
  buyer_type   text NOT NULL DEFAULT 'anyone' CHECK (buyer_type IN ('anyone', 'organization')),
  is_on_sale   boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CHECK (product_type = 'physical' OR plan_id IS NOT NULL),  -- สมุดบันทึกความสุขเป็นของจับต้องได้ที่มีแพ็กเกจด้วย
  CHECK (product_type = 'physical' OR NOT tracks_stock)
);
COMMENT ON TABLE products IS 'สินค้า · ที่นั่งอบรมไม่อยู่ที่นี่ ขายผ่าน seat_pools · สมุดบันทึกความสุขขายให้โรงเรียนเท่านั้น (buyer_type)';

CREATE TABLE prices (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id     uuid NOT NULL REFERENCES products (id),
  price_satang   bigint NOT NULL CHECK (price_satang >= 0),
  min_quantity   integer NOT NULL DEFAULT 1 CHECK (min_quantity > 0),  -- ราคาขั้นจำนวน เช่น 5 ชุดขึ้นไป
  valid_from     timestamptz NOT NULL DEFAULT now(),
  valid_until    timestamptz,                    -- ราคาช่วงโปรโมชันมีวันจบ
  includes_vat   boolean NOT NULL DEFAULT true,
  created_by     uuid REFERENCES users (id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  CHECK (valid_until IS NULL OR valid_until > valid_from)
);
CREATE INDEX prices_lookup_idx ON prices (product_id, min_quantity, valid_from);
CREATE TRIGGER prices_fill_once BEFORE UPDATE OR DELETE ON prices
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once('valid_until');
COMMENT ON TABLE prices IS 'ราคาแก้ทับไม่ได้ เปลี่ยนราคา = ปิดราคาเดิม (valid_until) แล้วเพิ่มราคาใหม่ · อ่านราคาผ่าน unit_price()';

CREATE TABLE inventory_movements (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id     uuid NOT NULL REFERENCES products (id),
  quantity       integer NOT NULL CHECK (quantity <> 0),
  movement_type  text NOT NULL CHECK (movement_type IN ('receive', 'sale', 'return', 'adjust')),
  order_id       uuid,                           -- FK ใส่หลังสร้าง orders
  note           text,
  created_by     uuid REFERENCES users (id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  CHECK (movement_type NOT IN ('receive', 'return') OR quantity > 0),
  CHECK (movement_type <> 'sale' OR (quantity < 0 AND order_id IS NOT NULL)),
  CHECK (movement_type <> 'adjust' OR note IS NOT NULL)
);
CREATE INDEX inventory_movements_product_idx ON inventory_movements (product_id);
CREATE TRIGGER inventory_movements_append_only BEFORE UPDATE OR DELETE ON inventory_movements
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE inventory_movements IS 'สต็อกเป็นรายการรับเข้าและตัดออก ห้ามแก้ · ยอดคงเหลืออ่านจาก view product_stock';

CREATE TABLE product_waitlist (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id   uuid NOT NULL REFERENCES products (id),
  user_id      uuid NOT NULL REFERENCES users (id),
  created_at   timestamptz NOT NULL DEFAULT now(),
  notified_at  timestamptz
);
CREATE UNIQUE INDEX product_waitlist_open_key ON product_waitlist (product_id, user_id) WHERE notified_at IS NULL;
COMMENT ON TABLE product_waitlist IS 'ปุ่ม "แจ้งฉันเมื่อวางขาย" (F3, กติกา K)';

CREATE TABLE orders (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number        text NOT NULL UNIQUE,      -- เลขที่แสดงให้ลูกค้าเห็น
  buyer_user_id       uuid NOT NULL REFERENCES users (id),
  on_behalf_org_id    uuid REFERENCES organizations (id),  -- ซื้อในนามโรงเรียน
  status              text NOT NULL DEFAULT 'pending_payment' CHECK (status IN (
                        'pending_payment', 'awaiting_verification', 'underpaid', 'paid',
                        'awaiting_packing', 'shipped', 'code_redeemed', 'completed',
                        'cancelled', 'expired', 'partially_refunded', 'refunded')),
  subtotal_satang     bigint NOT NULL CHECK (subtotal_satang >= 0),
  discount_satang     bigint NOT NULL DEFAULT 0 CHECK (discount_satang >= 0),
  shipping_satang     bigint NOT NULL DEFAULT 0 CHECK (shipping_satang >= 0),
  total_satang        bigint NOT NULL CHECK (total_satang >= 0),
  vat_satang          bigint NOT NULL DEFAULT 0 CHECK (vat_satang >= 0),  -- VAT ที่รวมอยู่ใน total แล้ว
  withholding_satang  bigint NOT NULL DEFAULT 0 CHECK (withholding_satang >= 0),  -- หัก ณ ที่จ่ายที่ตกลงไว้
  amount_due_satang   bigint NOT NULL,           -- ยอดที่ต้องได้รับ = total − หัก ณ ที่จ่าย
  payment_due_at      timestamptz,               -- หมดเวลาชำระ · ใบเสนอราคาใช้วันยืนราคาของใบนั้น
  quotation_id        uuid,                      -- FK ใส่หลังสร้าง financial_documents
  billing_snapshot    jsonb,                     -- ข้อมูลออกเอกสาร ณ ตอนซื้อ
  billing_checked_by  uuid REFERENCES users (id),  -- ทีมงานตรวจข้อมูลใบกำกับในนามโรงเรียนก่อนจ่าย (กติกา J)
  billing_checked_at  timestamptz,
  shipping_snapshot   jsonb,                     -- ที่อยู่จัดส่ง ณ ตอนซื้อ
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CHECK (total_satang = subtotal_satang - discount_satang + shipping_satang),
  CHECK (vat_satang <= total_satang),
  CHECK (amount_due_satang = total_satang - withholding_satang),
  CHECK (amount_due_satang >= 0),
  CHECK ((billing_checked_by IS NULL) = (billing_checked_at IS NULL))
);
CREATE INDEX orders_buyer_idx ON orders (buyer_user_id, created_at DESC);
CREATE INDEX orders_open_status_idx ON orders (status)
  WHERE status IN ('awaiting_verification', 'underpaid', 'paid', 'awaiting_packing');
COMMENT ON TABLE orders IS 'คำสั่งซื้อเก็บสำเนาราคาและข้อมูล ณ ตอนซื้อ · สถานะเปลี่ยนได้ตามลูกศรเท่านั้น (orders_guard) และบันทึกประวัติเอง';

ALTER TABLE inventory_movements ADD FOREIGN KEY (order_id) REFERENCES orders (id);

CREATE TABLE order_items (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id           uuid NOT NULL REFERENCES orders (id),
  product_id         uuid REFERENCES products (id),
  seat_pool_id       uuid REFERENCES seat_pools (id),
  name_snapshot      text NOT NULL,
  unit_price_satang  bigint NOT NULL CHECK (unit_price_satang >= 0),
  quantity           integer NOT NULL CHECK (quantity > 0),
  discount_satang    bigint NOT NULL DEFAULT 0 CHECK (discount_satang >= 0),
  discount_source    text CHECK (discount_source IN ('pro_entitlement', 'voucher')),
  voucher_entry_id   bigint REFERENCES credit_ledger (id),  -- รายการหักคูปอง ใส่ตอนชำระเงินสำเร็จ
  seat_user_id       uuid REFERENCES users (id),  -- คนที่นั่ง · ใช้ส่วนลดของคนนี้ ไม่ใช่ของผู้จ่าย
  line_total_satang  bigint NOT NULL CHECK (line_total_satang >= 0),
  created_at         timestamptz NOT NULL DEFAULT now(),
  CHECK (num_nonnulls(product_id, seat_pool_id) = 1),
  CHECK ((seat_pool_id IS NULL) = (seat_user_id IS NULL)),
  CHECK (line_total_satang = unit_price_satang * quantity - discount_satang),
  CHECK ((discount_satang > 0) = (discount_source IS NOT NULL)),
  CHECK (voucher_entry_id IS NULL OR discount_source = 'voucher')
);
CREATE INDEX order_items_order_idx ON order_items (order_id);
CREATE TRIGGER order_items_fill_once BEFORE UPDATE OR DELETE ON order_items
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once('voucher_entry_id');
COMMENT ON TABLE order_items IS 'รายการในคำสั่งซื้อ (สำเนา ณ ตอนซื้อ) · ส่วนลดใช้แบบที่ดีที่สุดแบบเดียว ไม่ซ้อน';

CREATE TABLE inventory_holds (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id  uuid NOT NULL REFERENCES products (id),
  order_id    uuid NOT NULL REFERENCES orders (id),
  quantity    integer NOT NULL CHECK (quantity > 0),
  expires_at  timestamptz NOT NULL,              -- ตามเวลาจ่ายเงินของคำสั่งซื้อ · แนบสลิปแล้วต่อเวลาจนทีมงานตรวจเสร็จ
  status      text NOT NULL DEFAULT 'held' CHECK (status IN ('held', 'committed', 'released')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX inventory_holds_active_idx ON inventory_holds (product_id) WHERE status = 'held';
COMMENT ON TABLE inventory_holds IS 'กันของไว้ตั้งแต่สร้างคำสั่งซื้อ · สร้างผ่าน hold_stock() เท่านั้น · จ่ายแล้ว = committed + รายการ sale ใน inventory_movements';

CREATE TABLE order_status_history (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id       uuid NOT NULL REFERENCES orders (id),
  from_status    text,
  to_status      text NOT NULL,
  actor_user_id  uuid REFERENCES users (id),     -- NULL = ระบบ (เช่น ระบบรับเงินยืนยัน)
  reason         text,
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX order_status_history_order_idx ON order_status_history (order_id, created_at);
CREATE TRIGGER order_status_history_append_only BEFORE UPDATE OR DELETE ON order_status_history
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE order_status_history IS 'ประวัติสถานะคำสั่งซื้อ trigger บันทึกให้เอง · API ตั้ง app.actor_user_id และ app.status_reason ก่อนเปลี่ยนสถานะ';

-- สถานะคำสั่งซื้อเปลี่ยนได้ตามลูกศรเท่านั้น (system-plan 6.2) และยอดเงินแก้ได้เฉพาะก่อนจ่าย
CREATE FUNCTION orders_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'คำสั่งซื้อห้ามลบ ให้เปลี่ยนเป็นยกเลิกแทน' USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status AND (OLD.status, NEW.status) NOT IN (
       ('pending_payment',       'awaiting_verification'),  -- แนบสลิป
       ('pending_payment',       'paid'),                   -- ระบบรับเงินยืนยัน
       ('pending_payment',       'cancelled'),
       ('pending_payment',       'expired'),
       ('awaiting_verification', 'paid'),
       ('awaiting_verification', 'underpaid'),
       ('awaiting_verification', 'pending_payment'),        -- สลิปไม่ถูกต้อง ให้ส่งใหม่
       ('awaiting_verification', 'cancelled'),
       ('underpaid',             'awaiting_verification'),  -- โอนส่วนที่ขาดมาแล้ว
       ('underpaid',             'cancelled'),
       ('paid',                  'awaiting_packing'),       -- สินค้าจับต้องได้
       ('paid',                  'completed'),              -- ที่นั่ง สมาชิก ชุดเติม
       ('paid',                  'cancelled'),              -- ยกเลิกก่อนแพ็ก (บันทึกคืนเงินใน refunds)
       ('awaiting_packing',      'shipped'),
       ('awaiting_packing',      'cancelled'),
       ('shipped',               'code_redeemed'),
       ('shipped',               'partially_refunded'),
       ('shipped',               'refunded'),
       ('code_redeemed',         'partially_refunded'),
       ('code_redeemed',         'refunded'),
       ('completed',             'partially_refunded'),
       ('completed',             'refunded'),
       ('partially_refunded',    'refunded')
     ) THEN
    RAISE EXCEPTION 'เปลี่ยนสถานะคำสั่งซื้อจาก % เป็น % ไม่ได้', OLD.status, NEW.status
      USING ERRCODE = 'check_violation';
  END IF;

  IF OLD.status NOT IN ('pending_payment', 'awaiting_verification', 'underpaid')
     AND (NEW.subtotal_satang, NEW.discount_satang, NEW.shipping_satang, NEW.total_satang,
          NEW.vat_satang, NEW.withholding_satang, NEW.amount_due_satang, NEW.buyer_user_id)
         IS DISTINCT FROM
         (OLD.subtotal_satang, OLD.discount_satang, OLD.shipping_satang, OLD.total_satang,
          OLD.vat_satang, OLD.withholding_satang, OLD.amount_due_satang, OLD.buyer_user_id) THEN
    RAISE EXCEPTION 'คำสั่งซื้อที่ชำระแล้วแก้ยอดเงินหรือผู้ซื้อไม่ได้' USING ERRCODE = 'insufficient_privilege';
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END $$;
CREATE TRIGGER orders_guard BEFORE UPDATE OR DELETE ON orders
  FOR EACH ROW EXECUTE FUNCTION orders_guard();

CREATE FUNCTION orders_record_status() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' OR NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO order_status_history (order_id, from_status, to_status, actor_user_id, reason)
    VALUES (NEW.id,
            CASE WHEN TG_OP = 'UPDATE' THEN OLD.status END,
            NEW.status,
            nullif(current_setting('app.actor_user_id', true), '')::uuid,
            nullif(current_setting('app.status_reason', true), ''));
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER orders_record_status AFTER INSERT OR UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION orders_record_status();

CREATE TABLE payments (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id             uuid NOT NULL REFERENCES orders (id),
  provider             text NOT NULL CHECK (provider IN ('stripe', 'opn', 'bank_transfer')),
  method               text NOT NULL CHECK (method IN ('promptpay', 'card', 'transfer')),
  provider_payment_id  text,                     -- รหัสฝั่งผู้ให้บริการ
  amount_satang        bigint NOT NULL CHECK (amount_satang > 0),
  currency             text NOT NULL DEFAULT 'THB' CHECK (currency = 'THB'),
  status               text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'succeeded', 'failed', 'expired', 'cancelled')),
  expires_at           timestamptz,              -- QR พร้อมเพย์อายุ 15 นาที สร้างใหม่ได้
  slip_file_id         uuid REFERENCES files (id),
  verified_by          uuid REFERENCES users (id),  -- ทีมงานที่ยืนยันสลิป
  verified_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  CHECK ((method = 'transfer') = (provider = 'bank_transfer')),
  CHECK (method <> 'transfer' OR status <> 'succeeded' OR verified_by IS NOT NULL),
  CHECK ((verified_by IS NULL) = (verified_at IS NULL))
);
CREATE UNIQUE INDEX payments_provider_key ON payments (provider, provider_payment_id) WHERE provider_payment_id IS NOT NULL;
CREATE INDEX payments_order_idx ON payments (order_id);
COMMENT ON TABLE payments IS 'การจ่ายแยกจากคำสั่งซื้อ 1 คำสั่งซื้อจ่ายได้หลายครั้ง เช่น QR หมดอายุแล้วสร้างใหม่ หรือโอนส่วนที่ขาด';

-- ยอดและผู้ให้บริการแก้ไม่ได้ · สถานะเดินจาก pending ไปสถานะจบได้ครั้งเดียว
CREATE FUNCTION payments_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'รายการจ่ายเงินห้ามลบ' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF (NEW.order_id, NEW.provider, NEW.method, NEW.amount_satang, NEW.currency)
     IS DISTINCT FROM (OLD.order_id, OLD.provider, OLD.method, OLD.amount_satang, OLD.currency) THEN
    RAISE EXCEPTION 'รายการจ่ายเงินแก้ยอดหรือช่องทางไม่ได้' USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status AND OLD.status <> 'pending' THEN
    RAISE EXCEPTION 'รายการจ่ายเงินที่จบแล้ว (%) เปลี่ยนสถานะไม่ได้', OLD.status USING ERRCODE = 'check_violation';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END $$;
CREATE TRIGGER payments_guard BEFORE UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION payments_guard();

CREATE TABLE payment_events (
  id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  provider           text NOT NULL CHECK (provider IN ('stripe', 'opn')),
  provider_event_id  text NOT NULL,
  event_type         text NOT NULL,
  payload            jsonb NOT NULL,             -- ข้อมูลดิบ เก็บหลังตรวจลายเซ็นผ่านแล้วเท่านั้น
  received_at        timestamptz NOT NULL DEFAULT now(),
  processed_at       timestamptz,
  UNIQUE (provider, provider_event_id)
);
CREATE INDEX payment_events_pending_idx ON payment_events (received_at) WHERE processed_at IS NULL;
CREATE TRIGGER payment_events_fill_once BEFORE UPDATE OR DELETE ON payment_events
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once('processed_at');
COMMENT ON TABLE payment_events IS 'ข้อความแจ้งจากระบบรับเงิน · รหัสเหตุการณ์ห้ามซ้ำ จึงรับข้อความซ้ำได้โดยผลไม่ซ้ำ (system-plan 6.3)';

CREATE TABLE refunds (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id     uuid NOT NULL REFERENCES payments (id),
  amount_satang  bigint NOT NULL CHECK (amount_satang > 0),
  method         text NOT NULL CHECK (method IN ('gateway', 'manual_transfer')),  -- พร้อมเพย์บางเจ้าต้องโอนคืนเอง
  reason         text NOT NULL,
  status         text NOT NULL DEFAULT 'requested' CHECK (status IN ('requested', 'approved', 'completed', 'rejected')),
  requested_by   uuid NOT NULL REFERENCES users (id),
  approved_by    uuid REFERENCES users (id),
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  completed_at   timestamptz,
  CHECK (status NOT IN ('approved', 'completed') OR approved_by IS NOT NULL),
  CHECK ((status = 'completed') = (completed_at IS NOT NULL))
);
CREATE INDEX refunds_payment_idx ON refunds (payment_id);
COMMENT ON TABLE refunds IS 'การคืนเงิน เต็มหรือบางส่วน · คืนรวมเกินยอดที่จ่ายไม่ได้';

-- คืนเงินรวมทุกรายการ (ที่ไม่ถูกปฏิเสธ) ต้องไม่เกินยอดที่จ่ายสำเร็จ
CREATE FUNCTION refunds_within_payment() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  paid      bigint;
  refunded  bigint;
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'รายการคืนเงินห้ามลบ' USING ERRCODE = 'insufficient_privilege';
  END IF;
  SELECT amount_satang INTO paid FROM payments
   WHERE id = NEW.payment_id AND status = 'succeeded' FOR UPDATE;
  IF paid IS NULL THEN
    RAISE EXCEPTION 'คืนเงินได้เฉพาะรายการจ่ายที่สำเร็จแล้ว' USING ERRCODE = 'check_violation';
  END IF;
  SELECT coalesce(sum(amount_satang), 0) INTO refunded FROM refunds
   WHERE payment_id = NEW.payment_id AND status <> 'rejected' AND id <> NEW.id;
  IF NEW.status <> 'rejected' AND refunded + NEW.amount_satang > paid THEN
    RAISE EXCEPTION 'คืนเงินรวม % สตางค์ เกินยอดที่จ่าย % สตางค์', refunded + NEW.amount_satang, paid
      USING ERRCODE = 'check_violation';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END $$;
CREATE TRIGGER refunds_within_payment BEFORE INSERT OR UPDATE OR DELETE ON refunds
  FOR EACH ROW EXECUTE FUNCTION refunds_within_payment();

CREATE TABLE shipments (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id         uuid NOT NULL REFERENCES orders (id),
  carrier          text NOT NULL,
  tracking_number  text NOT NULL,
  shipped_at       timestamptz NOT NULL DEFAULT now(),
  created_by       uuid NOT NULL REFERENCES users (id),
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX shipments_order_idx ON shipments (order_id);
COMMENT ON TABLE shipments IS 'การจัดส่งและเลขพัสดุ (A2)';

CREATE TABLE shipment_codes (
  shipment_id     uuid NOT NULL REFERENCES shipments (id),
  redeem_code_id  uuid NOT NULL UNIQUE REFERENCES redeem_codes (id),  -- รหัส 1 รหัสอยู่ได้กล่องเดียว
  added_by        uuid NOT NULL REFERENCES users (id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (shipment_id, redeem_code_id)
);
CREATE TRIGGER shipment_codes_append_only BEFORE UPDATE OR DELETE ON shipment_codes
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE shipment_codes IS 'รหัสในกล่องที่ทีมงานสแกนใส่ไปกับคำสั่งซื้อ · ใช้นับ "ผู้ซื้อที่เปิดใช้จริง" (view order_code_redemptions)';

CREATE TABLE reconciliation_items (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  statement_date   date NOT NULL,
  provider         text NOT NULL CHECK (provider IN ('stripe', 'opn', 'bank_transfer')),
  provider_txn_id  text NOT NULL,
  amount_satang    bigint NOT NULL,
  payment_id       uuid REFERENCES payments (id),
  status           text NOT NULL CHECK (status IN ('matched', 'mismatch', 'resolved')),
  note             text,
  resolved_by      uuid REFERENCES users (id),
  resolved_at      timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_txn_id),
  CHECK ((status = 'resolved') = (resolved_at IS NOT NULL)),
  CHECK (status <> 'resolved' OR (resolved_by IS NOT NULL AND note IS NOT NULL))
);
COMMENT ON TABLE reconciliation_items IS 'งานตรวจยอดทุกวัน เทียบรายการผู้ให้บริการกับคำสั่งซื้อ · ไม่ตรงขึ้นกล่องงานฝ่ายบัญชี';

CREATE TABLE seat_bookings (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seat_pool_id         uuid NOT NULL REFERENCES seat_pools (id),
  user_id              uuid NOT NULL REFERENCES users (id),  -- คนที่นั่ง
  booked_by            uuid NOT NULL REFERENCES users (id),  -- คนจอง/คนจ่าย (ซื้อให้คนอื่นได้)
  status               text NOT NULL CHECK (status IN (
                         'pending_payment', 'booked', 'awaiting_prerequisite', 'confirmed', 'attended',
                         'no_show', 'waitlisted', 'lottery_pending', 'lottery_not_selected',
                         'forfeited', 'cancelled')),
  order_id             uuid REFERENCES orders (id),
  hold_expires_at      timestamptz,              -- ที่นั่งจ่ายเงิน: กันที่ไว้ถึงเมื่อไร
  waitlist_position    integer CHECK (waitlist_position > 0),
  priority_next_round  boolean NOT NULL DEFAULT false,  -- จับรางวัลไม่ได้รับเลือก ได้จองก่อนรอบหน้า
  cancel_reason        text,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  CHECK ((status = 'waitlisted') = (waitlist_position IS NOT NULL)),
  CHECK ((status = 'pending_payment') = (hold_expires_at IS NOT NULL)),
  CHECK (status <> 'cancelled' OR cancel_reason IS NOT NULL)
);
CREATE UNIQUE INDEX seat_bookings_one_per_pool ON seat_bookings (seat_pool_id, user_id)
  WHERE status NOT IN ('cancelled', 'forfeited', 'lottery_not_selected');
COMMENT ON TABLE seat_bookings IS 'การจองที่นั่ง สถานะตาม O5 · no_show = ไม่มาโดยไม่แจ้ง (งดสิทธิ์ที่นั่งฟรีรอบถัดไป 1 รอบ) · แจ้งล่วงหน้าให้ใช้ cancelled';

-- จำนวนที่นั่งที่ใช้อยู่ห้ามเกิน capacity ของกอง (ล็อกแถวกองที่นั่งกันการจองพร้อมกัน)
CREATE FUNCTION seat_bookings_capacity() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  seat_limit  integer;
  taken       integer;
BEGIN
  IF NEW.status NOT IN ('pending_payment', 'booked', 'awaiting_prerequisite', 'confirmed', 'attended', 'no_show')
     OR (TG_OP = 'UPDATE' AND OLD.status IN ('pending_payment', 'booked', 'awaiting_prerequisite', 'confirmed', 'attended', 'no_show')) THEN
    NEW.updated_at := now();
    RETURN NEW;
  END IF;
  SELECT capacity INTO seat_limit FROM seat_pools WHERE id = NEW.seat_pool_id FOR UPDATE;
  SELECT count(*) INTO taken FROM seat_bookings
   WHERE seat_pool_id = NEW.seat_pool_id AND id <> NEW.id
     AND (status IN ('booked', 'awaiting_prerequisite', 'confirmed', 'attended', 'no_show')
          OR (status = 'pending_payment' AND hold_expires_at > now()));
  IF taken >= seat_limit THEN
    RAISE EXCEPTION 'ที่นั่งในกองนี้เต็มแล้ว (% ที่) ให้เข้าคิวสำรองแทน', seat_limit USING ERRCODE = 'check_violation';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END $$;
CREATE TRIGGER seat_bookings_capacity BEFORE INSERT OR UPDATE ON seat_bookings
  FOR EACH ROW EXECUTE FUNCTION seat_bookings_capacity();


-- =============================================================================
-- 6. เอกสารการเงิน (system-plan 6.6)
-- =============================================================================

CREATE TABLE document_sequences (
  doc_type     text NOT NULL CHECK (doc_type IN ('quotation', 'invoice', 'receipt', 'tax_invoice', 'credit_note')),
  year         integer NOT NULL,                 -- ปี พ.ศ. ของเลขที่เอกสาร
  last_number  integer NOT NULL CHECK (last_number > 0),
  PRIMARY KEY (doc_type, year)
);
COMMENT ON TABLE document_sequences IS 'เลขที่เอกสารล่าสุดแยกตามประเภทและปี · ออกเลขผ่าน next_document_number() ในธุรกรรมเดียวกับการออกเอกสาร จึงไม่ข้ามและไม่ซ้ำ';

CREATE TABLE financial_documents (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doc_type               text NOT NULL CHECK (doc_type IN ('quotation', 'invoice', 'receipt', 'tax_invoice', 'credit_note')),
  seq_year               integer NOT NULL,
  seq_number             integer NOT NULL CHECK (seq_number > 0),
  doc_number             text NOT NULL UNIQUE,   -- เลขที่ที่พิมพ์บนเอกสาร API จัดรูปแบบจาก doc_type + ปี + ลำดับ
  order_id               uuid REFERENCES orders (id),
  refers_to_document_id  uuid REFERENCES financial_documents (id),  -- ใบแจ้งหนี้อ้างใบเสนอราคา · ใบลดหนี้อ้างใบกำกับเดิม
  requested_by           uuid REFERENCES users (id),  -- ใบเสนอราคาที่ครูหรือโรงเรียนกดขอ (F10)
  buyer_snapshot         jsonb NOT NULL,         -- ชื่อ ที่อยู่ เลขผู้เสียภาษี สาขา ณ วันที่ออก
  items_snapshot         jsonb NOT NULL,
  subtotal_satang        bigint NOT NULL CHECK (subtotal_satang >= 0),
  discount_satang        bigint NOT NULL DEFAULT 0 CHECK (discount_satang >= 0),
  vat_satang             bigint NOT NULL DEFAULT 0 CHECK (vat_satang >= 0),
  total_satang           bigint NOT NULL CHECK (total_satang >= 0),
  amount_in_words        text NOT NULL,          -- เช่น ห้าร้อยบาทถ้วน
  valid_until            timestamptz,            -- ใบเสนอราคา: ยืนราคาถึง
  pdf_file_id            uuid REFERENCES files (id),
  issued_by              uuid REFERENCES users (id),  -- NULL = ระบบออกเอง เช่น ใบเสร็จหลังจ่ายผ่านระบบรับเงิน
  issued_at              timestamptz NOT NULL DEFAULT now(),
  voided_at              timestamptz,
  voided_by              uuid REFERENCES users (id),
  void_reason            text,
  UNIQUE (doc_type, seq_year, seq_number),
  CHECK ((doc_type = 'quotation') = (valid_until IS NOT NULL)),
  CHECK (doc_type IN ('quotation') OR order_id IS NOT NULL),
  CHECK (doc_type <> 'credit_note' OR refers_to_document_id IS NOT NULL),
  CHECK ((voided_at IS NULL) = (void_reason IS NULL)),
  CHECK ((voided_at IS NULL) = (voided_by IS NULL))
);
CREATE INDEX financial_documents_order_idx ON financial_documents (order_id);
CREATE TRIGGER financial_documents_fill_once BEFORE UPDATE OR DELETE ON financial_documents
  FOR EACH ROW EXECUTE FUNCTION allow_fill_once('pdf_file_id', 'voided_at', 'voided_by', 'void_reason');
COMMENT ON TABLE financial_documents IS 'เอกสารที่ออกแล้วห้ามแก้ ต้องออกใบใหม่ · ยกเลิก = ทำเครื่องหมายพร้อมเหตุผล · ใบกำกับภาษีออกได้เฉพาะเมื่อบริษัทจด VAT (ตรวจที่ API)';

ALTER TABLE orders ADD FOREIGN KEY (quotation_id) REFERENCES financial_documents (id);

CREATE TABLE quotation_followups (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id  uuid NOT NULL REFERENCES financial_documents (id),
  called_by     uuid NOT NULL REFERENCES users (id),
  outcome       text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX quotation_followups_quotation_idx ON quotation_followups (quotation_id, created_at DESC);
CREATE TRIGGER quotation_followups_append_only BEFORE UPDATE OR DELETE ON quotation_followups
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE quotation_followups IS 'บันทึกการโทรตามใบเสนอราคา (A3)';

CREATE TABLE withholding_records (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id               uuid NOT NULL REFERENCES orders (id),
  financial_document_id  uuid REFERENCES financial_documents (id),
  amount_satang          bigint NOT NULL CHECK (amount_satang > 0),
  certificate_file_id    uuid REFERENCES files (id),  -- หนังสือรับรองการหักภาษี ณ ที่จ่าย
  recorded_by            uuid NOT NULL REFERENCES users (id),
  created_at             timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER withholding_records_append_only BEFORE UPDATE OR DELETE ON withholding_records
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE withholding_records IS 'หลักฐานภาษีหัก ณ ที่จ่ายที่ได้รับจริง · ยอดที่ตกลงหักไว้ล่วงหน้าอยู่ที่ orders.withholding_satang · อัตราให้ผู้ทำบัญชียืนยัน';


-- =============================================================================
-- 7. แจ้งเตือนและบันทึก
-- =============================================================================

CREATE TABLE notification_templates (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_code  text NOT NULL,                     -- เช่น order.confirmed, shipment.tracking
  channel     text NOT NULL CHECK (channel IN ('line', 'email')),
  body        text NOT NULL,
  is_enabled  boolean NOT NULL DEFAULT true,
  is_required boolean NOT NULL DEFAULT false,    -- ปิดไม่ได้ เช่น ยืนยันคำสั่งซื้อ เลขพัสดุ
  updated_by  uuid REFERENCES users (id),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (event_code, channel),
  CHECK (is_enabled OR NOT is_required)
);
COMMENT ON TABLE notification_templates IS 'แม่แบบข้อความ ทีมงานแก้คำได้ (A11, O7)';

CREATE TABLE notifications (
  id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  recipient_user_id  uuid NOT NULL REFERENCES users (id),
  event_code         text NOT NULL,
  channel            text NOT NULL CHECK (channel IN ('line', 'email')),
  counts_line_quota  boolean NOT NULL,           -- push นับโควตา LINE · ข้อความตอบแชตไม่นับ
  status             text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'failed', 'skipped')),
  scheduled_for      timestamptz NOT NULL DEFAULT now(),
  sent_at            timestamptz,
  error              text,
  ref_type           text,                       -- เช่น order, seat_booking
  ref_id             text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  CHECK (channel = 'line' OR NOT counts_line_quota),
  CHECK ((status = 'sent') = (sent_at IS NOT NULL))
);
CREATE INDEX notifications_due_idx ON notifications (scheduled_for) WHERE status = 'queued';
CREATE INDEX notifications_quota_idx ON notifications (sent_at) WHERE counts_line_quota AND status = 'sent';
COMMENT ON TABLE notifications IS 'คิวและประวัติการส่งข้อความ · ยอดใช้โควตา LINE อ่านจาก view line_quota_usage';

CREATE TABLE audit_logs (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor_user_id  uuid REFERENCES users (id),     -- NULL = ระบบ
  action         text NOT NULL,                  -- เช่น grant.create, code.transfer, setting.update
  resource_type  text NOT NULL,
  resource_id    text NOT NULL,
  before         jsonb,                          -- ปิดข้อมูลอ่อนไหวก่อนบันทึก
  after          jsonb,
  reason         text,
  ip             inet,
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_logs_resource_idx ON audit_logs (resource_type, resource_id);
CREATE INDEX audit_logs_actor_idx ON audit_logs (actor_user_id, created_at DESC);
CREATE TRIGGER audit_logs_append_only BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE audit_logs IS 'บันทึกการเปลี่ยนแปลงของเงิน สิทธิ์ รหัส เอกสาร ข้อมูลส่วนบุคคล และค่าตั้ง · ห้ามลบ';

CREATE TABLE pii_access_logs (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  staff_user_id    uuid NOT NULL REFERENCES staff_members (user_id),
  subject_user_id  uuid NOT NULL REFERENCES users (id),
  field            text NOT NULL,                -- เช่น phone, address
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX pii_access_logs_subject_idx ON pii_access_logs (subject_user_id, created_at DESC);
CREATE TRIGGER pii_access_logs_append_only BEFORE UPDATE OR DELETE ON pii_access_logs
  FOR EACH ROW EXECUTE FUNCTION forbid_change();
COMMENT ON TABLE pii_access_logs IS 'ทีมงานกดดูเบอร์หรือที่อยู่เต็ม ระบบบันทึกว่าใครดูของใคร';


-- =============================================================================
-- 8. trigger ของตารางที่แก้ได้ (updated_at)
-- =============================================================================

CREATE TRIGGER users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER addresses_updated_at BEFORE UPDATE ON addresses FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER schools_directory_updated_at BEFORE UPDATE ON schools_directory FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER org_memberships_updated_at BEFORE UPDATE ON org_memberships FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER staff_members_updated_at BEFORE UPDATE ON staff_members FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER plans_updated_at BEFORE UPDATE ON plans FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER subscriptions_updated_at BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER seat_pools_updated_at BEFORE UPDATE ON seat_pools FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER inventory_holds_updated_at BEFORE UPDATE ON inventory_holds FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER shipments_updated_at BEFORE UPDATE ON shipments FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER reconciliation_items_updated_at BEFORE UPDATE ON reconciliation_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER notification_templates_updated_at BEFORE UPDATE ON notification_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- 9. ฟังก์ชันที่ต้องล็อกแถว (API เรียกผ่านฟังก์ชันเหล่านี้เท่านั้น)
-- =============================================================================

-- ตรวจทุกรายการที่เข้าสมุดเครดิต
--   grant : คูปองที่ได้ครั้งเดียวต่อบัญชี ห้ามได้ซ้ำ
--   อื่น ๆ : ต้องอ้างก้อนของเจ้าของและชนิดเดียวกัน · ห้ามหักจากก้อนที่หมดอายุ · ก้อนห้ามติดลบ
--           คืน (return) ได้เท่ากับที่หักไปเท่านั้น และคืนได้ครั้งเดียว (unique index)
CREATE FUNCTION credit_ledger_check() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  lot        credit_ledger;
  remaining  integer;
BEGIN
  IF NEW.entry_type = 'grant' THEN
    IF (SELECT once_per_holder FROM credit_types WHERE code = NEW.credit_type_code) THEN
      PERFORM pg_advisory_xact_lock(hashtext(
        'credit-once:' || coalesce(NEW.holder_user_id, NEW.holder_org_id)::text || ':' || NEW.credit_type_code));
      IF EXISTS (SELECT 1 FROM credit_ledger
                  WHERE entry_type = 'grant' AND credit_type_code = NEW.credit_type_code
                    AND holder_user_id IS NOT DISTINCT FROM NEW.holder_user_id
                    AND holder_org_id IS NOT DISTINCT FROM NEW.holder_org_id) THEN
        RAISE EXCEPTION 'เครดิต % ได้ครั้งเดียวต่อบัญชี', NEW.credit_type_code USING ERRCODE = 'unique_violation';
      END IF;
    END IF;
    RETURN NEW;
  END IF;

  SELECT * INTO lot FROM credit_ledger WHERE id = NEW.lot_id FOR UPDATE;
  IF lot.entry_type IS DISTINCT FROM 'grant'
     OR lot.credit_type_code <> NEW.credit_type_code
     OR lot.holder_user_id IS DISTINCT FROM NEW.holder_user_id
     OR lot.holder_org_id IS DISTINCT FROM NEW.holder_org_id THEN
    RAISE EXCEPTION 'lot_id ต้องชี้ไปที่ก้อนเครดิตของเจ้าของและชนิดเดียวกัน' USING ERRCODE = 'check_violation';
  END IF;
  IF NEW.entry_type = 'use' AND lot.expires_at IS NOT NULL AND lot.expires_at <= now() THEN
    RAISE EXCEPTION 'ก้อนเครดิตนี้หมดอายุแล้ว' USING ERRCODE = 'check_violation';
  END IF;
  IF NEW.entry_type = 'return' AND NOT EXISTS (
       SELECT 1 FROM credit_ledger
        WHERE id = NEW.reverses_id AND entry_type = 'use' AND lot_id = NEW.lot_id AND amount = -NEW.amount) THEN
    RAISE EXCEPTION 'คืนเครดิตได้เท่ากับรายการที่หักไปจากก้อนเดียวกันเท่านั้น' USING ERRCODE = 'check_violation';
  END IF;

  SELECT lot.amount + coalesce(sum(amount), 0) INTO remaining FROM credit_ledger WHERE lot_id = NEW.lot_id;
  IF remaining + NEW.amount < 0 THEN
    RAISE EXCEPTION 'เครดิตในก้อนนี้เหลือ % ไม่พอหัก %', remaining, -NEW.amount USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER credit_ledger_check BEFORE INSERT ON credit_ledger
  FOR EACH ROW EXECUTE FUNCTION credit_ledger_check();

-- หักเครดิตแบบปลอดภัย: ล็อกทุกก้อนของเจ้าของนี้ก่อน แล้วหักจากก้อนที่หมดอายุก่อนก่อน
-- เหลือไม่พอ = ไม่หักเลยสักก้อน (ทั้งคำสั่งย้อนกลับ) · amount > 1 ได้ เช่น ร่าง Canvas ทั้งใบ
CREATE FUNCTION use_credit(p_user uuid, p_org uuid, p_type text, p_amount integer,
                           p_ref_type text, p_ref_id text, p_actor uuid)
RETURNS SETOF credit_ledger LANGUAGE plpgsql AS $$
DECLARE
  lot    record;
  need   integer := p_amount;
  taken  credit_ledger;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'จำนวนที่หักต้องมากกว่า 0' USING ERRCODE = 'check_violation';
  END IF;

  PERFORM 1 FROM credit_ledger
   WHERE entry_type = 'grant' AND credit_type_code = p_type
     AND holder_user_id IS NOT DISTINCT FROM p_user AND holder_org_id IS NOT DISTINCT FROM p_org
   ORDER BY id
     FOR UPDATE;

  FOR lot IN
    SELECT id, remaining FROM credit_lots
     WHERE holder_user_id IS NOT DISTINCT FROM p_user AND holder_org_id IS NOT DISTINCT FROM p_org
       AND credit_type_code = p_type AND NOT is_expired AND remaining > 0
     ORDER BY expires_at NULLS LAST, id
  LOOP
    INSERT INTO credit_ledger (holder_user_id, holder_org_id, credit_type_code, entry_type, amount,
                               lot_id, usage_ref_type, usage_ref_id, created_by)
    VALUES (p_user, p_org, p_type, 'use', -least(lot.remaining, need),
            lot.id, p_ref_type, p_ref_id, p_actor)
    RETURNING * INTO taken;
    RETURN NEXT taken;
    need := need + taken.amount;
    EXIT WHEN need = 0;
  END LOOP;

  IF need > 0 THEN
    RAISE EXCEPTION 'เครดิต % ไม่พอ ขาดอีก %', p_type, need USING ERRCODE = 'check_violation';
  END IF;
END $$;

-- ราคาต่อชิ้นตามจำนวนและวันที่ (ราคาขั้นจำนวน + ราคาช่วงโปรโมชัน)
-- ขั้นจำนวนที่สูงสุดที่ถึงก่อน · ถ้าขั้นเดียวกันมีหลายราคาซ้อนช่วงเวลา ใช้ราคาที่เริ่มทีหลัง (โปรโมชัน)
CREATE FUNCTION unit_price(p_product uuid, p_quantity integer, p_at timestamptz DEFAULT now())
RETURNS bigint LANGUAGE sql STABLE AS $$
  SELECT price_satang FROM prices
   WHERE product_id = p_product AND min_quantity <= p_quantity
     AND valid_from <= p_at AND (valid_until IS NULL OR valid_until > p_at)
   ORDER BY min_quantity DESC, valid_from DESC
   LIMIT 1;
$$;

-- กันของไว้ให้คำสั่งซื้อ: ล็อกแถวสินค้าก่อน จึงไม่มี 2 คนได้ชิ้นสุดท้ายพร้อมกัน
CREATE FUNCTION hold_stock(p_product uuid, p_order uuid, p_quantity integer, p_expires_at timestamptz)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
  left_qty  integer;
  hold_id   uuid;
BEGIN
  PERFORM 1 FROM products WHERE id = p_product AND tracks_stock FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'สินค้านี้ไม่ได้นับสต็อก' USING ERRCODE = 'check_violation';
  END IF;
  SELECT available INTO left_qty FROM product_stock WHERE product_id = p_product;
  IF left_qty < p_quantity THEN
    RAISE EXCEPTION 'สินค้าเหลือ % ชิ้น ไม่พอสำหรับ % ชิ้น', left_qty, p_quantity USING ERRCODE = 'check_violation';
  END IF;
  INSERT INTO inventory_holds (product_id, order_id, quantity, expires_at)
  VALUES (p_product, p_order, p_quantity, p_expires_at)
  RETURNING id INTO hold_id;
  RETURN hold_id;
END $$;

-- ออกเลขที่เอกสารถัดไป: แถวของประเภทและปีนั้นถูกล็อกจนจบธุรกรรม
-- ต้องเรียกในธุรกรรมเดียวกับการเพิ่ม financial_documents ถ้าธุรกรรมล้มเลขจะย้อนกลับด้วย จึงไม่ข้าม
CREATE FUNCTION next_document_number(p_doc_type text, p_year integer) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE
  n integer;
BEGIN
  INSERT INTO document_sequences (doc_type, year, last_number) VALUES (p_doc_type, p_year, 1)
  ON CONFLICT (doc_type, year) DO UPDATE SET last_number = document_sequences.last_number + 1
  RETURNING last_number INTO n;
  RETURN n;
END $$;


-- =============================================================================
-- 10. view สำหรับอ่านสถานะที่คำนวณจากข้อมูล
-- =============================================================================

-- สถานะการได้สิทธิ์ (Appendix ก.: รอเริ่ม / ใช้งานอยู่ / ผ่อนผัน / หมดอายุ / ยกเลิก)
CREATE VIEW grant_statuses AS
SELECT g.*,
       CASE
         WHEN g.cancelled_at IS NOT NULL                     THEN 'cancelled'
         WHEN g.starts_at IS NULL OR g.starts_at > now()     THEN 'pending'
         WHEN g.ends_at IS NOT NULL AND g.ends_at <= now()   THEN 'expired'
         WHEN g.is_grace                                     THEN 'grace'
         ELSE 'active'
       END AS status
  FROM grants g;

-- สิทธิ์ที่ใช้ได้ตอนนี้ของแต่ละเจ้าของ · ฟังก์ชัน can() / limit() ของ API อ่านจาก view นี้
-- ยังไม่รวมสิทธิ์ของโรงเรียนที่ครูได้ที่นั่ง (Phase 3)
CREATE VIEW active_entitlements AS
SELECT g.holder_user_id, g.holder_org_id, g.id AS grant_id, g.ends_at,
       i.entitlement_code, d.value_type, d.combine_rule, i.entitlement_value, i.is_unlimited
  FROM grant_statuses g
  JOIN plan_version_items i ON i.part_id = g.part_id AND i.entitlement_code IS NOT NULL
  JOIN entitlement_defs d ON d.code = i.entitlement_code
 WHERE g.status IN ('active', 'grace');

-- ก้อนเครดิตและยอดคงเหลือของแต่ละก้อน
CREATE VIEW credit_lots AS
SELECT l.id, l.holder_user_id, l.holder_org_id, l.credit_type_code, l.grant_id,
       l.amount AS granted, l.expires_at,
       l.amount + coalesce((SELECT sum(x.amount) FROM credit_ledger x WHERE x.lot_id = l.id), 0) AS remaining,
       (l.expires_at IS NOT NULL AND l.expires_at <= now()) AS is_expired
  FROM credit_ledger l
 WHERE l.entry_type = 'grant';

-- ยอดเครดิตคงเหลือที่ยังไม่หมดอายุ · creditBalance() ของ API เรียกตัวนี้
CREATE FUNCTION credit_balance(p_user uuid, p_org uuid, p_type text) RETURNS integer
LANGUAGE sql STABLE AS $$
  SELECT coalesce(sum(remaining), 0)::integer FROM credit_lots
   WHERE holder_user_id IS NOT DISTINCT FROM p_user AND holder_org_id IS NOT DISTINCT FROM p_org
     AND credit_type_code = p_type AND NOT is_expired;
$$;

-- สต็อก: มีอยู่ − ที่กันไว้ (เฉพาะที่ยังไม่หมดเวลา)
CREATE VIEW product_stock AS
SELECT p.id AS product_id,
       coalesce((SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id), 0) AS on_hand,
       coalesce((SELECT sum(h.quantity) FROM inventory_holds h
                  WHERE h.product_id = p.id AND h.status = 'held' AND h.expires_at > now()), 0) AS held,
       coalesce((SELECT sum(m.quantity) FROM inventory_movements m WHERE m.product_id = p.id), 0)
     - coalesce((SELECT sum(h.quantity) FROM inventory_holds h
                  WHERE h.product_id = p.id AND h.status = 'held' AND h.expires_at > now()), 0) AS available
  FROM products p
 WHERE p.tracks_stock;

-- ยอดรับแล้วและยอดคืนของแต่ละคำสั่งซื้อ
CREATE VIEW order_payment_totals AS
SELECT o.id AS order_id, o.amount_due_satang,
       coalesce((SELECT sum(p.amount_satang) FROM payments p
                  WHERE p.order_id = o.id AND p.status = 'succeeded'), 0) AS paid_satang,
       coalesce((SELECT sum(r.amount_satang) FROM refunds r JOIN payments p ON p.id = r.payment_id
                  WHERE p.order_id = o.id AND r.status = 'completed'), 0) AS refunded_satang
  FROM orders o;

-- คำสั่งซื้อการ์ด: รหัสที่ส่งไปกี่รหัส กดใช้แล้วกี่รหัส (ตัวชี้วัด "ผู้ซื้อที่เปิดใช้จริง")
CREATE VIEW order_code_redemptions AS
SELECT s.order_id,
       count(*) AS codes_shipped,
       count(rc.redeemed_at) AS codes_redeemed
  FROM shipments s
  JOIN shipment_codes sc ON sc.shipment_id = s.id
  JOIN redeem_codes rc ON rc.id = sc.redeem_code_id
 GROUP BY s.order_id;

-- สถานะรหัสในกล่อง (O5: สร้างแล้ว → ส่งโรงพิมพ์ → อยู่ในกล่อง → เปิดใช้แล้ว · ยกเลิก)
CREATE VIEW redeem_code_statuses AS
SELECT rc.id, rc.batch_id, rc.last4, rc.redeemed_by, rc.redeemed_at,
       CASE
         WHEN rc.cancelled_at IS NOT NULL OR b.cancelled_at IS NOT NULL THEN 'cancelled'
         WHEN rc.redeemed_at IS NOT NULL THEN 'redeemed'
         WHEN b.boxed_at IS NOT NULL     THEN 'in_box'
         WHEN b.exported_at IS NOT NULL  THEN 'sent_to_printer'
         ELSE 'created'
       END AS status
  FROM redeem_codes rc
  JOIN code_batches b ON b.id = rc.batch_id;

-- สถานะใบเสนอราคา (O5: ออกใหม่ → ควรโทรตาม → โทรตามแล้ว → ชำระแล้ว เป็นคำสั่งซื้อ · หมดอายุ)
CREATE VIEW quotation_statuses AS
SELECT q.id, q.doc_number, q.issued_at, q.valid_until,
       CASE
         WHEN q.voided_at IS NOT NULL THEN 'void'
         WHEN EXISTS (SELECT 1 FROM orders o WHERE o.quotation_id = q.id
                         AND o.status NOT IN ('pending_payment', 'awaiting_verification', 'underpaid',
                                              'cancelled', 'expired')) THEN 'converted'
         WHEN q.valid_until <= now() THEN 'expired'
         WHEN EXISTS (SELECT 1 FROM quotation_followups f WHERE f.quotation_id = q.id) THEN 'called'
         WHEN q.issued_at + make_interval(days => coalesce(
                (SELECT (value #>> '{}')::integer FROM system_settings WHERE key = 'quotation_followup_days'), 7))
              <= now() THEN 'followup_due'
         ELSE 'new'
       END AS status
  FROM financial_documents q
 WHERE q.doc_type = 'quotation';

-- โควตาข้อความ LINE ที่ใช้ไปในเดือนนี้ (เวลาไทย)
CREATE VIEW line_quota_usage AS
SELECT date_trunc('month', sent_at AT TIME ZONE 'Asia/Bangkok') AS month_th,
       count(*) AS pushes_sent
  FROM notifications
 WHERE counts_line_quota AND status = 'sent'
 GROUP BY 1;

COMMIT;
