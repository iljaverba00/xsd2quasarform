package tests;

import com.java.Converter;
import com.java.Validator;
import org.junit.Test;

public class MapPlan {
    public final String dir = "/map_plan";

    @Test
    public void test1() {
        String xsd = dir + "/schema/main.xsd";
        String html = dir + "/result/form1.html";

        new Converter().generateForm(xsd, html, 1);

    }

    @Test
    public void test0() {
        String xsd = dir + "/schema/main.xsd";
        String html = dir + "/result/form0.html";

        new Converter().generateForm(xsd, html, 0);

    }


    @Test
    public void doc1() {
        String xsd = dir + "/schema/doc.xml";
        String html = dir + "/result/form-doc1.html";

        new Converter().generateForm(xsd, html, 1);

    }

    @Test
    public void doc0() {
        String xsd = dir + "/schema/doc.xml";
        String html = dir + "/result/form-doc0.html";

        new Converter().generateForm(xsd, html, 0);

    }

    @Test
    public void validation() {
        String xsd = dir + "/schema/main.xsd";
        String xml = dir + "/schema/doc.xml";
        new Validator().validate(xsd, xml);
        System.out.println("Validation passed.");

    }
}
