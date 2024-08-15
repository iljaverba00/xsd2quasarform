package com.java;

import javax.xml.transform.*;
import javax.xml.transform.stream.StreamSource;
import java.io.ByteArrayInputStream;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.HashMap;
import java.util.Map;

public class CustomUriResolver implements URIResolver {

    private final ClassLoader loader = CustomUriResolver.class.getClassLoader();
    public static final String basePathForXsl = "resources/";
    private Map<String, byte[]> cache = new HashMap<>();

    public CustomUriResolver() throws IOException {
        String path = "src/examples/mapplanv01/SchemaCommon";
        File folder = new File(path);
        File[] listOfFiles = folder.listFiles();
        for (File file : listOfFiles) {
            if (file.isFile()) {
                byte[] bytes = Files.readAllBytes(file.toPath());
                cache.put(file.getName().toLowerCase().trim(), bytes);
            }
        }
    }

    private Source getStreamSourceFromCache(String fileName) {
        if (cache.containsKey(fileName)) {
            InputStream is =  new ByteArrayInputStream(cache.get(fileName));
            return new StreamSource(is);
        }
        return null;
    }

    @Override
    public Source resolve(String href, String base) throws TransformerException {
        if (href != null && href.endsWith(".xsl")) {
            InputStream stream = loader.getResourceAsStream(basePathForXsl + href);
            return new StreamSource(stream);
        } else if (href != null && href.endsWith(".xsd")) {
            String[] split = href.split("/");
            String hrefFileName = split[split.length - 1].toLowerCase().trim();
            return getStreamSourceFromCache(hrefFileName);
        }
        return null;
    }
}
