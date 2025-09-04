import { EarnPoolScreen } from "@/src/screens/EarnPoolScreen/EarnPoolScreen";
import { SboldPoolScreen } from "@/src/screens/EarnPoolScreen/SboldPoolScreen";

export function generateStaticParams() {
  return [
    { pool: "ankr" },
    { pool: "usn" },
    { pool: "sbold" },
  ];
}

export default async function Layout({
  params,
}: {
  params: Promise<{
    pool: "ankr" | "usn" | "sbold";
  }>;
}) {
  const { pool } = await params;
  return pool === "sbold"
    ? <SboldPoolScreen />
    : <EarnPoolScreen />;
}
