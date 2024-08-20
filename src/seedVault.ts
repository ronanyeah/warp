import { registerPlugin } from "@capacitor/core";
import { SeedAuth } from "./ports";

interface SeedVault {
  assertPermissions(): Promise<void>;
  authorizeSeed(): Promise<void>;
  deauthorizeSeed(args: { authToken: number }): Promise<void>;
  signBytes(args: {
    authToken: number;
    bytes: number[];
  }): Promise<{ signed: number[] }>;
  getPubkey(args: { authToken: number }): Promise<{ pubkey: number[] }>;
  getAuthorizedSeeds(): Promise<{ seeds: SeedAuth[] }>;
}

const SeedVault = registerPlugin<SeedVault>("SeedVault");

export default SeedVault;
