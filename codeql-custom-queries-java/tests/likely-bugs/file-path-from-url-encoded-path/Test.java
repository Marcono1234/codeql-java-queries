import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Path;

class Test {
    void test(URI uri, URL url) {
        new File(uri.getRawPath());
        Path.of(uri.getRawPath());

        new File(url.getFile());
        Path.of(url.getFile());
        new File(url.getPath());
        Path.of(url.getPath());
    }

    void testCorrect(URI uri, URL url) throws URISyntaxException {
        new File(uri);
        Path.of(uri);

        new File(url.toURI());
        Path.of(url.toURI());
    }
}