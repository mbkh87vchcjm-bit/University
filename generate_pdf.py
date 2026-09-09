import sys
import os
import arabic_reshaper
from bidi.algorithm import get_display

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak, HRFlowable, KeepTogether
)
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

pdfmetrics.registerFont(TTFont('Amiri', '/tmp/Amiri-Regular.ttf'))
pdfmetrics.registerFont(TTFont('Amiri-Bold', '/tmp/Amiri-Bold.ttf'))

def ar(text):
    if not text:
        return ""
    reshaped = arabic_reshaper.reshape(text)
    return get_display(reshaped)

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_header_footer(num_pages)
            super().showPage()
        super().save()

    def draw_header_footer(self, page_count):
        self.saveState()
        if self._pageNumber > 1:
            # Header
            self.setFont('Amiri', 9)
            self.setFillColor(colors.HexColor('#37474F'))
            self.drawString(54, 802, ar("جامعة الحكمة | مشروع معمارية الحاسوب - Mini Processor Datapath"))
            self.setStrokeColor(colors.HexColor('#0D47A1'))
            self.setLineWidth(0.8)
            self.line(54, 794, 541, 794)

            # Footer
            self.line(54, 45, 541, 45)
            self.setFont('Amiri', 9)
            page_text = ar(f"صفحة {self._pageNumber} من {page_count}")
            self.drawRightString(541, 30, page_text)
            self.drawString(54, 30, ar("إعداد: محمد الفقيه وحازم الطيري | إشراف: الأستاذة القديرة ذكرى"))
        self.restoreState()

def build_pdf(filename="/app/المشروع_النهائي_معمارية_حاسوب.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=A4,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    title_style = ParagraphStyle(
        'TitleStyle',
        fontName='Amiri-Bold',
        fontSize=24,
        leading=32,
        alignment=TA_CENTER,
        textColor=colors.HexColor('#0D47A1')
    )

    subtitle_style = ParagraphStyle(
        'SubTitleStyle',
        fontName='Amiri-Bold',
        fontSize=16,
        leading=24,
        alignment=TA_CENTER,
        textColor=colors.HexColor('#1565C0')
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        fontName='Amiri-Bold',
        fontSize=14,
        leading=20,
        alignment=TA_RIGHT,
        textColor=colors.HexColor('#0D47A1'),
        spaceBefore=8,
        spaceAfter=4
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        fontName='Amiri-Bold',
        fontSize=11.5,
        leading=16,
        alignment=TA_RIGHT,
        textColor=colors.HexColor('#1565C0'),
        spaceBefore=6,
        spaceAfter=3
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        fontName='Amiri',
        fontSize=9.5,
        leading=15,
        alignment=TA_RIGHT,
        textColor=colors.HexColor('#212121'),
        spaceAfter=4
    )

    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        fontName='Amiri',
        fontSize=9,
        leading=14,
        alignment=TA_RIGHT,
        textColor=colors.HexColor('#37474F'),
        spaceAfter=3
    )

    table_text_style = ParagraphStyle(
        'TableText',
        fontName='Amiri',
        fontSize=8.5,
        leading=12,
        alignment=TA_CENTER,
        textColor=colors.HexColor('#212121')
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        fontName='Amiri-Bold',
        fontSize=9,
        leading=13,
        alignment=TA_CENTER,
        textColor=colors.white
    )

    story = []

    # ==================== PAGE 1: COVER PAGE ====================
    story.append(Spacer(1, 15))
    story.append(Paragraph(ar("الجمهورية اليمنية"), ParagraphStyle('Cov1', fontName='Amiri-Bold', fontSize=12, leading=16, alignment=TA_CENTER, textColor=colors.HexColor('#37474F'))))
    story.append(Paragraph(ar("وزارة التعليم العالي والبحث العلمي"), ParagraphStyle('Cov2', fontName='Amiri-Bold', fontSize=12, leading=16, alignment=TA_CENTER, textColor=colors.HexColor('#37474F'))))
    story.append(Paragraph(ar("جامعة الحكمة - كلية الهندسة وتقنية المعلومات"), ParagraphStyle('Cov3', fontName='Amiri-Bold', fontSize=16, leading=22, alignment=TA_CENTER, textColor=colors.HexColor('#0D47A1'))))
    story.append(Paragraph(ar("قسم تقنية المعلومات وعلم الحاسوب (IT & CS) - المستوى الثاني"), ParagraphStyle('Cov4', fontName='Amiri-Bold', fontSize=11, leading=15, alignment=TA_CENTER, textColor=colors.HexColor('#455A64'))))

    story.append(Spacer(1, 20))
    story.append(HRFlowable(width="85%", thickness=2.5, color=colors.HexColor('#0D47A1'), spaceBefore=5, spaceAfter=20))

    story.append(Paragraph(ar("تقرير المشروع النهائي لمادة معمارية وحاسوب (عملي)"), subtitle_style))
    story.append(Spacer(1, 12))
    story.append(Paragraph(ar("تصميم مسار بيانات معالج مصغر 4-بت"), title_style))
    story.append(Spacer(1, 6))
    story.append(Paragraph(ar("(Mini Processor Datapath Implementation using Logisim Evolution)"), ParagraphStyle('CovSub', fontName='Amiri-Bold', fontSize=13, leading=17, alignment=TA_CENTER, textColor=colors.HexColor('#2E7D32'))))

    story.append(HRFlowable(width="85%", thickness=2.5, color=colors.HexColor('#0D47A1'), spaceBefore=20, spaceAfter=25))
    story.append(Spacer(1, 20))

    # Meta Table
    meta_data = [
        [Paragraph(ar("2026 م / 1447 هـ"), ParagraphStyle('M1', fontName='Amiri-Bold', fontSize=11, alignment=TA_CENTER, textColor=colors.HexColor('#0D47A1'))),
         Paragraph(ar("العام الدراسي:"), ParagraphStyle('M2', fontName='Amiri-Bold', fontSize=11, alignment=TA_RIGHT, textColor=colors.HexColor('#37474F')))],
        [Paragraph(ar("محمد الفقيه  |  حازم الطيري"), ParagraphStyle('M3', fontName='Amiri-Bold', fontSize=12, alignment=TA_CENTER, textColor=colors.HexColor('#1B5E20'))),
         Paragraph(ar("إعداد الطالبين:"), ParagraphStyle('M4', fontName='Amiri-Bold', fontSize=11, alignment=TA_RIGHT, textColor=colors.HexColor('#37474F')))],
        [Paragraph(ar("الأستاذة القديرة / ذكرى الحسيني"), ParagraphStyle('M5', fontName='Amiri-Bold', fontSize=12, alignment=TA_CENTER, textColor=colors.HexColor('#B71C1C'))),
         Paragraph(ar("تحت إشراف:"), ParagraphStyle('M6', fontName='Amiri-Bold', fontSize=11, alignment=TA_RIGHT, textColor=colors.HexColor('#37474F')))]
    ]

    t_meta = Table(meta_data, colWidths=[270, 110])
    t_meta.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F5F7FA')),
        ('BOX', (0,0), (-1,-1), 1.5, colors.HexColor('#0D47A1')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CFD8DC')),
        ('PADDING', (0,0), (-1,-1), 8),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(t_meta)

    story.append(PageBreak())

    # ==================== PAGE 2: INTRODUCTION & LOGIC EQUATIONS ====================
    story.append(Paragraph(ar("1. مقدمة وفكرة المشروع"), h1_style))
    story.append(Paragraph(ar("يهدف هذا المشروع إلى تطبيق المفاهيم العملية المتقدمة لمادة معمارية الحاسوب من خلال بناء مسار بيانات لمعالج رقمي مصغر (Mini Processor Datapath) بعرض بيانات 4-بت باستعمال برنامج Logisim Evolution. يربط التصميم بين وحدة الحساب والمنطق (ALU) المطورة من مشروع النصف الأول، ووحدات التخزين التتابع المقيدة بالساعة (Registers)، بالإضافة إلى وحدة التحكم (Control Unit) ومفكك الترميز (Decoder)."), body_style))

    story.append(Paragraph(ar("2. المكونات الوظيفية للنظام"), h1_style))
    story.append(Paragraph(ar("• وحدة الحساب والمنطق (ALU): تنفيذ العمليات الحسابية والمنطقية الأساسية (AND, OR, XOR, ADD, SUB)."), bullet_style))
    story.append(Paragraph(ar("• المسجلات (Registers): تشمل Register A و Register B لتخزين المدخلات، و Result Register لتخزين النتائج عند حافة نبضة الساعة (Clock)."), bullet_style))
    story.append(Paragraph(ar("• وحدة التحكم (Control Unit) ومفكك الترميز (Decoder): تحويل شفرة Opcode (بعرض 3-بت) إلى إشارات تحكم دقيقة (Control Signals) لتشغيل المسجلات والـ ALU."), bullet_style))

    story.append(Spacer(1, 4))
    story.append(Paragraph(ar("3. المعادلات المنطقية وجداول الحقيقة للدوائر الأساسية"), h1_style))
    story.append(Paragraph(ar("3.1 دائرة الجامع الكامل (Full Adder)"), h2_style))
    story.append(Paragraph(ar("المعادلات المنطقية الأساسية للجامع الكامل هي:"), body_style))
    story.append(Paragraph("Sum = A ⊕ B ⊕ Cin", ParagraphStyle('Eq1', fontName='Helvetica-Bold', fontSize=10, leading=14, alignment=TA_LEFT, textColor=colors.HexColor('#1565C0'))))
    story.append(Paragraph("Cout = (A ⋅ B) + (Cin ⋅ (A ⊕ B))", ParagraphStyle('Eq2', fontName='Helvetica-Bold', fontSize=10, leading=14, alignment=TA_LEFT, textColor=colors.HexColor('#1565C0'))))

    story.append(Spacer(1, 3))
    # Full Adder Truth Table
    fa_headers = [Paragraph(ar("Cout"), table_header_style), Paragraph(ar("Sum"), table_header_style), Paragraph(ar("Cin"), table_header_style), Paragraph(ar("B"), table_header_style), Paragraph(ar("A"), table_header_style)]
    fa_data = [
        fa_headers,
        [Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style)],
        [Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style)],
        [Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("0", table_text_style)],
        [Paragraph("1", table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("1", table_text_style)],
        [Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("1", table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style)],
        [Paragraph("1", table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style)],
        [Paragraph("1", table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("1", table_text_style), Paragraph("0", table_text_style)],
        [Paragraph("1", table_text_style), Paragraph("1", table_text_style), Paragraph("1", table_text_style), Paragraph("1", table_text_style), Paragraph("1", table_text_style)],
    ]
    t_fa = Table(fa_data, colWidths=[65, 65, 65, 65, 65])
    t_fa.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#0D47A1')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#0D47A1')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#BDBDBD')),
        ('PADDING', (0,0), (-1,-1), 2.5),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(t_fa)

    story.append(PageBreak())

    # ==================== PAGE 3: OPCODE TABLE & SUB-DIAGRAMS ====================
    story.append(Paragraph(ar("4. جدول أفراد Opcode والعمليات المقابلة وإشارات التحكم"), h1_style))
    story.append(Paragraph(ar("تستقبل وحدة التحكم شفرة Opcode وتترجمها عبر مفكك الترميز (Decoder 3:8) للتحكم المباشر في الناخب (Multiplexer) وحالة التخزين وإشارة الطرح:"), body_style))

    opcode_headers = [
        Paragraph(ar("شرح وتوصيف العملية"), table_header_style),
        Paragraph(ar("إشارة الطرح Sub"), table_header_style),
        Paragraph(ar("الكتابة RegWrite"), table_header_style),
        Paragraph(ar("محدد ALU_Sel"), table_header_style),
        Paragraph(ar("العملية (Operation)"), table_header_style),
        Paragraph(ar("كود Opcode"), table_header_style)
    ]

    opcode_data = [
        opcode_headers,
        [Paragraph(ar("عملية AND منطقية بت مقابل بت"), table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("000", table_text_style), Paragraph("AND", table_text_style), Paragraph("000", table_text_style)],
        [Paragraph(ar("عملية OR منطقية بت مقابل بت"), table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("001", table_text_style), Paragraph("OR", table_text_style), Paragraph("001", table_text_style)],
        [Paragraph(ar("عملية XOR منطقية (عدم التماثل)"), table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("010", table_text_style), Paragraph("XOR", table_text_style), Paragraph("010", table_text_style)],
        [Paragraph(ar("جمع حسابي ثنائي 4-بت (A + B)"), table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("011", table_text_style), Paragraph("ADD", table_text_style), Paragraph("011", table_text_style)],
        [Paragraph(ar("طرح حسابي بمتمم أثنين (A - B)"), table_text_style), Paragraph("1", table_text_style), Paragraph("1", table_text_style), Paragraph("100", table_text_style), Paragraph("SUB", table_text_style), Paragraph("100", table_text_style)],
        [Paragraph(ar("غير مستخدم (RESERVED)"), table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("101", table_text_style), Paragraph("NOP", table_text_style), Paragraph("101", table_text_style)],
        [Paragraph(ar("غير مستخدم (RESERVED)"), table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("110", table_text_style), Paragraph("NOP", table_text_style), Paragraph("110", table_text_style)],
        [Paragraph(ar("غير مستخدم (RESERVED)"), table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("111", table_text_style), Paragraph("NOP", table_text_style), Paragraph("111", table_text_style)],
    ]

    t_opcode = Table(opcode_data, colWidths=[130, 60, 65, 65, 75, 65])
    t_opcode.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1B5E20')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#1B5E20')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#BDBDBD')),
        ('PADDING', (0,0), (-1,-1), 3),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(t_opcode)

    story.append(Spacer(1, 6))
    story.append(Paragraph(ar("5. مخططات وتصميمات Logisim Evolution للوحدات الفرعية"), h1_style))
    story.append(Paragraph(ar("5.1 مخطط الجامع الكامل (Full Adder Subcircuit)"), h2_style))
    story.append(Image('/app/diagrams/full_adder.png', width=360, height=160))

    story.append(Spacer(1, 4))
    story.append(Paragraph(ar("5.2 تصميم وحدة المسجلات (Registers Block)"), h2_style))
    story.append(Image('/app/diagrams/registers.png', width=360, height=160))

    story.append(PageBreak())

    # ==================== PAGE 4: DECODER, CONTROL UNIT & ALU DIAGRAMS ====================
    story.append(Paragraph(ar("5.3 تصميم مفكك الترميز (Decoder 3:8 Subcircuit)"), h2_style))
    story.append(Image('/app/diagrams/decoder.png', width=360, height=160))

    story.append(Spacer(1, 6))
    story.append(Paragraph(ar("5.4 تصميم وحدة التحكم (Control Unit Subcircuit)"), h2_style))
    story.append(Image('/app/diagrams/control_unit.png', width=360, height=160))

    story.append(Spacer(1, 6))
    story.append(Paragraph(ar("5.5 تصميم وحدة الحساب والمنطق (ALU 4-Bit Subcircuit)"), h2_style))
    story.append(Image('/app/diagrams/alu.png', width=380, height=180))

    story.append(PageBreak())

    # ==================== PAGE 5: TOP SYSTEM DIAGRAM ====================
    story.append(Paragraph(ar("5.6 المخطط الشامل لبنية مسار البيانات (Mini Processor Datapath)"), h1_style))
    story.append(Paragraph(ar("يعرض المخطط المعماري الهيكلي كيفية التزامن والربط بين جميع المكونات الفرعية:"), body_style))
    story.append(Image('/app/diagrams/top_system.png', width=450, height=220))

    story.append(Spacer(1, 10))
    story.append(Paragraph(ar("5.7 تطبيق المشروع في برنامج Logisim Evolution (الدارة المنفذة بالمختبر)"), h1_style))
    story.append(Paragraph(ar("الصورة التالية تمثل التصميم التطبيقي المباشر والمكتمل للمشروع على برنامج Logisim Evolution وتوضح توصيل المسجلات والـ ALU ومفكك الترميز ولمبات LED:"), body_style))
    story.append(Image('/app/diagrams/logisim_circuit_photo.jpg', width=450, height=210))

    story.append(PageBreak())

    # ==================== PAGE 6: STEPS & CONCLUSION ====================
    story.append(Paragraph(ar("6. خطوات تشغيل ودورة تنفيذ الأمر (Execution Cycle)"), h1_style))
    story.append(Paragraph(ar("1. تحميل البيانات (Fetch & Load): ضبط المدخلات Input A و Input B وتفعيل نبضة الساعة لتخزينها في Register A و Register B."), bullet_style))
    story.append(Paragraph(ar("2. فك شفرة الأمر (Decode): يُدخل كود Opcode (مثل 011 للجمع)، فيصدر Decoder الإشارة المناسبة لتوجيه الناخب وتفعيل RegWrite."), bullet_style))
    story.append(Paragraph(ar("3. التنفيذ بالـ ALU (Execute): تُجري الـ ALU العملية الحسابية أو المنطقية، ويختار MUX النتيجة مع إشارات Zero و Carry Flags."), bullet_style))
    story.append(Paragraph(ar("4. التخزين النهائي (Write Back): تقوم النبضة التالية للساعة بتخزين النتيجة النهائية في Result Register لعرضها عبر الشاشة الثنائية."), bullet_style))

    story.append(Spacer(1, 12))
    story.append(Paragraph(ar("7. الخاتمة والاستنتاج"), h1_style))
    story.append(Paragraph(ar("تم بفضل الله وتوفيقه بناء واختبار مسار البيانات المعالجي المصغر 4-بت بنجاح تام. أثبتت التجارب على برنامج Logisim Evolution استجابة النظام الدقيقة لجميع الأوامر الحسابية والمنطقية المحددة في جدول Opcode، وتحقق التزامن المثالي مع نبضات الساعة، مما يقدم نموذجاً عملياً واضحاً لمعمارية المعالجات الحديثة."), body_style))

    # Build Document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF successfully generated at {filename}")

build_pdf()
