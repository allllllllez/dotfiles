---
name: drawio
description: Guidelines and best practices for creating draw.io diagrams with proper formatting, font handling, and layout rules. Use when creating or editing .drawio files, generating architecture diagrams, or working with draw.io XML format. Ensures high-quality PNG output with correct Japanese text rendering and professional appearance.
---

# Draw.io Diagram Creation Guidelines

## Overview

This skill provides proven best practices for creating high-quality draw.io diagrams that render correctly in PNG format with proper Japanese text support, correct layering, and professional appearance.

## Core Guidelines

### 1. Font Configuration

**Critical:** Each text element must have explicit `fontFamily` attribute.

```xml
<mxCell ... style="text;...fontFamily=Noto Sans JP;..." />
```

**Why:** The `defaultFontFamily` in `<mxGraphModel>` does NOT affect PNG export. Only element-level `fontFamily` attributes are respected during image rendering.

**Recommended fonts:**
- Japanese text: `Noto Sans JP` or `Hiragino Sans`
- English text: `Arial`, `Helvetica`, or `Roboto`

### 2. Arrow and Connector Placement

**Rule:** Arrows must be written first in XML to render at the back layer.

**Problem:** If arrows are defined after labels/shapes, they will overlap text and make diagrams unreadable.

**Solution:**
```xml
<root>
  <mxCell id="0" />
  <mxCell id="1" parent="0" />
  <!-- ↓ Arrows FIRST -->
  <mxCell id="arrow1" edge="1" parent="1" ... />
  <mxCell id="arrow2" edge="1" parent="1" ... />
  <!-- ↓ Shapes and labels AFTER -->
  <mxCell id="shape1" vertex="1" parent="1" ... />
  <mxCell id="label1" vertex="1" parent="1" ... />
</root>
```

**Spacing:** Maintain minimum 20px clearance between arrows and labels to prevent visual overlap.

### 3. Text Size and Spacing

**Font size:** Use 1.5x standard size (18px recommended) for better readability.

**Japanese text width estimation:**
- Allocate 30-40px width per character
- Example: 5-character label → minimum 150-200px width

**English text:** Standard character width rules apply (~8-12px per character depending on font).

### 4. XML Structure Best Practices

**Standard draw.io structure:**
```xml
<mxfile host="app.diagrams.net">
  <diagram name="Page-1">
    <mxGraphModel dx="1422" dy="794" grid="1" ...>
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <!-- Elements here -->
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

### 5. Common Element Patterns

**Rectangle with text:**
```xml
<mxCell id="rect1" value="サービス名"
  style="rounded=0;whiteSpace=wrap;html=1;fontFamily=Noto Sans JP;fontSize=18;"
  vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="200" height="80" as="geometry"/>
</mxCell>
```

**Arrow connector:**
```xml
<mxCell id="arrow1"
  style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;"
  edge="1" parent="1" source="rect1" target="rect2">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

**Label (standalone text):**
```xml
<mxCell id="label1" value="説明テキスト"
  style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Noto Sans JP;fontSize=14;"
  vertex="1" parent="1">
  <mxGeometry x="150" y="200" width="100" height="30" as="geometry"/>
</mxCell>
```

## Workflow

When creating draw.io diagrams:

1. **Start with structure:** Define all arrows/edges first
2. **Add shapes:** Create rectangles, circles, containers
3. **Add labels:** Place standalone text elements last
4. **Verify fonts:** Ensure every text element has `fontFamily` attribute
5. **Check spacing:** Verify 20px+ clearance between overlapping elements
6. **Size Japanese text:** Allocate 30-40px width per character

## Quality Checklist

Before finalizing diagrams:

- [ ] All text elements have explicit `fontFamily` attribute
- [ ] Arrows are defined before shapes/labels in XML
- [ ] Japanese text has adequate width (30-40px per character)
- [ ] Font size is 18px or larger for readability
- [ ] Minimum 20px spacing between arrows and labels
- [ ] No overlapping text elements

## References

For additional guidance, see:
- `references/aws-icons.md` - AWS icon usage patterns (if working with AWS diagrams)

## Resources

### references/
Contains supplementary documentation that can be loaded as needed:
- AWS service icon naming conventions
- Common diagram patterns for specific domains

### scripts/
Reserved for helper scripts (e.g., icon search, validation tools)

### assets/
Reserved for reusable templates or icon files
