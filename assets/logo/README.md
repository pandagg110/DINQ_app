# DINQ Logo Assets

此目录包含 DINQ 品牌的 logo 资源文件。

## 文件说明

### `dinq-black.svg`
- **颜色**: 全黑配色（主体黑色 + 小点黑色）
- **用途**: 当前主要使用的 logo
- **尺寸**: 30×31 (viewBox)
- **使用场景**: 
  - Sidebar 导航
  - Header
  - 所有需要 logo 的位置

## 使用方式

推荐使用 `Logo` 组件：

```tsx
import { Logo } from "@/components/common/Logo";

// 完整 Logo（图标 + 文字）
<Logo size="md" />

// 只显示图标
<Logo showText={false} size="sm" />

// 大尺寸
<Logo size="lg" />
```

## 组件路径

`src/components/common/Logo.tsx`

## 尺寸规格

- **sm**: 20×21px
- **md**: 24×25px (默认)
- **lg**: 32×33px

