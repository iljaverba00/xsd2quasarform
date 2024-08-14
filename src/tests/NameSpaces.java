package tests;

import com.java.Converter;
import org.junit.Test;


public class NameSpaces {

    private final Converter converter = new Converter();

    @Test
    public void test() {
        String xsd = "namespaces/namespaces-sample.xml";
        String html = "namespaces/form.html";
        converter.run(xsd, html);
    }
}
