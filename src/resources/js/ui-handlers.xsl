<?xml version="1.0"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
	
	<xsl:template name="add-ui-handlers">
		<xsl:element name="script">
			<xsl:attribute name="type">text/javascript</xsl:attribute>
			<xsl:text disable-output-escaping="yes">
				/* UI HANDLERS */
				console.log('ui handlers inited');
				///////

function collapseSections (element) {
  Array.from(element.closest('fieldset').children).forEach(function (element) {
    if (element.tagName != 'SECTION') {
        return;
    }
    var value = JSON.parse(element.getAttribute('collapsed') || 'false');
    element.setAttribute('collapsed', !value);
  });
};

function startExpandSections() {
    var sectionElement = document.querySelector('body > form > section');
    if (!sectionElement) {
        return;
    }
    sectionElement.setAttribute('collapsed', 'false');
}

window.addEventListener('DOMContentLoaded', startExpandSections);


				///////

			</xsl:text>
		</xsl:element>	
	</xsl:template>
	
</xsl:stylesheet>