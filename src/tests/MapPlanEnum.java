package tests;

import com.java.Converter;
import com.java.Validator;
import org.junit.Test;

public class MapPlanEnum {
    public final String dir = "/map_plan_enum";

    @Test
    public void test1() {
        String xsd = dir + "/schema/main.xsd";
        String html = dir + "/result/form.html";

        new Converter().generateForm(xsd, html, 1);

    }

}
