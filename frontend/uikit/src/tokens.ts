import tokenBold from "./token-icons/bold.svg";
import tokenEth from "./token-icons/eth.svg";
import tokenWankr from "./token-icons/wankr.svg";

// any external token, without a known symbol
export type ExternalToken = {
  icon: string;
  name: string;
  symbol: string;
};

// a token with a known symbol (TokenSymbol)
export type Token = ExternalToken & {
  icon: string;
  name: string;
  symbol: TokenSymbol;
};

export type TokenSymbol =
  | "BOLD"
  | "MINT"
  | "WANKR"
  | "USN";

export type CollateralSymbol =
  & TokenSymbol
  & (
    | "WANKR"
    | "USN"
  );

export function isTokenSymbol(symbolOrUrl: string): symbolOrUrl is TokenSymbol {
  return (
    symbolOrUrl === "BOLD"
    || symbolOrUrl === "WANKR"
    || symbolOrUrl === "USN"
  );
}

export function isCollateralSymbol(symbol: string): symbol is CollateralSymbol {
  return (
    symbol === "WANKR"
    || symbol === "USN"
  );
}

export type CollateralToken = Token & {
  collateralRatio: number;
  symbol: CollateralSymbol;
};

export const BOLD: Token = {
  icon: tokenBold,
  name: "MINT",
  symbol: "BOLD" as const,
} as const;

export const WANKR: CollateralToken = {
  collateralRatio: 1.1,
  icon: tokenWankr,
  name: "wANKR",
  symbol: "WANKR" as const,
} as const;

export const USN: CollateralToken = {
  collateralRatio: 1.2,
  icon: tokenEth,
  name: "USN",
  symbol: "USN" as const,
} as const;

export const COLLATERALS: CollateralToken[] = [
  WANKR,
  USN,
];

export const TOKENS_BY_SYMBOL = {
  BOLD,
  MINT: BOLD,
  WANKR,
  USN,
} as const;
