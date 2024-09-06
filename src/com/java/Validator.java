package com.java;

import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.util.Scanner;

public class Validator {
    String examplesFolder = "src/examples";

    public boolean validate(String xsdPath, String xmlPath) {
        try {
            // Путь к XSD файлу
            File xsdFile = new File(examplesFolder + xsdPath);

            // Путь к XML файлу
            File xmlFile = new File(examplesFolder + xmlPath);

//            // Преобразуем XML файл в строку
//            String xmlString = readFile(xmlFile);
//
//            // Преобразуем XSD схему в строку
//            String xsdString = readFile(xsdFile);

            // Выполняем валидацию XML файла XSD схемой
            return validateXMLAgainstXSD(xmlFile, xsdFile);
        }catch (Exception e){
            e.printStackTrace();
            return false;
        }
    }


    private boolean validateXMLAgainstXSD(File xml, File xsd) {
        try {
            // Создание схемы из XSD
            SchemaFactory schemaFactory = SchemaFactory.newInstance("http://www.w3.org/2001/XMLSchema");
            //InputStream xsdStream = new ByteArrayInputStream(xsdString.getBytes());
            Schema schema = schemaFactory.newSchema(xsd);

            // Создание валидатора
            javax.xml.validation.Validator validator = schema.newValidator();
            //InputStream xmlStream = new ByteArrayInputStream(xmlString.getBytes());

            // Валидация XML
            validator.validate(new StreamSource(xml));
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private String readFile(File file) throws FileNotFoundException {
        Scanner scanner = new Scanner(file);

        StringBuilder xsdString = new StringBuilder();
        while (scanner.hasNextLine()) {
            xsdString.append(scanner.nextLine());
        }
        return xsdString.toString();
    }
}
