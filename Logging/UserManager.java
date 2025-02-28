import org.json.JSONArray;
import org.json.JSONObject;
import java.io.*;
import java.util.UUID;

public class UserManager {
    private static final String FILE_PATH = "users.json";

    // Register a new user
    public static boolean registerUser(String username, String password) {
        JSONArray users = loadUsers();
        
        // Check if username already exists
        for (int i = 0; i < users.length(); i++) {
            JSONObject user = users.getJSONObject(i);
            if (user.getString("username").equalsIgnoreCase(username)) {
                return false; // Username already taken
            }
        }

        // Create user
        JSONObject newUser = new JSONObject();
        newUser.put("username", username);
        newUser.put("password", password);  // In real apps, use encryption!
        newUser.put("uuid", generateOfflineUUID(username));
        newUser.put("skinURL", "");  // Default empty skin

        users.put(newUser);
        saveUsers(users);
        return true;
    }

    // Authenticate user
    public static boolean loginUser(String username, String password) {
        JSONArray users = loadUsers();
        
        for (int i = 0; i < users.length(); i++) {
            JSONObject user = users.getJSONObject(i);
            if (user.getString("username").equalsIgnoreCase(username) &&
                user.getString("password").equals(password)) {
                return true; // Login successful
            }
        }
        return false; // Login failed
    }

    // Get user UUID
    public static String getUserUUID(String username) {
        JSONArray users = loadUsers();
        
        for (int i = 0; i < users.length(); i++) {
            JSONObject user = users.getJSONObject(i);
            if (user.getString("username").equalsIgnoreCase(username)) {
                return user.getString("uuid");
            }
        }
        return null;
    }

    // Load users from JSON file
    private static JSONArray loadUsers() {
        File file = new File(FILE_PATH);
        if (!file.exists()) {
            return new JSONArray();
        }
        try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
            StringBuilder content = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                content.append(line);
            }
            return new JSONArray(content.toString());
        } catch (Exception e) {
            e.printStackTrace();
            return new JSONArray();
        }
    }

    // Save users to JSON file
    private static void saveUsers(JSONArray users) {
        try (FileWriter file = new FileWriter(FILE_PATH)) {
            file.write(users.toString(4));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Generate offline UUID
    private static String generateOfflineUUID(String username) {
        return UUID.nameUUIDFromBytes(("OfflinePlayer:" + username).getBytes()).toString();
    }
}
