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

### 5. Color, Icon, and Layout Conventions

背景は白を基本とする。クラウドアーキテクチャ図では、AWS/Azure公式アーキテクチャ図のテイスト（サブネットの色分け・公式アイコン・凡例ボックス）を基本とする。**黒枠・無色塗りのみで済ませない。**

**クラウド境界:** 点線枠（`dashed=1`）。左上にプロバイダ名ラベルを配置する。
- Azure: `strokeColor=#0078D4;dashed=1;fillColor=none;`
- AWS: `strokeColor=#FF9900;dashed=1;fillColor=none;`
- GCP: `strokeColor=#4285F4;dashed=1;fillColor=none;`
- Snowflake: `strokeColor=#29B5E8;dashed=1;fillColor=none;`

**VPC / VNet:** 紫の塗り。`fillColor=#E1D5E7;strokeColor=#9673A6;`

**Subnet の色分け:**
- Public subnet: 薄緑 `fillColor=#D5E8D4;strokeColor=#82B366;`
- Private subnet: 薄い青緑 `fillColor=#D9F2F0;strokeColor=#008080;`
- Availability Zone などのさらに内側の境界は無色・点線枠（`fillColor=none;strokeColor=#333333;dashed=1;`）でよい。

**サービスアイコン:** 黒枠テキストボックスではなく、公式アイコン風（丸/角丸のカラーアイコン）で各サービスを表現する。
- 対応する mxgraph stencil の名前に確証がある場合はそれを使う（例: `shape=umlActor;` は標準シェイプで確実に存在する）。
- クラウド公式アイコン（`mxgraph.aws4.*` / `mxgraph.azure.*` など）の正確な stencil 名は draw.io アプリの Shape Search で確認してから使う。確証のないまま書くと、その要素だけ無地の四角にフォールバックする。
- 確証が持てないサービスは、カテゴリカラーの円/角丸＋短い記号ラベルで近似する（コンピュート=オレンジ、DB/Storage=緑、ネットワーキング=紫、セキュリティ=赤、分析=青、など）。
- アイコンの下または右に、サービス名を別要素のテキストラベルとして添える（アイコン内に長文を詰め込まない）。

**凡例ボックス:** 左上または右上に、白背景・黒枠のボックスを置く。矢印の意味（実線=データフロー、破線=イベント）や `{env}` のような変数表記の意味をここに明記する。

**人物アイコン:** 利用者・担当者は標準 UML actor シェイプ（`shape=umlActor;html=1;`）で表現し、役割名・組織名をラベルに添える。

**矢印:** データフローは実線・太め（`strokeWidth=2`〜`3`）、イベント通知は破線・細め（`dashed=1;strokeWidth=1`〜`2`）で描き分け、凡例ボックスで必ず区別を明示する。

### 6. Common Element Patterns

**Rectangle with text:**
```xml
<mxCell id="rect1" value="サービス名"
  style="rounded=0;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#333333;fontFamily=Noto Sans JP;fontSize=18;"
  vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="200" height="80" as="geometry"/>
</mxCell>
```

**VPC / VNet container (colored):**
```xml
<mxCell id="vpc1" value="VPC"
  style="rounded=0;whiteSpace=wrap;html=1;fillColor=#E1D5E7;strokeColor=#9673A6;verticalAlign=top;fontFamily=Noto Sans JP;fontSize=18;fontStyle=1;container=1;collapsible=0;"
  vertex="1" parent="1">
  <mxGeometry x="50" y="50" width="600" height="400" as="geometry"/>
</mxCell>
```

**Public / Private subnet (colored):**
```xml
<mxCell id="public1" value="Public subnet"
  style="rounded=0;whiteSpace=wrap;html=1;fillColor=#D5E8D4;strokeColor=#82B366;verticalAlign=top;fontFamily=Noto Sans JP;fontSize=16;container=1;collapsible=0;"
  vertex="1" parent="vpc1">
  <mxGeometry x="20" y="40" width="250" height="300" as="geometry"/>
</mxCell>
<mxCell id="private1" value="Private subnet"
  style="rounded=0;whiteSpace=wrap;html=1;fillColor=#D9F2F0;strokeColor=#008080;verticalAlign=top;fontFamily=Noto Sans JP;fontSize=16;container=1;collapsible=0;"
  vertex="1" parent="vpc1">
  <mxGeometry x="300" y="40" width="250" height="300" as="geometry"/>
</mxCell>
```

**Cloud platform boundary (dashed, colored border):**
```xml
<mxCell id="azure1" value="Azure"
  style="rounded=0;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#0078D4;dashed=1;verticalAlign=top;fontFamily=Noto Sans JP;fontSize=20;fontStyle=1;container=1;collapsible=0;strokeWidth=2;"
  vertex="1" parent="1">
  <mxGeometry x="10" y="10" width="800" height="600" as="geometry"/>
</mxCell>
```

**Legend box:**
```xml
<mxCell id="legend" value="凡例"
  style="rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#333333;verticalAlign=top;align=left;fontFamily=Noto Sans JP;fontSize=14;fontStyle=1;spacingLeft=10;spacingTop=5;"
  vertex="1" parent="1">
  <mxGeometry x="20" y="20" width="220" height="90" as="geometry"/>
</mxCell>
```

**Person icon (UML actor):**
```xml
<mxCell id="person1" value="運用担当者"
  style="shape=umlActor;whiteSpace=wrap;html=1;strokeColor=#333333;fillColor=none;fontFamily=Noto Sans JP;fontSize=14;verticalLabelPosition=bottom;verticalAlign=top;"
  vertex="1" parent="1">
  <mxGeometry x="900" y="30" width="40" height="60" as="geometry"/>
</mxCell>
```

**Arrow connector (data flow, solid):**
```xml
<mxCell id="arrow1"
  style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#333333;strokeWidth=2;exitX=1;exitY=0.5;"
  edge="1" parent="1" source="rect1" target="rect2">
  <mxGeometry relative="1" as="geometry"/>
</mxCell>
```

**Arrow connector (event, dashed):**
```xml
<mxCell id="arrow2"
  style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#333333;dashed=1;exitX=1;exitY=0.5;"
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
2. **Add shapes:** Create containers (cloud boundary → VPC/VNet → subnet) with their color coding
3. **Add icons:** Place service icons (official stencil if confirmed, otherwise category-colored approximation)
4. **Add labels:** Place standalone text elements and the legend box last
5. **Verify fonts:** Ensure every text element has `fontFamily` attribute
6. **Check spacing:** Verify 20px+ clearance between overlapping elements
7. **Size Japanese text:** Allocate 30-40px width per character

## Quality Checklist

Before finalizing diagrams:

- [ ] All text elements have explicit `fontFamily` attribute
- [ ] Arrows are defined before shapes/labels in XML
- [ ] Japanese text has adequate width (30-40px per character)
- [ ] Font size is 18px or larger for readability
- [ ] Minimum 20px spacing between arrows and labels
- [ ] No overlapping text elements
- [ ] Background is white
- [ ] Cloud platform boundary uses a dashed border in the provider's brand color (not a solid fill)
- [ ] VPC/VNet uses purple fill; Public subnet uses green fill; Private subnet uses teal fill
- [ ] Services are represented by icons (official stencil or category-colored approximation), not plain black-bordered text boxes
- [ ] A legend box (white background, black border) explains arrow meanings (solid = data flow, dashed = event) and any `{env}`-style placeholders
- [ ] People are represented with the UML actor shape, not plain text
- [ ] Data-flow arrows are solid; event arrows are dashed

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
