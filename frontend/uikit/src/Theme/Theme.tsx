"use client";

import type { ReactNode } from "react";
import { createContext, useContext, useState } from "react";

export const colors = {
  "blue:50": "rgba(255, 255, 255, 0.10)",
  "blue:100": "rgba(255, 255, 255, 0.10)",
  "blue:200": "#C4D0F9",
  "blue:300": "#1C1D4F",
  "blue:400": "#6D8AED",
  "blue:500": "#405AE5",
  "blue:600": "#3544DB",
  "blue:700": "#2D33C8",
  "blue:800": "#2A2BA3",
  "blue:900": "#272A81",
  "blue:950": "#1C1D4F",

  "gray:50": "#F5F6F8",
  "gray:100": "#EDEFF2",
  "gray:200": "#DDE0E8",
  "gray:300": "#C8CDD9",
  "gray:400": "#B1B7C8",
  "gray:500": "#9EA2B8",
  "gray:600": "#878AA4",
  "gray:700": "#73748F",
  "gray:800": "#5F6174",
  "gray:900": "#50525F",
  "gray:950": "#2F3037",

  "yellow:50": "#FDFBE9",
  "yellow:100": "#FCF8C5",
  "yellow:200": "#FAEE8E",
  "yellow:300": "#F5D93A",
  "yellow:400": "#F1C91E",
  "yellow:500": "#E1B111",
  "yellow:600": "#C2890C",
  "yellow:700": "#9B620D",
  "yellow:800": "#804E13",
  "yellow:900": "#6D4016",
  "yellow:950": "#402108",

  "green:50": "#F1FCF2",
  "green:100": "#DEFAE4",
  "green:200": "#BFF3CA",
  "green:300": "#8EE7A1",
  "green:400": "#63D77D",
  "green:500": "#2EB94D",
  "green:600": "#20993C",
  "green:700": "#1D7832",
  "green:800": "#1C5F2C",
  "green:900": "#194E27",
  "green:950": "#082B12",

  "red:50": "#FEF5F2",
  "red:100": "#FFE7E1",
  "red:200": "#FFD5C9",
  "red:300": "#FEB7A3",
  "red:400": "#FB7C59",
  "red:500": "#F36740",
  "red:600": "#E14A21",
  "red:700": "#BD3C18",
  "red:800": "#9C3518",
  "red:900": "#82301A",
  "red:950": "#471608",

  "brown:50": "#F8F6F4",

  "desert:50": "#FAF9F7",
  "desert:100": "#EFECE5",
  "desert:950": "#2C231E",

  "white": "#FFFFFF",

  "primary:green": "#88FD9D",
  "primary:hover": "#2EFF54",
  "primary:disabled": "#88FD9D80",
  "primary:20": "#88FD9D33",

  "navy": "#011837",

  "white:100": "#FFFFFF",
  "white:70":  "#FFFFFFB3",
  "white:40":  "#FFFFFF66",
  "white:20":  "#FFFFFF33",
  "white:10":  "#FFFFFF1A",

  "error": "#FF6560",
  "error:20": "#FF656033",

  "primary:grad:start": "#88FD9D",
  "primary:grad:end":   "#2EFF54",

  "risk:1": "#2EFF54",
  "risk:2": "#88FD9D",
  "risk:3": "#FFFFFFB3",
  "risk:4": "#FF6560",
  "risk:5": "#FF6560",

  // Legacy Liquity V2 brand colors for backward compatibility
  "brand:blue": "#405AE5",
  "brand:lightBlue": "#6D8AED",
  "brand:darkBlue": "#121B44",
  "brand:green": "#63D77D",
  "brand:golden": "#F5D93A",
  "brand:cyan": "#95CBF3",
  "brand:coral": "#FB7C59",
  "brand:brown": "#DBB79B",
} as const;

export const lightTheme = {
  name: "light" as const,
  colors: {
    accent: "primary:green",
    accentActive: "primary:hover",
    accentHint: "primary:hover",
    accentContent: "navy",

    background: "navy",
    backgroundActive: "white:10",

    content: "white:100",
    contentAlt: "white:70",
    contentAlt2: "white:40",

    surface: "white:10",
    controlSurface: "white:10",
    controlSurfaceAlt: "white:20",
    strongSurface: "white:20",
    strongSurfaceContent: "white:100",
    strongSurfaceContentAlt: "white:70",
    strongSurfaceContentAlt2: "white:40",

    border: "white:20",
    borderSoft: "white:10",
    controlBorder: "white:20",
    controlBorderStrong: "white:40",
    tableBorder: "white:20",
    separator: "white:10",

    fieldSurface: "white:10",
    fieldBorder: "white:10",
    fieldBorderFocused: "white:40",
    focused: "primary:green",
    focusedSurface: "white:20",
    focusedSurfaceActive: "white:40",

    hint: "white:20",
    infoSurface: "white:10",
    infoSurfaceBorder: "white:20",
    infoSurfaceContent: "white:100",

    dimmed: "white:40",
    interactive: "primary:green",

    positive: "primary:green",
    positiveAlt: "primary:hover",
    positiveActive: "primary:hover",
    positiveHint: "primary:hover",
    positiveContent: "navy",

    negative: "error",
    negativeStrong: "error",
    negativeActive: "error",
    negativeHint: "error",
    negativeContent: "white:100",
    negativeSurface: "white:10",
    negativeSurfaceBorder: "white:20",
    negativeSurfaceContent: "error",
    negativeSurfaceContentAlt: "white:70",
    negativeInfoSurface: "white:10",
    negativeInfoSurfaceBorder: "white:20",
    negativeInfoSurfaceContent: "error",
    negativeInfoSurfaceContentAlt: "white:70",

    secondary: "white:10",
    secondaryActive: "white:20",
    secondaryContent: "white:100",
    secondaryHint: "white:20",
    selected: "primary:green",

    disabledSurface: "white:10",
    disabledBorder: "white:10",
    disabledContent: "white:40",

    warning: "error",
    warningAlt: "error",
    warningAltContent: "white:100",

    brandPrimary: "primary:green",
    brandPrimaryHover: "primary:hover",
    brandNavy: "navy",
    brandError: "error",
    brandWhite: "white:100",

    // Legacy brand colors from Liquity V2 theme for backward compatibility
    brandBlue: "brand:blue",
    brandBlueContent: "white:100",
    brandBlueContentAlt: "blue:50",
    brandDarkBlue: "brand:darkBlue",
    brandDarkBlueContent: "white:100",
    brandDarkBlueContentAlt: "gray:50",
    brandLightBlue: "brand:lightBlue",
    brandGolden: "brand:golden",
    brandGoldenContent: "yellow:950",
    brandGoldenContentAlt: "yellow:800",
    brandGreen: "brand:green",
    brandGreenContent: "green:950",
    brandGreenContentAlt: "green:800",
    brandCyan: "brand:cyan",
    brandCoral: "brand:coral",
    brandBrown: "brand:brown",

    primaryGradientStart: "primary:grad:start",
    primaryGradientEnd:   "primary:grad:end",

    position: "navy",
    positionContent: "white:100",
    positionContentAlt: "white:40",

    riskGradientDimmed1: "error:20",
    riskGradientDimmed2: "white:20",
    riskGradientDimmed3: "primary:20",

    // Legacy risk gradients from Liquity V2 theme for backward compatibility
    riskGradient1: "green:400",
    riskGradient2: "green:300",
    riskGradient3: "yellow:400",
    riskGradient4: "red:400",
    riskGradient5: "red:500",

    // Legacy loading gradients from Liquity V2 theme for backward compatibility
    loadingGradient1: "blue:50",
    loadingGradient2: "blue:100",
    loadingGradientContent: "blue:400",
  } satisfies Record<string, keyof typeof colors>,
} as const;

export type ThemeDescriptor = {
  name: "light";
  colors: typeof lightTheme.colors;
};
export type ThemeColorName = keyof ThemeDescriptor["colors"];

export const colorsWithDashKeys = Object.fromEntries(
  Object.entries(colors).map(([k, v]) => [k.replaceAll(":", "-"), v as string])
);

export const pandaColorTokens = Object.fromEntries(
  Object.entries(colorsWithDashKeys).map(([k, v]) => [k, { value: v }])
);

export function themeColor(theme: ThemeDescriptor, name: ThemeColorName) {
  const ref = theme.colors[name];
  const hex = colors[ref];
  if (!hex) throw new Error(`Color ${String(ref)} not found in theme palette`);
  return hex;
}

const ThemeContext = createContext({
  theme: lightTheme,
  setTheme: (_: ThemeDescriptor) => {},
});

export function useTheme() {
  const { theme, setTheme } = useContext(ThemeContext);
  return {
    color: (name: ThemeColorName) => themeColor(theme, name),
    setTheme,
    theme,
  };
}

export function Theme({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<ThemeDescriptor>(lightTheme);
  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}
