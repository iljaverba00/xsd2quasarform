package com.java;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class XslCombiner {

    public static String basePath = "src/resources/";

    public static void main(String[] args) {
        String xslFiles = basePath + "xsdToQuasarform.xsl";
        String outputFilePath = "src/resources/XslCombined.xsl";

        try {
            combineXslFiles(xslFiles, outputFilePath);
            System.out.println("Объединение завершено успешно.");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void combineXslFiles(String pathMain, String outputFilePath) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();

        // Чтение основного XSL файла
        Document mainDoc = builder.parse(new File(pathMain));
        Element mainRoot = mainDoc.getDocumentElement();

        // Удаление <xsl:include> и <xsl:import> директив
        List<String> xslFiles = new ArrayList<>();
        NodeList includeNodes = mainRoot.getChildNodes();
        for (int i = 0; i < includeNodes.getLength(); i++) {
            Node includeNode = includeNodes.item(i);
            if (includeNode.getNodeName().contains("include")) {
                String path = includeNode.getAttributes().item(0).getNodeValue();
                xslFiles.add(basePath + path);
                includeNode.getParentNode().removeChild(includeNode);
            }
        }

        for (int i = 0; i < xslFiles.size(); i++) {
            Document doc = builder.parse(new File(xslFiles.get(i)));
            Element root = doc.getDocumentElement();
            NodeList children = root.getChildNodes();

            for (int j = 0; j < children.getLength(); j++) {
                Node importedNode = mainDoc.importNode(children.item(j), true);
                mainRoot.appendChild(importedNode);
            }
        }

        // Сохранение объединенного файла
        Transformer transformer = TransformerFactory.newInstance().newTransformer();
        DOMSource source = new DOMSource(mainDoc);
        StreamResult result = new StreamResult(new File(outputFilePath));
        transformer.transform(source, result);
    }
}
