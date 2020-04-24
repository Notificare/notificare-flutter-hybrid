package re.notifica.demo

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry
import name.avioli.unilinks.UniLinksPlugin

class MainActivity : FlutterActivity() {
    // You can keep this empty class or remove it. Plugins on the new embedding
    // now automatically registers plugins.
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        // NOTE: The UniLinks plugin doesn't yet support v2 embedding.
        // That combined with the demand of an activity reference white registering the plugin
        // causes the v2 embedding to fail. Having that said, the plugin needs to be manually
        // registered.
        val shimPluginRegistry = ShimPluginRegistry(flutterEngine)
        UniLinksPlugin.registerWith(shimPluginRegistry.registrarFor("name.avioli.unilinks.UniLinksPlugin"))
    }
}
