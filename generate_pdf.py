import sys
import os
import arabic_reshaper
from bidi.algorithm import get_display

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak, HRFlowable
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
            self.setFillColor(colors.HexColor('#424242'))
            self.drawString(54, 800, ar("جامعة الحكمة | مشروع معمارية الحاسوب - Mini Processor Datapath"))
            self.setStrokeColor(colors.HexColor('#BDBDBD'))
            self.setLineWidth(0.5)
            self.line(54, 792, 541, 792)

            # Footer
            self.line(54, 45, 541, 45)
            self.setFont('Amiri', 9)
            page_text = ar(f"صفحة {self._pageNumber} من {page_count}")
            self.drawRightString(541, 30, page_text)
            self.drawString(54, 30, ar("إعداد: محمد الفقيه وحازم الطيري | إشراف: أ. ذكرى"))
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
        fontSize=26,
        leading=34,
        alignment=TA_CENTER,
        textColor=colors.HexColor('#1A237E')
    )

    subtitle_style = ParagraphStyle(
        'SubTitleStyle',
        fontName='Amiri-Bold',
        fontSize=18,
        leading=26,
        alignment=TA_CENTER,
        textColor=colors.HexColor('#283593')
    )

    h1_style = ParagraphStyle(
        'Heading1_Custom',
        fontName='Amiri-Bold',
        fontSize=16,
        leading=22,
        alignment=TA_RIGHT,
        textColor=colors.HexColor('#0D47A1'),
        spaceBefore=12,
        spaceAfter=6
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        fontName='Amiri-Bold',
        fontSize=13,
        leading=18,
        alignment=TA_RIGHT,
        textColor=colors.HexColor('#1565C0'),
        spaceBefore=8,
        spaceAfter=4
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        fontName='Amiri',
        fontSize=11,
        leading=17,
        alignment=TA_RIGHT,
        textColor=colors.HexColor('#212121'),
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        fontName='Amiri',
        fontSize=10.5,
        leading=16,
        alignment=TA_RIGHT,
        textColor=colors.HexColor('#37474F'),
        spaceAfter=4
    )

    table_text_style = ParagraphStyle(
        'TableText',
        fontName='Amiri',
        fontSize=10,
        leading=14,
        alignment=TA_CENTER,
        textColor=colors.HexColor('#212121')
    )

    table_header_style = ParagraphStyle(
        'TableHeader',
        fontName='Amiri-Bold',
        fontSize=10.5,
        leading=14,
        alignment=TA_CENTER,
        textColor=colors.white
    )

    story = []

    # ==================== PAGE 1: COVER PAGE ====================
    story.append(Spacer(1, 20))
    story.append(Paragraph(ar("الجمهورية اليمنية"), ParagraphStyle('Cov1', fontName='Amiri-Bold', fontSize=12, leading=16, alignment=TA_CENTER, textColor=colors.HexColor('#37474F'))))
    story.append(Paragraph(ar("وزارة التعليم العالي والبحث العلمي"), ParagraphStyle('Cov2', fontName='Amiri-Bold', fontSize=12, leading=16, alignment=TA_CENTER, textColor=colors.HexColor('#37474F'))))
    story.append(Paragraph(ar("جامعة الحكمة - كلية الهندسة وتقنية المعلومات"), ParagraphStyle('Cov3', fontName='Amiri-Bold', fontSize=14, leading=18, alignment=TA_CENTER, textColor=colors.HexColor('#0D47A1'))))
    story.append(Paragraph(ar("قسم تقنية المعلومات وعلم الحاسوب (IT & CS) - المستوى الثاني"), ParagraphStyle('Cov4', fontName='Amiri', fontSize=11, leading=15, alignment=TA_CENTER, textColor=colors.HexColor('#455A64'))))

    story.append(Spacer(1, 25))
    story.append(HRFlowable(width="80%", thickness=2, color=colors.HexColor('#0D47A1'), spaceBefore=10, spaceAfter=20))

    story.append(Paragraph(ar("تقرير المشروع النهائي لمادة معمارية وحاسوب عملي"), subtitle_style))
    story.append(Spacer(1, 10))
    story.append(Paragraph(ar("تصميم مسار بيانات معالج مصغر 4-بت"), title_style))
    story.append(Paragraph(ar("(Mini Processor Datapath using Logisim Evolution)"), ParagraphStyle('CovSub', fontName='Amiri-Bold', fontSize=14, leading=18, alignment=TA_CENTER, textColor=colors.HexColor('#2E7D32'))))

    story.append(HRFlowable(width="80%", thickness=2, color=colors.HexColor('#0D47A1'), spaceBefore=20, spaceAfter=25))
    story.append(Spacer(1, 20))

    # Meta Table
    meta_data = [
        [Paragraph(ar("2026 م / 1447 هـ"), ParagraphStyle('M1', fontName='Amiri-Bold', fontSize=11, alignment=TA_CENTER, textColor=colors.HexColor('#0D47A1'))),
         Paragraph(ar("العام الدراسي:"), ParagraphStyle('M2', fontName='Amiri-Bold', fontSize=11, alignment=TA_RIGHT, textColor=colors.HexColor('#37474F')))],
        [Paragraph(ar("محمد الفقيه وحازم الطيري"), ParagraphStyle('M3', fontName='Amiri-Bold', fontSize=12, alignment=TA_CENTER, textColor=colors.HexColor('#1B5E20'))),
         Paragraph(ar("إعداد الطالب:"), ParagraphStyle('M4', fontName='Amiri-Bold', fontSize=11, alignment=TA_RIGHT, textColor=colors.HexColor('#37474F')))],
        [Paragraph(ar("الأستاذة / ذكرى الحسيني"), ParagraphStyle('M5', fontName='Amiri-Bold', fontSize=12, alignment=TA_CENTER, textColor=colors.HexColor('#B71C1C'))),
         Paragraph(ar("تحت إشراف:"), ParagraphStyle('M6', fontName='Amiri-Bold', fontSize=11, alignment=TA_RIGHT, textColor=colors.HexColor('#37474F')))]
    ]

    t_meta = Table(meta_data, colWidths=[260, 120])
    t_meta.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F5F5F5')),
        ('BOX', (0,0), (-1,-1), 1.5, colors.HexColor('#0D47A1')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E0E0E0')),
        ('PADDING', (0,0), (-1,-1), 8),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(t_meta)

    story.append(PageBreak())

    # ==================== PAGE 2: INTRODUCTION & THEORY ====================
    story.append(Paragraph(ar("1. مقدمة وفكرة المشروع"), h1_style))
    story.append(Paragraph(ar("يهدف هذا المشروع إلى تطبيق المفاهيم الأساسية لمعمارية وتنظيم الحاسوب من خلال بناء مسار بيانات لمعالج رقمي مصغّر (Mini Processor Datapath) بمسجل بعرض 4-بت باستخدام برنامج Logisim Evolution. يجمع هذا النظام بين الدوائر التراكبية (Combinational Circuits) كالـ ALU ومفككات الترميز، والدوائر التتابعية (Sequential Circuits) كالمسجلات، ليحاكي التنفيذ الحقيقي للأوامر داخل المعالجات الحديثة."), body_style))

    story.append(Paragraph(ar("2. مكونات النظام الأساسية"), h1_style))
    story.append(Paragraph(ar("• وحدة الحساب والمنطق (ALU): تتولى تنفيذ العمليات الحسابية والمنطقية الأساسية (AND, OR, XOR, ADD, SUB)."), bullet_style))
    story.append(Paragraph(ar("• المسجلات (Registers): تتكون من Register A و Register B لتخزين المدخلات، و Result Register لتخزين نتيجة العملية عند نبضة الساعة (Clock)."), bullet_style))
    story.append(Paragraph(ar("• وحدة التحكم (Control Unit): تقوم بفك ترميز كود العملية (Opcode) باستخدام Decoder 3:8 وتوليد إشارات التحكم اللازمة لكل وحدة."), bullet_style))
    story.append(Paragraph(ar("• إشارات الحالة (Flags): تشمل Zero Flag لإشارة النتيجة الصفرية و Carry Flag لإشارة الفائض الحسابي."), bullet_style))

    story.append(Spacer(1, 10))
    story.append(Paragraph(ar("3. المعاملات المنطقية وجداول الحقيقة للدوائر الأساسية"), h1_style))
    story.append(Paragraph(ar("3.1 دائرة الجامع الكامل (Full Adder)"), h2_style))
    story.append(Paragraph(ar("المعادلات المنطقية الخاصة بالجامع الكامل هي:"), body_style))
    story.append(Paragraph("Sum = A ⊕ B ⊕ Cin", ParagraphStyle('Eq1', fontName='Helvetica-Bold', fontSize=11, leading=16, alignment=TA_LEFT, textColor=colors.HexColor('#1565C0'))))
    story.append(Paragraph("Cout = (A ⋅ B) + (Cin ⋅ (A ⊕ B))", ParagraphStyle('Eq2', fontName='Helvetica-Bold', fontSize=11, leading=16, alignment=TA_LEFT, textColor=colors.HexColor('#1565C0'))))

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
    t_fa = Table(fa_data, colWidths=[70, 70, 70, 70, 70])
    t_fa.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#0D47A1')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#0D47A1')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#BDBDBD')),
        ('PADDING', (0,0), (-1,-1), 4),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(t_fa)

    story.append(PageBreak())

    # ==================== PAGE 3: OPCODE TABLE & ALU SPECIFICATION ====================
    story.append(Paragraph(ar("4. جدول أفراد Opcode والعمليات المقابلة وإشارات التحكم"), h1_style))
    story.append(Paragraph(ar("يقوم مفكك الترميز (Decoder 3:8) بتحويل شفرة العملية (Opcode) إلى إشارات تحكم دقيقة لتوجيه الـ ALU والمسجلات:"), body_style))

    opcode_headers = [
        Paragraph(ar("شرح العملية"), table_header_style),
        Paragraph(ar("إشارة الطرح Sub"), table_header_style),
        Paragraph(ar("الكتابة للمسجل RegWrite"), table_header_style),
        Paragraph(ar("محدد ALU_Sel"), table_header_style),
        Paragraph(ar("العملية (Operation)"), table_header_style),
        Paragraph(ar("كود العملية Opcode"), table_header_style)
    ]

    opcode_data = [
        opcode_headers,
        [Paragraph(ar("عملية AND منطقية بت مقابل بت"), table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("000", table_text_style), Paragraph("AND", table_text_style), Paragraph("000", table_text_style)],
        [Paragraph(ar("عملية OR منطقية بت مقابل بت"), table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("001", table_text_style), Paragraph("OR", table_text_style), Paragraph("001", table_text_style)],
        [Paragraph(ar("عملية XOR منطقية (عدم التماثل)"), table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("010", table_text_style), Paragraph("XOR", table_text_style), Paragraph("010", table_text_style)],
        [Paragraph(ar("جمع حسابي ثنائي 4-بت (A + B)"), table_text_style), Paragraph("0", table_text_style), Paragraph("1", table_text_style), Paragraph("011", table_text_style), Paragraph("ADD", table_text_style), Paragraph("011", table_text_style)],
        [Paragraph(ar("طرح حسابي باستخدام المتمم الثنائي (A - B)"), table_text_style), Paragraph("1", table_text_style), Paragraph("1", table_text_style), Paragraph("100", table_text_style), Paragraph("SUB", table_text_style), Paragraph("100", table_text_style)],
        [Paragraph(ar("غير مستخدم (NOP)"), table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("101", table_text_style), Paragraph("RESERVED", table_text_style), Paragraph("101", table_text_style)],
        [Paragraph(ar("غير مستخدم (NOP)"), table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("110", table_text_style), Paragraph("RESERVED", table_text_style), Paragraph("110", table_text_style)],
        [Paragraph(ar("غير مستخدم (NOP)"), table_text_style), Paragraph("0", table_text_style), Paragraph("0", table_text_style), Paragraph("111", table_text_style), Paragraph("RESERVED", table_text_style), Paragraph("111", table_text_style)],
    ]

    t_opcode = Table(opcode_data, colWidths=[140, 60, 65, 65, 75, 65])
    t_opcode.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1B5E20')),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor('#1B5E20')),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#BDBDBD')),
        ('PADDING', (0,0), (-1,-1), 5),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(t_opcode)

    story.append(Spacer(1, 15))
    story.append(Paragraph(ar("5. المخططات الهندسية وتصميم Logisim Evolution"), h1_style))
    story.append(Paragraph(ar("5.1 مخطط جامع البتات الكامل (Full Adder Subcircuit)"), h2_style))
    story.append(Image('/app/diagrams/full_adder.png', width=420, height=240))

    story.append(PageBreak())

    # ==================== PAGE 4: ALU & CONTROL UNIT DIAGRAMS ====================
    story.append(Paragraph(ar("5.2 تصميم وحدة الحساب والمنطق (ALU 4-Bit)"), h2_style))
    story.append(Paragraph(ar("تستقبل الـ ALU مدخلين بعرض 4-بت وتنفذ العمليات التفرعية. يختار Multiplexer 8:1 النتيجة المطلوبة بناءً على خطوط تحديد العملية ALU_Sel:"), body_style))
    story.append(Image('/app/diagrams/alu.png', width=450, height=280))

    story.append(Spacer(1, 10))
    story.append(Paragraph(ar("5.3 تصميم وحدة التحكم ومفكك الترميز (Control Unit & Decoder)"), h2_style))
    story.append(Paragraph(ar("تحتوي وحدة التحكم على Decoder 3:8 الذي يحول شفرة Opcode إلى 8 خطوط مفردة، تليها بوابات منطقية لتوليد إشارة RegWrite للتخزين وإشارة SubSignal للطرح:"), body_style))
    story.append(Image('/app/diagrams/control_unit.png', width=420, height=240))

    story.append(PageBreak())

    # ==================== PAGE 5: TOP SYSTEM & CONCLUSION ====================
    story.append(Paragraph(ar("5.4 مخطط النظام الشامل (Full Mini Processor Datapath)"), h1_style))
    story.append(Paragraph(ar("يوضح المخطط التالي الربط المتكامل بين المسجلات A و B ووحدة ALU ووحدة التحكم Control Unit ومسجل النتيجة Result Register مع التزامن بواسطة نبضات الساعة Clock:"), body_style))
    story.append(Image('/app/diagrams/top_system.png', width=470, height=290))

    story.append(Spacer(1, 10))
    story.append(Paragraph(ar("6. شرح خطوات التشغيل والتنفيذ الميداني"), h1_style))
    story.append(Paragraph(ar("1. تحميل البيانات: يتم إدخال القيم في Input A و Input B وتفعيل Load_A و Load_B مع نبضة الساعة لتخزينها في المسجلات A و B."), bullet_style))
    story.append(Paragraph(ar("2. فك شفرة الأمر: يُدخل كود العملية (مثلاً 011 لعملية ADD) في مدخل Opcode، فتولد وحدة التحكم إشارات ALU_Sel = 011 و RegWrite = 1."), bullet_style))
    story.append(Paragraph(ar("3. التنفيذ بالـ ALU: تقوم الـ ALU بحساب النتيجة فوراً وتمريرها عبر Multiplexer إلى مدخل Result Register."), bullet_style))
    story.append(Paragraph(ar("4. تخزين النتيجة: مع حافة نبضة الساعة التالية، تقوم إشارة RegWrite بتخزين النتيجة النهائية في Result Register وإظهارها على Final Output."), bullet_style))

    story.append(Spacer(1, 10))
    story.append(Paragraph(ar("7. الخاتمة والاستنتاج"), h1_style))
    story.append(Paragraph(ar("تم بحمد الله وتوفيقه بناء نظام رقمي مصغر متكامل يجمع بين ALU والمسجلات ووحدة التحكم بنجاح على بيئة Logisim Evolution. أثبتت الاختبارات والتحقيقات لجميع عمليات الـ ALU كفاءة التصميم ودقة معالجة البيانات، مما يعزز الفهم العملي لبنية الحاسوب ومسارات البيانات."), body_style))

    # Build Document
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF successfully generated at {filename}")

build_pdf()
