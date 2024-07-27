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


    public static void main(String[] args) throws FileNotFoundException {

        // Путь к XML файлу
        File xmlFile = new File("src/examples/test.xml");

        // Путь к XSD файлу
        File xsdFile = new File("src/examples/schema.xsd");

        // Преобразуем XML файл в строку
        String xmlString = readFile(xmlFile);

        // Преобразуем XSD схему в строку
        String xsdString = readFile(xsdFile);

        // Выполняем валидацию XML файла XSD схемой
        boolean validationResult = validateXMLAgainstXSD(xmlString, xsdString);

        System.out.println("XML validation passed " + (validationResult ? "successfully" : "unsuccessfully"));
    }


    public static boolean validateXMLAgainstXSD(String xmlString, String xsdString) {
        try {
            // Создание схемы из XSD
            SchemaFactory schemaFactory = SchemaFactory.newInstance("http://www.w3.org/2001/XMLSchema");
            InputStream xsdStream = new ByteArrayInputStream(xsdString.getBytes());
            Schema schema = schemaFactory.newSchema(new StreamSource(xsdStream));

            // Создание валидатора
            javax.xml.validation.Validator validator = schema.newValidator();
            InputStream xmlStream = new ByteArrayInputStream(xmlString.getBytes());

            // Валидация XML
            validator.validate(new StreamSource(xmlStream));
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public static String readFile(File file) throws FileNotFoundException {
        Scanner scanner = new Scanner(file);

        StringBuilder xsdString = new StringBuilder();
        while (scanner.hasNextLine()) {
            xsdString.append(scanner.nextLine());
        }
        return xsdString.toString();
    }
}
