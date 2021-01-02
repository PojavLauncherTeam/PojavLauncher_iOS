
public class HelloWorldNoLoop extends HelloWorld {
    public HelloWorldNoLoop() {
    	super();
    	noLoop = true;
    }

    public static void main(String[] args) {
		new HelloWorldNoLoop().run();
	}
}
