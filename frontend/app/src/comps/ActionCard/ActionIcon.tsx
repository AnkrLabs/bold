import type { ReactNode } from "react";

import { a, useSpring } from "@react-spring/web";
import { match } from "ts-pattern";

type IconProps = {
  background: string;
  foreground: string;
  state: "initial" | "idle" | "active";
};

export const springConfig = {
  mass: 1,
  tension: 800,
  friction: 40,
};

export function ActionIcon({
  colors,
  iconType,
  state,
}: {
  colors: {
    background: string;
    foreground: string;
  };
  iconType: "borrow" | "multiply" | "earn" | "stake";
  state: IconProps["state"];
}) {
  const Icon = match(iconType)
    .with("borrow", () => ActionIconBorrow)
    .with("multiply", () => ActionIconLeverage)
    .with("earn", () => ActionIconEarn)
    .with("stake", () => ActionIconStake)
    .exhaustive();

  return (
    <Icon
      background={colors.background}
      foreground={colors.foreground}
      state={state}
    />
  );
}

function ActionIconBorrow(_: IconProps) {
  return (
    <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="40" height="40" rx="20" fill="#011837"/>
      <path
        d="M30 19.8095V20.2381V20C30 14.4772 25.5228 10 20 10V10C14.4772 10 10 14.4772 10 20V20C10 25.5228 14.4772 30 20 30H20.2381H19.8095"
        stroke="#88FD9D" strokeWidth="2.5" strokeLinejoin="round"/>
      <path d="M23 18.6665L19 22.6665L23 26.6665" stroke="#88FD9D" strokeWidth="2" strokeLinecap="round"/>
      <path d="M26.6665 30.6665L30.6665 26.6665L26.6665 22.6665" stroke="#88FD9D" strokeWidth="2"
            strokeLinecap="round"/>
    </svg>

  );
}

function ActionIconLeverage({ foreground, state }: IconProps) {
  const { t1, t2 } = useSpring({
    t1: state === 'active'
      ? 'translate(0 56) scale(0)'
      : 'translate(0 36) scale(2)',
    t2: state === 'active'
      ? 'translate(-6 -6) scale(6.8)'
      : 'translate(20 0) scale(3.6)',
    config: springConfig,
  });

  return (
    <IconBase>
      <a.path
        fill={foreground}
        d="
          M0 0
          h 10
          v 10
          h -10
          z
        "
        transform={t1}
      />
      <a.path
        fill={foreground}
        d="
          M0 0
          h 10
          v 10
          h -10
          z
        "
        transform={t2}
      />
    </IconBase>
  );
}

function ActionIconEarn(_: IconProps) {
  return (
    <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="40" height="40" rx="20" fill="#011837"/>
      <ellipse cx="5.625" cy="2.8125" rx="5.625" ry="2.8125" transform="matrix(-1 0 0 1 30 10.625)" stroke="#88FD9D" strokeWidth="2" strokeLinejoin="round"/>
      <path d="M18.75 13.4375C18.75 14.9908 21.2684 16.25 24.375 16.25C27.4816 16.25 30 14.9908 30 13.4375" stroke="#88FD9D" strokeWidth="2" strokeLinejoin="round"/>
      <path d="M18.75 22.1875C18.75 23.7408 21.2684 25 24.375 25C27.4816 25 30 23.7408 30 22.1875" stroke="#88FD9D" strokeWidth="2" strokeLinejoin="round"/>
      <path d="M18.75 17.8125C18.75 19.3658 21.2684 20.625 24.375 20.625C27.4816 20.625 30 19.3658 30 17.8125" stroke="#88FD9D" strokeWidth="2" strokeLinejoin="round"/>
      <ellipse cx="5.625" cy="2.8125" rx="5.625" ry="2.8125" transform="matrix(-1 0 0 1 18.75 19.375)" stroke="#88FD9D" strokeWidth="2" strokeLinejoin="round"/>
      <path d="M18.75 13.4375V26.5625C18.75 28.1158 21.2684 29.375 24.375 29.375C27.4816 29.375 30 28.1158 30 26.5625V13.4375" stroke="#88FD9D" strokeWidth="2" strokeLinejoin="round"/>
      <path d="M7.5 22.5V26.5625C7.5 28.1158 10.0184 29.375 13.125 29.375C16.2316 29.375 18.75 28.1158 18.75 26.5625V22.5" stroke="#88FD9D" strokeWidth="2" strokeLinejoin="round"/>
    </svg>
  );
}

export function ActionIconStake({ foreground, state }: IconProps) {
  const active = state === "active";

  // style transform
  const tr = (x: number, y: number, w: number = 1, h: number = 1) => `
    translate(${x * 56 / 3}px, ${y * 56 / 3}px)
    scale(${w}, ${h})
  `;

  const { sq1, sq2, sq3, sq4 } = useSpring({
    sq1: active ? tr(2, 0, 1, 3) : tr(1, 0),
    sq2: active ? tr(0, 0, 3, 1) : tr(2, 1),
    sq3: active ? tr(0, 0, 1, 3) : tr(1, 2),
    sq4: active ? tr(0, 2, 3, 1) : tr(0, 1),
    config: springConfig,
  });

  // square
  // const { sq1, sq2, sq3, sq4 } = useSpring({
  //   sq1: active ? tr(0, 0) : tr(1, 0),
  //   sq2: active ? tr(2, 0) : tr(2, 1),
  //   sq3: active ? tr(2, 2) : tr(1, 2),
  //   sq4: active ? tr(0, 2) : tr(0, 1),
  //   config: springConfig,
  // });

  // arrow compact
  // const { sq1, sq2, sq3, sq4 } = useSpring({
  //   sq1: active ? pos(0.5, 0.5) : pos(1, 0),
  //   sq2: active ? pos(1.5, 0.5) : pos(2, 1),
  //   sq3: active ? pos(1.5, 1.5) : pos(1, 2),
  //   sq4: active ? pos(0, 2) : pos(0, 1),
  //   config: springConfig,
  // });

  // arrow wide
  // const { sq1, sq2, sq3, sq4 } = useSpring({
  //   sq1: active ? tr(1, 0, 1) : tr(1, 0, 1),
  //   sq2: active ? tr(2, 0, 1) : tr(2, 1, 1),
  //   sq3: active ? tr(2, 1, 1) : tr(1, 2, 1),
  //   sq4: active ? tr(0, 2, 1) : tr(0, 1, 1),
  //   config: springConfig,
  // });

  return (
    <IconBase>
      {[sq1, sq2, sq3, sq4].map((transform, index) => (
        <a.rect
          key={index}
          fill={foreground}
          width={56 / 3}
          height={56 / 3}
          style={{
            transform,
            transformOrigin: "0 0",
          }}
        />
      ))}
    </IconBase>
  );
}

function IconBase({ children }: { children: ReactNode }) {
  return (
    <svg
      width="24"
      height="24"
      viewBox="0 0 56 56"
      style={{ overflow: "visible" }}
    >
      {children}
    </svg>
  );
}
