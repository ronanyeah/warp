package net.tarbh.warp;

import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;

import androidx.activity.result.ActivityResult;

import java.util.ArrayList;

import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;
import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.PermissionState;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;

import com.solanamobile.seedvault.BipLevel;
import com.solanamobile.seedvault.Bip32DerivationPath;
import com.solanamobile.seedvault.PublicKeyResponse;
import com.solanamobile.seedvault.SigningResponse;
import com.solanamobile.seedvault.Wallet;
import com.solanamobile.seedvault.WalletContractV1;


@CapacitorPlugin(
        name = "SeedVault",
        permissions = {
                @Permission(
                        alias = "seedvault",
                        strings = {WalletContractV1.PERMISSION_ACCESS_SEED_VAULT}
                )
        }
)
public class SeedVaultPlugin extends Plugin {
    @PluginMethod
    public void assertPermissions(PluginCall call) {
        if (getPermissionState("seedvault") == PermissionState.GRANTED) {
            call.resolve();
        } else {
            requestPermissionForAlias("seedvault", call, "permissionCb");
        }
    }

    @PermissionCallback
    private void permissionCb(PluginCall call) {
        if (getPermissionState("seedvault") == PermissionState.GRANTED) {
            call.resolve();
        } else {
            call.reject("Permission not granted");
        }
    }

    @PluginMethod
    public void authorizeSeed(PluginCall call) {
        boolean seedsAvailable = Wallet.hasUnauthorizedSeedsForPurpose(getContext(), WalletContractV1.PURPOSE_SIGN_SOLANA_TRANSACTION);
        if (seedsAvailable) {
            try {
                Intent intent = Wallet.authorizeSeed(WalletContractV1.PURPOSE_SIGN_SOLANA_TRANSACTION);
                startActivityForResult(call, intent, "authorizeCb");
            } catch (Exception e) {
                call.reject("Failed to start authorize seed activity", e);
            }
        } else {
            call.resolve();
        }
    }

    @ActivityCallback
    private void authorizeCb(PluginCall call, ActivityResult result) {
        try {
            long authToken = Wallet.onAuthorizeSeedResult(result.getResultCode(), result.getData());
            JSObject out = new JSObject();
            out.put("authToken", authToken);
            call.resolve(out);
        } catch (Wallet.ActionFailedException e) {
            call.reject("Authorization failed", e);
        }
    }

    @ActivityCallback
    private void pubkeyCb(PluginCall call, ActivityResult result) {
        try {
            ArrayList<PublicKeyResponse> responses = Wallet.onRequestPublicKeysResult(result.getResultCode(), result.getData());
            if (!responses.isEmpty()) {
                PublicKeyResponse response = responses.get(0);
                JSObject out = new JSObject();
                try {
                    byte[] bts = response.getPublicKey();

                    JSArray jsArray = new JSArray();
                    for (byte b : bts) {
                        jsArray.put(b & 0xFF); // unsigned int (0-255)
                    }

                    out.put("pubkey", jsArray);
                    call.resolve(out);
                } catch (PublicKeyResponse.KeyNotValidException e) {
                    call.reject("Public key is not valid: " + e.getMessage(), e);
                }
            } else {
                call.reject("No public key received");
            }
        } catch (Wallet.ActionFailedException e) {
            call.reject("Failed to get public key: " + e.getMessage(), e);
        }
    }

    @ActivityCallback
    private void signBytesCb(PluginCall call, ActivityResult result) {
        try {
            ArrayList<SigningResponse> responses = Wallet.onSignMessagesResult(result.getResultCode(), result.getData());
            SigningResponse response = responses.get(0);
            JSObject out = new JSObject();
            byte[] bts = response.getSignatures().get(0);

            JSArray jsArray = new JSArray();
            for (byte b : bts) {
                jsArray.put(b & 0xFF); // unsigned int (0-255)
            }

            out.put("signed", jsArray);
            call.resolve(out);
        } catch (Wallet.ActionFailedException e) {
            call.reject("sign failed", e);
        }
    }

    @PluginMethod
    public void signBytes(PluginCall call) {
        JSArray arr = call.getArray("bytes");
        Double authTokenDouble = call.getDouble("authToken");

        Long authToken = authTokenDouble.longValue();

        byte[] messageBytes = new byte[arr.length()];
        try {
            for (int i = 0; i < arr.length(); i++) {
                messageBytes[i] = (byte) arr.getInt(i);
            }
        } catch (Exception e) {
            call.reject("Error processing byte array", e);
        }

        Uri derivPath = Bip32DerivationPath.newBuilder()
                .appendLevel(new BipLevel(44, true))
                .appendLevel(new BipLevel(784, true))
                .appendLevel(new BipLevel(0, true))
                .appendLevel(new BipLevel(0, true))
                .appendLevel(new BipLevel(0, true))
                .build().toUri();
        try {
            Intent intent = Wallet.signMessage(authToken, derivPath, messageBytes);
            startActivityForResult(call, intent, "signBytesCb");
        } catch (Exception e) {
            call.reject("Failed to sign: " + e.getMessage(), e);
        }
    }

    @PluginMethod
    public void deauthorizeSeed(PluginCall call) {
        Double authTokenDouble = call.getDouble("authToken");
        Long authToken = authTokenDouble.longValue();
        try {
            Wallet.deauthorizeSeed(getContext(), authToken);
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed deauth", e);
        }
    }

    @PluginMethod
    public void getPubkey(PluginCall call) {
        Double authTokenDouble = call.getDouble("authToken");
        Long authToken = authTokenDouble.longValue();
        Uri derivPath = Bip32DerivationPath.newBuilder()
                .appendLevel(new BipLevel(44, true))
                .appendLevel(new BipLevel(784, true))
                .appendLevel(new BipLevel(0, true))
                .appendLevel(new BipLevel(0, true))
                .appendLevel(new BipLevel(0, true))
                .build().toUri();
        try {
            Intent intent = Wallet.requestPublicKey(authToken, derivPath);
            startActivityForResult(call, intent, "pubkeyCb");
        } catch (Exception e) {
            call.reject("Failed to request public key: " + e.getMessage(), e);
        }
    }

    @PluginMethod
    public void getAuthorizedSeeds(PluginCall call) {
        try {
            String[] projection = {
                    WalletContractV1.AUTHORIZED_SEEDS_AUTH_TOKEN,
                    WalletContractV1.AUTHORIZED_SEEDS_AUTH_PURPOSE,
                    WalletContractV1.AUTHORIZED_SEEDS_SEED_NAME
            };

            JSArray result = new JSArray();
            Cursor cursor = Wallet.getAuthorizedSeeds(getContext(), projection);
            if (cursor.moveToFirst()) {
                int authTokenIndex = cursor.getColumnIndexOrThrow(WalletContractV1.AUTHORIZED_SEEDS_AUTH_TOKEN);
                int purposeIndex = cursor.getColumnIndexOrThrow(WalletContractV1.AUTHORIZED_SEEDS_AUTH_PURPOSE);
                int nameIndex = cursor.getColumnIndexOrThrow(WalletContractV1.AUTHORIZED_SEEDS_SEED_NAME);

                do {
                    result.put(new JSObject()
                            .put("authToken", cursor.getLong(authTokenIndex))
                            .put("purpose", cursor.getInt(purposeIndex))
                            .put("name", cursor.getString(nameIndex)));
                } while (cursor.moveToNext());
            }

            call.resolve(new JSObject().put("seeds", result));
        } catch (Exception e) {
            call.reject("Failed to get authorized seeds: " + e.getMessage(), e);
        }
    }
}
