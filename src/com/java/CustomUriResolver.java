package com.java;

import com.geocad.wc.jdbc.xfiles.XFileDescriptor;
import com.geocad.wc.jdbc.xfiles.XFilesException;
import com.geocad.wc.kernel.session.SessionInstanceInterface;
import com.geocad.wc.kernel.xfiles.XFilesInterface;
import com.geocad.wc.metamodel.valueobject.FactDscrValue;
import com.geocad.wc.sfw.api.xml.XmlService;
import com.geocad.wc.sfw.xfiles.XFilesOpsXml;
import org.apache.commons.io.IOUtils;

import javax.ejb.CreateException;
import javax.xml.transform.*;
import javax.xml.transform.stream.StreamSource;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CustomUriResolver implements URIResolver {

    private final ClassLoader loader = XmlService.class.getClassLoader();
    public static final String basePathForXsl = "com/geocad/wc/sfw/api/xml/xsl/";

    private final XFilesOpsXml xf = new XFilesOpsXml();
    private final SessionInstanceInterface sii;
    private final Integer bankId;
    private final FactDscrValue fdv;
    private final Integer recId;
    private Map<String, byte[]> cache;

    public CustomUriResolver(SessionInstanceInterface sii, Integer bankId, FactDscrValue fdv, Integer recId) throws XFilesException, IOException, CreateException {
        this.sii = sii;
        this.bankId = bankId;
        this.fdv = fdv;
        this.recId = recId;
        init();
    }


    /**
     * Загружаем файлы xsd схемы в буфер.
     * Если это не сделать, то будут большие задержки - тк каждый раз читаем из бд
     */
    private void init() throws CreateException, XFilesException, IOException {
        this.cache = new HashMap<>();

        List<XFileDescriptor> xFilesList = xf.getFilesDscrList(sii, bankId, fdv.getTableId(), recId, null);
        for (XFileDescriptor xFileDescriptor : xFilesList) {
            XFilesInterface xFilesInterface = sii.getXFilesLocal(bankId, fdv.getTableId());
            InputStream stream = xFilesInterface.get(xFileDescriptor.getFileId());
            String fileName = xFileDescriptor.getFileName().toLowerCase().trim();
            this.cache.put(fileName, IOUtils.toByteArray(stream));
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
