from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak, Image
from reportlab.lib import colors
from reportlab.graphics.shapes import Drawing
from reportlab.graphics.charts.piecharts import Pie
from reportlab.graphics.charts.barcharts import VerticalBarChart
from datetime import datetime
import json
import os

class ReportGenerator:
    """
    Generate PDF and JSON reports for classroom sessions
    """
    
    def __init__(self, analytics_engine):
        self.analytics_engine = analytics_engine
        self.exports_dir = "exports"
        os.makedirs(self.exports_dir, exist_ok=True)
    
    def generate_pdf_report(self, session_id: str, session_data: dict, analytics: dict) -> str:
        """
        Generate comprehensive PDF report
        
        Returns:
            path to generated PDF
        """
        filename = f"{self.exports_dir}/session_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        
        doc = SimpleDocTemplate(filename, pagesize=A4)
        story = []
        styles = getSampleStyleSheet()
        
        # Custom styles
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            textColor=colors.HexColor('#1E40AF'),
            spaceAfter=30,
            alignment=1  # Center
        )
        
        heading_style = ParagraphStyle(
            'CustomHeading',
            parent=styles['Heading2'],
            fontSize=16,
            textColor=colors.HexColor('#3B82F6'),
            spaceAfter=12
        )
        
        # Title
        story.append(Paragraph("AI Classroom Analytics Report", title_style))
        story.append(Spacer(1, 0.2*inch))
        
        # Session Info
        story.append(Paragraph("Session Information", heading_style))
        session_info = [
            ['Subject:', session_data.get('subject', 'N/A')],
            ['Teacher:', session_data.get('teacher_id', 'N/A')],
            ['Date:', session_data.get('start_time', '')[:10]],
            ['Duration:', f"{session_data.get('duration_minutes', 0)} minutes"],
            ['Students:', str(len(session_data.get('students', [])))],
            ['Frames Processed:', str(session_data.get('total_frames_processed', 0))]
        ]
        
        t = Table(session_info, colWidths=[2*inch, 4*inch])
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#E0E7FF')),
            ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('GRID', (0, 0), (-1, -1), 1, colors.grey)
        ]))
        story.append(t)
        story.append(Spacer(1, 0.3*inch))
        
        # Overall Metrics
        story.append(Paragraph("Overall Performance", heading_style))
        avg_engagement = session_data.get('average_class_engagement', 0)
        
        metrics_data = [
            ['Metric', 'Value', 'Grade'],
            ['Average Engagement', f"{avg_engagement*100:.1f}%", self._get_grade(avg_engagement)],
            ['Alerts Generated', str(session_data.get('alerts_generated', 0)), '-'],
            ['Peak Engagement', f"{analytics.get('peak_engagement', 0)}%", '-']
        ]
        
        t2 = Table(metrics_data, colWidths=[2.5*inch, 2*inch, 1.5*inch])
        t2.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#3B82F6')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('GRID', (0, 0), (-1, -1), 1, colors.grey),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F3F4F6')])
        ]))
        story.append(t2)
        story.append(Spacer(1, 0.3*inch))
        
        # Emotion Distribution Chart
        if 'emotion_distribution' in analytics:
            story.append(Paragraph("Emotion Distribution", heading_style))
            drawing = self._create_pie_chart(analytics['emotion_distribution'])
            story.append(drawing)
            story.append(Spacer(1, 0.3*inch))
        
        # Page break
        story.append(PageBreak())
        
        # Student-wise breakdown
        story.append(Paragraph("Student Performance", heading_style))
        
        if 'student_comparison' in analytics:
            student_data = [['Student ID', 'Avg Engagement', 'Consistency', 'Participation']]
            
            for student_id, metrics in analytics['student_comparison'].items():
                student_data.append([
                    student_id,
                    f"{metrics.get('average_engagement', 0):.1f}%",
                    f"{metrics.get('consistency', 0):.1f}%",
                    str(metrics.get('participation', 0))
                ])
            
            t3 = Table(student_data, colWidths=[2*inch, 1.5*inch, 1.5*inch, 1.5*inch])
            t3.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#10B981')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, -1), 9),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
                ('GRID', (0, 0), (-1, -1), 1, colors.grey),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F3F4F6')])
            ]))
            story.append(t3)
        
        # Build PDF
        doc.build(story)
        return filename
    
    def _create_pie_chart(self, data: dict) -> Drawing:
        """Create pie chart for emotion distribution"""
        drawing = Drawing(400, 200)
        pie = Pie()
        pie.x = 150
        pie.y = 50
        pie.width = 100
        pie.height = 100
        
        pie.data = list(data.values())
        pie.labels = list(data.keys())
        pie.slices.strokeWidth = 0.5
        
        # Color mapping
        colors_map = {
            'happy': colors.HexColor('#10B981'),
            'surprise': colors.HexColor('#F59E0B'),
            'neutral': colors.HexColor('#6B7280'),
            'sad': colors.HexColor('#3B82F6'),
            'fear': colors.HexColor('#8B5CF6'),
            'angry': colors.HexColor('#EF4444'),
            'disgust': colors.HexColor('#EC4899')
        }
        
        for i, label in enumerate(pie.labels):
            pie.slices[i].fillColor = colors_map.get(label, colors.grey)
        
        drawing.add(pie)
        return drawing
    
    def generate_json_report(self, session_id: str, session_data: dict, analytics: dict) -> str:
        """
        Generate JSON report for API consumption
        
        Returns:
            path to JSON file
        """
        filename = f"{self.exports_dir}/session_{session_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        report = {
            'session_info': session_data,
            'analytics': analytics,
            'generated_at': datetime.now().isoformat()
        }
        
        with open(filename, 'w') as f:
            json.dump(report, f, indent=2)
        
        return filename
    
    def _get_grade(self, score: float) -> str:
        """Convert score to letter grade"""
        if score >= 0.9:
            return 'A+'
        elif score >= 0.8:
            return 'A'
        elif score >= 0.7:
            return 'B'
        elif score >= 0.6:
            return 'C'
        else:
            return 'D'
