package tests;

import com.java.Converter;
import org.junit.Test;

public class Les {

    @Test
    public void test1(){
        String xsd = "/les/schema/main.xsd";
        String html = "/les/result/form1.html";

        new Converter().generateForm(xsd, html,1);

    }

    @Test
    public void test0(){
        String xsd = "/les/schema/main.xsd";
        String html = "/les/result/form0.html";

        new Converter().generateForm(xsd, html,0);

    }


    @Test
    public void doc1(){
        String xsd = "/les/schema/doc0.xml";
        String html = "/les/result/form-doc1.html";

        new Converter().generateForm(xsd, html,1);

    }

    @Test
    public void doc0(){
        String xsd = "/les/schema/doc0.xml";
        String html = "/les/result/form-doc0.html";

        new Converter().generateForm(xsd, html,0);

    }
}
