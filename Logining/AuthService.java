import java.util.UUID;

public class CustomAuth {
    private String username;
    private String uuid;

    public CustomAuth(String username) {
        this.username = username;
        this.uuid = generateOfflineUUID(username);
    }

    private String generateOfflineUUID(String username) {
        return UUID.nameUUIDFromBytes(("OfflinePlayer:" + username).getBytes()).toString();
    }

    public String getUsername() {
        return username;
    }

    public String getUUID() {
        return uuid;
    }
}
