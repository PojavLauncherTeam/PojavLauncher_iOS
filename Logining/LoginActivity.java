CustomAuth auth = new CustomAuth(inputUsername);
String username = auth.getUsername();
String uuid = auth.getUUID();

String skinURL = CustomSkinManager.getSkinURL(uuid);
System.out.println("Logged in as: " + username + " (" + uuid + ")");
System.out.println("Skin URL: " + skinURL);
