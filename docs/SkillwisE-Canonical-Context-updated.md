# SE – SkillwisE
## Canonical Product & System Context for Claude Code

- **Context version:** 2 Nov 2026 (เพิ่มภาพปลายทาง UI กับแผนระบบฉบับสร้างจริงในข้อ 60.13 ซึ่งแทนหลายข้อเดิม · ก่อนหน้านี้: ผลประชุมครั้งที่ 1 ในข้อ 60.10, โค้ดอ้างอิงกับขอบเขตฐานข้อมูล MVP ในข้อ 60.11 และแนวคิดบันทึกย้อนหลังในข้อ 60.12)
- **Project:** SkillwisE Social Enterprise
- **Repository:** ทีมทำงานหลายเครื่อง จึงไม่ระบุ path ให้ใช้ repository ที่เปิดอยู่ในเครื่องนั้น

---

## 0. วิธีใช้ Context นี้

เอกสารนี้เป็น Canonical Context หลักของโปรเจกต์ SkillwisE

Claude Code ต้องใช้ลำดับความน่าเชื่อถือดังนี้:

1. **[CANONICAL]** ข้อตกลงเดิมที่ทีมเคยคุยและพัฒนาไว้ = ใช้เป็น Baseline
2. **[CONFIRMED]** เรื่องที่ทีมยืนยันภายหลัง = ใช้เพิ่มเติมหรือ Override ของเดิมได้
3. **[DIRECTION]** แนวทางที่กำลังพัฒนา = ใช้ออกแบบได้ แต่ต้องไม่ Hard-code Decision ที่ยังไม่ Final
4. **[OPEN]** ยังไม่ตัดสินใจ = ห้ามเดาเป็นข้อสรุป
5. **[REFERENCE]** กรณีศึกษา / Inspiration / ข้อเสนอจาก AI = ใช้ประกอบความคิดเท่านั้น

หาก Requirement ใหม่ขัดกับ Canonical Context นี้:
อย่าแก้ของเดิมเงียบ ๆ
ให้ชี้ Conflict ให้ทีมเห็นก่อน เช่น

> "Requirement ใหม่นี้ทำให้ผู้บริหารสามารถเห็น Coach Feedback รายบุคคล ซึ่งขัดกับ Privacy Principle เดิม ต้องการ Override หลักการเดิมหรือไม่?"

---

## 1. SkillwisE คืออะไร

**[CANONICAL]**

SkillwisE เป็น Social Enterprise ที่พัฒนาระบบและบริการเพื่อยกระดับความสามารถของครูในการเป็น Facilitator (FA)

เป้าหมายคือให้ครูสามารถนำทักษะ FA ไปใช้กับสถานการณ์จริง เพื่อช่วยพัฒนาศักยภาพของนักเรียน

SkillwisE ไม่ใช่เพียง:

- LMS
- Online Course
- ระบบส่งงาน
- AI Canvas
- ระบบบริหารโรงเรียน
- Course Marketplace

สิ่งเหล่านี้อาจเป็นองค์ประกอบของ Product แต่ไม่ใช่แก่นของ SkillwisE

### Core Definition

SkillwisE คือระบบพัฒนาครูให้เป็น Facilitator ที่สามารถอ่านสถานการณ์ ออกแบบกระบวนการ ลงมือทำ สังเกต สะท้อนผล และปรับการพัฒนาจากสถานการณ์จริง เพื่อช่วยปลดล็อกศักยภาพของผู้เรียนอย่างต่อเนื่อง

English:

> SkillwisE is a professional teacher-development platform that helps educators build facilitation capability and unlock student potential through real practice, structured design, reflection, coaching, and AI-assisted tools.

---

### 1.1 Brand-level Definition

**[CANONICAL — 24 Oct 2026]**

ในระดับ **Brand / Company** SkillwisE มีขอบเขตกว้างกว่า Product สำหรับโรงเรียน

SkillwisE คือ **ระบบนิเวศสำหรับการพัฒนามนุษย์ (Human Growth Ecosystem)** ผ่าน 3 องค์ประกอบหลัก:

- **Courses**
- **Tools**
- **Platform**

โดยมุ่งพัฒนา 3 แกนหลัก:

1. **พัฒนานิสัย (Habit Development)**
2. **ปลดล็อกศักยภาพ (Unlock Potential)**
3. **ยกระดับจิตใจ (Inner Growth / Elevating the Mind)**

เป้าหมายปลายทางคือ:

> **พัฒนาผู้คนให้เติบโต และร่วมสร้างสังคมที่ดีกว่าเดิม**

Tagline ที่ยืนยันแล้ว:

> **Growing People, Brighter Society.**

### 1.2 Brand vs Education Product

**[CANONICAL]**

ต้องแยก 2 ระดับให้ชัดเจน:

#### SkillwisE Brand / Company

ครอบคลุม Human Growth Ecosystem ในภาพใหญ่:

**Courses + Tools + Platform**

เพื่อ:

**Habit Development + Unlock Potential + Inner Growth**

#### SkillwisE Education / School Product

เป็น Product สำคัญภายใต้ Brand ที่มุ่ง:

> **พัฒนาครูให้เป็น Facilitator ที่สามารถพัฒนานิสัยและปลดล็อกศักยภาพของผู้เรียนจากสถานการณ์จริง**

ดังนั้น Definition เรื่อง **FA Development** ใน Context นี้ยังคงเป็น Core ของ Education Product

แต่ไม่ควรตีความว่า SkillwisE ทั้งบริษัทจะจำกัดตัวเองอยู่เฉพาะ Teacher Development ตลอดไป

---

## 2. Product North Star

**[CANONICAL]**

ทุก Feature ต้องช่วยสนับสนุนวงจรนี้:

```
Teacher sees a real situation
↓
Understand the learner / group
↓
Identify potential
↓
Design development
↓
Facilitate / Practice
↓
Observe what happens
↓
Reflect
↓
Receive coaching / feedback
↓
Adjust
↓
Practice again
↓
Teacher FA capability improves
↓
Student grows
```

Platform, AI, Canvas, Course และ Dashboard เป็นเครื่องมือสนับสนุนวงจรนี้
ไม่ใช่ตัวแทนของวงจรนี้

---

## 3. FA Development คือแกนหลัก

**[CANONICAL]**

เป้าหมายของ SkillwisE ไม่ใช่แค่ให้ครู "รู้วิธีจัดกิจกรรม"
แต่ต้องพัฒนาครูไปสู่ระดับที่สามารถ:

- อ่านคน
- อ่านกลุ่ม
- อ่านสถานการณ์
- สังเกตสิ่งที่เกิดขึ้นจริง
- ตั้งคำถาม
- Deep Listening
- สร้าง Psychological Safety
- ออกแบบ Learning Process
- อ่าน Group Dynamics
- ปรับ Intervention หน้างาน
- Reflection
- Meaning Making
- ให้ Feedback
- เชื่อมการเรียนรู้กลับสู่ชีวิตจริง
- ปรับกระบวนการหลังเห็นผลลัพธ์

แนวคิดสำคัญ:

> **FA = อ่านการเรียนรู้ตรงหน้า แล้วพาไปต่อ**
> ไม่ใช่เพียงทำ Activity ตาม Script

---

### 3.1 SkillwisE FA Differentiation

**[CANONICAL — 24 Oct 2026]**

SkillwisE ไม่ได้มุ่งพัฒนา **Facilitator ทั่วไป** เท่านั้น

จุดแตกต่างของ **SkillwisE FA** คือการใช้ทักษะ Facilitation เพื่อ:

- **พัฒนานิสัย (Habit Development)**
- **ปลดล็อกศักยภาพของผู้เรียน (Unlock Human Potential)**
- ช่วยให้ผู้เรียนเกิดการตระหนักรู้และเติบโตจากประสบการณ์จริง
- เชื่อมสิ่งที่เกิดขึ้นในห้องเรียนกับการเปลี่ยนแปลงในชีวิตจริง

ดังนั้น SkillwisE FA ควรถูกมองเป็น:

> **Facilitator for Human Growth**

ไม่ใช่เพียงผู้ดำเนินกิจกรรมหรือผู้จัด Workshop

Canvas, 7 กิจวัตร, Reflection, Coaching, NVC และเครื่องมืออื่น เป็นกลไกที่ช่วยให้ SkillwisE FA ทำหน้าที่นี้ได้อย่างเป็นระบบ

---

## 4. Practice-Based Development

**[CANONICAL]**

การพัฒนา FA ไม่ควรเป็น

```
เรียน Content → ทำ Quiz → ได้ Certificate → จบ
```

แต่ควรเป็น:

```
Learn
↓
Practice
↓
Real Case
↓
Reflection
↓
Coach Feedback
↓
Adjust
↓
Practice Again
```

นี่คือ Learning Architecture หลักของ SkillwisE

---

## 5. Do → Reflect → Share → Grow

**[CANONICAL]**

ทีมเคยใช้วงจร:

- **Do** — ลงมือทำจริง
- **Reflect** — กลับมามองสิ่งที่เกิดขึ้น
- **Share** — แลกเปลี่ยนกับ Coach / Peer / Community
- **Grow** — นำสิ่งที่เรียนรู้กลับไปปรับและทดลองใหม่

SkillwisE ควรรักษา Loop นี้ไว้ใน Product

---

## 6. Unlock Hidden Potential

**[CANONICAL]**

หนึ่งใน Framework สำคัญที่ทีมพัฒนามาก่อน SkillwisE คือ **Unlock Hidden Potential**

เปลี่ยนวิธีคิดจาก:

> "เด็กมีปัญหาอะไร?"

เป็น:

> "มีศักยภาพอะไรที่ยังไม่ได้รับการพัฒนา และหากพัฒนาแล้ว เด็กจะตอบสนองต่อสถานการณ์เดิมได้ดีขึ้นอย่างไร?"

Potential ไม่ได้หมายถึงเฉพาะคุณธรรม สามารถเป็น:

- Self-management
- Emotional regulation
- Communication
- Leadership
- Teamwork
- Critical thinking
- Creativity
- Social ability
- Language
- Academic ability
- Sport
- Art
- Digital ability
- ความสามารถเฉพาะด้าน
- Character
- Life Skills

---

## 7. Unlock Hidden Potential Canvas

**[CANONICAL]**

Canvas ไม่ใช่แค่ Form แต่เป็น Thinking Framework ของครู

โครงสร้างที่พัฒนามาก่อนมีประมาณ:

1. ศักยภาพที่ต้องการปลดล็อก
2. ทำไมจึงเลือกศักยภาพนี้
3. ภาพปลายทาง
4. Routine / Practice
5. Scaffolding
6. Opportunity
7. Signals of Success

ชื่อ Field สามารถปรับตาม UX ได้
แต่ Logic หลักไม่ควรถูกทำลาย

---

## 8. Character Skills + Scaffolding + Systems of Opportunity

**[CANONICAL]**

การปลดล็อกศักยภาพไม่ได้เกิดจากกิจกรรมครั้งเดียว ทีมใช้ Framework 3 ส่วน:

### 8.1 Character Skills

สร้างฐานภายใน เช่น

- Self-management
- วินัย
- ความรับผิดชอบ
- ความพยายาม
- การอยู่ร่วมกับผู้อื่น
- Character

### 8.2 Scaffolding

สิ่งที่ช่วยให้ผู้เรียนพัฒนา เช่น

- Teacher
- FA
- Coach
- Question
- Feedback
- NVC
- Tool
- Activity
- Peer
- Environment
- Support System

### 8.3 Systems of Opportunity

ต้องสร้างโอกาสให้เด็กนำสิ่งที่พัฒนาไปใช้จริง เช่น

- ทำงานกลุ่ม
- เป็นผู้นำ
- นำเสนอ
- รับผิดชอบงาน
- แก้ปัญหา
- ทำ Project
- แสดงความสามารถ
- ช่วยผู้อื่น
- สร้างผลงาน

หลักสำคัญ:

> **พัฒนาศักยภาพแล้วต้องมีเวทีให้ใช้**

---

## 9. 7 กิจวัตรความดี

**[CANONICAL]**

7 กิจวัตรเป็น Existing Practice Asset จาก Sila5School

แต่ใน SkillwisE: **7 กิจวัตรไม่ใช่ Main Product**

ความสัมพันธ์ที่ถูกต้องคือ:

```
FA = Core Capability
↓
Unlock Hidden Potential = Development Framework
↓
7 กิจวัตร = Character / Practice System หนึ่งชุด
```

SkillwisE ไม่จำเป็นต้องใช้คำว่า

- ศีล 5
- คุณธรรม
- ความดี

เป็น Main Marketing Message
แต่สามารถใช้องค์ความรู้เดิมภายในระบบได้

---

## 10. ความสัมพันธ์กับ Sila5School

**[CANONICAL]**

SkillwisE ไม่ได้เริ่มจากศูนย์
สามารถนำ IP, Framework และ Learning System จาก `school.sila5.com` มาพัฒนาใหม่

โดยเฉพาะ:

- Unlock Hidden Potential Canvas
- Canvas Pool
- Activity Planning
- Development Plan
- Evidence
- Reflection
- Teacher Development
- Team Collaboration
- AI Assistant
- Progress Tracking

แต่:

> **SkillwisE ไม่ควรเป็น Clone ของ Sila5School**
> ต้อง Re-design เพื่อเป็น Professional / Commercial Platform

---

### 10.1 Dual-brand Strategy: Sila5School × SkillwisE

**[CANONICAL — 24 Oct 2026]**

Sila5School และ SkillwisE ต้องสามารถ **ขับเคลื่อนคู่ขนานกันโดยไม่สับสนหรือซ้อนทับกัน**

#### Sila5School

Main Entry / ตัวชูโรงคือ:

> **7 กิจวัตรความดี**

โดยใช้ **FA** เป็นกลไกสำคัญในการ Delivery และช่วยให้ครูนำ 7 กิจวัตรไปใช้จนเกิดการพัฒนานิสัยจริง

#### SkillwisE

Main Entry / Core Capability คือ:

> **FA for Human Growth**

โดยมี:

- Unlock Hidden Potential
- Canvas
- Habit Development
- 7 กิจวัตร
- Reflection
- Coaching
- AI-assisted tools

เป็น Framework / Practice / Tool ที่อยู่ภายใต้ Ecosystem

ดังนั้นความสัมพันธ์โดยหลักคือ:

**Sila5School**
→ ชู 7 กิจวัตร
→ ใช้ FA เป็นกลไก Delivery

**SkillwisE**
→ ชู FA for Human Growth
→ ใช้ Canvas / Unlock Hidden Potential เป็น Core Tool & Framework
→ 7 กิจวัตรสามารถเป็น Practice Set / Subset หนึ่งใน Ecosystem

### 10.2 Brand Boundary Principle

**[CANONICAL]**

ต้องหลีกเลี่ยงการสื่อสารที่ทำให้ตลาดเข้าใจว่า:

- SkillwisE คือชื่อใหม่ของ Sila5School
- Sila5School เป็นเพียง Package หนึ่งของ SkillwisE
- SkillwisE มีเฉพาะเรื่องศีล 5 หรือคุณธรรม
- SkillwisE กับ Sila5School แข่งขันกันเอง

แนวทางคือให้ทั้งสองแบรนด์ **ใช้ IP และองค์ความรู้ร่วมกันได้** แต่มี Entry Message และ Positioning ต่างกัน

---

## 11. Positioning

**[CANONICAL / DIRECTION]**

ในระดับ Brand ให้ยึดแนวคิด:

> **Growing People, Brighter Society.**

และภาพรวม:

> **Human Growth Ecosystem — Courses + Tools + Platform**

สำหรับ Education / School Product ให้สื่อสารด้วยภาษา Professional เช่น:

- Human Potential
- Life Skills
- Leadership
- Facilitation
- Teacher Capability
- Student Potential
- Classroom Transformation
- Future Skills
- Professional Development

มากกว่าการใช้ ศีล 5 / คุณธรรม เป็น Entry Message

---

## 12. AI Role

**[CANONICAL]**

AI เป็น **Thinking Assistant / Design Assistant** ไม่ใช่ Decision Maker

AI อาจช่วย:

- วิเคราะห์ Situation
- ช่วยตั้งคำถาม
- ช่วยค้นหา Potential
- เชื่อมข้อมูล
- ตรวจ Logic ของ Canvas
- แนะนำ Routine
- แนะนำ Scaffolding
- ช่วยคิด Opportunity
- ช่วยคิด Signal
- สังเคราะห์ Canvas
- เปลี่ยน Canvas เป็น Plan
- ช่วย Reflection
- สรุปข้อมูลให้ Coach
- ช่วยวิเคราะห์ Pattern

แต่:

> **Final Decision เป็นของครู**

---

## 13. Canvas Pool

**[CANONICAL]**

Canvas สามารถมีหลาย Scope เช่น:

- Individual student
- Student group
- Classroom
- Other scope ในอนาคต

หลาย Canvas สามารถนำมาสังเคราะห์เพื่อดู Pattern และสร้าง Development Plan

ตัวอย่าง:

```
Situation
↓
Canvas
↓
Canvas Pool
↓
Pattern Analysis
↓
Prioritize Potential
↓
Development Plan
```

ในระบบเดิมมีแนวคิดให้สังเคราะห์ Canvas หลายใบ เช่นประมาณ 5 ใบ

แต่: **อย่า Hard-code ตัวเลขนี้จนกว่าจะ Final**

---

## 14. Canvas → Action

**[CANONICAL]**

*(แก้โดยข้อ 60.13.4: วงจรนี้ไม่ใช่แบบของระบบแล้ว · Canvas ใน Phase 2 ต่อไปที่เรื่องเล่าผ่าน LINE และไทม์ไลน์เด็ก · แผนของโรงเรียนอยู่ Phase 3 · ไม่มีแผนลงมือทำรายสัปดาห์และไม่มี feedback จากโค้ชที่เป็นคน)*

Canvas ต้องไม่จบที่การวิเคราะห์ Core Flow ควรไปถึง:

```
Canvas
↓
Development Plan
↓
Activity / Intervention
↓
Implementation
↓
Evidence
↓
Reflection
↓
Feedback
↓
Revision
↓
Next Cycle
```

---

## 15. Evidence / Submission

**[DIRECTION]**

การส่งผลงานครูไม่ควรออกแบบเป็น:

```
Upload → Score
```

ควรเป็นส่วนหนึ่งของ Development Cycle:

```
Case
↓
Design
↓
Practice
↓
Evidence
↓
Reflection
↓
Coach Feedback
```

Evidence อาจรองรับ:

- Text
- Image
- File
- Video
- Link
- Observation
- Reflection

Exact Types: **[OPEN]**

---

## 16. Coaching

**[CANONICAL]**

*(แก้โดยข้อ 60.13.4: แผน Phase 1–5 ไม่มีโค้ชที่เป็นคน · "โค้ช" ในภาพปลายทางคือโค้ช AI ที่ช่วยครูคิด Canvas ใน Phase 2)*

Coaching เป็นส่วนสำคัญของ Skill Development
Coach ไม่ได้มีหน้าที่เพียงตรวจคะแนน สามารถใช้:

- Question
- Comment
- Reflection Prompt
- Recommendation
- Skill Feedback
- Rubric
- Next Practice

เป้าหมายคือ **Development ไม่ใช่ Evaluation อย่างเดียว**

---

## 17. Super FA เป็นฐานสำคัญ

**[CANONICAL]**

องค์ความรู้จาก Super FA ควรถูกนำมาใช้ในการออกแบบ SkillwisE

แก่นคือ:

> **ไม่ใช่คอร์สเพิ่ม แต่เป็น Professional FA Support**

ครูต้องนำ Case จริงกลับมา:

```
สะท้อน → ฝึก → ทดลอง → กลับมาเรียนรู้ใหม่
```

---

## 18. FA Competency

**[CANONICAL]**

ทีมมี Competency เดิม 9 ด้านจาก Super FA:

1. FA Presence & Safety
2. Questioning for Awareness
3. Deep Listening / NVC
4. Group Dynamics & Energy
5. Reflection & Meaning-Making
6. Activity Design & Flow
7. Habit Development Facilitation
8. Canvas to Plan & VA/PA Docs
9. Subject Integration

มีแนวคิด Rubric 5 ระดับ

ดังนั้น: **อย่าออกแบบ FA Skill Model ใหม่จากศูนย์โดยไม่ดู Framework เดิมนี้**
การนำมาใช้กับ SkillwisE แบบ Commercial ยังสามารถปรับได้

---

## 19. Skill Progression

**[DIRECTION]**

SkillwisE ควรรองรับการเก็บ Skill Progress ในอนาคต เช่น:

- Baseline
- Practice
- Coach Assessment
- Self Assessment
- Evidence
- Progress over time

แต่ต้องระวังไม่ให้ระบบกลายเป็น Teacher Performance Appraisal

> **Skill Development ≠ HR Performance Evaluation**

---

## 20. Portfolio

**[DIRECTION]**

ครูควรสามารถสะสม Professional Development Portfolio เช่น:

- Canvas
- Case
- Plan
- Activity
- Evidence
- Reflection
- Coach Feedback
- Course
- Skill Progress

ข้อมูลเหล่านี้อาจต่อยอดไปสู่:

- Professional Portfolio
- Development Record
- Certificate
- VA / PA Documentation

---

## 21. Business Model

**[CONFIRMED DIRECTION]**

รายได้ SkillwisE มีอย่างน้อย 2 กลุ่ม:

### 21.1 Subscription Platform

เป้าหมายคือสร้าง Recurring Revenue

Subscription ให้ครูเข้าถึง:

- Professional Tools
- Canvas
- AI
- Development Workflow
- Reflection
- Portfolio
- Skill Development
- บริการอื่นตาม Package

### 21.2 Training / Professional Services

เช่น:

- FA Training
- Unlock Hidden Potential
- NVC
- Goal Setting
- Design
- On-site workshop
- In-house
- Public course
- Coaching

Training ต้องเชื่อมกับ Development Journey
ไม่ควรกลายเป็นธุรกิจ Course แยกจาก Platform

---

## 22. Business Model Inspiration: Leader in Me

**[REFERENCE — NOT REQUIREMENT]**

ทีมเคยศึกษาธุรกิจ Leader in Me / 7 Habits เพื่อใช้เป็น Business Model Reference

สิ่งที่น่าสนใจคือ: อย่าขายเฉพาะ Training ครั้งเดียว แต่สร้าง Relationship ต่อเนื่องกับโรงเรียน

แนวคิด Funnel ที่เคยศึกษา:

```
Entry Workshop
↓
Implementation Program
↓
Annual Partnership
↓
Advanced Support
```

อย่างไรก็ตาม: **อย่า Copy Leader in Me ตรง ๆ**
ใช้เพียงเป็น Reference เพื่อเข้าใจ Recurring Business Model

---

## 23. Recurring Value Principle

**[DIRECTION]**

Subscription / Annual Partnership ต้องมีเหตุผลให้ลูกค้ากลับมาใช้ต่อเนื่อง

ไม่ควรเป็นเพียง Content Library ที่เปิดดูได้ตลอดปี

Recurring Value ควรมาจากสิ่งเช่น:

- Tools ใช้งานจริง
- AI
- Canvas
- Reflection
- Teacher Portfolio
- Skill Tracking
- Coach Clinic
- New Practice
- Continuous Development
- School Insight
- Implementation Support

หลักสำคัญ:

> **Recurring Revenue ต้องมี Recurring Value**

---

## 24. Coaching Economics

**[DIRECTION]**

*(แก้โดยข้อ 60.13.4: แผน Phase 1–5 ไม่มีโค้ชที่เป็นคน · ต้นทุนที่ต้องคุมตอนนี้คือรอบโค้ช AI ซึ่งคุมด้วยเครดิตตามข้อ 60.13.5)*

Human Coaching มีต้นทุน ดังนั้นไม่ควรออกแบบ Package แบบ Unlimited Coaching โดยไม่คิด Unit Economics

ระบบควรรองรับ Package ที่กำหนดขอบเขตได้ เช่น:

- จำนวน Coaching Session
- จำนวน Review
- จำนวน Case
- Coach Response SLA
- Teacher / Coach Ratio
- Monthly Clinic
- Group Coaching
- Premium 1:1

Exact Model: **[OPEN]**

แต่ **Architecture ไม่ควร Assume ว่า Coaching Unlimited**

---

## 25. Social Enterprise Model

**[CANONICAL]**

SkillwisE เป็น Social Enterprise

แต่: **Social Impact Mechanism ไม่จำเป็นต้อง Hard-code ลง Product**
ทีมมีแนวทาง SE ของตนเองอยู่แล้ว

จึงไม่ต้อง Assume ว่าระบบต้องมี:

- Free seat
- Subsidized seat
- Donation
- CSR dashboard
- Sponsor module

เว้นแต่ทีมจะสั่งเพิ่ม

---

## 26. Impact Data

**[DIRECTION]**

แม้ไม่สร้าง Social Impact Feature โดยเฉพาะ ข้อมูลที่เกิดจากการใช้งานจริงสามารถนำไปวิเคราะห์ Impact ในอนาคต เช่น:

- จำนวนครู
- จำนวนโรงเรียน
- จำนวน Case
- Teacher Skill Development
- Student reach
- Activities
- Development Outcomes

ดังนั้น **Data Architecture ไม่ควรปิดทางการทำ Impact Report ในอนาคต**

---

## 27. Free Layer

**[DIRECTION]**

SkillwisE สามารถมี Public / Free Content เช่น:

- Facilitation
- Life Skills
- Human Potential
- Leadership
- Teacher Development
- 7 กิจวัตรกับการพัฒนาเยาวชน

หน้าที่ของ Free Layer คือ:

```
Educate
↓
Build Trust
↓
Demonstrate Value
↓
Convert
```

**ไม่เท่ากับ Free Subscription**

---

## 28. Target Market

**[DIRECTION]**

ตลาดเริ่มต้นที่ทีมกำลังมอง: **โรงเรียนเอกชนที่มีงบประมาณสำหรับ Teacher Development**

เหตุผลเชิงสมมติฐาน:

- มี Budget
- ตัดสินใจค่อนข้างเร็ว
- สนใจ Differentiation
- สนใจ Life Skills
- Leadership
- Future Skills
- Teacher Capability

แต่การกำหนด Segment รายละเอียดยังสามารถปรับได้

---

## 29. Buyer / User / Beneficiary

**[CANONICAL PRODUCT PRINCIPLE]**

ต้องแยก:

- **Buyer** อาจเป็น: School Owner, Director, Academic Director, Organization
- **User** หลักคือ: Teacher, Facilitator, Coach
- **Beneficiary** หลักคือ: Student

> **Buyer ≠ User ≠ Beneficiary**

การออกแบบ UX / Dashboard / Marketing ต้องคำนึงถึงทั้งสามกลุ่ม

---

## 30. User Roles

**[CONFIRMED DIRECTION]**

### SkillwisE Admin

บริหาร Platform เช่น:

- School
- User
- Coach
- Subscription
- Course
- Payment
- Configuration

Exact Permission: **[OPEN]**

### SkillwisE Coach

*(แก้โดยข้อ 60.13.4: บทบาทนี้ไม่อยู่ในแผน Phase 1–5)*

Account แยกจาก Admin ใช้สำหรับ:

- ดู Case
- Coach
- Feedback
- Review
- Skill Assessment

### School Executive / School Manager

ควรเห็นข้อมูลระดับ Aggregate เช่น:

- Participation
- Active Teacher
- Submission
- Progress
- Aggregate Skill Development

### Teacher

Primary User ใช้:

- Tool
- Canvas
- Plan
- Practice
- Evidence
- Reflection
- Feedback
- Course
- Portfolio

### Student

ยังไม่ใช่ Core User ใน Phase 1
Student System: **Phase 2**

---

## 31. Privacy & Psychological Safety

**[CANONICAL]**

Coach Feedback และ Teacher Reflection อาจเป็นพื้นที่ Sensitive

หลักการ:

> **ผู้บริหารโรงเรียนไม่ควรเห็น Private Coach Feedback ของครูโดย Default**

เหตุผล: ถ้าครูรู้ว่าผู้บริหารอ่าน Feedback ทุกอย่างได้ ครูอาจไม่กล้านำ Case ที่ยังทำได้ไม่ดีมาขอ Coaching ซึ่งสวนทางกับเป้าหมายการพัฒนา

ดังนั้นต้องแยก:

> **Development Data** กับ **Management Data**

---

## 32. Position ≠ Permission

**[DIRECTION]**

บุคลากรในโรงเรียนอาจมีตำแหน่ง:

- Teacher
- Head Teacher
- Academic Head
- Vice Director
- Director
- Owner
- Coordinator
- Staff

แต่: **Job Position ไม่ควร Hard-code System Permission**

Permission อาจเป็น:

- Manage members
- Manage seats
- Manage classroom
- View aggregate dashboard
- Register course
- Billing

---

## 33. Organization Model

**[DIRECTION]**

ควรแยก **User Identity** ออกจาก **Organization Membership**

เพื่อรองรับ:

- ครูสมัครเอง
- ครูย้ายโรงเรียน
- ครูสังกัดโรงเรียนภายหลัง
- ผู้ใช้มีหลาย Role
- Coach
- Multiple Organization ในอนาคต

---

## 34. Independent Teacher

**[CONFIRMED DIRECTION]**

ครูสามารถมี Account แบบ Independent ได้ ไม่จำเป็นต้องสังกัด School ตั้งแต่แรก

ถ้าภายหลังโรงเรียนซื้อ Seat ให้:

- Account เดิมควรอยู่
- Learning History ไม่ควรหาย
- Portfolio ไม่ควรหาย
- Canvas เดิมไม่ควรหาย

Data Ownership Policy: **[OPEN]** โดยเฉพาะเมื่อครูย้ายโรงเรียน

---

## 35. School Structure

**[CONFIRMED DIRECTION]**

โครงสร้างเบื้องต้น:

```
School
↓
Level / Grade
↓
Classroom
↓
Group
```

แต่ระบบควร Flexible ไม่ควร Hard-code เฉพาะ:

- ป.1
- ม.1
- รูปแบบโรงเรียนไทย

เพราะอนาคตอาจใช้กับ Organization อื่น

---

## 36. Subscription Model

**[CONFIRMED DIRECTION]**

แนวคิดปัจจุบัน:

- **B2B:** โรงเรียนซื้อ Seat → Assign ให้ Teacher
- **B2C:** Teacher สมัครและจ่ายเอง

รายละเอียดต่อไปนี้: **[OPEN]**

- Monthly / Annual
- Pricing
- Packages
- Feature limit
- AI quota
- Coaching quota
- Storage
- Trial
- Seat transfer
- Grace period
- Upgrade / Downgrade
- Cancellation

---

## 37. Course / Training Registration

**[CONFIRMED DIRECTION]**

ระบบควรรองรับ:

- Individual registration
- School registers multiple teachers

Possible Course Type:

- Public
- In-house
- On-site
- Online
- Hybrid

แต่: **Exact Scope Phase 1 = OPEN**

---

## 38. Existing Course Assets

**[CANONICAL AS IP / NOT FINAL PACKAGE]**

องค์ความรู้เดิมมี เช่น:

- Unlock Hidden Potential
- FA
- NVC
- Goal Setting
- Design Thinking
- Habit Development
- Super FA
- Unlock Hidden Potential Camp

ระยะเวลาหรือ Package Commercial ใหม่สามารถเปลี่ยนได้

---

## 39. Payment

**[CONFIRMED DIRECTION]**

มีเงินสองกลุ่มหลัก:

- **Subscription** — Recurring payment / renewal
- **Course** — One-time payment

แนวทางช่องทาง:

- Payment Gateway
- Card
- PromptPay
- Bank Transfer
- Upload Slip
- Invoice

Exact Provider: **[OPEN]**

---

## 40. B2B Billing

**[DIRECTION]**

โรงเรียนอาจมี Flow:

```
Quotation
↓
Approval / PO
↓
Invoice
↓
Payment
↓
Verification
↓
Activation
```

ระบบควรออกแบบ **Payment / Billing แยกจาก Product Entitlement**

---

## 41. Receipt / Tax Invoice

**[DIRECTION]**

เพราะลูกค้าเป็นองค์กร / โรงเรียน ควรเผื่อ:

- Organization billing name
- Tax ID
- Billing address
- Receipt
- Tax invoice

Exact Accounting Workflow: **[OPEN]**

---

## 42. Entitlement

**[SYSTEM PRINCIPLE]**

อย่าผูก Access กับ Payment Status แบบ Hard-code กระจัดกระจายในระบบ

ควรมี Concept: **Entitlement / Access**

เพื่อรองรับ:

- Subscription
- School seat
- Individual plan
- Course bundle
- Trial
- Promotion
- Manual grant

ในอนาคต

---

## 43. Dashboard

**[DIRECTION]**

### Teacher Dashboard

เช่น:

- Current practice
- Canvas
- Case
- Plan
- Reflection
- Feedback
- Skill Progress
- Course

### Coach Dashboard

*(แก้โดยข้อ 60.13.4: ไม่อยู่ในแผน Phase 1–5 เพราะไม่มีโค้ชที่เป็นคน)*

เช่น:

- Assigned Teacher
- Pending Review
- Cases
- Feedback
- Skill Progress

### School Dashboard

Aggregate:

- Active teachers
- Participation
- Usage
- Submission
- Skill development

### Admin Dashboard

เช่น:

- Customer
- Subscription
- Revenue
- Course
- User
- Usage
- Coach workload

---

## 44. Student — Phase 2

**[CONFIRMED]**

*(แก้โดยข้อ 60.13.4: นักเรียนไม่มีบัญชี · เข้าห้องตอบคำถามหรือแบบทดสอบด้วยรหัสห้องหรือรหัสประจำตัวที่ครูออกให้ (Phase 3) · หลัก "Phase 1 ต้องไม่ปิดทาง" ยังใช้ได้)*

Student User ยังไม่ทำเต็มรูปแบบใน Phase 1

Phase 2 อาจมี:

- Student account
- Reflection
- Evidence
- Portfolio
- Practice
- Challenge
- Feedback
- Opportunity

แต่ **Phase 1 ควรออกแบบ Domain ไม่ให้ปิดทาง**

---

## 45. Tool Architecture

**[CANONICAL PRODUCT PRINCIPLE]**

Unlock Hidden Potential Canvas เป็น Core Tool ปัจจุบัน

แต่: **SkillwisE Platform ต้องไม่ Hard-code ว่ามี Tool เพียงตัวเดียว** อนาคตอาจเพิ่ม Tool อื่น

Claude: **ห้ามคิด Tool ใหม่แล้วถือเป็น Requirement โดยไม่ได้รับการยืนยัน**

---

## 46. Domain Architecture

**[SYSTEM DIRECTION]**

ก่อนเลือก Database Schema ให้คิดจาก Business Domain

อย่างน้อยควรพิจารณา Domain เช่น:

- Identity
- Organization
- Membership
- Position
- Role
- Permission
- Subscription
- Entitlement
- Billing
- Payment
- Course
- Enrollment
- Tool
- Case
- Canvas
- Plan
- Activity
- Practice
- Evidence
- Reflection
- Feedback
- Coach Assignment
- Skill
- Competency
- Assessment
- Portfolio
- AI
- Notification
- Reporting

**อย่าออกแบบ Database ตามหน้า UI อย่างเดียว**

---

## 47. Modular Design Principle

**[SYSTEM DIRECTION]**

SkillwisE มีโอกาสขยาย Product มาก Architecture จึงควรแยก Module

หลีกเลี่ยง:

- One giant teacher table
- One giant school table
- Permission ผ่าน boolean จำนวนมาก
- Payment logic กระจายไปทั่วระบบ
- Hard-code Tool Type
- Hard-code Thai School Structure
- Hard-code Subscription Package

---

## 48. Phase 1 Product Loop

**[DIRECTION]**

*(แก้โดยข้อ 60.13.3: ขอบเขต Phase 1 ตัดสินแล้ว คือขายของ รหัสในกล่อง เอกสารการเงิน และอบรม · วงจร Canvas → แผน → ลงมือทำ → feedback ในหัวข้อนี้ไม่ใช่ Phase 1 แล้ว)*

MVP / Phase 1 ควรทำให้วงจรนี้เกิดได้ก่อน:

```
User / Organization
↓
Access / Entitlement
↓
Teacher uses Tool
↓
Situation / Case
↓
Canvas
↓
Plan
↓
Practice
↓
Evidence / Reflection
↓
Coach Feedback
↓
Teacher improves
↓
School sees Aggregate
```

สิ่งที่อยู่นอก Loop นี้ควรพิจารณาความสำคัญก่อนเพิ่มเข้า MVP

---

## 49. Product Principle: Recurring Development

SkillwisE ไม่ควรเป็น:

> "เข้าอบรม 2 วัน แล้วจบ"

และไม่ควรเป็น:

> "สมัคร Software แล้วกรอก Form"

แต่ควรสร้าง **Continuous Professional Development**
ผ่าน **Tool + Practice + Reflection + Coaching + Repetition**

---

## 50. สิ่งที่ยัง OPEN

Claude ห้ามถือว่า Final:

1. Final Pricing
2. Monthly / Annual
3. Subscription Package
4. Trial
5. AI Quota
6. Coaching Quota
7. Exact Coaching Model
8. Teacher / Coach Ratio
9. Seat Transfer
10. Data Ownership
11. Exact School Positions
12. Exact Permission Matrix
13. Exact Submission Types
14. Coach Assignment Logic
15. Course Package
16. Public vs In-house scope
17. Course + Subscription Bundle
18. Certificate
19. Tax Invoice Workflow
20. Payment Gateway
21. Refund
22. Cancellation
23. ~~Tech Stack~~ — TypeScript + Next.js (หน้าบ้าน) + NestJS (หลังบ้าน) ตัดสินแล้ว ดูข้อ 60.5
24. ~~Database~~ — PostgreSQL ตัดสินแล้ว ดูข้อ 60.11
25. Hosting
26. Cloud Provider
27. Storage
28. AI Provider
29. AI Model
30. ~~Exact Phase 1 Feature List~~ — ตัดสินแล้ว ดูข้อ 60.13.3

---

## 51. Tech Stack

**[CONFIRMED — 24 Oct 2026]** ภาษา TypeScript และสถาปัตยกรรม Next.js (หน้าบ้าน) + NestJS (หลังบ้าน) ตัดสินแล้ว ส่วนประกอบย่อยเป็น DIRECTION ดูข้อ 60.5

ส่วนที่ยัง OPEN (Hosting, Cloud Provider, AI Provider, Payment Gateway) ก่อนเลือกให้:

1. Inspect repository ปัจจุบันก่อน
2. ดูว่ามี Code / Config / Architecture เดิมหรือไม่
3. ดู Deployment Requirement
4. ดู Team Skill
5. ดู Budget
6. ดู AI Integration Requirement
7. ดู Payment Requirement
8. ดู Scale ที่ต้องรองรับ

แล้วค่อยเสนอทางเลือกให้ทีมตัดสิน

---

## 52. Working Rule สำหรับ Claude Code

เมื่อผู้ใช้สั่ง Feature:

- **Rule 1** — ตรวจ Canonical Context ก่อน
- **Rule 2** — อย่าขยาย Scope เอง
- **Rule 3** — อย่าเปลี่ยน Business Rule เพราะคิดว่า "น่าจะดีกว่า"
- **Rule 4** — ถ้าเป็นเรื่อง OPEN: ใช้ Flexible Architecture แต่อย่า Hard-code Decision
- **Rule 5** — หากมี Existing Code: Inspect ก่อนแก้
- **Rule 6** — อย่าสร้าง Database Migration ขนาดใหญ่โดยไม่ดู Domain Impact
- **Rule 7** — Privacy / Data Ownership / Billing ต้องระวังเป็นพิเศษ

---

## 53. Things Claude Must NOT Do

ห้าม:

- เปลี่ยน SkillwisE เป็น LMS ธรรมดา
- ทำ Course Catalog เป็น Home ของ Product โดยอัตโนมัติ
- ทำ Canvas เป็น Form กรอกแล้วจบ
- ให้ AI ตัดสินเด็กแทนครู
- สร้าง Teacher Ranking โดยไม่มี Requirement
- เปลี่ยน Coaching เป็น Performance Evaluation
- เปิด Private Coach Feedback ให้ผู้บริหาร
- Hard-code 7 กิจวัตร
- Hard-code Sila5 เป็น Brand
- Hard-code Thai School Structure
- Assume Teacher ต้องมี School
- Assume School owns all teacher history
- ผูก Permission กับ Position
- Assume Coaching Unlimited
- Assume Subscription = Content Library
- Copy Leader in Me โดยตรง
- สร้าง Social Impact Module เอง
- สร้าง Tool ใหม่เอง
- เลือก Tech Stack ก่อน Inspect Existing Project

---

## 54. Separation ที่ต้องรักษา

| ฝั่งหนึ่ง | ≠ | อีกฝั่ง |
|---|---|---|
| Teacher Development | ≠ | Teacher Performance Evaluation |
| Private Coach Feedback | ≠ | Management Reporting |
| Job Position | ≠ | System Permission |
| User Identity | ≠ | Organization Membership |
| Subscription Payment | ≠ | Product Entitlement |
| Canvas | ≠ | Platform |
| AI Suggestion | ≠ | Teacher Decision |
| Training | ≠ | Development Journey |
| 7 กิจวัตร | ≠ | SkillwisE Brand |
| Social Enterprise | ≠ | Free Product |

---

## 55. Current Business Hypothesis

**[DIRECTION — NOT FINAL BUSINESS PLAN]**

ภาพธุรกิจที่กำลังพัฒนาคือ:

```
Free Knowledge / Awareness
↓
Entry Training / Workshop
↓
Platform Subscription
↓
Practice + AI Tools
↓
Reflection
↓
Coaching / Professional Support
↓
Skill Development
↓
School Partnership / Renewal
```

โมเดลนี้ได้ Inspiration บางส่วนจากการศึกษาธุรกิจเช่น Leader in Me
แต่ SkillwisE ต้องสร้าง Model ของตนเอง

---

## 56. Core Competitive Asset

SkillwisE ไม่ควรแข่งขันเพียงด้วย Feature Software

Potential Competitive Assets คือ:

- FA Framework
- FA Competency
- Unlock Hidden Potential
- Canvas
- Real Case Method
- Practice Loop
- Coaching Method
- Reflection
- Character Development System
- 7 กิจวัตร
- Teacher Development IP
- Existing School Network
- Knowledge from Sila5School
- AI-assisted Development Workflow

**Software เป็นเครื่องมือ Scale Intellectual Property เหล่านี้**

---

## 57. Core Strategic Principle

อย่าเริ่มจากคำถามว่า

> "เราจะสร้าง Software Feature อะไร"

ให้เริ่มจาก:

> "เราต้องทำอย่างไรให้ครูเก่ง FA ขึ้นจากสถานการณ์จริง และทำให้การพัฒนานั้นเกิดซ้ำได้อย่างต่อเนื่อง?"

จากนั้นจึงค่อยออกแบบ:

- Tool
- Workflow
- AI
- Data
- Coaching
- Subscription
- Dashboard

---

## 58. Final Canonical Summary

Claude Code ควรจำ 10 ข้อนี้:

1. FA Development คือแกนหลักของ SkillwisE
2. เป้าหมายปลายทางคือช่วยครู Unlock Student Potential
3. Skill Development ต้องเกิดผ่าน Real Practice
4. Canvas เป็น Thinking Tool ไม่ใช่ Product ทั้งหมด
5. AI เป็น Assistant ไม่ใช่ Decision Maker
6. Reflection + Coaching + Practice Again เป็น Core Loop
7. School Management Data ต้องแยกจาก Private Development Data
8. Subscription ต้องสร้าง Recurring Value
9. Human Coaching ต้องคิด Unit Economics
10. SkillwisE คือการนำ IP และประสบการณ์จากงานเดิมมาสร้างเป็น Professional, Scalable, Commercial Teacher Development Platform

---

## 59. Instruction เมื่อเริ่มทำงานใน Repository

ก่อนเริ่ม Implement Feature ใหม่:

1. อ่านไฟล์ Context นี้ก่อน
2. Inspect repository ที่เปิดอยู่ (ไม่ผูกกับ path ใด ๆ เพราะทีมทำงานหลายเครื่อง)
3. สรุป Existing Architecture ให้สั้น ๆ
4. ระบุว่า Requirement ที่ได้รับแตะ Domain ไหนบ้าง
5. ตรวจว่ามี Conflict กับ Canonical Context หรือไม่
6. ถ้าไม่มี Conflict ให้ทำต่อ
7. ถ้ามี Conflict ให้แจ้งก่อนเปลี่ยน Business Rule
8. อย่าแก้ไฟล์ที่ไม่เกี่ยวข้อง
9. รักษา Backward Compatibility เท่าที่สมเหตุสมผล
10. หลังแก้ ให้สรุป:
    - สิ่งที่เปลี่ยน
    - Business Rule ที่ใช้
    - File ที่แก้
    - Migration / Config ที่ต้องทำ
    - Open Issue ที่ยังเหลือ

---

## 60. Decision Log (หลัง Context version 8 Oct 2026)

**[CONFIRMED]** 8 Oct 2026 จากการคุยกับ Claude Code

### 60.1 โค้ดของ Sila5School

- **ไม่นำโค้ดของ Sila5School มาใช้** เพราะเป็น framework ที่ทีมเขียนขึ้นเอง
- นำมาเฉพาะ**แนวคิดและการออกแบบระบบ**ตามข้อ 10
- ศึกษาโค้ดเดิมเพื่อทำความเข้าใจแนวคิดได้ แต่ห้าม copy *(แก้เพิ่มโดยข้อ 60.11: เก็บสำเนาโค้ดไว้เป็นโค้ดอ้างอิงในเครื่องได้ แต่ยังห้ามนำไปใช้เป็นโค้ด production)*
- *(แก้เพิ่มโดยข้อ 60.13.2: โค้ด ตาราง และ flow ของระบบ Sila5School ไม่ใช่หลักของการออกแบบอีกต่อไป · ระบบใหม่ออกแบบจากภาพปลายทางและแผนระบบ ส่วนระบบเดิมใช้อ้างอิงได้อย่างเดียว · IP และ framework ด้านเนื้อหาตามข้อ 10 ยังใช้ได้)*

### 60.2 ข้อมูลนักเรียนใน Phase 1

*(แก้โดยข้อ 60.13.4: ข้อมูลเด็กย้ายไปอยู่ Phase 2 · ใช้ชื่อเล่นหรือชื่อที่ครูตั้งเอง ไม่ต้องมีนามสกุล · เห็นได้เฉพาะครูที่ดูแลห้อง · ไม่มีโค้ชที่เป็นคน · กฎตัดชื่อก่อนส่งข้อมูลให้ AI ยังเหมือนเดิม)*

- นักเรียนยังไม่มี account ใน Phase 1 (ข้อ 44) แต่ครูบันทึกข้อมูลนักเรียนเพื่อใช้กับ Canvas ได้ (ข้อ 13)
- ข้อมูลที่เก็บโดยประมาณ: **ชื่อ นามสกุล ชั้นปี ห้องเรียน**
- รายการ field สุดท้าย: **[OPEN]**
- ข้อมูลนี้เป็นข้อมูลส่วนบุคคลของผู้เยาว์ จึงต้องระวังเป็นพิเศษตาม Rule 7 และ PDPA
- **สิทธิ์การเห็นข้อมูลนักเรียน:** เห็นได้เฉพาะบุคลากรในโรงเรียนนั้น และโค้ชที่ดูแล case ที่เกี่ยวกับนักเรียนคนนั้น *(แก้เพิ่มโดยข้อ 60.7: แอดมิน SkillwisE ที่มีสิทธิ์เฉพาะก็ดูได้ และระบบบันทึกทุกครั้ง)*
- **ข้อมูลนักเรียนกับ AI:** ก่อนส่งข้อมูลให้ AI วิเคราะห์ ระบบต้องตัดชื่อและนามสกุลจริงออกทุกครั้ง แล้วใช้รหัสแทน (pseudonymize) เพื่อไม่ให้ข้อมูลระบุตัวเด็กออกไปนอกระบบ และเมื่อได้ผลลัพธ์กลับมา ระบบค่อยแปลงรหัสกลับเป็นชื่อเพื่อแสดงให้ครูเห็น

### 60.3 การแชร์ข้อมูลให้ผู้บริหาร (ขยายความข้อ 31)

- **Default:** ผู้บริหารไม่เห็น Private Coach Feedback และ Teacher Reflection
- **ครูเลือกแชร์บางชิ้นให้ผู้บริหารเห็นได้เอง** (opt-in เป็นรายชิ้น)
- ขอบเขตการแชร์ เช่น แชร์อะไรได้บ้าง และยกเลิกการแชร์ได้ไหม: **[OPEN]**

### 60.4 ขอบเขตของสิ่งที่ได้จาก Sila5School

- Sila5School **ไม่ได้มีทุกอย่าง**ที่ SkillwisE จะทำ หลายส่วนต้องออกแบบใหม่ทั้งหมด เช่น Coaching, FA Competency/Rubric และ Subscription/Billing
- รายละเอียดของ Rubric 5 ระดับในแต่ละ FA Competency (ข้อ 18): **[OPEN]**
- บันทึกการศึกษาระบบเดิมอยู่ที่ `docs/sila5school-study.md`

### 60.5 Tech Stack (แก้ไข 24 Oct 2026)

*(ทบทวนแล้วเมื่อ 2 Nov 2026 และยืนยันตามเดิม ดูข้อ 60.13.6)*

- **ภาษา: TypeScript ทั้งระบบ** [CONFIRMED] เหตุผล: เลือกภาษาที่ Claude เขียน เทส และรีวิวได้ดีที่สุด ใช้ภาษาเดียวทั้งหน้าเว็บ หลังบ้าน และเทสต์
  - ข้อนี้**แก้ (override) Laravel** ที่เคยตกลงไว้ (เดิมเลือกเพราะทีมถนัด PHP)
- หลักการเลือก (จากประชุมครั้งที่ 1): ทีมให้ Claude เลือก **ตัวที่เขียน รีวิว และเทสได้ดี ราบรื่น และปลอดภัยที่สุด** แทนหลักการเดิม "ตัวที่ทีมถนัด"

#### สถาปัตยกรรม: แยกหน้าบ้านกับหลังบ้าน

**[CONFIRMED — 24 Oct 2026]** หน้าบ้าน **React (Next.js)** + หลังบ้าน **NestJS** อยู่ใน monorepo เดียว
แทนแผนเดิมที่ให้ Next.js ตัวเดียวทำทั้งหน้าบ้านและหลังบ้าน

```
skillwise/  (monorepo: pnpm + Turborepo)
├─ apps/web          Next.js (React) — หน้าบ้านอย่างเดียว · SSR ให้หน้าสาธารณะติด SEO
├─ apps/api          NestJS — business logic, สิทธิ์, DB, AI, LINE webhook, งานเบื้องหลัง, PDF
└─ packages/shared   Zod schema + type ที่ใช้ร่วมกันทั้งสองฝั่ง
```

เหตุผลที่ไม่ใช้ Next.js ตัวเดียว:

1. **SkillwisE หนักที่หลังบ้าน** มีทั้งสิทธิ์หลายระดับ, Entitlement, Billing, AI, LINE, งานตั้งเวลา, audit log และการตัดชื่อเด็กก่อนส่ง AI (ข้อ 60.2) NestJS แบ่ง module ตาม domain ได้ตรงกับข้อ 46–47
2. **มีหลายช่องทางที่เรียกระบบเดียวกัน** คือเว็บ, LINE bot (ข้อ 60.10.6), หลังบ้านแบบแชท (ข้อ 60.10.7), แอปนักเรียน Phase 2 (ข้อ 44) และงานเบื้องหลัง ทุกช่องทางเรียก API ชุดเดียว กฎจึงอยู่ที่เดียว
3. **ปลอดภัยกว่า** ตรวจสิทธิ์รวมศูนย์ที่ guard ของ NestJS ทุก endpoint ส่วนหน้าบ้านไม่แตะฐานข้อมูล ถ้า Next.js มีช่องโหว่ ก็ไม่ถึงข้อมูลโดยตรง
4. **งานที่ใช้เวลานานรันได้เป็นธรรมชาติ** เช่น AI ทำแผนหลายนาที หรือเตือนผ่าน LINE ตามเวลา NestJS มี queue และ scheduler ในตัว
5. **AI เขียน รีวิว และเทสได้คงเส้นคงวา** เพราะ NestJS มีรูปแบบตายตัว (module / controller / service / guard) และ DI ทำให้เทสง่าย ข้อนี้สำคัญเพราะจะมี AI หลายรอบหลายแชทเขียนโค้ดต่อกัน
6. แนวคิดของ NestJS ใกล้กับ Laravel (controller, service, middleware, DI) คนที่มาจาก PHP อ่านเข้าใจง่าย

ข้อแลกเปลี่ยนที่ยอมรับ:

- มี 2 แอปต้อง deploy และดูแล และ boilerplate มากขึ้น
- ต้องคุม type ทั้งสองฝั่งให้ตรงกัน แก้ด้วย `packages/shared`
- login ข้ามแอปต้องให้ web กับ api อยู่โดเมนเดียวกัน (ใช้ reverse proxy) เพื่อใช้ httpOnly cookie ได้และเลี่ยงปัญหา CORS / CSRF
- ต้องมี Redis เพิ่มถ้าใช้ BullMQ

**[SYSTEM PRINCIPLE]** กฎการแบ่งหน้าที่:

- `apps/web` **ไม่เชื่อมฐานข้อมูล และไม่มี business logic** ข้อมูลทุกอย่างได้มาจาก API
- ทุก endpoint ของ `apps/api` ต้องประกาศสิทธิ์ที่ต้องใช้ และตรวจด้วย guard · ค่าเริ่มต้นคือปฏิเสธ
- ช่องทางอื่นทั้งหมด (LINE webhook, งาน AI, หลังบ้านแบบแชท, แอปนักเรียนในอนาคต) ต้องผ่าน API และกฎสิทธิ์ชุดเดียวกัน
- schema สำหรับตรวจข้อมูลอยู่ใน `packages/shared` ทั้งสองฝั่งใช้ตัวเดียวกัน

#### ส่วนประกอบ

**[DIRECTION]** ปรับได้ระหว่างออกแบบ:

- หน้าบ้าน: Next.js (App Router) + React + Tailwind + shadcn/ui
- หลังบ้านแอดมินและโค้ช: หน้าเว็บใน `apps/web` ด้วย shadcn/ui + TanStack Table ข้อมูลผ่าน API
- API: NestJS
- ฐานข้อมูล: PostgreSQL + Prisma (ใช้ใน `apps/api` เท่านั้น) · PostgreSQL เป็น [CONFIRMED] แล้วตามข้อ 60.11
- ตรวจข้อมูลขาเข้า: Zod
- งานเบื้องหลังและตั้งเวลา: BullMQ + Redis (`@nestjs/bullmq`) + `@nestjs/schedule` · ถ้าไม่อยากเพิ่ม Redis ใช้ pg-boss แทนได้ แต่ต้องเขียนเชื่อมกับ NestJS เอง
- Login: ทำใน NestJS (Passport: Google, LINE) เก็บ session ใน httpOnly cookie
- ไฟล์: Cloudflare R2 (ผ่าน S3 API)
- PDF: แปลง HTML เป็น PDF ด้วย Playwright ฝั่ง API (Chromium จัดสระและวรรณยุกต์ภาษาไทยถูกต้อง)
- Test: Vitest (unit/integration) + Supertest (API) + Playwright (E2E)
- คุณภาพโค้ด: TypeScript strict + ESLint + Prettier + CI รัน typecheck, lint และเทสต์ทุกครั้งก่อน merge

ผลจากการเปลี่ยน:

- ทีมต้องเรียน TypeScript, React และ NestJS เพื่อดูแลโค้ดต่อ
- ไม่มีเครื่องมือหลังบ้านสำเร็จรูปแบบ Filament ต้องเขียนหน้าแอดมินเอง

ยังเป็น **[OPEN]**: AI Provider, Payment Gateway, Hosting · Hosting ต้องรัน Node แบบทำงานตลอดได้ (API + worker + Redis) ไม่ใช่ serverless อย่างเดียว

#### กฎความปลอดภัย

**[SYSTEM PRINCIPLE]**

- อัปเดต Next.js / React / NestJS / dependency ทันทีเมื่อมี security advisory อย่าค้างเวอร์ชันเก่า (Next.js เคยมีช่องโหว่ร้ายแรงที่ข้ามการตรวจสิทธิ์ผ่าน middleware ได้ ในปี 2025)
- **ห้ามพึ่ง middleware ของหน้าบ้านในการตรวจสิทธิ์** สิทธิ์ตรวจที่ API เสมอ หน้าบ้านซ่อนหรือแสดงเมนูได้ แต่ไม่ถือเป็นการกันสิทธิ์
- secret และ API key อยู่ฝั่ง API หรือ server เท่านั้น ห้ามอยู่ใน bundle ของหน้าบ้าน
- เปิด dependency audit อัตโนมัติ (เช่น Dependabot หรือ Renovate)

#### Repository ที่เริ่มไว้แล้ว

- ถ้า repository มีโค้ดที่เริ่มไว้ตามแผนเก่า (Laravel หรือ Next.js ตัวเดียว) ให้ inspect แล้วสรุปขอบเขตการย้ายให้ทีมก่อน **อย่าลบหรือแปลงเงียบ ๆ**
- เอกสารใน `docs/` ยังใช้ได้ในระดับแนวคิด แต่ส่วนที่อ้าง Laravel / Livewire / Filament / MySQL / Auth.js / pg-boss ต้องปรับตามข้อนี้

### 60.6 ลำดับการทำงาน

*(หมายเหตุ 2 Nov 2026: ไฟล์ `docs/roadmap.md` และ `docs/proposals.md` ที่ข้อนี้อ้างยังไม่เคยสร้างใน repo · แผนปัจจุบันอยู่ที่ `docs/system-plan.md` และการตัดสินใจอยู่ในข้อ 60 ดูข้อ 60.13)*

- ยังไม่ทำเอกสารสรุประบบทั้งหมด ให้**วางแผนก่อน** ดูแผนที่ `docs/roadmap.md`
- ข้อเสนอของ Claude ที่รอทีมตัดสินใจ เก็บไว้ที่ `docs/proposals.md` และยังไม่ถือเป็นข้อตกลง

### 60.7 หน้าแอดมินและระดับสิทธิ์ของแอดมิน (11 Oct 2026)

*(แก้โดยข้อ 60.13.4: ทีมงานดูเรื่องเล่าและไทม์ไลน์ของเด็กไม่ได้ · ที่เหลือในข้อนี้ยังใช้ได้ ได้แก่ บทบาทตามหน้าที่, ยืนยันตัวตน 2 ขั้น และบันทึกทุกครั้งที่เปิดดูข้อมูลส่วนบุคคล)*

- **หน้าแอดมินเป็นหน้า UX สำหรับดูข้อมูลได้ทุกอย่างในระบบ** ค้นหาและไล่ดูข้อมูลต่อกันได้ เช่น โรงเรียน → ครู → Canvas → แผน → บันทึก → feedback และแก้ไขได้ตามสิทธิ์
- **ระดับสิทธิ์ของแอดมินเป็นแบบ "บทบาทตามหน้าที่"** (role) แต่ละบทบาทประกอบด้วยสิทธิ์ที่ตั้งชื่อชัดเจน และปรับได้ในหน้าแอดมิน ไม่ใช้ตัวเลขระดับ 1–9 แบบ Sila5School
- **ข้อมูลอ่อนไหวดูได้เฉพาะแอดมินที่มีสิทธิ์นั้น** ได้แก่ ชื่อนักเรียน, reflection ของครู และเนื้อหา feedback ของโค้ช **และระบบบันทึกทุกครั้งที่เปิดดู** (ใคร ดูอะไร เมื่อไร)
  - ข้อนี้**แก้ (override) ข้อ 60.2** ซึ่งเดิมไม่รวมแอดมินไว้
  - **ข้อ 31 ยังคงเดิม** ผู้บริหารโรงเรียนไม่เห็น Private Coach Feedback ข้อนี้เกี่ยวกับแอดมินของ SkillwisE เท่านั้น
- รายชื่อบทบาทและสิทธิ์ในแต่ละบทบาท: **[DIRECTION]** มีร่างใน `docs/plan-phase1.md` *(ไฟล์นี้ไม่มีใน repo · ร่างปัจจุบันของบทบาททีมงานอยู่ใน `docs/database/seed.sql` ตาราง `staff_roles` และ `staff_role_permissions`)*

### 60.8 รูปแบบการซื้อ Subscription (18 Oct 2026)

*(ดูข้อ 60.13.4–60.13.5: แบบรายคนคือ Pro รายปีหรือรายเดือน · Set Package นับเป็นแพ็กเกจโรงเรียนแบบหนึ่งซึ่งอยู่ใน Phase 3)*

**[CONFIRMED]** ขยายความข้อ 36 ระยะแรกคิดเงิน **รายคน (per seat)** ซื้อได้ 3 แบบ:

| แบบ | รายละเอียด |
|---|---|
| **รายคน** | ครู 1 คนซื้อสิทธิ์ให้ตัวเอง |
| **Set Package** | ซื้อเป็นชุด **10, 20 หรือ 30 คน** แล้วแจก seat ให้ครูแต่ละคนได้ |
| **B2B ราคาตามตกลง** | โรงเรียนหรือองค์กรคุยราคากันเป็นรายกรณี (ทำตามขั้นตอนในข้อ 40) |

- ไอเดีย "ราคาตามขอบเขต ห้อง/ชั้น/โรงเรียน" จากประชุมครั้งที่ 1 **ยังไม่ใช้ในระยะแรก**
- ยังเป็น **[OPEN]**:
  - ราคาของแต่ละแบบ
  - ใครซื้อ Set Package ได้ (ครูรายคนหรือเฉพาะโรงเรียน)
  - ดึง seat คืนหรือย้ายให้ครูคนอื่นได้ไหม (ข้อ 36: seat transfer)
  - อายุของ seat (รายเดือนหรือรายปี)

---

### 60.9 Brand Architecture และ SkillwisE FA Differentiation (24 Oct 2026)

**[CONFIRMED]**

1. **SkillwisE ในระดับ Brand / Company** เป็น Human Growth Ecosystem ผ่าน **Courses + Tools + Platform**
2. แกนการพัฒนาหลักของ Brand คือ:
   - พัฒนานิสัย
   - ปลดล็อกศักยภาพ
   - ยกระดับจิตใจ
3. เป้าหมายคือ **พัฒนาผู้คนให้เติบโต และร่วมสร้างสังคมที่ดีกว่าเดิม**
4. Tagline ที่ยืนยันแล้วคือ **“Growing People, Brighter Society.”**
5. **SkillwisE Education / School Product** ยังคงมี **FA Development** เป็น Core Capability
6. จุดแตกต่างของ **SkillwisE FA** คือ **FA for Human Growth** โดยเน้น Habit Development + Unlock Human Potential ไม่ใช่ Facilitator ทั่วไป
7. **Sila5School และ SkillwisE ต้องเดินคู่ขนานโดยไม่ซ้อนทับกัน**
   - Sila5School ชู **7 กิจวัตรความดี** และใช้ FA เป็นกลไก Delivery
   - SkillwisE ชู **FA for Human Growth** โดยใช้ Unlock Hidden Potential / Canvas เป็น Framework & Tool และ 7 กิจวัตรเป็นหนึ่งใน Practice Assets
8. ทั้งสองแบรนด์สามารถใช้ IP และองค์ความรู้ร่วมกันได้ แต่ต้องมี Entry Message และ Positioning ต่างกัน

---

### 60.10 ประชุม SE ครั้งที่ 1 — สรุปเรื่องระบบ (24 Oct 2026)

ที่มา: ถอดจากไฟล์เสียงประชุมครั้งที่ 1 แล้วทีมยืนยันเพิ่มในวันเดียวกัน
ป้ายในข้อนี้ใช้ความหมายตามข้อ 0 **ตัวเลขทุกตัวเป็นค่าที่พูดในประชุม ไม่ใช่ค่าที่ตัดสินแล้ว** เว้นแต่ติดป้าย [CONFIRMED]
เรื่อง Tech Stack ที่คุยในประชุมนี้ บันทึกไว้ในข้อ 60.5 แล้ว

#### 60.10.1 SkillwisE กับ Sila5School

**[CONFIRMED]**

- SkillwisE ใช้องค์ความรู้และประสบการณ์จาก Sila5School เป็นต้นทุน แล้ว**คิดแบบธุรกิจและแบบ Product ได้เต็มที่** ไม่ต้องติดข้อจำกัดเดิมของ Sila5School (ทรัพยากรจำกัด และไม่ได้ทำเชิงธุรกิจ)
- สิ่งที่ทำใน SkillwisE แล้วได้ผล **ส่งกลับไปใช้ที่ Sila5School ได้**
- SkillwisE เป็นพื้นที่ทดลองการพัฒนาระบบด้วย AI เต็มรูปแบบ
- ระบบหลังบ้านเดิมของ Sila5School (framework เฉพาะของทีมเดิม เขียนด้วย PHP) **ไม่นำมาใช้** สอดคล้องกับข้อ 60.1

#### 60.10.2 สินค้าและบริการของ SkillwisE

**[CONFIRMED]** ทุกรายการในตารางเป็นของ **SkillwisE** และอยู่ใต้ Courses + Tools + Platform (ข้อ 1.1)
**[OPEN]** รายการไหนเข้า Phase 1 · ชื่อสินค้า · ราคา

หลักคิดของทีม:

- วาดภาพระยะยาวก่อน แล้ว**หั่นส่วนที่ขายง่ายออกมาทำก่อน** อย่าเริ่มจากของที่ซับซ้อน
- ผสมสินค้าดิจิทัลกับ**สินค้าที่จับต้องได้**
- คุณค่าไม่ได้อยู่ที่แพลตฟอร์มอย่างเดียว แต่อยู่ที่เกม คอนเซ็ปต์การอบรม และหลักสูตรด้วย (ข้อ 56)

| สินค้า / บริการ | รายละเอียดจากประชุม |
|---|---|
| **การ์ดเกม / บอร์ดเกม (เซ็ตเกม)** | สินค้าจับต้องได้ เล่นออฟไลน์แล้ว**กลับมาบันทึกผลบนแพลตฟอร์ม** · ทดลองกับผู้ใช้แล้วผลตอบรับดีมาก เพราะรูปแบบเกมทำให้ไม่เครียด แนวเดียวกับเกม Cashflow · กล่องและแพ็กเกจยังไม่เสร็จ |
| **คอร์ส** | ดูข้อ 60.10.3 |
| **สื่อพร้อมใช้ในห้องเรียน** | เช่น คลิปการ์ตูนให้ครูเปิดให้เด็กดู + คู่มือ FA ว่าดูจบแล้วจะชวนคุยและตั้งคำถามอย่างไร |
| **บริการ AI ตัดคลิป** | ครูอัปโหลดวิดีโอกิจกรรมหรือสัมภาษณ์ → AI ตัดเป็นคลิปสั้น ใส่ชื่อและโลโก้ SkillwisE · คิดเป็นเครดิต (ตัวอย่างที่พูด: ต้นทุนราว 20 บาท ขาย 50–100 บาทต่อครั้ง) · มีเครื่องมือต้นแบบแล้ว |
| **แพลตฟอร์ม** | Canvas → แผน → ลงมือทำ → บันทึก → ติดตามพัฒนาการ (ข้อ 60.10.4) และแปลงผลงานจริงเป็นเอกสาร (ข้อ 60.10.5) *(แก้โดยข้อ 60.13.4: ไม่มีแผนลงมือทำรายสัปดาห์ · Phase 2 ใช้เรื่องเล่าผ่าน LINE + ไทม์ไลน์เด็ก)* |

#### 60.10.3 โมเดลคอร์ส

**[DIRECTION]** ขยายความข้อ 21.2, 27, 37

| ช่องทาง | หน้าที่ |
|---|---|
| **Online** | ทฤษฎีทั้งหมดอยู่ที่นี่ ผู้เรียนเรียนเองตามเวลาของตัวเอง |
| **On-Zoom** | Workshop ที่ทำผ่าน Zoom ได้ ต้องเปิดกล้อง |
| **On-site** | Workshop ขั้นสูงหรือ experience จริง **ไม่มีการบรรยายทฤษฎี** |

กติกา:

- **ต้องเรียน Online ผ่านก่อน** จึงสมัคร On-Zoom / On-site ได้ (prerequisite)
- มี **Free tier** (คอร์สออนไลน์ฟรี) และ **Subscription tier** (จ่ายแล้วเรียนได้หลายคอร์ส)
  - Free tier ของคอร์ส **ไม่ได้หมายถึงใช้เครื่องมือบนแพลตฟอร์มฟรี** (ข้อ 27) · ขอบเขต Free tier: **[OPEN]**
- On-site สำหรับสมาชิก: จัดทุก 2–3 เดือน รับราว **20 คน** · สมาชิกที่มีสิทธิ์ลงชื่อแสดงความสนใจ → ระบบ**สุ่มเลือก** → ที่เหลือเป็น**ตัวสำรอง** และเลื่อนขึ้นเมื่อมีคนสละสิทธิ์
- วิดีโอออนไลน์ต้องเป็น **interactive**:
  - มีคำถามเด้งระหว่างวิดีโอ ต้องตอบก่อนจึงดูต่อได้
  - **ข้ามไปส่วนที่ยังไม่ได้ดูไม่ได้**
  - ต้องดูจบและทำแบบทดสอบผ่าน จึงปลดล็อกบทถัดไป
  - เก็บชั่วโมงเรียนได้ (คล้ายระบบเก็บชั่วโมงพัฒนาวิชาชีพ)
  - เปิดกล้องยืนยันตัวตนระหว่างเรียน: **[OPEN]**
- Approach ต้องต่างจากคอร์สออนไลน์ทั่วไปที่ล้นตลาด

ผลต่อระบบ: Domain Course / Enrollment (ข้อ 46) ต้องรองรับ prerequisite, ประเภทช่องทาง, การลงชื่อแสดงความสนใจ, การสุ่มเลือก, รายชื่อสำรอง, ความคืบหน้ารายวิดีโอ และคำถามในวิดีโอ

#### 60.10.4 Flow หลักจากระบบ Sila5School (เคยเป็นต้นแบบของ SkillwisE ก่อนข้อ 60.13)

*(แก้โดยข้อ 60.13.2 และ 60.13.4: flow นี้ไม่ใช่ต้นแบบของ SkillwisE แล้ว · ระบบใหม่ไม่มีแผนลงมือทำรายสัปดาห์ และ Phase 2 ใช้การเล่าผลผ่าน LINE แทน)*

**[REFERENCE]** ระบบที่ใช้งานจริงซึ่งทีมสาธิตในประชุม ใช้เป็นต้นแบบแนวคิดเท่านั้น ห้าม copy โค้ด (ข้อ 60.1) และห้าม hard-code ของเฉพาะ Sila5School เช่น สมุดบันทึกความดี ชั่วโมงสุขจริงหนอ 7 กิจวัตร ให้เป็นแกนของ SkillwisE (ข้อ 9, 53)

```
ประเด็นท้าทาย → Canvas → AI ตรวจ Canvas → แผนพัฒนาศักยภาพ → แผนลงมือทำ → บันทึกรายสัปดาห์ → Timeline พัฒนาการรายเด็ก
```

**1. Canvas**

- เริ่มจาก **ประเด็นท้าทาย** (เกิดอะไรขึ้น ส่งผลอย่างไร) แล้วเลือกขอบเขต (รายคน / กลุ่ม / ห้อง)
- แนวคิดที่ใช้สื่อสารกับครู: เปลี่ยนจาก **Manage view** ("จะจัดการเด็กอย่างไร" ซึ่งมักจบที่ลงโทษหรือออกกฎ) เป็น **Unlock view** ("เด็กขาดศักยภาพอะไร จะช่วยเด็กอย่างไร")
- ช่อง 1 ศักยภาพที่ต้องการปลดล็อก
- ช่อง 2 เหตุผลที่เลือก ตรวจด้วยประโยค "ถ้า [เด็ก] มี [ศักยภาพ] จะทำให้ [ปัญหา] ลดลง" ถ้าอ่านแล้วไม่สมเหตุสมผล แปลว่าเลือกศักยภาพผิด
- ช่อง 3 ภาพปลายทาง
- ช่อง 4–6 **"กุญแจ 3 ดอก"**: นิสัยเล็ก ๆ ที่ทำทุกวัน / ครูเป็นนั่งร้าน (scaffolding) / สร้างโอกาสหรือเวทีให้ใช้
- ช่อง 7 สัญญาณแห่งความสำเร็จที่จับต้องได้ภายใน 1 เทอม

**2. AI ตรวจ Canvas**

- ระบบเดิม: AI ให้คะแนนรายช่อง ต้องได้ ≥ 7 จึงใช้ทำแผนได้ · รันเป็นรอบตอนกลางคืน มี AI ตัวที่สองตรวจซ้ำเพื่อกันการหลอน แล้วมีคนตรวจในเครื่องมือภายนอกก่อนอนุมัติและอีเมลแจ้งครู
- **[DIRECTION] SkillwisE ต้องทำทั้งกระบวนการให้จบในระบบเดียว** ไม่อ้อมผ่านเครื่องของคนหรือเครื่องมือภายนอก และต้องตรวจความถูกต้องของผล AI ก่อนแสดงให้ครู
- **[OPEN]** คะแนนจาก AI จะเป็นเงื่อนไขบังคับก่อนทำแผนหรือไม่ (ระวังข้อ 12: AI ไม่ใช่ผู้ตัดสิน) · ยังต้องมีคนตรวจซ้ำหรือไม่

**3. Canvas → แผนพัฒนาศักยภาพ**

- เลือก Canvas ไม่เกิน 5 ใบ (ตั้งค่าได้ ห้าม hard-code ตามข้อ 13) → AI สรุปเป็นแผน 4 หัวข้อ เช่น บริบทและประเด็นท้าทาย เป้าหมายการพัฒนา วิธีดำเนินงาน
- ใช้เวลาหลายนาที จึง**ต้องเป็นงานเบื้องหลังที่มีสถานะให้ครูเห็น**
- ครูเติมค่าเป้าหมายเองในช่องว่าง → ส่งตรวจ → ยกเลิกการส่งได้
- ต้นทุน AI ราว **8–10 บาทต่อครั้ง** (Canvas 5 ใบ) · ระบบเดิมจำกัด 2 ครั้งต่อปีการศึกษา
- **[DIRECTION] SkillwisE คิดการใช้ AI เป็นเครดิต:** ลองฟรี 1 ครั้ง จากนั้นใช้ตาม quota ของแพ็กเกจหรือเติมเครดิต · ตัวเลข: **[OPEN]** (ข้อ 36)

**4. แผนพัฒนา → แผนลงมือทำ**

- ผู้ประสานงานหลักเป็นคนกดแปลง · **แปลงแล้ว Canvas และแผนพัฒนาจะถูกล็อก**
- กำหนดช่วงดำเนินงาน (≥ 8 สัปดาห์) ครูร่วม กิจวัตรหลัก (ห้อง / ครู / วัน / เวลา) และกิจกรรมเสริมจากไอเดียใน Canvas
- ผลลัพธ์คือ **to-do รายสัปดาห์** · เตือนทุกครั้งที่เข้าระบบ · เลื่อนวันเวลาได้ตลอด
- แนวคิด: **"แผนคือคำสัญญา"**

**5. บันทึกและพัฒนาการ**

- ครูบันทึกเรื่องราวรายสัปดาห์ · แชร์เข้าพื้นที่แลกเปลี่ยนเรียนรู้ได้ (ต้องอนุมัติก่อน และไม่แสดงชื่อเด็ก)
- **Timeline รายเด็ก:** รวมบันทึกจากครูทุกคน + สัญญาณจากช่อง 7 · AI เติมสรุป "ก่อน / หลัง" ให้ ครูแก้ได้ทั้งหมด

สิ่งที่ระบบเดิมยังขาดและอยากได้ใน SkillwisE: อัปเดตผ่าน LINE แทนการเข้าหน้าจอ (ข้อ 60.10.6) และ Dashboard สรุป

#### 60.10.5 หลักฐานแบบ "ทำไปบันทึกไป"

**[DIRECTION]** ขยายความข้อ 15 และ 20

ปัญหาที่ครูเจอ: ผลงานจากโครงการได้รับการรับรองจากหน่วยงานน้อย ครูส่วนใหญ่ทำเอกสารย้อนหลังตอนปลายเทอม และผู้ตรวจไม่มีทางรู้ว่าทำจริงหรือไม่

แนวทางของ SkillwisE:

*(ดูข้อ 60.13.4: ไม่มีบันทึกการลงมือทำรายสัปดาห์แล้ว · หลักในข้อนี้ใช้กับเรื่องเล่าผ่าน LINE ใน Phase 2)*

- สร้างวัฒนธรรม **"ทำไปบันทึกไป"** บันทึกสั้น ๆ ทุกครั้งที่ทำ แล้วระบบสรุปเป็นรายงานตอนท้ายให้
- **เวลาบันทึกต้องมาจากระบบ** ผู้ใช้ตั้งวันย้อนหลังเองไม่ได้ · การแก้ไขต้องเก็บประวัติ · แนวคิดเรื่องบันทึกย้อนหลังดูข้อ 60.12
- ระบบช่วย**แปลงบันทึกจริงเป็นเอกสารที่ครูต้องส่ง** เช่น แผนแบบราชการ PDF เอกสาร VA/PA วิทยฐานะ และวิจัยในชั้นเรียน 5 บท (โรงเรียนเอกชนก็ต้องทำ)
- หลักสำคัญ: **ครูต้องเรียนรู้และลงมือทำจริง ระบบช่วยลดภาระ ไม่ใช่เครื่องผลิตเอกสาร** (ข้อ 4, 49)
- มุมมองจากประชุม: ครูยอมจ่ายสูงเพื่อเอกสารวิทยฐานะ ราคาระดับ "หลักพัน" จึงยังคุ้มสำหรับครู ไม่จำเป็นต้องฟรี · ราคาจริง: **[OPEN]**
- เปิดให้หน่วยงานภายนอก (เช่น ศึกษานิเทศก์) ตรวจหลักฐานในระบบ หรือทำ MOU: **[OPEN — ทำทีหลัง]** ให้โฟกัสการพัฒนาครูและเด็กก่อน · ถ้าทำ ต้องเปิดเฉพาะหลักฐานการทำ ไม่รวม Reflection หรือ Coach Feedback และครูต้องเลือกแชร์เอง (ข้อ 31, 60.3)

#### 60.10.6 LINE เป็นช่องทางหลัก

**[DIRECTION]**

- งานประจำของครูให้ทำผ่าน LINE ได้มากที่สุด แทนการเข้าหน้าจอ
- เตือนตามแผนลงมือทำ เช่น "วันนี้ตั้งใจจะเล่นเกม … ทำหรือยัง ผลเป็นอย่างไร มีภาพไหม" → ครูตอบใน LINE → ระบบบันทึกกลับเป็นหลักฐาน (ตามกฎข้อ 60.10.5) *(แก้โดยข้อ 60.13.4: ไม่มีแผนลงมือทำ · Phase 2 ครูเล่าผลผ่าน LINE 7 ขั้นเอง (หน้า L1) ไม่มีการเตือนตามแผน)*
- เตือนก่อนวันคอร์ส 2–3 วัน
- รูปแบบการประมวลผลข้อความ: **AI จัดประเภทข้อความที่เข้ามา แล้ว workflow แบบกำหนดตายตัวทำงานต่อ** · ข้อความที่ไม่เกี่ยวข้องให้ตอบกลับสุภาพ ไม่ปล่อยให้ AI คุยยาว เพื่อคุมค่า token
- ใช้ n8n หรือเขียน workflow ในระบบเอง: **[OPEN]**

#### 60.10.7 หลังบ้านแบบสั่งงานด้วยแชท

**[DIRECTION — อนาคต]** ไม่แทนที่ข้อ 60.7

- Phase 1 ใช้หน้าแอดมินแบบปกติตามข้อ 60.7
- อนาคต: หลังบ้านเป็นหน้าแชท แอดมินพิมพ์สั่งพร้อมแนบไฟล์ได้ เช่น "วันนี้มีอบรม เอาโปสเตอร์นี้ขึ้นหน้าแรก" แล้ว AI agent ทำให้ โดยไม่ต้องจำเมนู
- การสั่งงานผ่านแชทต้องผ่านสิทธิ์และ audit log ชุดเดียวกับหน้าแอดมิน (ข้อ 60.7) และต้องให้ยืนยันก่อนลบหรือเผยแพร่

#### 60.10.8 AI และวิธีพัฒนา

**[DIRECTION]**

- **ข้อมูลคือทรัพย์สินหลัก:** ข้อมูลที่ครูสะสมไว้บนแพลตฟอร์ม (Canvas แผน บันทึก พัฒนาการ) คือเหตุผลที่ครูใช้ต่อเนื่อง จึงต้องออกแบบ data ให้ต่อยอดได้ (ข้อ 26)
- **คุมต้นทุน AI:** งานใหม่หรืองานยากใช้โมเดลที่เก่ง · งานที่ทำซ้ำจนรูปแบบนิ่งแล้ว แปลงเป็น script / workflow หรือใช้โมเดลที่ถูกกว่า
- ลงทุน Local AI (ฮาร์ดแวร์ของตัวเอง) **เมื่อมีลูกค้าจ่ายเงินแล้วเท่านั้น**
- วิธีทำงาน: AI เขียนโค้ดเป็นหลัก · คนเข้าใจโครงสร้าง ตรวจว่าตรงคอนเซ็ปต์ และเป็นผู้ตัดสินใจ · ปล่อยฟีเจอร์ได้ถี่ เมื่อทีมตรวจแล้วและผ่าน test

#### 60.10.9 ขั้นตอนต่อไปจากประชุม

1. ~~คัดฟีเจอร์ Phase 1~~ — ตัดสินแล้ว ดูข้อ 60.13.3
2. ~~ดูระบบ Sila5School เดิมว่ามีอะไรแล้ว~~ — ศึกษาแล้ว 24 Oct 2026 ดู `docs/sila5school-study.md` (ร่างฟีเจอร์ Phase 1 อยู่ในหัวข้อ 8 และคำถามที่ทีมต้องตัดสินอยู่ในหัวข้อ 9)
3. ใช้ Stack ตามข้อ 60.5 → ทำ wireframe → สร้าง SkillwisE → ปรับต่อเนื่อง
4. ตกลงฟีเจอร์และ stack แล้ว ค่อยเลือก Hosting

#### 60.10.10 สิ่งที่ยัง OPEN จากประชุมนี้

- ~~รายการฟีเจอร์ Phase 1 และสินค้าไหนเข้า Phase 1~~ — ตัดสินแล้ว ดูข้อ 60.13.3
- ชื่อและแพ็กเกจของเกม
- ขอบเขต Free tier ของคอร์ส
- ราคา: เครดิต AI บริการตัดคลิป และระดับราคาแพลตฟอร์ม
- คะแนน AI ของ Canvas เป็นเงื่อนไขบังคับหรือไม่ และยังต้องมีคนตรวจซ้ำหรือไม่
- การเปิดให้หน่วยงานภายนอกตรวจหลักฐาน
- การเปิดกล้องยืนยันตัวตนในคอร์สออนไลน์
- n8n หรือ workflow ในระบบ
- Hosting / Cloud, AI Provider / Model, Payment Gateway

### 60.11 โค้ดอ้างอิง ขอบเขตฐานข้อมูล MVP และฐานข้อมูล (27 Oct 2026)

**[CONFIRMED]** ทีม dev ขอโค้ดของฟีเจอร์ที่เกี่ยวข้องและร่างฐานข้อมูลเบื้องต้น เพื่อนำไปเขียน SkillwisE

#### 60.11.1 โค้ดอ้างอิงจาก Sila5School (แก้เพิ่มข้อ 60.1)

- **เก็บสำเนาโค้ด PHP** ของ Sila5School เฉพาะส่วนที่เกี่ยวกับฟีเจอร์ SkillwisE **โดยไม่แปลงภาษา** เพื่อให้ทีมและ AI ที่ช่วยเขียนโค้ดเข้าใจ business rule ตรงกัน
- **เก็บในเครื่องเท่านั้น** ที่ `reference/sila5school/` ซึ่งอยู่ใน `.gitignore`
  - เหตุผล: repo ต้นทาง (`RGTCenter/sila5school`) เป็น private แต่ repo SkillwisE เป็น public และโค้ดนี้คือระบบที่ยังใช้งานจริงและมีข้อมูลนักเรียน
  - ส่งต่อทีมผ่านช่องทางที่ไม่ public เท่านั้น
- ไม่ copy config ที่มี secret, vendor และข้อมูลจริง
- **ข้อ 60.1 ส่วนที่ห้ามใช้โค้ดเดิมเป็นโค้ด production ยังคงเดิม** · SkillwisE เขียนใหม่ด้วย TypeScript ตามข้อ 60.5
- spec รายฟีเจอร์ที่อธิบายโค้ดอ้างอิงอยู่ที่ `docs/feature-spec/` ขึ้น GitHub ได้
- เอกสารศึกษาและ spec **คงรายละเอียดปัญหาของระบบเดิมไว้ รวมถึงช่องโหว่** เพื่อให้ทีมและ AI รู้ตรงกันว่าอะไรห้ามทำตาม

#### 60.11.2 ขอบเขตการออกแบบฐานข้อมูล MVP

*(แก้โดยข้อ 60.13.4: ร่างฐานข้อมูลใหม่ตามโครงข้อมูลในแผนระบบแล้ว ไม่ยึดหัวข้อ 8 ของเอกสารศึกษาอีกต่อไป ดู `docs/database/README.md`)*

- ออกแบบให้ครอบคลุมฟีเจอร์ระดับ **Must + Should** ในหัวข้อ 8 ของ `docs/sila5school-study.md` แต่**สร้างระบบจาก Must ก่อน**
- Should ข้อไหนจะสร้างใน MVP ตัดสินภายหลังได้โดยไม่ต้องแก้ schema
- รายการฟีเจอร์ Phase 1 สุดท้ายยังเป็น **[OPEN]** (ข้อ 50 #30)
- ร่าง schema **[DIRECTION]** รอทีมตรวจ อยู่ที่ `docs/database/`:
  - `schema.sql`
  - `seed.sql` (mock data ที่แต่งขึ้น)
  - `rls.sql`
  - `checks.sql`

#### 60.11.3 ฐานข้อมูล: PostgreSQL

**[CONFIRMED]** ยกระดับจาก [DIRECTION] ในข้อ 50 #24 และ 60.5 เหตุผล:
- **Row-Level Security:** กันข้อมูลนักเรียนข้ามองค์กรได้ในระดับฐานข้อมูล เป็นชั้นที่สองต่อจาก guard ของ API (ข้อ 60.2)
- **Migration ย้อนกลับได้ทั้งชุด (transactional DDL):** เหมาะกับการปล่อยฟีเจอร์ถี่และให้ AI เขียน migration (ข้อ 60.10.8)
- **JSONB:** เก็บค่าตั้งของ Tool โดยไม่ hard-code (ข้อ 45)
- **timestamptz:** เก็บเวลาบันทึกจากระบบได้แม่น (ข้อ 60.10.5)
- **partial unique index และ exclusion constraint:** กันข้อมูลซ้ำซ้อนในระดับฐานข้อมูล เช่น หักเครดิตงานเดียวซ้ำ หรือนักเรียนอยู่ห้องเดียวกันซ้อนช่วงเวลา

### 60.12 บันทึกย้อนหลัง (28 Oct 2026)

**[DIRECTION]** ทีมยังไม่ได้คุยรายละเอียด จึงบันทึกไว้เป็นแนวคิดเพื่อใช้ออกแบบเท่านั้น ห้ามถือเป็นข้อสรุป · ขยายความข้อ 60.10.5

*(แก้โดยข้อ 60.13.4: ระบบใหม่ไม่มีบันทึกการลงมือทำ ให้นำแนวคิดนี้ไปใช้กับเรื่องเล่าใน Phase 2 · ตาราง `practice_logs` และ `practice_log_revisions` ที่อ้างด้านล่างเอาออกจากร่าง schema แล้ว ยังดูได้ใน git ที่ commit `b38ad71`)*

**ขอบเขต:** ใช้กับบันทึกการลงมือทำ (กด "ทำแล้ว" / "เลื่อน") ซึ่งเป็นหลักฐานที่นำไปทำรายงานและเอกสาร · Canvas ไม่เกี่ยว เพราะไม่มีช่องให้ผู้ใช้กรอกวันที่ ทุก version ใช้เวลาจากระบบ

**แนวคิด**
- บันทึกหนึ่งรายการเก็บเวลา 2 ค่าแยกกัน:
  - **เวลาบันทึก:** ระบบใส่ให้ ผู้ใช้ส่งมาเองไม่ได้และแก้ภายหลังไม่ได้
  - **วันที่ทำจริง:** ครูระบุได้ แต่เป็นวันในอนาคตไม่ได้
- ถ้าวันที่ทำจริงอยู่ก่อนวันที่บันทึก ระบบติดป้าย "บันทึกย้อนหลัง" ให้อัตโนมัติ และแสดงทั้งสองค่าคู่กันเสมอ
- แก้บันทึกได้ แต่ระบบเก็บประวัติการแก้ทุกครั้ง
- ระยะที่ย้อนได้เป็นค่าตั้ง ไม่ hard-code · ถ้าทีมเลือกไม่ให้ย้อนหลังเลย ให้ตั้งเป็น 0 วัน โดยไม่ต้องแก้ schema
- ที่มาของแนวคิด: ครูที่ลืมบันทึก 1–2 วันยังบันทึกได้ตรงวัน และผู้ตรวจยังเห็นว่ารายการไหนบันทึกย้อนหลัง
- ระบบเดิมให้ย้อนหลังได้เฉพาะงานรายสัปดาห์และไม่มีป้ายบอก (`docs/feature-spec/08-practice-log-story.md`)
- ร่าง schema ที่รองรับแนวคิดนี้: `practice_logs` (`happened_on`, `recorded_at`, `is_backdated`) และ `practice_log_revisions` ใน `docs/database/schema.sql`

**[OPEN] รายละเอียดที่ยังไม่ได้คุย**
- ข้อ 60.10.5 ที่เขียนว่า "ผู้ใช้ตั้งวันย้อนหลังเองไม่ได้" หมายถึงแบบไหน:
  - ห้ามปลอมเวลาบันทึก แต่ระบุวันที่ทำจริงได้ (แนวคิดนี้)
  - หรือห้ามระบุวันที่ทำเลย (วันที่ทำ = วันที่บันทึกเสมอ)
- ให้ย้อนได้นานเท่าไร
- ใช้กับงานประเภทไหน (รายสัปดาห์ หรือทำครั้งเดียว) และช่องทางไหน (เว็บ หรือ LINE)
- ใครเห็นป้ายบ้าง และแสดงอย่างไร: ครู, ผู้บริหาร, โค้ช, ผู้ตรวจภายนอก
- บันทึกย้อนหลังนับในรายงาน Dashboard และเอกสารที่ครูต้องส่งอย่างไร
- แก้วันที่ทำจริงหลังบันทึกไปแล้วได้หรือไม่
- ครูตอบข้อความเตือนใน LINE ข้ามวัน นับเป็นบันทึกย้อนหลังหรือไม่ (ข้อ 60.10.6)

### 60.13 ภาพปลายทาง UI และแผนระบบฉบับสร้างจริง (2 Nov 2026)

**[CONFIRMED]** ทีมทำภาพปลายทาง UI กับแผนระบบฉบับสร้างจริงเสร็จแล้ว และให้ใช้ทั้งสองอย่างเป็นหลักของขอบเขตและการออกแบบ ข้อนี้แทนหลายข้อเดิม ซึ่งติดหมายเหตุ "แก้โดยข้อ 60.13" ไว้ทุกจุดแล้ว

#### 60.13.1 แหล่งข้อมูลหลัก

**[CONFIRMED]**

- **ภาพปลายทาง SkillwisE:** 71 หน้า ได้แก่ หน้าอธิบายภาพรวม O0–O9 และหน้าจอกับ flow ที่แบ่งตาม Phase 1–5 · https://claude.ai/artifact/Tp729kFxPEdn9JdggbHrsT (เป็นลิงก์ส่วนตัว ต้องได้สิทธิ์จากทีมก่อนจึงเปิดได้)
- **แผนระบบฉบับสร้างจริง:** สรุปลง repo ไว้ที่ `docs/system-plan.md` · ตัดชื่อคนออก และปรับให้ตรงกับข้อนี้
- ถ้าข้อเดิมใน Context ขัดกับสองแหล่งนี้ ให้ยึดข้อ 60.13 ยกเว้นเรื่องที่ข้อ 60.13 ระบุว่ายังเป็น [OPEN]
- **ทุกครั้งที่ตัดสินเรื่องระบบใหม่ ต้องแก้ Context ไฟล์นี้ทันที** และยังบันทึกการตัดสินใจไว้ในข้อ 60 เหมือนเดิม ไม่แยกเป็นไฟล์ decisions อีกไฟล์

#### 60.13.2 หลักการออกแบบ

**[CONFIRMED]**

- **โค้ดเก่าที่คัดลอกมาจาก Sila5School ไม่ใช่หลักของระบบใหม่** (แก้เพิ่มข้อ 60.1 และ 60.11)
  - ออกแบบใหม่จากภาพปลายทางและแผนระบบ ไม่ดัดแปลงหรือต่อยอดจากโค้ด ตาราง หรือ flow เดิม
  - `reference/sila5school/`, `docs/feature-spec/` และ `docs/sila5school-study.md` เป็น [REFERENCE] ใช้เปิดดูเมื่ออยากรู้ว่าระบบเดิมเคยทำอะไร แต่ไม่ใช่แบบที่ต้องทำตาม
  - ข้อนี้ว่าด้วย**ตัวระบบ** (โค้ด ตาราง flow) · IP และ framework ด้านเนื้อหาตามข้อ 10 ยังใช้ได้ เช่น Canvas และแนวคิด Unlock Potential ซึ่งภาพปลายทางก็ใช้อยู่
- **ระบบต้องดูง่าย เข้าใจง่าย ใช้ง่าย สบายตา**
  - หน้าจอ: หน้าตายึดตามภาพปลายทาง และข้อความใช้ภาษาง่าย
  - โครงระบบและโครงข้อมูล: เลือกแบบที่เรียบง่ายที่สุดที่ยังทำงานถูกต้อง คนที่ไม่รู้จักระบบเดิมต้องอ่านเข้าใจได้
- **หลัก 5 ข้อที่โค้ดทุกส่วนต้องทำตาม**
  1. ราคาและกติกาสิทธิ์ต้องไม่อยู่ในโค้ด ทุกหน้าจอถามแค่ "บัญชีนี้มีสิทธิ์ X ไหม" หรือ "เหลือเครดิต Y เท่าไร" และคำตอบมาจากข้อมูลที่ทีมงานตั้งในหลังบ้าน
  2. รายการเงินและสิทธิ์ห้ามแก้ทับและห้ามลบ ทุกการเปลี่ยนแปลงต้องเป็นรายการใหม่ที่บันทึกผู้ทำ เวลา และเหตุผล
  3. ยืนยันการจ่ายเงินจากฝั่งผู้ให้บริการรับเงินเท่านั้น และเมื่อได้รับข้อความยืนยันซ้ำ ต้องไม่เปิดสิทธิ์ซ้ำ
  4. โครงข้อมูลของคน องค์กร สิทธิ์ เครดิต คำสั่งซื้อ และเอกสารการเงิน ต้องรองรับทั้งระบบตั้งแต่ Phase 1 ส่วนหน้าจอค่อยเพิ่มทีหลังได้
  5. แยกจาก Sila5School โดยสิ้นเชิง ไม่ใช้ฐานข้อมูล บัญชี หรือข้อมูลครูร่วมกัน ยกเว้นรายชื่อสถานศึกษาซึ่งเป็นข้อมูลสาธารณะ
- **ชื่อ:** แบรนด์เขียนว่า **SkillwisE** · ชื่อ repo และชื่อในโค้ดใช้ `skillwise` · ผู้ขายคือ บริษัท สกิลไวส์ จำกัด

#### 60.13.3 ขอบเขต Phase 1 (ตัดสินข้อ 50 #30)

**[CONFIRMED]**

- **หัวใจ 2 ระบบที่ต้องถูกตั้งแต่แรก:** (ก) สิทธิ์และเครดิต (ข) ซื้อขาย รับเงิน และเอกสารการเงิน
- **วันเปิด:** ยังไม่กำหนด แต่ต้องเสร็จให้เร็วที่สุด จึงแบ่งงานเป็นชิ้นที่ปล่อยได้ทีละชิ้น
- **หน้าบ้าน**
  - F1 หน้าแรก
  - F2 แนวคิด พร้อมวิดีโอฟรีและดาวน์โหลดฟอร์ม Canvas (ต้องสมัครก่อน)
  - F3 ร้านค้า พร้อมปุ่ม "แจ้งฉันเมื่อวางขาย"
  - F4 หน้าการ์ดจับดี
  - F6 อบรมครู (เวบินาร์ฟรี, onZoom แบบจ่ายเงิน, คิวสำรอง)
  - F8 สมัครและเข้าสู่ระบบ
  - F9 ชำระเงิน
  - F10 ขอใบเสนอราคา
  - F11 เปิดใช้รหัสในกล่อง
  - หน้า "ของฉัน" แบบย่อ และหน้านโยบาย
- **หลังบ้าน**
  - A1 ภาพรวมและกล่องงาน
  - A2 คำสั่งซื้อ
  - A3 เอกสารการเงิน
  - A4 ผู้ใช้และโรงเรียน
  - A5 อบรม (ย่อ)
  - A7 แพ็กเกจและสิทธิ์ (ย่อ)
  - A8 รหัสในกล่อง
  - A11 แม่แบบข้อความ (ย่อ)
  - บันทึกการเปลี่ยนแปลง
- **LINE:** ให้เพิ่มเพื่อนตอนสมัคร · มีเมนู · ส่งข้อความยืนยันคำสั่งซื้อ เลขพัสดุ เตือนให้เปิดใช้รหัส และยืนยันกับเตือนก่อนอบรม
- **ไม่อยู่ใน Phase 1:** เกม "ห้องนี้ต้องรอด" เพราะแนวคิดอาจเปลี่ยน
  - รหัสในกล่องยังไม่ให้สิทธิ์เกม และหน้าขายต้องไม่สัญญาเรื่องเกม
  - เมื่อเกมพร้อม ระบบมอบสิทธิ์ย้อนหลังให้ทุกคนที่เคยกดรหัสได้
- **ลำดับสร้าง:**
  1. ฐานระบบและระบบสิทธิ์
  2. ขายได้จริงด้วยการโอนเงินแนบสลิป
  3. รหัสในกล่องและเอกสารการเงิน
  4. เชื่อมระบบรับเงินและเปิดหน้าอบรม
- **Phase ถัดไป:** ให้ถือเป็นลำดับ ไม่ใช่วันที่ · มีเส้นตายเดียว คือคอร์สออนไลน์กับระบบจองที่นั่งแบบกองต้องพร้อมก่อนเวิร์กช็อป onZoom ที่นั่งฟรีต้น ก.พ. 2570 ถ้ายังจัดตามแผนเดิม
  - **Phase 2:** สมาชิก Pro, Canvas + โค้ช AI + ผลวิเคราะห์, เล่าผลผ่าน LINE + ไทม์ไลน์เด็ก, ห้องเรียน, คอร์สออนไลน์ที่นับเวลาดูจริงพร้อมแบบทดสอบและเกียรติบัตร, จองที่นั่งแบบกอง + เงื่อนไขก่อนอบรม + คิวสำรอง, สมุดพัฒนาตนเอง, ห้องตั้งค่าโค้ช
  - **Phase 3:** คลังสื่อ + โหมดสอนสด, ห้องตอบคำถาม, แพ็กเกจโรงเรียน + รายงาน + ผู้ชมภายนอก, แผนของโรงเรียน (หน้า C3 ในภาพปลายทาง), หน้าหมุนวงล้อ, เปิดจองสมุดบันทึกความสุข, ผู้ช่วยแอดมินแบบพิมพ์สั่ง
  - **Phase 4:** ยังว่าง
  - **Phase 5:** ลีกข้ามโรงเรียน, ตัดต่อวิดีโอ, วันเด็กเล่าการเติบโต, รายงานประจำปี, เกม (ถ้าแนวคิดนิ่งแล้ว)
  - รายละเอียดของแต่ละ Phase อยู่ใน `docs/system-plan.md` ส่วนที่ 9 และหน้าจอในภาพปลายทาง

#### 60.13.4 สิ่งที่เปลี่ยนจากข้อเดิม

**[CONFIRMED]**

| เรื่อง | เดิม | ตอนนี้ |
|---|---|---|
| โค้ชที่เป็นคน (ข้อ 16, 24, 30, 48 และ Coach Dashboard) | เป็นแกนของการพัฒนาทักษะ | ไม่อยู่ในแผน Phase 1–5 · "โค้ช" ในภาพปลายทางคือโค้ช AI ที่ช่วยครูคิด Canvas (Phase 2) |
| แผนลงมือทำรายสัปดาห์และบันทึก (ข้อ 48, 60.10.4) | เป็นวงจรหลัก | ไม่มีแล้ว · Phase 2 ใช้ "เรื่องเล่า" ผ่าน LINE + ไทม์ไลน์เด็กแทน (โหมดสอนสดอยู่ Phase 3) · กติกา "เวลาบันทึกมาจากระบบ" และ "เก็บประวัติการแก้" (60.10.5) รวมถึงแนวคิดบันทึกย้อนหลัง (60.12) ย้ายไปใช้กับเรื่องเล่า |
| แผนพัฒนา | ครูทำแผนเองจาก Canvas | เป็นแผนของโรงเรียน 4 ส่วน รวมจาก Canvas ที่ครูแชร์ (Phase 3) |
| ข้อมูลนักเรียน (ข้อ 60.2, 60.7) | เก็บชื่อ นามสกุล ชั้น ห้อง · บุคลากรในโรงเรียนและโค้ชเห็นได้ | **ใช้ชื่อเล่นหรือชื่อที่ครูตั้งเอง** ไม่ต้องมีนามสกุลหรือเลขประจำตัว · เด็กเป็นข้อมูลของห้องเรียนหรือโรงเรียน ไม่ใช่ของครู · เห็นได้เฉพาะครูที่ดูแลห้อง · ทีมงานไม่เห็นเรื่องเล่าและไทม์ไลน์ของเด็ก · คนนอกเห็นแค่ตัวเลขรวม · นักเรียนไม่มีบัญชี · ครูต้องยืนยันว่าโรงเรียนแจ้งผู้ปกครองแล้วก่อนเปิดห้องแรก · ทั้งหมดนี้เป็นงาน Phase 2 |
| ตัดชื่อก่อนส่ง AI (ข้อ 60.2) | ตัดชื่อจริงออกทุกครั้ง | **เหมือนเดิม** และใช้กับชื่อเล่นด้วย · **ขัดกับภาพปลายทาง:** หน้า L1 ให้ "AI จับชื่อเด็กเทียบรายชื่อห้อง" ซึ่งต้องส่งชื่อให้ AI · ยึดข้อ 60.2 และต้องแก้ภาพปลายทางให้ตรง · **[DIRECTION]** ระบบจับชื่อจากรายชื่อในห้องเอง แล้วแทนด้วยรหัสก่อนส่งให้ AI |
| Set Package 10/20/30 (ข้อ 60.8) | ซื้อเป็นชุดแล้วแจก seat | **[DIRECTION]** ภาพปลายทางและแผนระบบไม่พูดถึง · เสนอให้นับเป็นแพ็กเกจโรงเรียนแบบหนึ่ง ซึ่งให้ที่นั่ง Pro ตามจำนวน (Phase 3) · ขนาด ราคา และใครซื้อได้ยัง [OPEN] |
| ร่างฐานข้อมูล MVP (ข้อ 60.11.2) | ครอบคลุม Must + Should จากหัวข้อ 8 ของเอกสารศึกษา | ร่างใหม่ตามโครงข้อมูลของแผนระบบ (Phase 1) · เอาตารางวงจรเดิม 38 ตารางและตารางนักเรียน 3 ตารางออก ยังดูได้ใน git ที่ commit `b38ad71` · ตาราง Phase 2 ขึ้นไปออกแบบใหม่เมื่อถึง Phase นั้น โดยต้องไม่ออกแบบ Phase 1 ให้ขวางทาง |

#### 60.13.5 แพ็กเกจ ราคา และกติกาสิทธิ์

**[DIRECTION]** ค่าตั้งต้นจากภาพปลายทางและแผนระบบ

> **ราคาและตัวเลขทั้งหมดในข้อนี้เป็นข้อมูลตัวอย่าง (mockup) และเปลี่ยนแปลงได้** ค่าจริงตั้งในหลังบ้าน (A7) และห้ามเขียนตายในโค้ด (ข้อ 47, 53)

| แพ็กเกจ | ค่าตั้งต้น (ตัวอย่าง) |
|---|---|
| สมาชิกฟรี | ห้องเรียน 1 ห้อง · เล่าผลผ่าน LINE ไม่จำกัด · โค้ช 2 รอบและวิเคราะห์ Canvas 2 ครั้ง ใช้ได้ตลอด · คอร์สบทแรกพร้อมเกียรติบัตร · บทสื่อตัวอย่าง |
| Pro รายปี | 990 บาท/ปี · ห้องเรียนไม่จำกัด · คอร์สและบทสื่อครบทุกบท · ส่งออก PDF · โค้ช 10 รอบและวิเคราะห์ 5 ครั้งต่อเดือน · ได้ที่นั่ง onZoom ฟรีตามเงื่อนไข และลด 30% สำหรับที่นั่งแบบจ่ายเงิน |
| Pro รายเดือน | 200 บาท/เดือน ตัดบัตรอัตโนมัติ · ได้เหมือนรายปีทุกอย่าง ยกเว้นที่นั่งฟรี |
| การ์ดจับดีพร้อมรหัสในกล่อง | ราว 500 บาท/ชุด · รหัสให้วิดีโอสาธิต, คู่มือครู PDF ที่พิมพ์ชื่อครูกำกับ, Pro 3 เดือน และคูปองลด 30% สำหรับเวิร์กช็อป onZoom 1 ครั้ง |
| ชุดเติม | เช่น 10 รอบ 99 บาท ใช้ได้ 12 เดือน · เติมได้ทั้งรอบโค้ชและรอบวิเคราะห์ |
| สมุดบันทึกความสุข | ขายให้โรงเรียน ขั้นต่ำ 20 เล่ม · แถม Teacher Edition และห้องเรียนออนไลน์ 1 ห้องตลอดปีการศึกษา |
| อบรม | onZoom 900 บาท (ผู้ซื้อการ์ดจ่าย 630) · onSite ประกาศราว 9,000 บาท แบ่งเป็นจองเร็ว 25 ที่และจับรางวัล 25 ที่ |
| แพ็กเกจโรงเรียน | ให้ที่นั่ง Pro ตามจำนวนพร้อมรายงาน · ราคาเป็น [OPEN] (Phase 3) |

**กติกาหลัก** (รายละเอียดอยู่ใน `docs/system-plan.md`)
- **เครดิต**
  - รอบเครดิตรายเดือนนับจากวันเริ่ม Pro ไม่ใช่ตามเดือนปฏิทิน
  - หักจากก้อนที่หมดอายุก่อนก่อน และยอดติดลบไม่ได้
  - หักในธุรกรรมเดียวกับการเริ่มงาน ถ้างาน AI ผิดพลาด ระบบคืนเครดิตให้อัตโนมัติ
- **Pro จากรหัสในกล่อง:** เริ่มนับจากวันที่ช้ากว่า ระหว่างวันกดรหัสกับวันเปิดระบบ Pro
- **Pro หมดอายุ:** กลับเป็นสมาชิกฟรี ข้อมูลยังอยู่ครบ · ห้องที่เกินสิทธิ์เปิดดูได้แต่เพิ่มเรื่องใหม่ไม่ได้
- **ส่วนลด:** ไม่ซ้อนกัน ระบบใช้ส่วนลดที่ดีที่สุดเพียงแบบเดียว
- **เงิน:** เก็บเป็นหน่วยสตางค์ (จำนวนเต็ม)
- **คำสั่งซื้อ:** เก็บสำเนาราคาและข้อมูล ณ ตอนซื้อ
- **เอกสารการเงิน:** เลขที่เอกสารเรียงต่อเนื่อง ไม่ข้ามและไม่ซ้ำ

#### 60.13.6 เครื่องมือและ Tech Stack

**[CONFIRMED — 2 Nov 2026]** ทีมทบทวนข้อเสนอในแผนระบบแล้ว (Next.js ตัวเดียว + Auth.js + Inngest + Vercel) และ**เลือกคงข้อ 60.5: Next.js (หน้าบ้าน) + NestJS (หลังบ้าน) ใน monorepo**
- ส่วนเครื่องมือและโครงโฟลเดอร์ใน `docs/system-plan.md` ปรับให้ตรงกับข้อ 60.5 แล้ว
- module ใน `apps/api` แบ่งตามเรื่องในแผนระบบ: `identity`, `org`, `entitlements`, `commerce`, `payments`, `documents`, `codes`, `events`, `notify`, `audit`
- คิวงานเบื้องหลังใช้ BullMQ + Redis ตามข้อ 60.5 · ใช้ pg-boss แทน Redis ได้ตามที่ข้อ 60.5 (ส่วนประกอบ) อนุญาตไว้ แต่ต้องเขียนเชื่อมกับ NestJS เอง
- การหักเครดิต กันสต็อก และออกเลขที่เอกสาร **ต้องล็อกแถวในธุรกรรมเดียว** ตามแผนระบบส่วนที่ 5.4 และ 6.1
  - **[DIRECTION]** วิธีทำตอนนี้คือฟังก์ชัน SQL ใน `docs/database/schema.sql` เพราะ Prisma ยังไม่มีคำสั่งล็อกแถว (`SELECT … FOR UPDATE`) ในตัว

**[REFERENCE]** ผลประเมินภาษาหลังบ้านโดย Claude (2 Nov 2026) ซึ่งทีมใช้ประกอบการตัดสิน
- แนะนำคง TypeScript + NestJS
- อันดับ 2 คือ PHP + Laravel คะแนนใกล้กันมาก Laravel จะชนะถ้าให้น้ำหนักความเร็วในการทำหลังบ้านกับความถนัด PHP มากกว่าการใช้ภาษาเดียวทั้งระบบ
- ไม่แนะนำ Next.js ตัวเดียว เพราะ logic เงินและสิทธิ์จะปนกับหน้าจอ และงานเบื้องหลังต้องพึ่งบริการภายนอก

**[DIRECTION]** ข้อเสนอในแผนระบบที่ไม่ขัดกับข้อ 60.5 นำมาใช้ได้
- PostgreSQL แบบมีผู้ดูแลที่สิงคโปร์, Cloudflare R2, Playwright + pdf-lib + ฟอนต์ Sarabun, Resend, Sentry
- staging ใช้กุญแจทดสอบของระบบรับเงิน และห้ามทดสอบเงินบนระบบจริง
- ผู้ให้บริการรับเงิน: ยื่นสมัคร Stripe และ Opn พร้อมกัน แล้วเลือกเจ้าเดียวเมื่อได้คำตอบ 3 เรื่อง
  1. ตัดบัตรรายเดือนกับบัตรไทยที่ต้องยืนยันตัวตนได้จริงไหม
  2. คืนเงินพร้อมเพย์ผ่านระบบได้ไหม
  3. ค่าธรรมเนียมจริงเท่าไร
- เขียนโค้ดผ่านตัวเชื่อมผู้ให้บริการรับเงินชั้นเดียว เพื่อเปลี่ยนเจ้าได้โดยไม่แก้ส่วนอื่น
- ระหว่างรออนุมัติ เปิดขายด้วยการโอนเงินแนบสลิปไปก่อน
- Payment Gateway และ Hosting ยังเป็น [OPEN]

#### 60.13.7 เอกสารใน repo

**[CONFIRMED]**

- repo เป็น public จึงลงตัวเลขธุรกิจได้ในฐานะข้อมูลตัวอย่าง (mockup) แต่ต้องมีข้อความกำกับว่าเปลี่ยนแปลงได้ · ห้ามลงชื่อคน
- ไฟล์ Context เปลี่ยนชื่อเป็น `docs/SkillwisE-Canonical-Context-updated.md`

#### 60.13.8 สิ่งที่ยัง OPEN

**[OPEN]**

- **ข้อมูลธุรกิจที่ยังไม่มี**
  - เลขผู้เสียภาษี ที่อยู่จดทะเบียน และบริษัทจด VAT แล้วหรือยัง
  - บัญชีธนาคารสำหรับรับโอน
  - ราคาการ์ดชุดโรงเรียน ค่าส่ง และจำนวนสต็อก
  - โดเมน, LINE OA และอีเมลติดต่อ
  - วันเวลาอบรมและจำนวนที่นั่ง
  - นโยบายความเป็นส่วนตัว ข้อกำหนดการใช้ และนโยบายคืนเงิน ซึ่งต้องมีก่อนเริ่มรับเงินจริง
  - ไฟล์คู่มือครูและวิดีโอสาธิต
  - ราคาแพ็กเกจโรงเรียน
- **กติกาที่แผนระบบเสนอค่าเริ่มต้นไว้ รอทีมยืนยัน**
  - มี Pro รายเดือนอยู่แล้วกดรหัสในกล่อง
  - 1 บัญชีกดรหัสในกล่องได้ 1 รหัส
  - ตัดบัตรรายเดือนไม่ผ่าน
  - ยกเลิกคำสั่งซื้อการ์ด
  - ยกเลิกที่นั่งเวิร์กช็อป
  - ขอบเขตคูปอง 30% ของผู้ซื้อการ์ด
- **คำถามเรื่องสิทธิ์**
  - Pro ที่ได้จากรหัสในกล่องได้ที่นั่ง onZoom ฟรีด้วยไหม
  - ผู้สั่งสมุดได้ Pro 3 เดือนไหม
  - คูปองของผู้ซื้อการ์ดมีอายุเท่าไร
- ค่า onSite รวมที่พักและอาหารหรือไม่
- Set Package: ขนาด ราคา และใครซื้อได้
- แก้หน้า L1 ในภาพปลายทางให้ตรงกับกฎตัดชื่อเด็กก่อนส่ง AI (ข้อ 60.13.4)
- ทีมงานเข้าถึงข้อมูลเด็กอย่างไรเมื่อทำ support หรือรับคำขอลบข้อมูล
- Phase 4 จะมีงานอะไร

---

**END OF CANONICAL CONTEXT**
