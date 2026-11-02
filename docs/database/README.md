# ฐานข้อมูล SkillwisE Phase 1

- **สถานะ:** [DIRECTION] ร่างออกแบบให้ทีมตรวจ ยังไม่ใช่ migration ที่ใช้จริง
- **ฐานข้อมูล:** PostgreSQL 16 ขึ้นไป (Context ข้อ 60.5, 60.11.3)
- **ที่มา:** ภาคผนวก ก. ของ `docs/system-plan.md` (Context ข้อ 60.13)
  - ออกแบบใหม่ทั้งหมด ไม่ต่อยอดจากร่างเดิมที่อิงระบบ Sila5School (ข้อ 60.13.2)
  - ร่างเดิมยังดูได้ใน git ที่ commit `b38ad71`
- **ขอบเขต:** โครงข้อมูลที่ Phase 1 ต้องมี ได้แก่ บัญชี องค์กร สิทธิ์ เครดิต ซื้อขาย รับเงิน เอกสารการเงิน รหัสในกล่อง อบรม แจ้งเตือน และบันทึก
  - ตาราง Phase 2 ขึ้นไปออกแบบเมื่อถึง Phase นั้น โดยต้องไม่ออกแบบ Phase 1 ให้ขวาง (หัวข้อ 5)
- **ขนาด:** 52 ตาราง (ตามภาคผนวก ก. 46 + ตารางเสริม 6) + 9 view
- **ราคาและตัวเลขใน `seed.sql` เป็นข้อมูลตัวอย่าง (mockup) และเปลี่ยนแปลงได้** ค่าจริงตั้งในหลังบ้าน

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `schema.sql` | สร้างตาราง constraint trigger ฟังก์ชันที่ล็อกแถว และ view ทั้งหมด |
| `seed.sql` | ข้อมูลตัวอย่างที่แต่งขึ้น ไหลครบตั้งแต่ซื้อการ์ด ตรวจสลิป แพ็กส่ง กดรหัส ใช้คูปองจองเวิร์กช็อป จนถึงใบเสนอราคาโรงเรียน |
| `rls.sql` | Row-Level Security: ผู้ใช้เห็นเฉพาะคำสั่งซื้อ ที่อยู่ สิทธิ์ เครดิต และที่นั่งของตัวเอง |
| `checks.sql` | ทดสอบ 35 ข้อว่ากฎสำคัญทำงานจริง (ROLLBACK ตอนจบ ไม่เปลี่ยนข้อมูล) |

## วิธีรัน

ต้องมี Docker

```bash
docker run -d --name skillwise-pg -e POSTGRES_PASSWORD=dev -e POSTGRES_DB=skillwise postgres:16-alpine
cd docs/database
cat schema.sql seed.sql rls.sql checks.sql | docker exec -i skillwise-pg psql -U postgres -d skillwise -v ON_ERROR_STOP=1
```

ผลที่ถูกต้องคือขึ้น `NOTICE: OK 1` ถึง `OK 35` ครบ และไม่มี ERROR

**seed คิดวันที่จากวันที่รัน** (เขตเวลา Asia/Bangkok) ข้อมูลจึงสมเหตุสมผลทุกครั้ง เช่น เครดิตรอบเดือนแรกของ Pro หมดอายุไปแล้ว ส่วนรอบที่สองยังใช้อยู่

**ทดสอบการหักเครดิตพร้อมกัน** (ทดสอบใน session เดียวไม่ได้ จึงแยกจาก `checks.sql`) ให้รันหลังโหลด seed

```bash
U="'a1000000-0000-4000-8000-000000000001'"   # ครูฟ้า มีเครดิตโค้ช 2
docker exec skillwise-pg psql -U postgres -d skillwise -c "BEGIN; SELECT * FROM use_credit($U, NULL, 'coach_session', 2, 'canvas', 'race-A', NULL); SELECT pg_sleep(3); COMMIT;" &
sleep 1
docker exec skillwise-pg psql -U postgres -d skillwise -c "SELECT * FROM use_credit($U, NULL, 'coach_session', 1, 'canvas', 'race-B', NULL);"
```

ผลที่ถูกต้อง: session A หักได้ · session B รอจน A จบแล้วได้ ERROR "เครดิต coach_session ไม่พอ" · ยอดคงเหลือเป็น 0 ไม่ติดลบ

---

## 1. ตาราง

| กลุ่ม | ตาราง |
|---|---|
| **บัญชีและองค์กร** | `users`, `auth_accounts`, `user_roles`, `consents`, `addresses`, `schools_directory`, `organizations`, `org_memberships`, `staff_members` · เสริม: `files`, `policy_documents`, `staff_roles`, `staff_role_permissions`, `staff_member_roles` |
| **สิทธิ์และเครดิต** (หัวใจ 1) | `system_settings`, `entitlement_defs`, `credit_types`, `plans`, `plan_versions`, `plan_version_items`, `grants`, `credit_ledger`, `subscriptions` · เสริม: `plan_version_parts` |
| **ซื้อขายและเงิน** (หัวใจ 2) | `products`, `prices`, `inventory_movements`, `inventory_holds`, `product_waitlist`, `orders`, `order_items`, `order_status_history`, `payments`, `payment_events`, `refunds`, `shipments`, `shipment_codes`, `reconciliation_items` |
| **เอกสารการเงิน** | `document_sequences`, `financial_documents`, `quotation_followups`, `withholding_records` |
| **รหัสในกล่อง** | `code_batches`, `redeem_codes`, `redeem_attempts` |
| **อบรม** | `events`, `seat_pools`, `seat_bookings` |
| **แจ้งเตือนและบันทึก** | `notification_templates`, `notifications`, `audit_logs`, `pii_access_logs` |

**view** (อ่านสถานะที่คำนวณจากข้อมูล ไม่เก็บซ้ำ)

| view | ใช้ทำอะไร |
|---|---|
| `grant_statuses` | สถานะการได้สิทธิ์: รอเริ่ม / ใช้งานอยู่ / ผ่อนผัน / หมดอายุ / ยกเลิก |
| `active_entitlements` | สิทธิ์ที่ใช้ได้ตอนนี้ · `can()` และ `limit()` ของ API อ่านจากตัวนี้ |
| `credit_lots` | ก้อนเครดิตและยอดคงเหลือของแต่ละก้อน |
| `product_stock` | สต็อกที่มี − ที่กันไว้ = ขายได้ |
| `order_payment_totals` | ยอดรับแล้วและยอดคืนของแต่ละคำสั่งซื้อ |
| `order_code_redemptions` | ส่งรหัสไปกี่รหัส กดใช้แล้วกี่รหัส (ตัวชี้วัด "ผู้ซื้อที่เปิดใช้จริง") |
| `redeem_code_statuses` | สร้างแล้ว → ส่งโรงพิมพ์ → อยู่ในกล่อง → เปิดใช้แล้ว · ยกเลิก (O5) |
| `quotation_statuses` | ออกใหม่ → ควรโทรตาม → โทรตามแล้ว → เป็นคำสั่งซื้อ · หมดอายุ (O5) |
| `line_quota_usage` | ข้อความ LINE ที่ระบบส่งเองต่อเดือน (นับโควตา) |

**ฟังก์ชันที่ API ต้องเรียก** (ส่วนที่ต้องล็อกแถว เพราะ Prisma ยังไม่มีคำสั่งล็อกแถวในตัว)

| ฟังก์ชัน | ใช้ทำอะไร |
|---|---|
| `use_credit(user, org, type, amount, ref_type, ref_id, actor)` | หักเครดิต ล็อกทุกก้อนของเจ้าของก่อน หักจากก้อนที่หมดอายุก่อนก่อน ไม่พอ = ไม่หักเลย |
| `credit_balance(user, org, type)` | ยอดเครดิตคงเหลือที่ยังไม่หมดอายุ |
| `hold_stock(product, order, quantity, expires_at)` | กันของให้คำสั่งซื้อ ล็อกแถวสินค้า ชิ้นสุดท้ายได้คนเดียว |
| `unit_price(product, quantity, at)` | ราคาต่อชิ้นตามขั้นจำนวนและช่วงเวลา |
| `next_document_number(doc_type, year)` | เลขที่เอกสารถัดไป ต้องเรียกในธุรกรรมเดียวกับการออกเอกสาร |

---

## 2. ต่างจากภาคผนวก ก. ตรงไหน และเพราะอะไร

| เรื่อง | ภาคผนวก ก. | ร่างนี้ | เหตุผล |
|---|---|---|---|
| ตารางเสริม 6 ตาราง | — | `files`, `policy_documents`, `staff_roles`, `staff_role_permissions`, `staff_member_roles`, `plan_version_parts` | `consents`, `payments` และ `financial_documents` อ้างไฟล์และนโยบาย · บทบาททีมงานต้องปรับสิทธิ์ได้ในหลังบ้าน (ข้อ 60.7) · แพ็กเกจหนึ่งมีหลายส่วนที่เริ่มหรือหมดไม่พร้อมกัน (system-plan 5.5) |
| สถานะของ `grants`, รหัสในกล่อง, ใบเสนอราคา, เอกสาร | เก็บเป็นคอลัมน์ | คำนวณใน view | สถานะเหล่านี้ขึ้นกับวันที่ ถ้าเก็บไว้ต้องมีงานประจำวันคอยเปลี่ยน และข้อมูลอาจขัดกันเอง (งานประจำวันยังต้องมีไว้ส่งข้อความเตือน) |
| ราคา | อยู่ใน `plan_versions` และ `prices` | อยู่ที่ `prices` ที่เดียว | ไม่มีราคา 2 แหล่งที่ขัดกัน · `plan_versions` เก็บแค่สิทธิ์และรอบบิล |
| `orders.ยอดรับแล้ว` | เก็บเป็นคอลัมน์ | view `order_payment_totals` | คำนวณจาก `payments` ที่สำเร็จ ไม่เก็บซ้ำ |
| `inventory_holds` | ใช้กับสินค้าหรือกองที่นั่ง | ใช้กับสินค้าเท่านั้น | ที่นั่งกันด้วย `seat_bookings` สถานะ `pending_payment` + `hold_expires_at` ซึ่งตรวจจำนวนที่นั่งในที่เดียว |
| `updated_at` | ทุกตาราง | เฉพาะตารางที่แก้ได้ | ตารางเพิ่มอย่างเดียวและตารางที่กรอกได้ครั้งเดียวไม่มีการแก้ |
| session การเข้าสู่ระบบ | — | ไม่มีตาราง | เก็บใน Redis ผ่าน session store ของ NestJS · ถ้าทีมเลือก pg-boss แทน Redis ต้องเพิ่มตาราง session |
| `products.plan_id` | — | ของจับต้องได้มีแพ็กเกจได้ | สมุดบันทึกความสุขได้ห้องเรียนเพิ่ม · การ์ดไม่มี เพราะได้สิทธิ์ผ่านรหัสในกล่อง |

**คำที่ความหมายเปลี่ยนจากร่างเดิม:** `seat_pools` เคยหมายถึงที่นั่ง Pro ของโรงเรียน ตอนนี้หมายถึงกองที่นั่งอบรม ส่วนที่นั่ง Pro ของโรงเรียนอยู่ที่ `org_memberships.has_pro_seat` (Phase 3)

---

## 3. กฎที่ฐานข้อมูลบังคับ

| กฎ | วิธีบังคับ |
|---|---|
| รายการเงินและสิทธิ์ห้ามแก้ ห้ามลบ | `forbid_change()` กับ `credit_ledger`, `inventory_movements`, `order_status_history`, `plan_version_items`, `plan_version_parts`, `shipment_codes`, `quotation_followups`, `withholding_records`, `redeem_attempts`, `audit_logs`, `pii_access_logs`, `policy_documents` |
| ช่องที่กรอกภายหลังกรอกได้ครั้งเดียว ห้ามลบแถว | `allow_fill_once()` เช่น วันเริ่มของ Pro ที่รอเริ่ม, วันยกเลิก, วันส่งออกรหัส, ไฟล์ PDF ของเอกสาร · ใช้กับ `grants`, `plan_versions`, `prices`, `order_items`, `payment_events`, `financial_documents`, `code_batches`, `redeem_codes`, `consents` |
| สถานะคำสั่งซื้อเดินตามลูกศรเท่านั้น ยอดเงินแก้ได้เฉพาะก่อนจ่าย | `orders_guard()` · `orders_record_status()` บันทึกประวัติพร้อมผู้ทำและเหตุผลจาก `app.actor_user_id` และ `app.status_reason` |
| ยอดคำสั่งซื้อตรงสูตร | CHECK: ยอดรวม = ก่อนส่วนลด − ส่วนลด + ค่าส่ง · ยอดที่ต้องได้รับ = ยอดรวม − หัก ณ ที่จ่าย · ราคาต่อรายการ × จำนวน − ส่วนลด |
| รายการจ่ายเงินแก้ยอดไม่ได้ สถานะจบแล้วเปลี่ยนไม่ได้ · โอนต้องมีทีมงานยืนยัน | `payments_guard()` + CHECK |
| ข้อความจากระบบรับเงินรับซ้ำได้โดยผลไม่ซ้ำ | UNIQUE `(provider, provider_event_id)` |
| คืนเงินรวมไม่เกินยอดที่จ่าย | `refunds_within_payment()` (ล็อกแถวรายการจ่าย) |
| เครดิตไม่ติดลบ ไม่หักจากก้อนหมดอายุ คืนได้ครั้งเดียว คูปองได้ครั้งเดียวต่อบัญชี | `credit_ledger_check()` + `use_credit()` + UNIQUE `reverses_id` |
| ชิ้นสุดท้ายไม่ขายเกิน | `hold_stock()` |
| ที่นั่งไม่เกินจำนวน | `seat_bookings_capacity()` (ล็อกแถวกองที่นั่ง และเห็นทุกแถวแม้เปิด RLS) |
| เลขที่เอกสารไม่ข้าม ไม่ซ้ำ | `next_document_number()` + UNIQUE `(doc_type, seq_year, seq_number)` |
| รหัสในกล่องกดได้ครั้งเดียว รหัสที่ยกเลิกกดไม่ได้ | `allow_fill_once()` + `redeem_codes_check_usable()` |
| สลิปรับเฉพาะรูปภาพหรือ PDF | CHECK ใน `files` |
| ผู้ใช้เห็นเฉพาะข้อมูลของตัวเอง | `rls.sql` (ชั้นที่สองต่อจาก guard ของ API) |

**กฎที่ API ต้องตรวจเอง** (ฐานข้อมูลไม่ได้บังคับ)
- เลือกส่วนลดที่ดีที่สุดเพียงแบบเดียว
- 1 บัญชีกดรหัสได้ 1 รหัส (กติกา B ยัง [OPEN])
- คำนวณวันเริ่มของ Pro เมื่อกดรหัสหลังเปิดระบบ หรือเมื่อมี Pro อยู่แล้ว
- ยอดรวมของคำสั่งซื้อตรงกับผลรวมของรายการ

---

## 4. เทียบกับชุดทดสอบบังคับในแผนระบบ

ตัวเลขในคอลัมน์ `checks.sql` คือเลขข้อที่ทดสอบในฐานข้อมูล · "API" = ต้องเขียนเทสใน `apps/api` ตอนเขียนโค้ด

**ส่วนสิทธิ์ (system-plan 5.7)**

| # | กรณี | ทดสอบที่ |
|---|---|---|
| 1 | บัญชีใหม่ได้สมาชิกฟรีพร้อมเครดิต 2+2 | `checks.sql` 1 |
| 2 | กดรหัสก่อนวันเปิด Pro → รอเริ่ม · วิดีโอ คู่มือ คูปองใช้ได้ทันที | `checks.sql` 2 |
| 3 | เลื่อนวันเปิด Pro แล้ว Pro ที่รอเริ่มยังถูก · เปิดแล้วได้ 3 เดือนจากวันเปิด | `checks.sql` 3 (รอเริ่มไม่มีวันเริ่ม จึงเลื่อนวันเปิดได้โดยข้อมูลไม่ผิด) |
| 4 | กดรหัสหลังเปิด Pro → 3 เดือนจากวันกด | API |
| 5 | มี Pro รายปีแล้วกดรหัส → ต่อท้าย | API |
| 6 | มี Pro รายเดือนแล้วกดรหัส → ไม่ตัดเงินซ้อน (กติกา A2) | API + ผู้ให้บริการรับเงิน |
| 7 | กดรหัสกล่องที่ 2 ในบัญชีเดียวกัน → ไม่ยอม (กติกา B) | API |
| 8 | Pro รายเดือนไม่มี `seat.free_zoom` | `checks.sql` 14 |
| 9 | ส่วนลดไม่ซ้อน · คูปองใช้ครั้งเดียว · ยกเลิกคำสั่งซื้อแล้วคูปองกลับมา | API (`bestDiscount`) · ฐานข้อมูลรองรับการคืนด้วยรายการ `return` (`checks.sql` 10) |
| 10 | ผู้ซื้อการ์ดที่ชำระแล้วใช้คูปองได้ · กดรหัสภายหลังไม่ได้คูปองซ้ำ | `checks.sql` 11 + ตัวอย่างใน `seed.sql` หัวข้อ 10–11 |
| 11 | ห้องเรียน: ฟรี 1 + โบนัสสมุด 1 = 2 | `checks.sql` 15 |
| 12 | หักพร้อมกัน 2 คำขอ · หัก 2 เมื่อเหลือ 1 | `checks.sql` 7–8 + ทดสอบหักพร้อมกันในหัวข้อ "วิธีรัน" |
| 13 | งาน AI ผิดพลาด → คืนเครดิต | `checks.sql` 10 |
| 14 | เครดิตรายเดือนหมดตามรอบ · ชุดเติมยังอยู่ · ใช้ก้อนที่หมดก่อน | `checks.sql` 6, 9 |
| 15 | ตัดบัตรไม่ผ่าน → ผ่อนผัน 7 วัน → กลับเป็นฟรี | API (`grants.is_grace`) |
| 16 | Pro หมด → ห้องที่ 2 ขึ้นไปอ่านอย่างเดียว | API |
| 17 | ทีมงานย้ายรหัสไปบัญชีอื่น | API (ยกเลิก grants เดิม + สร้าง `transfer` ใหม่ · ฐานข้อมูลบังคับให้มีเหตุผลและผู้ทำ) |

**ส่วนซื้อขาย (system-plan 6.9)**

| # | กรณี | ทดสอบที่ |
|---|---|---|
| 1 | จ่ายพร้อมเพย์สำเร็จ → ใบเสร็จส่ง LINE + อีเมล | API (ตัวอย่างข้อมูลใน `seed.sql` หัวข้อ 11) |
| 2 | ข้อความยืนยันซ้ำ 3 ครั้ง → ใบเสร็จ 1 ใบ สต็อกตัด 1 ครั้ง | `checks.sql` 20 + API |
| 3 | ข้อความปลอม (ลายเซ็นผิด) | API |
| 4 | ยอดไม่ตรง → ไม่เปิดสิทธิ์ | API |
| 5 | QR หมดอายุ → สร้างใหม่ได้ | API (1 คำสั่งซื้อมีหลาย `payments` ได้) |
| 6 | โอนแนบสลิป → ทีมงานยืนยัน | `checks.sql` 22 + ตัวอย่างใน `seed.sql` หัวข้อ 10 |
| 7 | ราคาขั้นจำนวน 4 / 5 ชุด | `checks.sql` 16 |
| 8 | ผู้ซื้อการ์ดสมัคร onZoom 630 / ครั้งที่ 2 900 / onSite ไม่รับคูปอง | API (`seat_pools.accepted_voucher_type`) + `checks.sql` 11 |
| 9 | ยกเลิกก่อนแพ็กได้ · หลังแพ็กไม่ได้ | `checks.sql` 18 |
| 10 | ชิ้นสุดท้าย 2 คนจ่ายพร้อมกัน | `checks.sql` 24 |
| 11 | โอนขาด · หัก ณ ที่จ่ายถือว่าครบ | API · ฐานข้อมูลบังคับสูตรยอดที่ต้องได้รับ |
| 12 | คำสั่งซื้อจากใบเสนอราคาหมดเวลาตามวันยืนราคา | API (`orders.payment_due_at`) |
| 13 | คืนเงินการ์ดที่ส่งแล้ว → ยกเลิกรหัสที่ยังไม่กด | API · ฐานข้อมูลกันคืนเกินยอด (`checks.sql` 23) |
| 14 | เลขที่เอกสารไม่ข้ามไม่ซ้ำ | `checks.sql` 26 |
| 15 | Pro รายเดือนต่ออายุ / ตัดไม่ผ่าน / ยกเลิก | API |
| 16 | ใบเสนอราคาถึงวันเตือน · เลยวันยืนราคา | `checks.sql` 28 |

---

## 5. สิ่งที่ต้องเผื่อไว้ให้ Phase 2 (system-plan ส่วนที่ 9)

ตารางของ Phase 2 จะออกแบบใหม่จากภาพปลายทางตอนเริ่ม Phase 2 ไม่ต่อยอดจากร่างเดิม

- **ข้อมูลเด็ก**
  - เป็นของห้องเรียนหรือโรงเรียน ไม่ใช่ของครู · ใช้ชื่อเล่นหรือชื่อที่ครูตั้งเอง ไม่ต้องมีนามสกุล
  - เห็นได้เฉพาะครูที่ดูแลห้อง ซึ่งต้องเพิ่ม policy ใน `rls.sql` · ทีมงานไม่เห็นเรื่องเล่าและไทม์ไลน์ (Context ข้อ 60.13.4)
- **งานส่วนตัวของครู** (Canvas, เกียรติบัตร, ประวัติคอร์ส) ผูกกับ `users` ไม่ผูกกับโรงเรียน จึงติดตัวครูเมื่อย้ายโรงเรียน
- **การกล่าวถึงเด็ก** ในเรื่องเล่าผ่าน LINE ต้องเก็บชื่อที่ยังจับคู่ไม่ได้ไว้ก่อน แล้วจับคู่ภายหลัง
- **ส่งข้อมูลให้ AI:** ระบบจับชื่อจากรายชื่อในห้องเอง แล้วแทนด้วยรหัสก่อนส่งให้ AI (ข้อ 60.2, 60.13.4)
- **งาน AI ทุกครั้งบันทึก:** ผู้ใช้ รุ่นโมเดล จำนวนโทเคน ต้นทุน และรายการหักเครดิต (`credit_ledger.usage_ref_type` / `usage_ref_id` รองรับแล้ว)
- **เวลาบันทึกมาจากระบบ** เก็บประวัติการแก้ และนำแนวคิดบันทึกย้อนหลัง (ข้อ 60.12) ไปใช้กับเรื่องเล่า
- **ที่รองรับไว้แล้วใน Phase 1**
  - สิทธิ์และเครดิตของโรงเรียนใช้ `holder_org_id`
  - ที่นั่ง Pro ของโรงเรียนใช้ `org_memberships.has_pro_seat`
  - เงื่อนไขก่อนเข้าอบรมใช้ `seat_pools.prerequisite_*`
  - Pro รายเดือนใช้ `subscriptions`

---

## 6. ตารางที่เอาออกจากร่างเดิม (commit `b38ad71`)

ร่างเดิมมี 72 ตาราง ออกแบบตามวงจรของ Sila5School: Canvas → แผนพัฒนา → แผนลงมือทำรายสัปดาห์ → บันทึก → feedback จากโค้ชที่เป็นคน

ร่างใหม่เอาตารางกลุ่มต่อไปนี้ออก เพราะไม่อยู่ในแผน หรือต้องออกแบบใหม่ตามภาพปลายทาง (Context ข้อ 60.13.4)

| กลุ่มเดิม | เหตุผล |
|---|---|
| Tool / Case / Canvas, AI, Development Plan, Practice, Evidence, Reflection / Coaching, Timeline (38 ตาราง) | ไม่มีโค้ชที่เป็นคน ไม่มีแผนรายสัปดาห์ · Canvas, โค้ช AI และเรื่องเล่าจะออกแบบใหม่ใน Phase 2 · แผนโรงเรียนอยู่ใน Phase 3 |
| Student (`students`, `student_enrollments`, `import_jobs`) | ร่างเดิมบังคับเก็บชื่อจริงและนามสกุล แต่กติกาใหม่ใช้ชื่อเล่นและไม่ต้องมีนามสกุล · ออกแบบใหม่ใน Phase 2 |
| `org_units`, `membership_org_units`, `invitations`, `seat_assignments` | โครงสร้างย่อยในโรงเรียนและทีมครูเป็นงาน Phase 3 · คำเชิญใช้ `org_memberships.status = 'invited'` |
| `permissions`, `roles`, `role_permissions`, `role_assignments` | แทนด้วยบทบาทผู้ใช้ (`user_roles`) และบทบาททีมงาน (`staff_*`) ที่เรียบง่ายกว่า |
| `features`, `product_features`, `entitlements`, `usage_ledger`, `billing_profiles` | เปลี่ยนเป็นคำและโครงตามแผนระบบ: `entitlement_defs`, `plans` / `plan_versions` / `plan_version_items`, `grants`, `credit_ledger` และข้อมูลออกเอกสารใน `organizations` + สำเนาในคำสั่งซื้อ |
| `memberships`, `notification_jobs`, `notification_events`, `contents`, `auth_sessions`, `user_identities`, `user_consents` | เปลี่ยนเป็น `org_memberships`, `notifications`, `auth_accounts` และ `consents` · เนื้อหาหน้าเว็บยังไม่ต้องมีตาราง · session อยู่ใน Redis |

---

## 7. เรื่องที่ยัง [OPEN] และกระทบฐานข้อมูล

- **กติกา B:** 1 บัญชีกดรหัสในกล่องได้ 1 รหัส · ตอนนี้ให้ API ตรวจ ถ้ายืนยันแล้วเพิ่ม unique index ได้
- **อายุของคูปองผู้ซื้อการ์ด** (`system_settings.voucher_valid_months` เป็นค่าตัวอย่าง)
- **Pro จากรหัสในกล่องได้ `seat.free_zoom` ไหม** · seed ตั้งว่าไม่ได้ตามแผนระบบ
- **บริษัทจด VAT แล้วหรือยัง** · ถ้ายัง `vat_satang` เป็น 0 และออกใบกำกับภาษีไม่ได้
- **อัตราหัก ณ ที่จ่าย** ให้ผู้ทำบัญชียืนยัน
- **ผู้ให้บริการรับเงิน** · `provider` รองรับ `stripe` และ `opn` ไว้ก่อน
- **ราคาการ์ดชุดโรงเรียน ค่าส่ง และราคาแพ็กเกจโรงเรียน** · seed ใช้ค่าสมมติ
- **Set Package** (ข้อ 60.8): ขนาด ราคา และใครซื้อได้ · โครง `plans` แบบ `org` รองรับแล้ว

---

## 8. ตอนแปลงเป็น Prisma

- **ตาราง** แปลงเป็น `schema.prisma` ได้ตรง ๆ
- **trigger ฟังก์ชัน และ view ทั้งหมด** (อยู่กระจายทุกหมวดของ `schema.sql` ข้างตารางที่เกี่ยวข้อง) ใส่เป็น migration แบบ SQL ตรง เพราะ Prisma สร้างให้ไม่ได้
- **ฟังก์ชันที่ล็อกแถว** (`use_credit`, `hold_stock`, `next_document_number`) เรียกผ่าน `$queryRaw` ภายใน `$transaction`
- **RLS:** API ต้องเชื่อมฐานด้วย role ที่ไม่ใช่เจ้าของตาราง และตั้ง `app.user_id`, `app.is_staff`, `app.actor_user_id` ด้วย `set_config(..., true)` ที่ต้นทุกธุรกรรม
