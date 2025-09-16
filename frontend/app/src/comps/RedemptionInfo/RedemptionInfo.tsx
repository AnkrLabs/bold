import { LinkTextButton } from "@/src/comps/LinkTextButton/LinkTextButton";
import content from "@/src/content";
import { css } from "@/styled-system/css";
import { IconExternal } from "@liquity2/uikit";
import { a, useInView, useTransition } from "@react-spring/web";
import { memo } from "react";

const { title, subtitle, infoItems, learnMore } = content.redemptionInfo;

const iconComponents = {
  bold: BoldIcon,
  redemption: BoldIcon,
  interest: BoldIcon,
} as const;

export const RedemptionInfo = memo(function RedemptionInfo() {
  const [ref, inView] = useInView({ once: true });

  const iconsTrail = useTransition(
    infoItems.map((item) => ({ ...item, inView })),
    {
      keys: ({ text, inView }) => `${text}-${inView}`,
      from: {
        opacity: 0,
        transform: `
          scale3d(0.2, 0.2, 1)
          rotate3d(0, 0, 1, -180deg)
        `,
      },
      enter: {
        opacity: 1,
        transform: `
          scale3d(1, 1, 1)
          rotate3d(0, 0, 1, 0deg)
        `,
      },
      trail: 100,
      delay: 50,
      config: {
        mass: 1,
        tension: 800,
        friction: 60,
      },
    },
  );

  return (
    <section
      className={css({
        display: "flex",
        flexDirection: "column",
        gap: 16,
        padding: 16,
        color: "content",
        background: "fieldSurface",
        border: "1px solid token(colors.border)",
        borderRadius: 8,
        medium: {
          gap: 32,
        },
      })}
    >
      <header
        className={css({
          display: "flex",
          flexDirection: "column",
          fontSize: 16,
          gap: {
            base: 8,
            medium: 0,
          },
        })}
      >
        <h1
          className={css({
            fontWeight: 600,
          })}
        >
          {title}
        </h1>
        <p
          className={css({
            fontSize: 15,
            color: "contentAlt",
          })}
        >
          {subtitle}
        </p>
      </header>

      <ul
        ref={ref}
        className={css({
          display: "grid",
          gridTemplateColumns: "none",
          gap: 16,
          fontSize: 15,
          medium: {
            gridTemplateColumns: "repeat(3, 1fr)",
            gap: 24,
            fontSize: 14,
          },
        })}
      >
        {iconsTrail((props, item, _, index) => {
          const Icon = iconComponents[item.icon];
          return (
            <li
              key={index}
              className={css({
                display: "flex",
                gap: 12,
                flexDirection: "row",
                alignItems: "flex-start",
                medium: {
                  gap: 16,
                  flexDirection: "column",
                  alignItems: "flex-start",
                },
              })}
            >
              <div
                className={css({
                  display: "flex",
                  paddingTop: {
                    base: 2,
                    medium: 0,
                  },
                })}
              >
                <a.div
                  className={css({
                    display: "grid",
                    placeItems: "center",
                    width: 28,
                    height: 28,
                    transformOrigin: "center",
                  })}
                  style={props}
                >
                  <Icon />
                </a.div>
              </div>
              <div>{item.text}</div>
            </li>
          );
        })}
      </ul>

      {learnMore?.href && (<div>
        <LinkTextButton
          href={learnMore.href}
          rel="noopener noreferrer"
          target="_blank"
          label={
            <span
              className={css({
                display: "flex",
                alignItems: "center",
                gap: 4,
                color: "accent",
              })}
            >
              <span>
                {learnMore.text}
              </span>
              <IconExternal size={16} />
            </span>
          }
        />
      </div>)}
    </section>
  );
});

function BoldIcon() {
  return (
    <svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="32" height="32" rx="16" fill="#011837"/>
      <rect x="0.5" y="0.5" width="31" height="31" rx="15.5" stroke="#88FD9D" stroke-opacity="0.1"/>
      <g>
        <path
          d="M16.0147 26.2868C16.0147 26.2868 6.27935 24.3378 6.27935 14.7525C6.27935 12.5662 7.31106 9.25 7.31106 9.25C10.5804 10.0991 14.38 12.3145 16.0147 14.6768C17.5833 12.6401 20.3839 10.5524 24.743 9.25C25.3629 10.9594 25.75 12.8061 25.75 14.7525C25.75 24.5135 16.0147 26.2868 16.0147 26.2868Z"
          fill="#88FD9D"/>
        <path
          d="M15.9224 26.7503L16.0109 26.768L16.0998 26.7518L16.0152 26.2872L15.9224 26.7503ZM6.752 14.753C6.752 13.7171 6.99895 12.3856 7.25545 11.2894C7.38251 10.7464 7.50967 10.2703 7.60501 9.93023C7.61484 9.89515 7.62437 9.86152 7.63348 9.82944C9.09389 10.2581 10.6434 10.9517 12.0301 11.7993C13.5622 12.7358 14.8609 13.839 15.6268 14.9459L15.9948 15.4776L16.3892 14.9653C17.8369 13.0858 20.4152 11.1203 24.4475 9.83596C24.9642 11.3808 25.2783 13.0287 25.2783 14.753C25.2783 19.4438 22.952 22.1943 20.6164 23.7906C19.4425 24.5929 18.2655 25.1028 17.3806 25.4119C16.9389 25.5661 16.5719 25.6697 16.3173 25.7343C16.1901 25.7666 16.0911 25.7891 16.025 25.8034C16.023 25.8038 16.0211 25.8042 16.0192 25.8046C16.0172 25.8041 16.0151 25.8037 16.013 25.8032C15.9467 25.7877 15.8476 25.7634 15.7201 25.729C15.4652 25.66 15.0978 25.5504 14.6556 25.3893C13.7698 25.0666 12.5916 24.5402 11.4163 23.7264C9.07598 22.1057 6.752 19.3536 6.752 14.753ZM5.80762 14.753C5.80762 19.7376 8.35133 22.7526 10.8786 24.5028C12.1372 25.3744 13.3928 25.9344 14.3323 26.2767C14.8028 26.448 15.1961 26.5655 15.4735 26.6406C15.6123 26.6781 15.7222 26.7051 15.7986 26.7229C15.8368 26.7318 15.8667 26.7384 15.8875 26.7429C15.8979 26.7452 15.9061 26.7469 15.9119 26.7481C15.9148 26.7487 15.9172 26.7492 15.9189 26.7496C15.9198 26.7497 15.9206 26.7499 15.9212 26.75C15.9214 26.7501 15.9218 26.7502 15.9219 26.7502C15.9222 26.7501 15.9242 26.7418 16.0152 26.2872C16.0998 26.7518 16.1 26.7518 16.1003 26.7517C16.1005 26.7517 16.1008 26.7516 16.1011 26.7516C16.1017 26.7515 16.1024 26.7513 16.1033 26.7512C16.1051 26.7508 16.1075 26.7504 16.1104 26.7498C16.1163 26.7487 16.1245 26.7471 16.1349 26.745C16.1558 26.7409 16.1857 26.7348 16.224 26.7265C16.3005 26.71 16.4107 26.685 16.5496 26.6497C16.8274 26.5792 17.221 26.468 17.692 26.3035C18.6324 25.975 19.8893 25.4315 21.1493 24.5703C23.6813 22.8398 26.2227 19.8231 26.2227 14.753C26.2227 12.7433 25.8229 10.842 25.1874 9.08946L25.0354 8.67041L24.6083 8.79798C20.5019 10.0249 17.7202 11.9468 16.0293 13.9127C15.1551 12.8422 13.9047 11.8383 12.5226 10.9935C10.9239 10.0163 9.11398 9.23071 7.4302 8.79341L6.9944 8.68023L6.86066 9.11017L7.31152 9.25044C6.86783 9.1124 6.86074 9.11024 6.86061 9.11027C6.8606 9.11031 6.86058 9.1104 6.86056 9.11048C6.86051 9.11064 6.86043 9.11084 6.86035 9.1111C6.86019 9.11161 6.85997 9.11234 6.85968 9.11326C6.85912 9.11508 6.85831 9.11769 6.85727 9.12107C6.85517 9.12786 6.85214 9.13779 6.84822 9.15067C6.84037 9.17646 6.82897 9.21419 6.81456 9.26272C6.78572 9.35977 6.74475 9.5002 6.69567 9.67529C6.59756 10.0253 6.46675 10.5149 6.33589 11.0742C6.07653 12.1827 5.80762 13.6025 5.80762 14.753Z"
          fill="#88FD9D"/>
        <path
          d="M24.9628 8.42253C24.9628 8.42253 27.8248 14.9339 25.3247 19.9759C22.8247 25.0179 15.9094 26.6812 15.9094 26.6812C15.9094 26.6812 13.0474 20.1699 15.5475 15.1279C18.0475 10.0859 24.9628 8.42253 24.9628 8.42253Z"
          fill="#011837"/>
        <path
          d="M23.7569 19.1985C24.7648 17.1658 24.7337 14.7184 24.3585 12.6159C24.2224 11.8533 24.0466 11.1676 23.8794 10.6075C23.3324 10.8135 22.6801 11.0886 21.9908 11.4419C20.0901 12.4159 18.1232 13.8726 17.1153 15.9053C16.1074 17.938 16.1385 20.3854 16.5137 22.4878C16.6498 23.2504 16.8256 23.9361 16.9928 24.4962C17.5398 24.2902 18.1921 24.0151 18.8815 23.6619C20.7821 22.6879 22.749 21.2311 23.7569 19.1985ZM25.2952 20.0348C22.7708 25.0308 15.9094 26.6812 15.9094 26.6812L15.8778 26.6069C15.5738 25.8761 13.2234 19.9048 15.5184 15.187L15.5475 15.1279C18.0452 10.0907 24.9497 8.42568 24.9628 8.42252C24.9628 8.42252 27.8248 14.9339 25.3247 19.9759L25.2952 20.0348Z"
          fill="#88FD9D"/>
      </g>
    </svg>
  );
}
