import type { Address, Dnum} from "@/src/types";
import type { UseQueryResult } from "@tanstack/react-query";
import type { Config as WagmiConfig } from "wagmi";

import { BribeInitiative } from "@/src/abi/BribeInitiative";
import { getProtocolContract } from "@/src/contracts";
import { dnum18} from "@/src/dnum-utils";
import { useQuery } from "@tanstack/react-query";
import { erc20Abi} from "viem";
import { useConfig as useWagmiConfig, useReadContracts } from "wagmi";
import { readContract, readContracts } from "wagmi/actions";

export type InitiativeStatus =
  | "nonexistent"
  | "warm up"
  | "skip"
  | "claimable"
  | "claimed"
  | "unregisterable"
  | "disabled";

export function initiativeStatusFromNumber(status: number): InitiativeStatus {
  const statuses: Record<number, InitiativeStatus> = {
    0: "nonexistent",
    1: "warm up",
    2: "skip",
    3: "claimable",
    4: "claimed",
    5: "unregisterable",
    6: "disabled",
  };
  return statuses[status] || "nonexistent";
}

export function useGovernanceState() {
  const Governance = getProtocolContract("Governance");
  return useReadContracts({
    contracts: [{
      ...Governance,
      functionName: "epoch",
    }, {
      ...Governance,
      functionName: "epochStart",
    }, {
      ...Governance,
      functionName: "globalState",
    }, {
      ...Governance,
      functionName: "secondsWithinEpoch",
    }, {
      ...Governance,
      functionName: "EPOCH_DURATION",
    }, {
      ...Governance,
      functionName: "EPOCH_VOTING_CUTOFF",
    }],
    query: {
      select: ([
        epoch_,
        epochStart_,
        globalState,
        secondsWithinEpoch,
        GOVERNANCE_EPOCH_DURATION,
        GOVERNANCE_EPOCH_VOTING_CUTOFF,
      ]) => {
        const epoch = epoch_.result ?? 0n;
        const epochStart = epochStart_.result ?? 0n;
        const epochDuration = GOVERNANCE_EPOCH_DURATION.result ?? 0n;
        const epochVotingCutoff = GOVERNANCE_EPOCH_VOTING_CUTOFF.result ?? 0n;
        const cutoffStart = epochStart + epochVotingCutoff;

        const period: "cutoff" | "voting" = (secondsWithinEpoch.result ?? 0n) > epochVotingCutoff
          ? "cutoff"
          : "voting";

        const seconds = Number(secondsWithinEpoch.result ?? 0n);
        const daysLeft = (Number(epochDuration) - seconds) / (24 * 60 * 60);
        const daysLeftRounded = Math.ceil(daysLeft);

        return {
          countedVoteLQTY: globalState.result?.[0] ?? 0n,
          countedVoteOffset: globalState.result?.[1] ?? 0n,
          cutoffStart,
          daysLeft,
          daysLeftRounded,
          epoch,
          epochEnd: epochStart + epochDuration,
          epochStart,
          period,
          secondsWithinEpoch: secondsWithinEpoch.result,
        };
      },
    },
  });
}

export function useNamedInitiatives() {
  throw new Error("undefined subgraph query");
}

export function useInitiativesStates(initiatives: Address[]) {
  const wagmiConfig = useWagmiConfig();

  const Governance = getProtocolContract("Governance");

  return useQuery({
    queryKey: ["initiativesStates", initiatives.join("")],
    queryFn: async () => {
      const results = await readContracts(wagmiConfig, {
        contracts: initiatives.map((address) => ({
          ...Governance,
          functionName: "getInitiativeState",
          args: [address],
        } as const)),
      });

      const initiativesStates: Record<Address, {
        status: InitiativeStatus;
        lastEpochClaim: bigint;
        claimableAmount: bigint;
      }> = {};

      for (const [i, { result }] of results.entries()) {
        if (result && initiatives[i]) {
          initiativesStates[initiatives[i]] = {
            status: initiativeStatusFromNumber(result[0]),
            lastEpochClaim: result[1],
            claimableAmount: result[2],
          };
        }
      }

      return initiativesStates;
    },
  });
}

export type VoteTotals = {
  voteLQTY: bigint;
  voteOffset: bigint;
  vetoLQTY: bigint;
  vetoOffset: bigint;
};

export function useInitiativesVoteTotals(initiatives: Address[]) {
  const wagmiConfig = useWagmiConfig();
  const Governance = getProtocolContract("Governance");

  return useQuery({
    queryKey: ["initiativesVoteTotals", initiatives.join("")],
    queryFn: async () => {
      const voteTotals: Record<Address, VoteTotals> = {};

      const results = await readContracts(wagmiConfig, {
        contracts: initiatives.map((address) => ({
          ...Governance,
          functionName: "initiativeStates",
          args: [address],
        } as const)),
      });

      for (const [i, { result }] of results.entries()) {
        if (result && initiatives[i]) {
          const [voteLQTY, voteOffset, vetoLQTY, vetoOffset] = result;
          voteTotals[initiatives[i]] = {
            voteLQTY,
            voteOffset,
            vetoLQTY,
            vetoOffset,
          };
        }
      }

      return voteTotals;
    },
  });
}

export async function getUserAllocations(
  wagmiConfig: WagmiConfig,
  account: Address,
  initiatives?: Address[],
) {
  wagmiConfig;
  account;
  initiatives;
  throw new Error("undefined subgraph query");
}

export async function getUserAllocatedInitiatives(
  wagmiConfig: WagmiConfig,
  account: Address,
  initiatives?: Address[],
) {
  wagmiConfig;
  account;
  initiatives;
  throw new Error("undefined subgraph query");
}

export async function getUserStates(
  wagmiConfig: WagmiConfig,
  account: Address,
) {
  const Governance = getProtocolContract("Governance");
  const result = await readContract(wagmiConfig, {
    ...Governance,
    functionName: "userStates",
    args: [account],
  });

  const [
    unallocatedLQTY,
    unallocatedOffset,
    allocatedLQTY,
    allocatedOffset,
  ] = result;

  return {
    allocatedLQTY,
    allocatedOffset,
    stakedLQTY: allocatedLQTY + unallocatedLQTY,
    stakedOffset: allocatedOffset + unallocatedOffset,
    unallocatedLQTY,
    unallocatedOffset,
  };
}

export function useGovernanceUser(account: Address | null) {
  account;
  throw new Error("undefined subgraph query");
}

// votingPower(t) = lqty * t - offset
export function votingPower(
  stakedLQTY: bigint,
  offset: bigint,
  timestampInSeconds: bigint,
) {
  return stakedLQTY * timestampInSeconds - offset;
}

export function useVotingPower(
  account: Address | null,
  callback: (share: Dnum | null) => void,
  updatesPerSecond: number = 30,
) {
  account;
  callback;
  updatesPerSecond;
  throw new Error("undefined subgraph query");
}

export function useGovernanceStats() {
  throw new Error("undefined subgraph query");
}

type ClaimData = {
  epoch: number;
  prevLQTYAllocationEpoch: number;
  prevTotalLQTYAllocationEpoch: number;
};

type BribeClaim = {
  bribeTokens: Array<{
    address: Address;
    symbol: string;
    amount: Dnum;
  }>;
  claimableInitiatives: Array<{
    initiative: Address;
    boldAmount: Dnum;
    bribeTokenAmount: Dnum;
    bribeTokenAddress: Address;
    epochs: number[];
    claimData: ClaimData[];
  }>;
  totalBold: Dnum;
};

// represents an initiative bribe for a given epoch
type InitiativeBribe = {
  boldAmount: Dnum;
  tokenAmount: Dnum;
  tokenAddress: Address;
  tokenSymbol: string;
};

export function useCurrentEpochBribes(
  initiatives: Address[],
): UseQueryResult<Record<Address, InitiativeBribe>> {
  const wagmiConfig = useWagmiConfig();
  const govState = useGovernanceState();

  return useQuery({
    queryKey: [
      "currentEpochBribes",
      initiatives.join(""),
      String(govState.data?.epoch),
    ],
    queryFn: async () => {
      if (!govState.data || initiatives.length === 0) {
        return {};
      }

      const bribeTokens = await readContracts(wagmiConfig, {
        contracts: initiatives.map((initiative) => ({
          abi: BribeInitiative,
          address: initiative,
          functionName: "bribeToken",
        } as const)),
        // this is needed because some initiatives may revert if they don't have a bribe token
        allowFailure: true,
      });

      // initiatives with a bribe token
      const bribeInitiatives: Array<{
        initiative: Address;
        bribeToken: Address;
      }> = [];

      for (const [index, bribeTokenResult] of bribeTokens.entries()) {
        if (bribeTokenResult.result && initiatives[index]) {
          bribeInitiatives.push({
            initiative: initiatives[index],
            bribeToken: bribeTokenResult.result,
          });
        }
      }

      if (bribeInitiatives.length === 0) {
        return {};
      }

      const bribeAmounts = await readContracts(wagmiConfig, {
        contracts: bribeInitiatives.map(({ initiative }) => ({
          abi: BribeInitiative,
          address: initiative,
          functionName: "bribeByEpoch",
          args: [govState.data.epoch],
        } as const)),
        allowFailure: false,
      });

      const tokenSymbols = await readContracts(wagmiConfig, {
        contracts: bribeInitiatives.map(({ bribeToken }) => ({
          abi: erc20Abi,
          address: bribeToken,
          functionName: "symbol",
        } as const)),
        allowFailure: false,
      });

      const bribes: Record<Address, InitiativeBribe> = {};

      for (const [index, [remainingBold, remainingBribeToken]] of bribeAmounts.entries()) {
        const bribeInitiative = bribeInitiatives[index];
        if (!bribeInitiative) continue;

        const { initiative, bribeToken } = bribeInitiative;

        bribes[initiative] = {
          boldAmount: dnum18(remainingBold),
          tokenAmount: dnum18(remainingBribeToken),
          tokenAddress: bribeToken,
          tokenSymbol: tokenSymbols[index] ?? "Unknown",
        };
      }

      return bribes;
    },
    enabled: Boolean(govState.data && initiatives.length > 0),
  });
}

export function useBribingClaim(
  account: Address | null,
): UseQueryResult<BribeClaim | null> {
  account;
  throw new Error("undefined subgraph query");
}
