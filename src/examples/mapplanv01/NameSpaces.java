package examples.mapplanv01;

import com.java.Converter;
import org.junit.Test;


public class NameSpaces {

    private final Converter converter = new Converter();

    @Test
    public void test() throws Exception {
        String xsd = "mapplanv01/interact_map_plan/root.xsd";
        String html = "mapplanv01/form.html";
        converter.generateForm(xsd, html);
    }
}
