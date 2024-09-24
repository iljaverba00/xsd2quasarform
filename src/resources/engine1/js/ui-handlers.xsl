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
  // Находим все обязательные поля
  const requiredForms = Array.from(
    document.querySelectorAll(
      'input[required]:not([disabled]):not([hidden] *):not([checked])'
    )
  );
  requiredForms = requiredForms.concat(Array.from(
    document.querySelectorAll(
      'select[required]:not([disabled]):not([hidden] *):not([checked])'
    )
  ))
  const radioWalkedFieldsets = new Set();
  requiredForms.forEach(function (element) {
    let fieldsetToAdd = null;
    if (element.getAttribute('type') === 'radio') {
      if (element.checkValidity()) {
        // Если среди радио с одним именем будет отмеченный, то это будет валидное поле
        return;
      } else {
        // У радио с одним именем будет один fieldset
        const fieldset = element.closest('fieldset');
        if (radioWalkedFieldsets.has(fieldset)) {
          // Остальные радио в контейнере нет смысла раскрывать
          return;
        }
        // Сейчас не можем добавить, потому что иначе не раскроется в цикле ниже
        fieldsetToAdd = fieldset;
      }
    } else if (element.checkValidity()) {
      // Валидные поля пропускаем
      return;
    }
    while (true) {
      // Раскрываем все секции выше
      const collapsed = element.closest('section[collapsed="true"]');
      if (!collapsed) {
        break;
      }
      if (radioWalkedFieldsets.has(collapsed.parentElement)) {
        // Эта секция уже раскрыта, а мы пытаемся раскрыть второй радио
        break;
      }
      // Находим элемент, который управляет коллапсом
      const legend = collapsed.parentElement.querySelector('legend[onClick="collapseSections(this);"]');
      if (!legend || legend.parentElement !== collapsed.parentElement || isRadioLegend(legend) || isRadioInnerLegend(legend)) {
        // Взял условие из collapseSections, в этом случае раскрыть нужно только один
        collapsed.setAttribute("collapsed", "false");
        console.debug('simple expanded');
        continue;
      }
      Array.from(collapsed.parentElement.children).forEach(otherCollapsed => {
        // Перебираем все секции
        if (otherCollapsed.tagName.toLowerCase() !== 'section') {
          return;
        }
        // Каждую раскрываем
        otherCollapsed.setAttribute("collapsed", "false");
      });
      console.debug('complex expanded');
    }
    if (fieldsetToAdd) {
      radioWalkedFieldsets.add(fieldsetToAdd);
    }
  });
}

function generateGUID() {
  if (window.isSecureContext) {
    return crypto.randomUUID();
  }
  const objectURL = URL.createObjectURL(new Blob([]));
  URL.revokeObjectURL(objectURL);
  return objectURL.slice(-36);
}

function main() {
  window.parent.postMessage('loaded', '*');
  startExpandSections();


  const guidLabel = document.querySelector('[data-xsd2html2xml-name="guid"]');
  const guidInput = document.querySelector('[data-xsd2html2xml-name="guid"] input');
  if (guidInput) {
    const guid = generateGUID();
    guidInput.value = guid;
    guidInput.setAttribute('value', guid);
  }
<!--  guidLabel.style.display = 'none';-->
  // const
}
window.addEventListener("DOMContentLoaded", main);

				///////

			</xsl:text>
		</xsl:element>
	</xsl:template>

</xsl:stylesheet>
