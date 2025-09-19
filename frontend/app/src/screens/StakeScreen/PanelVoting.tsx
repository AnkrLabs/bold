import type { InitiativeStatus} from "@/src/liquity-governance";
import type { Address, Dnum, Entries, VoteAllocations } from "@/src/types";

import { Amount } from "@/src/comps/Amount/Amount";
import { FlowButton } from "@/src/comps/FlowButton/FlowButton";
import { LinkTextButton } from "@/src/comps/LinkTextButton/LinkTextButton";
import { Spinner } from "@/src/comps/Spinner/Spinner";
import { Tag } from "@/src/comps/Tag/Tag";
import content from "@/src/content";
import { formatDate } from "@/src/formatting";
import {
  useGovernanceState,
  useInitiativesStates,
  useInitiativesVoteTotals,
  votingPower,
} from "@/src/liquity-governance";
import { jsonStringifyWithBigInt } from "@/src/utils";
import { css } from "@/styled-system/css";
import { IconExternal} from "@liquity2/uikit";
import * as dn from "dnum";
import { useEffect, useMemo, useState } from "react";

function isInitiativeStatusActive(
  status: InitiativeStatus,
): status is Exclude<InitiativeStatus, "disabled" | "nonexistent" | "unregisterable" | "warm up"> {
  return status !== "disabled"
    && status !== "nonexistent"
    && status !== "unregisterable"
    && status !== "warm up";
}
function filterVoteAllocationsForSubmission(
  voteAllocations: VoteAllocations,
  initiativesStates: Record<Address, { status: InitiativeStatus }>,
) {
  const voteAllocationsFiltered = { ...voteAllocations };

  for (const [address, data] of Object.entries(voteAllocations) as Entries<VoteAllocations>) {
    // Filter out allocations with null or zero values. No need to explicitly set them to 0,
    // as allocated initiatives always get reset when allocating new votes.
    if (data.vote === null || dn.eq(data.value, 0)) {
      delete voteAllocationsFiltered[address];
    }

    // filter out invalid initiatives
    const initiativeStatus = initiativesStates[address]?.status;
    if (!isInitiativeStatusActive(initiativeStatus ?? "nonexistent")) {
      delete voteAllocationsFiltered[address];
    }
  }

  return voteAllocationsFiltered;
}

export function PanelVoting() {
  const governanceState = useGovernanceState();

  const initiativesAddresses = new Array<Address>();
  const initiativesStates = useInitiativesStates(initiativesAddresses);
  const voteTotals = useInitiativesVoteTotals(initiativesAddresses);

  const stakedLQTY = 0n;
  const stakedOffset = 0n;
  const epochEnd = governanceState.data?.epochEnd;
  const absoluteAllocations = 0n;

  // current vote allocations
  const [voteAllocations, setVoteAllocations] = useState<VoteAllocations>({});

  // vote allocations from user input
  const [inputVoteAllocations, setInputVoteAllocations] = useState<VoteAllocations>({});

  // fill input vote allocations from user data
  useEffect(() => {
    if (!stakedLQTY || !stakedOffset || !epochEnd || !absoluteAllocations) return;

    const stakedVotingPower = votingPower(
      stakedLQTY,
      stakedOffset,
      epochEnd,
    );

    if (stakedVotingPower === 0n) {
      setVoteAllocations({});
      setInputVoteAllocations({});
      return;
    }

    const allocations: VoteAllocations = {};

    setVoteAllocations(allocations);
    setInputVoteAllocations(allocations);
  }, [stakedLQTY, stakedOffset, epochEnd, jsonStringifyWithBigInt(absoluteAllocations)]);

  const hasAnyAllocationChange = useMemo(() => {
    if (!initiativesStates.data) {
      return false;
    }

    const serialize = (allocations: VoteAllocations) => (
      jsonStringifyWithBigInt(
        Object.entries(allocations).sort(([a], [b]) => a.localeCompare(b)),
      )
    );

    // filter the current vote allocations, taking care of removing
    // disabled + allocated initiatives as removing them doesn’t count as a change
    const voteAllocationsFiltered = filterVoteAllocationsForSubmission(
      voteAllocations,
      initiativesStates.data,
    );

    const voteAllocationsToSubmit = filterVoteAllocationsForSubmission(
      inputVoteAllocations,
      initiativesStates.data,
    );

    return serialize(voteAllocationsFiltered) !== serialize(voteAllocationsToSubmit);
  }, [voteAllocations, inputVoteAllocations, initiativesStates.data]);

  const isCutoff = governanceState.data?.period === "cutoff";

  const hasAnyAllocations = false;

  const remainingVotingPower = useMemo(() => {
    let remaining = dn.from(1, 18);

    const combinedAllocations: Record<Address, Dnum> = {};

    // input allocations (takes precedence)
    for (const [address, voteData] of Object.entries(inputVoteAllocations) as Entries<VoteAllocations>) {
      if (voteData.vote !== null) {
        combinedAllocations[address] = voteData.value;
      } else {
        delete combinedAllocations[address];
      }
    }

    for (const [address, value] of Object.entries(combinedAllocations)) {
      // check if the initiative is still active
      const initiativeState = initiativesStates.data?.[address as Address];
      if (!isInitiativeStatusActive(initiativeState?.status ?? "nonexistent")) {
        continue;
      }
      remaining = dn.sub(remaining, value);
    }

    return remaining;
  }, [
    [],
    inputVoteAllocations,
    initiativesStates.data,
  ]);

  const daysLeft = governanceState.data?.daysLeft ?? 0;
  const rtf = new Intl.RelativeTimeFormat("en", { style: "long" });

  const remaining = daysLeft > 1
    ? rtf.format(Math.ceil(daysLeft), "day")
    : daysLeft > (1 / 24)
    ? rtf.format(Math.ceil(daysLeft * 24), "hours")
    : rtf.format(Math.ceil(daysLeft * 24 * 60), "minute");

  const allowSubmit = hasAnyAllocationChange && stakedLQTY && (
    (
      dn.eq(remainingVotingPower, 0) && hasAnyAllocations
    ) || (
      dn.eq(remainingVotingPower, 1)
    )
  );

  const cutoffStartDate = governanceState.data && new Date(
    Number(governanceState.data.cutoffStart) * 1000,
  );
  const epochEndDate = governanceState.data && new Date(
    Number(governanceState.data.epochEnd) * 1000,
  );

  if (
    governanceState.status !== "success"
    || initiativesStates.status !== "success"
    || voteTotals.status !== "success"
  ) {
    return (
      <div
        className={css({
          height: 200,
          paddingTop: 40,
        })}
      >
        <div
          className={css({
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
            fontSize: 18,
            userSelect: "none",
          })}
        >
          <Spinner size={18} />
          Loading
        </div>
      </div>
    );
  }

  return (
    <section
      className={css({
        display: "flex",
        justifyContent: "center",
        flexDirection: "column",
        gap: 16,
        width: "100%",
        paddingTop: 24,
      })}
    >
      <header
        className={css({
          display: "flex",
          flexDirection: "column",
          gap: 20,
          paddingBottom: 32,
        })}
      >
        <h1
          className={css({
            fontSize: 20,
          })}
        >
          {content.stakeScreen.votingPanel.title}
        </h1>
        <div
          className={css({
            color: "contentAlt",
            fontSize: 14,
            "& a": {
              color: "accent",
              _focusVisible: {
                borderRadius: 2,
                outline: "2px solid token(colors.focused)",
                outlineOffset: 1,
              },
            },
          })}
        >
          {content.stakeScreen.votingPanel.intro}
        </div>
      </header>

      <div
        className={css({
          display: "flex",
          justifyContent: "space-between",
          alignItems: "start",
          gap: 24,
          width: "100%",
          userSelect: "none",
        })}
      >
        {governanceState.data && (
          <div
            className={css({
              flexShrink: 1,
              minWidth: 0,
              display: "grid",
              gridTemplateColumns: "1fr auto",
              alignItems: "center",
              gap: 6,
            })}
          >
            <div
              className={css({
                flexShrink: 1,
                minWidth: 0,
                whiteSpace: "nowrap",
                overflow: "hidden",
                textOverflow: "ellipsis",
              })}
            >
              Current voting round ends in{" "}
            </div>
            <Tag
              title={governanceState.data
                && `Epoch ${governanceState.data.epoch} ends on the ${
                  formatDate(new Date(Number(governanceState.data.epochEnd) * 1000))
                }`}
            >
              {governanceState.data.daysLeftRounded} {governanceState.data.daysLeftRounded === 1 ? "day" : "days"}
            </Tag>
          </div>
        )}

        <div
          className={css({
            flexShrink: 0,
            display: "grid",
            justifyContent: "end",
          })}
        >
          <LinkTextButton
            label={
              <>
                Discuss
                <IconExternal size={16} />
              </>
            }
            href="https://voting.liquity.org/"
            external
          />
        </div>
      </div>

      {isCutoff && (
        <div
          className={css({
            paddingTop: 16,
          })}
        >
          <div
            className={css({
              display: "flex",
              alignItems: "center",
              gap: 8,
              height: 40,
              paddingLeft: 12,
              fontSize: 14,
              background: "yellow:50",
              border: "1px solid token(colors.yellow:200)",
              borderRadius: 8,
            })}
          >
            <div>
              <svg width="16" height="17" fill="none">
                <path
                  fill="#E1B111"
                  d="M.668 14.333h14.667L8 1.666.668 14.333Zm8-2H7.335v-1.334h1.333v1.334Zm0-2.667H7.335V6.999h1.333v2.667Z"
                />
              </svg>
            </div>
            <div>Only downvotes are accepted today.</div>
          </div>
        </div>
      )}

      <table
        className={css({
          width: "100%",
          borderCollapse: "collapse",
          userSelect: "none",
          "& thead": {
            "& th": {
              lineHeight: 1.2,
              fontSize: 12,
              fontWeight: 400,
              color: "contentAlt",
              textAlign: "right",
              verticalAlign: "bottom",
              padding: "8px 0",
              borderBottom: "1px solid token(colors.tableBorder)",
            },
            "& th:first-child": {
              textAlign: "left",
            },
          },
          "& tbody": {
            "& td": {
              verticalAlign: "top",
              fontSize: 14,
              textAlign: "right",
              padding: 8,
            },
            "& td:first-child": {
              paddingLeft: 0,
              textAlign: "left",
            },
            "& td:last-child": {
              paddingRight: 0,
            },
            "& td:nth-of-type(2) > div, & td:nth-of-type(3) > div, & td:nth-of-type(4) > div": {
              display: "flex",
              alignItems: "center",
              justifyContent: "flex-end",
              minHeight: 34,
            },
            "& tr:last-child td": {
              paddingBottom: 16,
            },
          },
          "& tfoot": {
            fontSize: 14,
            color: "contentAlt",
            "& td": {
              borderTop: "1px solid token(colors.tableBorder)",
              padding: "16px 0 32px",
            },
            "& td:last-child": {
              textAlign: "right",
            },
          },
        })}
      >
        <thead>
          <tr>
            <th>
              Epoch<br /> Initiatives
            </th>
            <th>{hasAnyAllocations ? "Allocation" : "Decision"}</th>
          </tr>
        </thead>
        <tbody>
        </tbody>
        <tfoot>
          <tr>
            <td colSpan={2}>
              <div
                className={css({
                  display: "grid",
                  gridTemplateColumns: "1fr auto",
                  gap: 8,
                })}
              >
                <div
                  className={css({
                    overflow: "hidden",
                    display: "flex",
                  })}
                >
                  <div
                    title="100% of your voting power needs to be allocated."
                    className={css({
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                    })}
                  >
                    100% of your voting power needs to be allocated.
                  </div>
                </div>
                <div
                  className={css({
                    "--color-negative": "token(colors.negative)",
                  })}
                  style={{
                    color: dn.lt(remainingVotingPower, 0)
                      ? "var(--color-negative)"
                      : "inherit",
                  }}
                >
                  {"Remaining: "}
                  <Amount
                    format={2}
                    value={remainingVotingPower}
                    percentage
                  />
                </div>
              </div>
            </td>
          </tr>
        </tfoot>
      </table>

      <BribeMarketsInfo />

      {governanceState.data && (
        <div
          className={css({
            display: "flex",
            alignItems: "flex-start",
            gap: 8,
            marginBottom: 32,
            medium: {
              gap: 16,
            },
          })}
        >
          <div
            className={css({
              paddingTop: 12,
            })}
          >
            <div
              className={css({
                position: "relative",
                display: "flex",
                width: 16,
                height: 16,
                color: "strongSurfaceContent",
                background: "strongSurface",
                borderRadius: "50%",
                medium: {
                  width: 20,
                  height: 20,
                },
              })}
            >
              <svg
                fill="none"
                viewBox="0 0 20 20"
                className={css({
                  position: "absolute",
                  inset: 0,
                })}
              >
                <path
                  clipRule="evenodd"
                  fill="currentColor"
                  fillRule="evenodd"
                  d="m15.41 5.563-6.886 10.1-4.183-3.66 1.317-1.505 2.485 2.173 5.614-8.234 1.652 1.126Z"
                />
              </svg>
            </div>
          </div>
          <div
            className={css({
              fontSize: 14,
              medium: {
                fontSize: 16,
              },
            })}
          >
            {cutoffStartDate && epochEndDate && (
              <div>
                {isCutoff ? "Upvotes ended on " : "Upvotes accepted until "}
                <time
                  dateTime={formatDate(cutoffStartDate, "iso")}
                  title={formatDate(cutoffStartDate, "iso")}
                >
                  {formatDate(cutoffStartDate)}
                </time>.
                {" Downvotes accepted until "}
                <time
                  dateTime={formatDate(epochEndDate, "iso")}
                  title={formatDate(epochEndDate, "iso")}
                >
                  {formatDate(epochEndDate)}
                </time>.
              </div>
            )}
            <div
              className={css({
                color: "contentAlt",
              })}
            >
              Votes for epoch #{String(governanceState.data.epoch)} will be snapshotted {remaining}.
            </div>
          </div>
        </div>
      )}

      <FlowButton
        disabled={!allowSubmit}
        footnote={!allowSubmit && !stakedLQTY
          ? "You have no voting power to allocate. Please stake LQTY before voting."
          : !allowSubmit && hasAnyAllocations
          ? "You can reset your votes by allocating 0% to all initiatives."
          : allowSubmit && dn.eq(remainingVotingPower, 1)
          ? "Your votes will be reset to 0% for all initiatives."
          : null}
        label="Cast votes"
        request={{
          flowId: "allocateVotingPower",
          backLink: ["/stake/voting", "Back"],
          successLink: ["/stake/voting", "Back to overview"],
          successMessage: "Your voting power has been allocated.",
          voteAllocations: filterVoteAllocationsForSubmission(
            inputVoteAllocations,
            initiativesStates.data ?? {},
          ),
        }}
      />
    </section>
  );
}
function BribeMarketsInfo() {
  return (
    <div
      className={css({
        display: "flex",
        flexDirection: "column",
        padding: 16,
        color: "content",
        background: "fieldSurface",
        border: "1px solid token(colors.border)",
        borderRadius: 8,
        marginBottom: 16,
        marginTop: -16,
        gap: {
          base: 16,
          medium: 16,
        },
      })}
    >
      <header
        className={css({
          display: "flex",
          flexDirection: "column",
          fontSize: 16,
          gap: {
            base: 16,
            medium: 0,
          },
        })}
      >
        <h1
          className={css({
            fontWeight: 600,
          })}
        >
          Bribe Markets in Liquity V2
        </h1>
        <p
          className={css({
            fontSize: 15,
            color: "contentAlt",
          })}
        >
          Initiatives may offer bribes to incentivize votes, which are displayed in the table above and can be claimed
          afterwards on this page.
        </p>
      </header>
      <div>
        <LinkTextButton
          external
          href="https://www.liquity.org/blog/bribe-markets-in-liquity-v2-strategic-value-for-lqty-stakers"
          label={
            <span
              className={css({
                display: "flex",
                alignItems: "center",
                gap: 4,
                color: "accent",
              })}
            >
              <span>Learn more about bribes</span>
              <IconExternal size={16} />
            </span>
          }
        />
      </div>
    </div>
  );
}
