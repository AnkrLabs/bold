import type { ComponentType } from "react";

import { css } from "@/styled-system/css";
import { token } from "@/styled-system/tokens";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { MenuItem } from "./MenuItem";

export type MenuItem = [
  label: string,
  url: string,
  Icon: ComponentType<{}>,
];

export function Menu({
  menuItems,
}: {
  menuItems: MenuItem[];
}) {
  const pathname = usePathname();
  return (
    <nav
      className={css({
        display: "none",
        large: {
          display: "block",
        },
      })}
    >
      <ul
        className={css({
          position: "relative",
          zIndex: 2,
          display: "flex",
          gap: 32,
          height: "100%",
        })}
      >
        {menuItems.map(([label, href]) => {
          const selected = href === "/" ? pathname === "/" : pathname.startsWith(href);
          console.log('selected', selected);
          return (
            <li key={label + href}>
              <Link
                href={href}
                className={css({
                  display: "flex",
                  height: "100%",
                  borderBottom: selected ? `2px solid token(colors.content)` : "2px solid transparent",

                  _active: {
                    translate: "0 1px",
                  },
                  _focusVisible: {
                    borderRadius: 4,
                  },
                })}
                style={{
                  color: selected ? token(`colors.content`) : 'rgba(255, 255, 255, 0.70)',
                }}
              >
                <MenuItem
                  icon={null}
                  label={label}
                  selected={selected}
                />
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
