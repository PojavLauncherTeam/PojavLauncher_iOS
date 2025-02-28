import java.net.URL;
import java.util.HashMap;

public class CustomSkinManager {
    private static final String SKIN_API_URL = "https://mineskin.org/get/uuid/";

    private static HashMap<String, String> skinCache = new HashMap<>();

    public static String getSkinURL(String uuid) {
        if (skinCache.containsKey(uuid)) {
            return skinCache.get(uuid);
        }

        try {
            URL url = new URL(SKIN_API_URL + uuid);
            String skinURL = url.toString(); // Simulating API fetch
            skinCache.put(uuid, skinURL);
            return skinURL;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
