import java.util.Scanner;

public class LoginActivity {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.println("1. Register");
        System.out.println("2. Login");
        System.out.print("Select option: ");
        int choice = scanner.nextInt();
        scanner.nextLine(); // Consume newline

        if (choice == 1) {
            System.out.print("Enter username: ");
            String username = scanner.nextLine();
            System.out.print("Enter password: ");
            String password = scanner.nextLine();

            if (UserManager.registerUser(username, password)) {
                System.out.println("Registration successful!");
            } else {
                System.out.println("Username already taken.");
            }
        } else if (choice == 2) {
            System.out.print("Enter username: ");
            String username = scanner.nextLine();
            System.out.print("Enter password: ");
            String password = scanner.nextLine();

            if (UserManager.loginUser(username, password)) {
                String uuid = UserManager.getUserUUID(username);
                System.out.println("Login successful! Your UUID: " + uuid);
            } else {
                System.out.println("Invalid username or password.");
            }
        } else {
            System.out.println("Invalid choice.");
        }
    }
}
