import matplotlib.pyplot as plt
import matplotlib.patches as patches
import os

os.makedirs('/app/diagrams', exist_ok=True)

# Set global styles
plt.rcParams['font.sans-serif'] = 'DejaVu Sans'
plt.rcParams['axes.edgecolor'] = '#333333'

def draw_full_adder():
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)
    ax.axis('off')

    # Title
    ax.text(5, 5.6, "Full Adder Circuit Schema (دائرة الجمع الكامل)", fontsize=14, fontweight='bold', ha='center', va='center')

    # Inputs
    ax.add_patch(patches.Rectangle((0.5, 4.3), 0.8, 0.4, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(0.9, 4.5, "A", fontsize=11, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((0.5, 3.3), 0.8, 0.4, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(0.9, 3.5, "B", fontsize=11, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((0.5, 1.8), 0.8, 0.4, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(0.9, 2.0, "Cin", fontsize=11, fontweight='bold', ha='center', va='center')

    # XOR 1
    ax.add_patch(patches.FancyBboxPatch((2.5, 3.6), 1.2, 0.8, boxstyle="round,pad=0.1", facecolor='#FFF9C4', edgecolor='#FBC02D', linewidth=1.5))
    ax.text(3.1, 4.0, "XOR1", fontsize=10, fontweight='bold', ha='center', va='center')

    # AND 1
    ax.add_patch(patches.FancyBboxPatch((2.5, 2.4), 1.2, 0.8, boxstyle="round,pad=0.1", facecolor='#C8E6C9', edgecolor='#388E3C', linewidth=1.5))
    ax.text(3.1, 2.8, "AND1", fontsize=10, fontweight='bold', ha='center', va='center')

    # XOR 2
    ax.add_patch(patches.FancyBboxPatch((5.0, 3.8), 1.2, 0.8, boxstyle="round,pad=0.1", facecolor='#FFF9C4', edgecolor='#FBC02D', linewidth=1.5))
    ax.text(5.6, 4.2, "XOR2", fontsize=10, fontweight='bold', ha='center', va='center')

    # AND 2
    ax.add_patch(patches.FancyBboxPatch((5.0, 1.6), 1.2, 0.8, boxstyle="round,pad=0.1", facecolor='#C8E6C9', edgecolor='#388E3C', linewidth=1.5))
    ax.text(5.6, 2.0, "AND2", fontsize=10, fontweight='bold', ha='center', va='center')

    # OR 1
    ax.add_patch(patches.FancyBboxPatch((7.2, 2.1), 1.2, 0.8, boxstyle="round,pad=0.1", facecolor='#FFCCBC', edgecolor='#D84315', linewidth=1.5))
    ax.text(7.8, 2.5, "OR1", fontsize=10, fontweight='bold', ha='center', va='center')

    # Outputs
    ax.add_patch(patches.Rectangle((8.8, 4.0), 0.9, 0.4, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(9.25, 4.2, "Sum", fontsize=11, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((8.8, 2.3), 0.9, 0.4, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(9.25, 2.5, "Cout", fontsize=11, fontweight='bold', ha='center', va='center')

    # Wires
    # A to XOR1 & AND1
    ax.plot([1.3, 2.0, 2.0, 2.5], [4.5, 4.5, 4.2, 4.2], color='#1565C0', lw=1.5)
    ax.plot([2.0, 2.0, 2.5], [4.2, 3.0, 3.0], color='#1565C0', lw=1.5)

    # B to XOR1 & AND1
    ax.plot([1.3, 2.2, 2.2, 2.5], [3.5, 3.5, 3.8, 3.8], color='#1565C0', lw=1.5)
    ax.plot([2.2, 2.2, 2.5], [3.5, 2.6, 2.6], color='#1565C0', lw=1.5)

    # XOR1 output to XOR2 and AND2
    ax.plot([3.7, 4.4, 4.4, 5.0], [4.0, 4.0, 4.3, 4.3], color='#D84315', lw=1.5)
    ax.plot([4.4, 4.4, 5.0], [4.0, 2.2, 2.2], color='#D84315', lw=1.5)

    # Cin to XOR2 and AND2
    ax.plot([1.3, 4.6, 4.6, 5.0], [2.0, 2.0, 3.9, 3.9], color='#6A1B9A', lw=1.5)
    ax.plot([4.6, 4.6, 5.0], [2.0, 1.8, 1.8], color='#6A1B9A', lw=1.5)

    # XOR2 to Sum
    ax.plot([6.2, 8.8], [4.2, 4.2], color='#2E7D32', lw=2)

    # AND1 & AND2 to OR1
    ax.plot([3.7, 6.8, 6.8, 7.2], [2.8, 2.8, 2.3, 2.3], color='#2E7D32', lw=1.5)
    ax.plot([6.2, 6.8, 6.8, 7.2], [2.0, 2.0, 2.7, 2.7], color='#2E7D32', lw=1.5)

    # OR1 to Cout
    ax.plot([8.4, 8.8], [2.5, 2.5], color='#2E7D32', lw=2)

    plt.tight_layout()
    plt.savefig('/app/diagrams/full_adder.png', dpi=300)
    plt.close()

draw_full_adder()

def draw_alu():
    fig, ax = plt.subplots(figsize=(9, 6), dpi=300)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 7)
    ax.axis('off')

    ax.text(5, 6.6, "4-Bit ALU Internal Architecture (وحدة الحساب والمنطق)", fontsize=14, fontweight='bold', ha='center', va='center')

    # Inputs A & B
    ax.add_patch(patches.Rectangle((0.5, 4.8), 1.0, 0.6, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(1.0, 5.1, "Input A [3:0]", fontsize=9, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((0.5, 1.8), 1.0, 0.6, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(1.0, 2.1, "Input B [3:0]", fontsize=9, fontweight='bold', ha='center', va='center')

    # Sub-blocks inside ALU
    blocks = [
        ("AND Gate (4-bit)", 4.8, '#C8E6C9', '#2E7D32'),
        ("OR Gate (4-bit)", 3.9, '#C8E6C9', '#2E7D32'),
        ("XOR Gate (4-bit)", 3.0, '#FFF9C4', '#FBC02D'),
        ("Adder/Subtractor 4-bit", 2.1, '#FFCCBC', '#D84315')
    ]

    for name, y, fc, ec in blocks:
        ax.add_patch(patches.FancyBboxPatch((2.8, y), 2.2, 0.6, boxstyle="round,pad=0.05", facecolor=fc, edgecolor=ec, linewidth=1.5))
        ax.text(3.9, y+0.3, name, fontsize=8.5, fontweight='bold', ha='center', va='center')

        # Wires from Inputs to blocks
        ax.plot([1.5, 2.2, 2.2, 2.8], [5.1, 5.1, y+0.4, y+0.4], color='#1565C0', lw=1.2)
        ax.plot([1.5, 2.4, 2.4, 2.8], [2.1, 2.1, y+0.2, y+0.2], color='#1565C0', lw=1.2)

    # Multiplexer
    ax.add_patch(patches.Polygon([[6.0, 1.8], [6.8, 2.3], [6.8, 5.3], [6.0, 5.8]], facecolor='#E1BEE7', edgecolor='#7B1FA2', linewidth=1.5))
    ax.text(6.4, 3.8, "8:1 MUX\n(4-bit)", fontsize=10, fontweight='bold', ha='center', va='center', rotation=90)

    # Connect blocks to MUX
    y_outs = [5.1, 4.2, 3.3, 2.4]
    mux_ins = [5.1, 4.4, 3.7, 3.0]
    for yo, mi in zip(y_outs, mux_ins):
        ax.plot([5.0, 6.0], [yo, mi], color='#2E7D32', lw=1.5)

    # ALU Selector
    ax.add_patch(patches.Rectangle((5.9, 0.6), 1.0, 0.5, facecolor='#FFF3E0', edgecolor='#E65100', linewidth=1.5))
    ax.text(6.4, 0.85, "ALU_Sel [2:0]", fontsize=8.5, fontweight='bold', ha='center', va='center')
    ax.plot([6.4, 6.4], [1.1, 2.05], color='#E65100', lw=1.5)

    # Output Pin
    ax.add_patch(patches.Rectangle((7.8, 3.5), 1.4, 0.6, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(8.5, 3.8, "Result [3:0]", fontsize=9.5, fontweight='bold', ha='center', va='center')
    ax.plot([6.8, 7.8], [3.8, 3.8], color='#2E7D32', lw=2)

    # Zero Flag Detector
    ax.add_patch(patches.FancyBboxPatch((7.8, 2.2), 1.4, 0.6, boxstyle="round,pad=0.05", facecolor='#F8BBD0', edgecolor='#C2185B', linewidth=1.5))
    ax.text(8.5, 2.5, "Zero Flag\nDetector", fontsize=8, fontweight='bold', ha='center', va='center')
    ax.plot([7.3, 7.3, 7.8], [3.8, 2.5, 2.5], color='#C2185B', lw=1.2)

    # Carry Flag
    ax.add_patch(patches.Rectangle((7.8, 1.2), 1.4, 0.5, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(8.5, 1.45, "Cout Flag", fontsize=8.5, fontweight='bold', ha='center', va='center')
    ax.plot([5.0, 5.5, 5.5, 7.8], [2.2, 2.2, 1.45, 1.45], color='#D84315', lw=1.2)

    plt.tight_layout()
    plt.savefig('/app/diagrams/alu.png', dpi=300)
    plt.close()

draw_alu()

def draw_control_unit():
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 6)
    ax.axis('off')

    ax.text(5, 5.5, "Control Unit Schematics (وحدة التحكم والفك)", fontsize=14, fontweight='bold', ha='center', va='center')

    # Opcode Input
    ax.add_patch(patches.Rectangle((0.5, 2.7), 1.2, 0.6, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(1.1, 3.0, "Opcode [2:0]", fontsize=9.5, fontweight='bold', ha='center', va='center')

    # Decoder 3:8
    ax.add_patch(patches.FancyBboxPatch((2.5, 1.8), 2.0, 2.4, boxstyle="round,pad=0.1", facecolor='#EDE7F6', edgecolor='#512DA8', linewidth=1.5))
    ax.text(3.5, 3.0, "3-to-8\nDecoder\n(فك الترميز)", fontsize=10, fontweight='bold', ha='center', va='center')

    ax.plot([1.7, 2.5], [3.0, 3.0], color='#1565C0', lw=2)

    # Control Signals Logic
    ax.add_patch(patches.FancyBboxPatch((5.5, 2.0), 1.8, 2.0, boxstyle="round,pad=0.1", facecolor='#FFF3E0', edgecolor='#E65100', linewidth=1.5))
    ax.text(6.4, 3.0, "Control Logic\n& Signal Mapper", fontsize=9.5, fontweight='bold', ha='center', va='center')

    ax.plot([4.5, 5.5], [3.0, 3.0], color='#512DA8', lw=2)

    # Outputs
    ax.add_patch(patches.Rectangle((8.0, 4.0), 1.5, 0.5, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(8.75, 4.25, "ALU_Sel [2:0]", fontsize=8.5, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((8.0, 2.7), 1.5, 0.5, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(8.75, 2.95, "RegWrite", fontsize=8.5, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((8.0, 1.4), 1.5, 0.5, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(8.75, 1.65, "SubSignal", fontsize=8.5, fontweight='bold', ha='center', va='center')

    ax.plot([7.3, 7.7, 7.7, 8.0], [3.4, 3.4, 4.25, 4.25], color='#E65100', lw=1.5)
    ax.plot([7.3, 8.0], [3.0, 2.95], color='#E65100', lw=1.5)
    ax.plot([7.3, 7.7, 7.7, 8.0], [2.6, 2.6, 1.65, 1.65], color='#E65100', lw=1.5)

    plt.tight_layout()
    plt.savefig('/app/diagrams/control_unit.png', dpi=300)
    plt.close()

draw_control_unit()

def draw_top_system():
    fig, ax = plt.subplots(figsize=(10, 6.5), dpi=300)
    ax.set_xlim(0, 11)
    ax.set_ylim(0, 7)
    ax.axis('off')

    ax.text(5.5, 6.6, "Mini Processor Datapath System (المخطط الشامل للمشروع)", fontsize=14, fontweight='bold', ha='center', va='center')

    # External Inputs
    ax.add_patch(patches.Rectangle((0.4, 5.0), 1.1, 0.5, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(0.95, 5.25, "Input A [3:0]", fontsize=8.5, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((0.4, 3.4), 1.1, 0.5, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(0.95, 3.65, "Input B [3:0]", fontsize=8.5, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((0.4, 1.5), 1.1, 0.5, facecolor='#E3F2FD', edgecolor='#1976D2', linewidth=1.5))
    ax.text(0.95, 1.75, "Opcode [2:0]", fontsize=8.5, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((0.4, 0.6), 1.1, 0.5, facecolor='#FFF9C4', edgecolor='#FBC02D', linewidth=1.5))
    ax.text(0.95, 0.85, "Clock / Enable", fontsize=8.5, fontweight='bold', ha='center', va='center')

    # Register A & B
    ax.add_patch(patches.FancyBboxPatch((2.2, 4.7), 1.5, 1.1, boxstyle="round,pad=0.08", facecolor='#BBDEFB', edgecolor='#1565C0', linewidth=1.5))
    ax.text(2.95, 5.25, "Register A\n(4-bit)", fontsize=9.5, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.FancyBboxPatch((2.2, 3.1), 1.5, 1.1, boxstyle="round,pad=0.08", facecolor='#BBDEFB', edgecolor='#1565C0', linewidth=1.5))
    ax.text(2.95, 3.65, "Register B\n(4-bit)", fontsize=9.5, fontweight='bold', ha='center', va='center')

    # Control Unit Block
    ax.add_patch(patches.FancyBboxPatch((2.2, 1.2), 1.5, 1.2, boxstyle="round,pad=0.08", facecolor='#EDE7F6', edgecolor='#512DA8', linewidth=1.5))
    ax.text(2.95, 1.8, "Control Unit\n(وحدة التحكم)", fontsize=9, fontweight='bold', ha='center', va='center')

    # ALU Block
    ax.add_patch(patches.FancyBboxPatch((4.8, 3.3), 1.8, 2.0, boxstyle="round,pad=0.08", facecolor='#C8E6C9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(5.7, 4.3, "4-Bit ALU\n(وحدة الحساب والمنطق)", fontsize=10, fontweight='bold', ha='center', va='center')

    # Result Register
    ax.add_patch(patches.FancyBboxPatch((7.5, 3.7), 1.5, 1.2, boxstyle="round,pad=0.08", facecolor='#FFE0B2', edgecolor='#E65100', linewidth=1.5))
    ax.text(8.25, 4.3, "Result\nRegister\n(4-bit)", fontsize=9.5, fontweight='bold', ha='center', va='center')

    # Output Pins
    ax.add_patch(patches.Rectangle((9.5, 4.05), 1.2, 0.5, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(10.1, 4.3, "Final Output\n[3:0]", fontsize=8, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((9.5, 3.1), 1.2, 0.5, facecolor='#F8BBD0', edgecolor='#C2185B', linewidth=1.5))
    ax.text(10.1, 3.35, "Zero Flag", fontsize=8, fontweight='bold', ha='center', va='center')

    ax.add_patch(patches.Rectangle((9.5, 2.2), 1.2, 0.5, facecolor='#E8F5E9', edgecolor='#2E7D32', linewidth=1.5))
    ax.text(10.1, 2.45, "Carry Flag", fontsize=8, fontweight='bold', ha='center', va='center')

    # Connections
    # Input A -> Reg A
    ax.plot([1.5, 2.2], [5.25, 5.25], color='#1565C0', lw=1.8)
    # Input B -> Reg B
    ax.plot([1.5, 2.2], [3.65, 3.65], color='#1565C0', lw=1.8)
    # Opcode -> Control Unit
    ax.plot([1.5, 2.2], [1.75, 1.75], color='#512DA8', lw=1.8)

    # Reg A -> ALU Input A
    ax.plot([3.7, 4.3, 4.3, 4.8], [5.25, 5.25, 4.7, 4.7], color='#1565C0', lw=2)
    # Reg B -> ALU Input B
    ax.plot([3.7, 4.3, 4.3, 4.8], [3.65, 3.65, 3.9, 3.9], color='#1565C0', lw=2)

    # Control Unit -> ALU_Sel & Result Reg Enable
    ax.plot([3.7, 5.4, 5.4], [1.8, 1.8, 3.3], color='#512DA8', lw=1.8, linestyle='--')
    ax.plot([3.7, 8.25, 8.25], [1.5, 1.5, 3.7], color='#512DA8', lw=1.8, linestyle='--')

    # Clock -> Reg A, Reg B, Result Reg
    ax.plot([1.5, 1.8, 1.8, 2.2], [0.85, 0.85, 4.9, 4.9], color='#FBC02D', lw=1.2)
    ax.plot([1.8, 2.2], [3.3, 3.3], color='#FBC02D', lw=1.2)
    ax.plot([1.8, 8.0, 8.0], [0.85, 0.85, 3.7], color='#FBC02D', lw=1.2)

    # ALU -> Result Reg & Flags
    ax.plot([6.6, 7.5], [4.3, 4.3], color='#2E7D32', lw=2)
    ax.plot([6.6, 7.1, 7.1, 9.5], [3.8, 3.8, 3.35, 3.35], color='#C2185B', lw=1.5)
    ax.plot([6.6, 6.9, 6.9, 9.5], [3.5, 3.5, 2.45, 2.45], color='#2E7D32', lw=1.5)

    # Result Reg -> Final Output
    ax.plot([9.0, 9.5], [4.3, 4.3], color='#2E7D32', lw=2)

    plt.tight_layout()
    plt.savefig('/app/diagrams/top_system.png', dpi=300)
    plt.close()

draw_top_system()

print("Diagrams generated successfully in /app/diagrams/")
