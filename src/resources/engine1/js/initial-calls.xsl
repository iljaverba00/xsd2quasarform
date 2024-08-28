<?xml version="1.0"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
	
	<xsl:template name="add-initial-calls">
		<xsl:element name="script">
			<xsl:attribute name="type">text/javascript</xsl:attribute>
			<xsl:text disable-output-escaping="yes">
				var globalValuesMap = [];
				
				document.addEventListener("DOMContentLoaded",
					function() {
						/* INITIAL CALLS */

						function clickFilledRadio() {
							// find all filled fields and check all radio contains that fields
							const clicked = new Set();
							document.querySelectorAll("[data-xsd2html2xml-filled='true']").forEach(function (o) {
								let currentChoice = o.closest("[data-xsd2html2xml-choice]");
								while (currentChoice) {
									let node = currentChoice.previousElementSibling;
									while (node) {
										if (!node.hasAttribute("data-xsd2html2xml-choice")) {
											// TODO chernik: node это label[radio]
											const radioInput = node.querySelector("input[type='radio']");
											if (!clicked.has(radioInput)) { // TODO chernik: чтобы не кликать по много раз
												radioInput.click();
												clicked.add(radioInput);
											}
											break;
										} else {
											node = node.previousElementSibling;
										};
									};
									// TODO chernik: переходим к следующему блоку радио
									currentChoice = currentChoice.parentElement.closest("[data-xsd2html2xml-choice]");
								}
							});
						}
						
						addHiddenFields();
						xmlToHTML(document);
						updateIdentifiers();
						setDynamicValues();
						setValues();
						ensureMinimum();
						clickFilledRadio();
					}
				);
			</xsl:text>
		</xsl:element>	
	</xsl:template>
	
</xsl:stylesheet>