package tests;

import com.java.Converter;
import org.junit.Test;


public class GlobalTest {

    private final Converter converter = new Converter();


    // interact-map-plan-v01-r04

    @Test
    public void testInteractPlan() {
        String xsd = "example-interact-map-plan-v01-R04/interact_map_plan/interact_map_plan_v01.xsd";
        String html = "example-interact-map-plan-v01-R04/form.html";
        converter.run(xsd, html);
    }

    @Test
    public void testInteractPlan_filledForm() {
        String xsd = "example-interact-map-plan-v01-R04/interact_map_plan/interact_map_plan_v01.xsd";
        String html = "example-interact-map-plan-v01-R04/filled-form.html";
        converter.run(xsd, html);
    }

    @Test
    public void testNewDesign() {
        String xsd = "example-new-design/schema.xsd";
        String html = "example-new-design/form.html";
        converter.run(xsd, html);
    }

    @Test
    public void testNewDesign_filledForm() {
        String xsd = "example-new-design/test.xml";
        String html = "example-new-design/filled-form.html";
        converter.run(xsd, html);
    }
}
