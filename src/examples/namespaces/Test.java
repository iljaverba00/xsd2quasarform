package examples.namespaces;

import com.java.Converter;


public class Test {

    private final Converter converter = new Converter();

    @org.junit.Test
    public void test() throws Exception {
        String xsd = "namespaces/test.xml";
        String html = "namespaces/form.html";
        converter.generateForm(xsd, html);
    }
}
