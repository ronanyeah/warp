package net.tarbh.warp;

import com.getcapacitor.BridgeActivity;
import android.os.Bundle;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(SeedVaultPlugin.class);
        super.onCreate(savedInstanceState);
    }
}
