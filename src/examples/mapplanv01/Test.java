package examples.mapplanv01;

import com.java.CacheConverter;
import com.java.Converter;


public class Test {

    @org.junit.Test
    public void test() throws Exception {
        String xsd = "mapplanv01/interact_map_plan/root.xsd";
        String html = "mapplanv01/form.html";

        new Converter().generateForm(xsd, html);
    }

    @org.junit.Test
    public void test_cache() throws Exception {
        String xsd = "mapplanv01/interact_map_plan/root.xsd";
        String html = "mapplanv01/generated-html-form.html";

        new CacheConverter().generateForm(xsd, html);
    }
}
