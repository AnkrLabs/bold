import tokenBold from "./token-icons/bold.svg";
import tokenEth from "./token-icons/eth.svg";
import tokenSbold from "./token-icons/sbold.svg";

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
  | "SBOLD"
  | "ANKR"
  | "USN";

export type CollateralSymbol =
  & TokenSymbol
  & (
    | "ANKR"
    | "USN"
  );

export function isTokenSymbol(symbolOrUrl: string): symbolOrUrl is TokenSymbol {
  return (
    symbolOrUrl === "BOLD"
    || symbolOrUrl === "ANKR"
    || symbolOrUrl === "USN"
  );
}

export function isCollateralSymbol(symbol: string): symbol is CollateralSymbol {
  return (
    symbol === "ANKR"
    || symbol === "USN"
  );
}

export type CollateralToken = Token & {
  collateralRatio: number;
  symbol: CollateralSymbol;
};

export const BOLD: Token = {
  icon: tokenBold,
  name: "BOLD",
  symbol: "BOLD" as const,
} as const;

export const SBOLD: Token = {
  icon: tokenSbold,
  name: "sBOLD",
  symbol: "SBOLD" as const,
} as const;

export const ANKR: CollateralToken = {
  collateralRatio: 1.1,
  icon: tokenEth,
  name: "ANKR",
  symbol: "ANKR" as const,
} as const;

export const USN: CollateralToken = {
  collateralRatio: 1.2,
  icon: tokenEth,
  name: "USN",
  symbol: "USN" as const,
} as const;

export const COLLATERALS: CollateralToken[] = [
  ANKR,
  USN,
];

export const TOKENS_BY_SYMBOL = {
  BOLD,
  ANKR,
  USN,
  SBOLD,
} as const;
