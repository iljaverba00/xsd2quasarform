package com.java;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.Scanner;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

public class ClassReader {

    // Путь к XSLT файлу
    private static String xslFilePath = "src/resources/XslCombined.xsl";

    // Путь к XSD файлу
    private static String xsdFilePath = "src/examples/schema.xsd";

    // Путь к выходному HTML файлу
    private static String htmlFilePath = "src/examples/form.html";

    public static void main(String[] args) throws FileNotFoundException {

        InputStream stream = ClassReader.class.getClassLoader().getResourceAsStream("com/java/XslCombined.xsl");


        Scanner scanner = new Scanner(stream);
        StringBuilder sb = new StringBuilder();
        while (scanner.hasNextLine()) {
            sb.append(scanner.nextLine());
        }

        System.out.println(sb.length());


    }


}
