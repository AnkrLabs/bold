import { EarnPoolScreen } from "@/src/screens/EarnPoolScreen/EarnPoolScreen";
import { SboldPoolScreen } from "@/src/screens/EarnPoolScreen/SboldPoolScreen";

export function generateStaticParams() {
  return [
    { pool: "wankr" },
    { pool: "usn" },
  ];
}

export default async function Layout() {
  return <EarnPoolScreen />;
}
