package tests;

import com.java.Converter;
import org.junit.Test;

public class MapPlan {

    @Test
    public void test1(){
        String xsd = "/mapplanv01/interact_map_plan/root.xsd";
        String html = "/mapplanv01/form1.html";

        new Converter().generateForm(xsd, html,1);

    }

    @Test
    public void test0(){
        String xsd = "/mapplanv01/interact_map_plan/root.xsd";
        String html = "/mapplanv01/form0.html";

        new Converter().generateForm(xsd, html,0);

    }


    @Test
    public void doc1(){
        String xsd = "/mapplanv01/interact_map_plan/doc0.xml";
        String html = "/mapplanv01/form-doc1.html";

        new Converter().generateForm(xsd, html,0);

    }

    @Test
    public void doc0(){
        String xsd = "/mapplanv01/interact_map_plan/doc0.xml";
        String html = "/mapplanv01/form-doc0.html";

        new Converter().generateForm(xsd, html,0);

    }
}
