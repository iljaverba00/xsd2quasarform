import java.io.File;
import java.io.FileNotFoundException;
import java.nio.file.Files;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

public class Converter {

    // Путь к XSLT файлу
    private static String xslFilePath = "src/resources/XslCombined.xsl";

    // Путь к XSD файлу
    private static String xsdFilePath = "src/examples/schema.xsd";

    // Путь к выходному HTML файлу
    private static String htmlFilePath = "src/examples/form.html";

    public static void main(String[] args) throws FileNotFoundException {

        File xslFile = new File(xslFilePath);
        File xsdFile = new File(xsdFilePath);
        File htmlFile = new File(htmlFilePath);

        generateForm(xsdFile, xslFile, htmlFile);
    }


    public static void generateForm(File xsdSchemaPath, File xslSchemaPath, File htmlResultPath) {
        try {
            // Создание источников для XSD и XSLT
            StreamSource xsdSource = new StreamSource(xsdSchemaPath);
            StreamSource xsltSource = new StreamSource(xslSchemaPath);

            // Создание результата для выходного HTML файла
            StreamResult htmlResult = new StreamResult(Files.newOutputStream(htmlResultPath.toPath()));

            // Создание фабрики трансформеров
            TransformerFactory factory = TransformerFactory.newInstance();

            // Создание трансформера для XSLT
            Transformer transformer = factory.newTransformer(xsltSource);

            // Преобразование XSD в HTML
            transformer.transform(xsdSource, htmlResult);

            System.out.println("Преобразование завершено. HTML форма создана: " + htmlResultPath.getAbsolutePath());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
