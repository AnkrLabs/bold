import { EarnPoolScreen } from "@/src/screens/EarnPoolScreen/EarnPoolScreen";

export function generateStaticParams() {
  return [
    { pool: "wankr" },
    { pool: "usn" },
  ];
}

export default async function Layout() {
  return <EarnPoolScreen />;
}
