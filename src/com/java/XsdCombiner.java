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
import java.util.HashSet;
import java.util.Set;

@Deprecated
public class XsdCombiner {
    public static String basePath = "src/examples/interact_map_plan_v01_R04/interact_map_plan/";
    public static String baseFolder = "src/examples/interact_map_plan_v01_R04/SchemaCommon/";

    public static void main(String[] args) {

        String mainXsdPath = "src/examples/interact_map_plan_v01_R04/interact_map_plan/root.xsd";
        String outputFilePath = "src/examples/interact_map_plan_v01_R04/combined.xsd";

        try {
            combineXsdFiles(mainXsdPath, outputFilePath);
            System.out.println("Объединение завершено успешно.");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void combineXsdFiles(String mainXsdPath, String outputFilePath) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();

        // Чтение основного XSD файла
        Document mainDoc = builder.parse(new File(mainXsdPath));
        Element mainRoot = mainDoc.getDocumentElement();

        Set<String> includedFiles = new HashSet<>();
        processIncludesAndImports(mainDoc, mainRoot, includedFiles, builder);

        // Сохранение объединенного файла
        Transformer transformer = TransformerFactory.newInstance().newTransformer();
        DOMSource source = new DOMSource(mainDoc);
        StreamResult result = new StreamResult(new File(outputFilePath));
        transformer.transform(source, result);
    }

    private static void processIncludesAndImports(Document mainDoc, Element root, Set<String> includedFiles, DocumentBuilder builder) throws Exception {
//        NodeList includeNodes = root.getElementsByTagNameNS("http://www.w3.org/2001/XMLSchema", "include");
//        NodeList importNodes = root.getElementsByTagNameNS("http://www.w3.org/2001/XMLSchema", "import");
//
//        int includeLength = includeNodes.getLength();
//        int importLength = importNodes.getLength();

        // Обработка <xs:include>
        NodeList includeNodes = root.getChildNodes();
        for (int i = 0; i < includeNodes.getLength(); i++) {
            Node includeElement = includeNodes.item(i);
            if (includeElement != null &&
                    (includeElement.getNodeName().contains("include") || includeElement.getNodeName().contains("import"))) {
                String schemaLocation = includeElement.getAttributes().item(1).getNodeValue();
                if (includedFiles.add(schemaLocation)) {
                    String finalPath = (schemaLocation.contains("..") ? basePath : baseFolder) + schemaLocation;
                    Document includeDoc = builder.parse(new File(finalPath));
                    Element includeRoot = includeDoc.getDocumentElement();
                    processIncludesAndImports(mainDoc, includeRoot, includedFiles, builder);
                    appendChildren(mainDoc, root, includeRoot);
                    root.removeChild(includeElement);
                }
            }
        }

    }

    private static void appendChildren(Document mainDoc, Element root, Element source) {
        NodeList children = source.getChildNodes();
        for (int j = 0; j < children.getLength(); j++) {
            Node importedNode = mainDoc.importNode(children.item(j), true);
            root.appendChild(importedNode);
        }
    }
}
