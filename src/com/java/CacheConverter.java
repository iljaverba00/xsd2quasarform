package com.java;

import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import java.io.File;
import java.nio.file.Files;

@Deprecated
public class CacheConverter {

    public void generateForm(String xsdFilePath, String htmlFilePath) throws Exception {

        // Путь к XSL файлу
        String xslFilePath = "src/resources/XslCombined.xsl";
        String examplesFolder = "src/examples/";

//        File xslFile = new File(xslFilePath);
//        File xsdFile = new File(examplesFolder + xsdFilePath);
        File htmlFile = new File(examplesFolder + htmlFilePath);

        CustomUriResolver uriResolver = new CustomUriResolver();

        StreamSource xsltSource = (StreamSource) uriResolver.resolve("XslCombined.xsl", null);
        StreamSource xsdSource = (StreamSource) uriResolver.resolve("root.xsd", null);

        // Создание источников для XSD и XSLT
//        StreamSource xsdSource = new StreamSource(xsdFile);
//        StreamSource xsltSource = new StreamSource(xslCombined);

        // Создание результата для выходного HTML файла
        StreamResult htmlResult = new StreamResult(Files.newOutputStream(htmlFile.toPath()));

        // Создание фабрики трансформеров
        TransformerFactory factory = TransformerFactory.newInstance();
        factory.setURIResolver(uriResolver);

        // Создание трансформера для XSLT
        Transformer transformer = factory.newTransformer(xsltSource);


        // Преобразование XSD в HTML
        transformer.transform(xsdSource, htmlResult);

        System.out.println("Преобразование завершено. HTML форма создана: " + htmlFile.length());
    }
}
