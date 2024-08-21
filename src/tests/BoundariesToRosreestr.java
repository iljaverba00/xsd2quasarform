package tests;

import com.java.Converter;
import org.junit.Test;

public class BoundariesToRosreestr {

    @Test
    public void test1(){
        String xsd = "/boundaries-to-rosreestr/schema/main.xsd";
        String html = "/boundaries-to-rosreestr/result/form1.html";

        new Converter().generateForm(xsd, html,1);

    }

    @Test
    public void test0(){
        String xsd = "/boundaries-to-rosreestr/schema/main.xsd";
        String html = "/boundaries-to-rosreestr/result/form0.html";

        new Converter().generateForm(xsd, html,0);

    }

    @Test
    public void doc1(){
        String xsd = "/boundaries-to-rosreestr/schema/doc0.xml";
        String html = "/boundaries-to-rosreestr/result/form-doc1.html";

        new Converter().generateForm(xsd, html,1);

    }

    @Test
    public void doc0(){
        String xsd = "/boundaries-to-rosreestr/schema/doc0.xml";
        String html = "/boundaries-to-rosreestr/result/form-doc0.html";

        new Converter().generateForm(xsd, html,0);

    }
}
