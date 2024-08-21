package com.java;

import java.io.File;
import java.nio.file.Files;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;


public class Converter {

    public void generateForm(String xsdFilePath, String htmlFilePath, Integer engineVersion) {

        try {
            // Путь к XSL файлу
            String xslFilePath = "src/resources/engine"+engineVersion+"/XslCombined.xsl";
            String examplesFolder = "src/examples/";

            File xslFile = new File(xslFilePath);
            File xsdFile = new File(examplesFolder + xsdFilePath);
            File htmlFile = new File(examplesFolder + htmlFilePath);

            // Создание источников для XSD и XSLT
            StreamSource xsdSource = new StreamSource(xsdFile);
            StreamSource xsltSource = new StreamSource(xslFile);

            // Создание результата для выходного HTML файла
            StreamResult htmlResult = new StreamResult(Files.newOutputStream(htmlFile.toPath()));

            // Создание фабрики трансформеров c xslt процессором xalan
            TransformerFactory factory = TransformerFactory.newInstance(
//                    "org.apache.xalan.processor.TransformerFactoryImpl",
//                    this.getClass().getClassLoader()
            );


            // Создание трансформера для XSLT
            Transformer transformer = factory.newTransformer(xsltSource);

            // Преобразование XSD в HTML
            transformer.transform(xsdSource, htmlResult);

            System.out.println("Преобразование завершено. HTML форма создана: " + htmlFile.length());
        } catch (Exception e) {
            e.printStackTrace();
        }

    }
}
