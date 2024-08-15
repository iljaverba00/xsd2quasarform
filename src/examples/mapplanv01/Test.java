package examples.mapplanv01;

import com.java.Converter;


public class Test {

    private final Converter converter = new Converter();

    @org.junit.Test
    public void test() throws Exception {
        String xsd = "mapplanv01/interact_map_plan/root.xsd";
        String html = "mapplanv01/form.html";
        converter.generateForm(xsd, html);
    }
}
