package com.java;

import java.io.File;
import java.nio.file.Files;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;


public class Converter {

    public void run(String xsdFilePath, String htmlFilePath)  {

        // Путь к XSL файлу
        String xslFilePath = "src/resources/XslCombined.xsl";
        String examplesFolder = "src/examples/";

        File xslFile = new File(xslFilePath);
        File xsdFile = new File(examplesFolder + xsdFilePath);
        File htmlFile = new File(examplesFolder + htmlFilePath);

        generateForm(xsdFile, xslFile, htmlFile);
    }


    private void generateForm(File xsdSchemaPath, File xslSchemaPath, File htmlResultPath) {
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
