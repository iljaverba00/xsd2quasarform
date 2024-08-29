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
function collapseSections(element) {
  if (isRadioLegend(element) || isRadioInnerLegend(element)) {
    return;
  }
  Array.from(element.closest("fieldset").children).forEach(function (element) {
    if (element.tagName != "SECTION") {
      return;
    }
    var value = JSON.parse(element.getAttribute("collapsed") || "false");
    element.setAttribute("collapsed", !value);
  });
}

function startExpandSections() {
  var sectionElement = document.querySelector("body > form > section");
  if (!sectionElement) {
    return;
  }
  sectionElement.setAttribute("collapsed", "false");
}

function isRadioSection(element) {
  if (element.tagName != "SECTION") {
    return false;
  }
  const value = [
    ...document.querySelectorAll("section:has( > fieldset > label[radio])"),
  ].includes(element);
  if (value) {
    console.log(element);
  }
  return value;
}

function isRadioLegend(element) {
  return [...document.querySelectorAll("legend:has(+ label[radio])")].includes(
    element
  );
}
function isRadioInnerLegend(element) {
  return [
    ...document.querySelectorAll("label[radio] + section > fieldset > legend"),
  ].includes(element);
}

function onOk() {
  expandRequiredForms();
}

function setVisible(element) {
  var rect = element.getBoundingClientRect();
  var width = rect.width;
  var height = rect.height;
  if (width !== 0 || height !== 0) {
    return;
  }
  if (getComputedStyle(element).display === "none") {
    element.style.display = "block";
    return;
  }
  if (element.parentElement) {
    setVisible(element.parentElement);
  }
}

function expandRequiredForms() {
  var requiredForms = Array.from(
    document.querySelectorAll(
      'input[required="required"]:not([disabled="disabled"]):not([hidden] *):not([checked="checked"])'
    )
  );
  requiredForms.forEach(function (element) {
    var sections = document.querySelectorAll('section[collapsed="true"]');
    sections.forEach(function (section) {
      if (section.contains(element)) {
        section.setAttribute("collapsed", "false");
      }
    });
  });
}

function generateGUID() {
  return crypto.randomUUID();
}

function main() {
  startExpandSections();


  const guidLabel = document.querySelector('[data-xsd2html2xml-name="guid"]');
  const guidInput = document.querySelector('[data-xsd2html2xml-name="guid"] input');
  const guid = generateGUID();
  guidInput.value = guid;
  guidInput.setAttribute('value', guid);
}
window.addEventListener("DOMContentLoaded", main);

				///////

			</xsl:text>
		</xsl:element>
	</xsl:template>

</xsl:stylesheet>
