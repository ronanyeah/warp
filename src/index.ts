import "@fontsource/turret-road/400.css";
import "@fontsource/roboto/400.css";

const { Elm } = require("./Main.elm");

import { ElmApp, SeedAuth } from "./ports";
import SeedVault from "./seedVault";
import {
  MIST_PER_SUI,
  SUI_TYPE_ARG,
  isValidSuiNSName,
  isValidSuiAddress,
} from "@mysten/sui/utils";
import { Ed25519PublicKey, Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import {
  messageWithIntent,
  toSerializedSignature,
} from "@mysten/sui/cryptography";
import { Transaction } from "@mysten/sui/transactions";
import { SuiClient } from "@mysten/sui/client";
import { blake2b } from "@noble/hashes/blake2b";
import { SuinsClient } from "@mysten/suins";

// @ts-ignore
const DEV: boolean = __DEV;

const provider = new SuiClient({
  url: "https://fullnode.mainnet.sui.io:443",
});

const suinsClient = new SuinsClient({
  client: provider,
  network: "mainnet",
});

(async () => {
  const app: ElmApp = Elm.Main.init({
    node: document.getElementById("app"),
    flags: {},
  });

  app.ports.authorizeSeeds.subscribe(() =>
    (async () => {
      if (!DEV) {
        await SeedVault.assertPermissions();
        await SeedVault.authorizeSeed();
      }
      const seeds = await fetchAuthed();
      app.ports.authedCb.send(seeds);
    })().catch((e) => {
      console.error(e);
    })
  );

  app.ports.deauthorize.subscribe((authToken) =>
    (async () => {
      if (DEV) {
        return;
      }
      await SeedVault.deauthorizeSeed({ authToken });
      const seeds = await fetchAuthed();
      app.ports.authedCb.send(seeds);
    })().catch((e) => {
      console.error(e);
    })
  );

  app.ports.refreshPrice.subscribe((wallet) =>
    (async () => {
      const bal = await provider.getBalance({
        owner: wallet,
        coinType: SUI_TYPE_ARG,
      });

      app.ports.priceCb.send(Number(bal.totalBalance) / Number(MIST_PER_SUI));
    })().catch((e) => {
      console.error(e);
      app.ports.priceCb.send(null);
    })
  );

  app.ports.fetchSeed.subscribe((auth) =>
    (async () => {
      if (DEV) {
        const pk = new Ed25519Keypair().getPublicKey();
        return app.ports.seedCb.send({
          pubkey: pk.toSuiAddress(),
          pubkeyBytes: Array.from(pk.toRawBytes()),
          balance: Math.random() * 1_000,
          auth,
        });
      }

      const pubk = await fetchPubkey(auth.authToken);

      const bal = await provider.getBalance({
        owner: pubk.toSuiAddress(),
        coinType: SUI_TYPE_ARG,
      });

      const seed = {
        pubkey: pubk.toSuiAddress(),
        pubkeyBytes: Array.from(pubk.toRawBytes()),
        balance: Number(bal.totalBalance) / Number(MIST_PER_SUI),
        auth,
      };
      app.ports.seedCb.send(seed);
    })().catch((e) => {
      console.error(e);
      app.ports.seedCb.send(null);
    })
  );

  app.ports.copy.subscribe((val) => {
    navigator.clipboard.writeText(val);
  });

  app.ports.submitTx.subscribe((data) =>
    (async () => {
      const addr = await (async () => {
        if (isValidSuiAddress(String(data.recipient))) {
          return data.recipient;
        } else {
          const val = data.recipient.includes(".sui")
            ? data.recipient
            : `@${data.recipient.replace("@", "")}`;
          if (isValidSuiNSName(val)) {
            const ns = await suinsClient.getNameRecord(val);
            return ns.targetAddress;
          } else {
            return null;
          }
        }
      })();

      console.log(addr);

      if (!addr) {
        return app.ports.sigCb.send(null);
      }

      if (DEV) {
        return app.ports.sigCb.send("wut");
      }

      const pubk = new Ed25519PublicKey(new Uint8Array(data.seed.pubkeyBytes));

      const tx = buildTx(pubk, data.amount, addr);
      const txBytes = await tx.build({ client: provider });

      const intentMessage = messageWithIntent("TransactionData", txBytes);
      const intentBytes = blake2b(intentMessage, { dkLen: 32 });

      const signRes = await SeedVault.signBytes({
        authToken: data.seed.auth.authToken,
        bytes: Array.from(intentBytes),
      });
      const signedTx = new Uint8Array(signRes.signed);
      const sigOk =
        (await pubk.verify(intentBytes, signedTx)) &&
        (await pubk.verifyTransaction(txBytes, signedTx));
      if (sigOk) {
        const signature = toSerializedSignature({
          signature: signedTx,
          signatureScheme: "ED25519",
          publicKey: pubk,
        });
        const res = await provider.executeTransactionBlock({
          transactionBlock: txBytes,
          signature: signature,
          options: { showEffects: true },
        });
        app.ports.sigCb.send(res.digest);
      } else {
        throw Error("bad sig");
      }
    })().catch((e) => {
      console.error(e);
      app.ports.sigCb.send(null);
    })
  );

  // Setup complete

  const seeds = await fetchAuthed();
  app.ports.authedCb.send(seeds);
})().catch(console.error);

async function fetchPubkey(authToken: number) {
  const res = await SeedVault.getPubkey({ authToken });
  const pubk = new Ed25519PublicKey(new Uint8Array(res.pubkey));
  return pubk;
}

async function fetchAuthed(): Promise<SeedAuth[]> {
  const seeds: SeedAuth[] = DEV
    ? [{ name: "Cool wallet", authToken: 1 }]
    : (await SeedVault.getAuthorizedSeeds()).seeds;
  return seeds;
}

function buildTx(
  payer: Ed25519PublicKey,
  amount: number,
  recipient: string
): Transaction {
  const txb = new Transaction();
  txb.setSender(payer.toSuiAddress());
  const [coin] = txb.splitCoins(txb.gas, [
    BigInt(amount * Number(MIST_PER_SUI)),
  ]);
  txb.transferObjects([coin], recipient);
  return txb;
}
