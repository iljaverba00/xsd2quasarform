<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exsl="http://exslt.org/common" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.0">


    <xsl:variable name="templates" select="document('')/*/xsl:template"/>
    <xsl:variable name="root-element-stylesheet" select="document('handlers/root-element.xsl')"/>
    <xsl:variable name="complex-elements-stylesheet" select="document('handlers/complex-elements.xsl')"/>
    <xsl:variable name="enumerations-stylesheet" select="document('handlers/enumerations.xsl')"/>
    <xsl:variable name="extensions-stylesheet" select="document('handlers/extensions.xsl')"/>
    <xsl:variable name="element-stylesheet" select="document('matchers/element@type.xsl')"/>
    <xsl:variable name="element-attribute-stylesheet" select="document('matchers/element-attribute@ref.xsl')"/>
    <xsl:variable name="element-complexType-stylesheet" select="document('matchers/element-complexType.xsl')"/>
    <xsl:variable name="element-simpleType-stylesheet" select="document('matchers/element-simpleType.xsl')"/>
    <xsl:variable name="element-simpleContent-stylesheet" select="document('matchers/element-simpleContent.xsl')"/>
    <xsl:variable name="group-stylesheet" select="document('matchers/group@ref.xsl')"/>
    <xsl:variable name="attributeGroup-stylesheet" select="document('matchers/attributeGroup@ref.xsl')"/>
    <xsl:variable name="attr-value-stylesheet" select="document('utils/attr-value.xsl')"/>
    <xsl:variable name="gui-attributes-stylesheet" select="document('utils/gui-attributes.xsl')"/>
    <xsl:variable name="namespaces-stylesheet" select="document('utils/namespaces.xsl')"/>
    <xsl:variable name="types-stylesheet" select="document('utils/types.xsl')"/>

    <xsl:template match="*"/>

    <xsl:template match="/*">
        <xsl:element name="html">
            <xsl:choose>
                <!-- check if noNamespaceSchemaLocation contains a value -->
                <xsl:when test="@xsi:noNamespaceSchemaLocation">
                    <xsl:call-template name="inform">
                        <xsl:with-param name="message">
                            <xsl:text>XML file detected. Loading schema: </xsl:text><xsl:value-of
                                select="@xsi:noNamespaceSchemaLocation"/>
                        </xsl:with-param>
                    </xsl:call-template>

                    <xsl:call-template name="add-metadata">
                        <xsl:with-param name="xml-document" select="."/>
                    </xsl:call-template>

                    <xsl:for-each select="document(@xsi:noNamespaceSchemaLocation)/*">
                        <xsl:call-template name="handle-schema"/>
                    </xsl:for-each>
                </xsl:when>
                <!-- check if schemaLocation contains a value -->
                <xsl:when test="@xsi:schemaLocation">
                    <xsl:choose>
                        <!-- check if schemaLocation contains spaces (and thus namespace-location combinations) -->
                        <xsl:when test="contains(@xsi:schemaLocation, ' ')">
                            <!-- extract the namespace of the root element -->
                            <xsl:variable name="default-namespace">
                                <xsl:value-of
                                        select="namespace::*[name() = substring-before(name(), concat(':', local-name()))]"/>
                            </xsl:variable>

                            <!-- extract schema location relative to default namespace -->
                            <xsl:variable name="schema-location">
                                <xsl:value-of
                                        select="normalize-space(substring-after(@xsi:schemaLocation, $default-namespace))"/>
                            </xsl:variable>

                            <xsl:choose>
                                <!-- if schema-location still contains spaces, break off before the first one to find the schema location -->
                                <xsl:when test="contains($schema-location, ' ')">
                                    <xsl:call-template name="inform">
                                        <xsl:with-param name="message">
                                            <xsl:text>XML file detected. Loading schema: </xsl:text><xsl:value-of
                                                select="normalize-space(substring-before($schema-location, ' '))"/>
                                        </xsl:with-param>
                                    </xsl:call-template>

                                    <xsl:call-template name="add-metadata">
                                        <xsl:with-param name="xml-document" select="."/>
                                    </xsl:call-template>

                                    <xsl:for-each
                                            select="document(normalize-space(substring-before($schema-location, ' ')))/*">
                                        <xsl:call-template name="handle-schema"/>
                                    </xsl:for-each>
                                </xsl:when>
                                <!-- otherwise, the remaining value should point to a schema -->
                                <xsl:otherwise>
                                    <xsl:call-template name="inform">
                                        <xsl:with-param name="message">
                                            <xsl:text>XML file detected. Loading schema: </xsl:text><xsl:value-of
                                                select="$schema-location"/>
                                        </xsl:with-param>
                                    </xsl:call-template>

                                    <xsl:call-template name="add-metadata">
                                        <xsl:with-param name="xml-document" select="."/>
                                    </xsl:call-template>

                                    <xsl:for-each select="document($schema-location)/*">
                                        <xsl:call-template name="handle-schema"/>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <!-- if not, assume the value points to a schema -->
                        <xsl:otherwise>
                            <xsl:call-template name="inform">
                                <xsl:with-param name="message">
                                    <xsl:text>XML file detected. Loading schema: </xsl:text><xsl:value-of
                                        select="@xsi:schemaLocation"/>
                                </xsl:with-param>
                            </xsl:call-template>

                            <xsl:call-template name="add-metadata">
                                <xsl:with-param name="xml-document" select="."/>
                            </xsl:call-template>

                            <xsl:for-each select="document(@xsi:schemaLocation)/*">
                                <xsl:call-template name="handle-schema"/>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- else, assume an XSD document -->
                <xsl:otherwise>
                    <xsl:call-template name="add-metadata"/>
                    <xsl:call-template name="handle-schema"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <!-- add metadata, including optionally xml document, to head section -->
    <xsl:template name="add-metadata">
        <xsl:param name="xml-document"/>

        <xsl:element name="head">
            <xsl:element name="title">
                <xsl:value-of select="$config-title"/>
            </xsl:element>

            <!-- add stylesheet and script elements -->
            <xsl:if test="not($config-style = '')">
                <xsl:element name="link">
                    <xsl:attribute name="rel">stylesheet</xsl:attribute>
                    <xsl:attribute name="type">text/css</xsl:attribute>
                    <xsl:attribute name="href">
                        <xsl:value-of select="$config-style"/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:if>

            <xsl:call-template name="add-style"/>

            <xsl:call-template name="add-polyfills"/>
            <xsl:call-template name="add-xml-generators"/>
            <xsl:call-template name="add-html-populators"/>
            <xsl:call-template name="add-value-fixers"/>
            <xsl:call-template name="add-event-handlers"/>
            <xsl:call-template name="add-initial-calls"/>

            <xsl:if test="not($config-script = '')">
                <xsl:element name="script">
                    <xsl:attribute name="type">text/javascript</xsl:attribute>
                    <xsl:attribute name="src">
                        <xsl:value-of select="$config-script"/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:if>

            <!-- add a generator meta element -->
            <xsl:element name="meta">
                <xsl:attribute name="name">generator</xsl:attribute>
                <xsl:attribute name="content">XSD2HTML2XML v3: https://github.com/MichielCM/xsd2html2xml</xsl:attribute>

                <!-- if an xml document has been provided, save it as an attribute to the meta element -->
                <xsl:if test="not($xml-document = '')">
                    <xsl:attribute name="data-xsd2html2xml-source">
                        <xsl:apply-templates mode="serialize" select="$xml-document"/>
                    </xsl:attribute>
                </xsl:if>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- root match from which all other templates are invoked -->
    <xsl:template name="handle-schema">
        <xsl:call-template name="inform">
            <xsl:with-param name="message">
                <text>XSD file detected.</text>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="init"/>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:schema</xsl:with-param>
        </xsl:call-template>

        <!-- save root-document for future use -->
        <xsl:variable name="root-document" select="/*"/>

        <!-- load root-namespaces for future use -->
        <xsl:variable name="root-namespaces">
            <xsl:call-template name="inform">
                <xsl:with-param name="message">
                    <xsl:text>Namespaces in root document:</xsl:text>
                </xsl:with-param>
            </xsl:call-template>

            <xsl:for-each select="namespace::*">
                <xsl:element name="root-namespace">
                    <xsl:call-template name="inform">
                        <xsl:with-param name="message">
                            <xsl:if test="not(name() = '')">
                                <xsl:value-of select="name()"/>
                                <xsl:text>:</xsl:text>
                            </xsl:if>
                            <xsl:value-of select="."/>
                        </xsl:with-param>
                    </xsl:call-template>

                    <xsl:if test="not(name() = '')">
                        <xsl:attribute name="prefix">
                            <xsl:value-of select="name()"/>
                            <xsl:text>:</xsl:text>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:attribute name="namespace">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </xsl:element>
            </xsl:for-each>
        </xsl:variable>

        <xsl:element name="body">
            <xsl:element name="form">
                <!-- disable default form action -->
                <xsl:attribute name="action">javascript:void(0);</xsl:attribute>

                <!-- add class for scoping -->
                <xsl:attribute name="class">xsd2html2xml</xsl:attribute>

                <!-- specify action on submit -->
                <xsl:attribute name="onsubmit">
                    <xsl:value-of select="$config-callback"/>
                    <xsl:text>(htmlToXML(this));</xsl:text>
                </xsl:attribute>

                <!-- add custom appinfo data -->
                <xsl:for-each select="xs:annotation/xs:appinfo/*">
                    <xsl:call-template name="add-appinfo"/>
                </xsl:for-each>

                <!-- start parsing the XSD from the top -->
                <xsl:for-each select="xs:element">
                    <!-- use the element with the position indicated in config-root as root, or default to the first (usually the only) root element -->
                    <xsl:if test="($config-root = '' and position() = 1) or position() = $config-root">
                        <xsl:call-template name="forward-root">
                            <xsl:with-param name="stylesheet" select="$root-element-stylesheet"/>
                            <xsl:with-param name="template">handle-root-element</xsl:with-param>
                            <xsl:with-param name="root-document" select="//xs:schema"/>
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:for-each>

                <xsl:element name="button">
                    <xsl:attribute name="type">submit</xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:element>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">
                <xsl:text>XSLT processing completed.</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <xsl:template name="add-style">
        <xsl:element name="style">
            <xsl:attribute name="type">text/css</xsl:attribute>
            <xsl:text>
				[hidden] {
					display: none;
				}
				section {
					margin: 5px;
				}
				label {
					display: block;
				}
				label &gt; span {
					float: left;
					margin-right: 5px;
					min-width: 200px;
				}
				button[type='submit']:before {
					content: "OK";
				}
				button.add:before {
					content: "+ ";
				}
				button.remove:before {
					content: "-";
				}
				input[data-xsd2html2xml-duration='days'] + span:after {
					content: " (days)";
				}
				input[data-xsd2html2xml-duration='minutes'] + span:after {
					content: " (minutes)";
				}
			</xsl:text>
        </xsl:element>
    </xsl:template>


    <xsl:template name="add-event-handlers">
        <xsl:element name="script">
            <xsl:attribute name="type">text/javascript</xsl:attribute>
            <xsl:text disable-output-escaping="yes">
				/* EVENT HANDLERS */

				var clickAddButton = function(button) {
					var newNode = button.previousElementSibling.cloneNode(true);

					newNode.removeAttribute("hidden");

					newNode.querySelectorAll("input, select, textarea").forEach(function(o) {
						if (o.closest("[hidden]") == null)
							o.removeAttribute("disabled");
					});

					//set a new random id for radio buttons
					newNode.querySelectorAll("input[type='radio']").forEach(function(o) {
						if (o.parentElement.previousElementSibling != null
						&amp;&amp; o.parentElement.previousElementSibling.previousElementSibling != null
						&amp;&amp; o.parentElement.previousElementSibling.previousElementSibling.children.length &gt; 0
						&amp;&amp; o.parentElement.previousElementSibling.previousElementSibling.children[0].hasAttribute("type")
						&amp;&amp; o.parentElement.previousElementSibling.previousElementSibling.children[0].getAttribute("type") === "radio") {
							o.setAttribute("name", o.parentElement.previousElementSibling.previousElementSibling.children[0].getAttribute("name"));
						} else {
							o.setAttribute("name", o.getAttribute("name").concat(
								Math.random().toString().substring(2)
							));
						};

						o.setAttribute("onclick", "clickRadioInput(this, '".concat(o.getAttribute("name")).concat("');"));
					});

					button.parentNode.insertBefore(
						newNode, button.previousElementSibling
					);

					if ((button.parentNode.children.length - 2) == button.getAttribute("data-xsd2html2xml-max"))
						button.setAttribute("disabled", "disabled");

					if (newNode.querySelectorAll("[data-xsd2html2xml-primitive='id']").length &gt; 0)
						updateIdentifiers();
				}

				var clickRemoveButton = function(button) {
					var section = button.closest("section");

					if ((button.closest("section").children.length - 2) == button.closest("section").lastElementChild.getAttribute("data-xsd2html2xml-min"))
						button.closest("section").lastElementChild.click();

					if ((button.closest("section").children.length - 2) == button.closest("section").lastElementChild.getAttribute("data-xsd2html2xml-max"))
						button.closest("section").lastElementChild.removeAttribute("disabled");

					button.closest("section").removeChild(
						button.closest("fieldset, label")
					);

					if (section.querySelectorAll("[data-xsd2html2xml-primitive = 'id']").length &gt; 0)
						updateIdentifiers();
				}

				var clickRadioInput = function(input, name) {
					var activeSections = [];
					var currentSection = input.parentElement.nextElementSibling;

					while (currentSection &amp;&amp; currentSection.hasAttribute("data-xsd2html2xml-choice")) {
						activeSections.push(currentSection);
						currentSection = currentSection.nextElementSibling;
					};

					document.querySelectorAll("[name=".concat(name).concat("]")).forEach(function(o) {
						o.removeAttribute("checked");

						var section = o.parentElement.nextElementSibling;

						while (section &amp;&amp; section.hasAttribute("data-xsd2html2xml-choice")) {
							section.querySelectorAll("input, select, textarea").forEach(function(p) {
								var contained = false;
								activeSections.forEach(function(q) {
									if (q.contains(p)) contained = true;
								});

								if (contained) {
									if (p.closest("[data-xsd2html2xml-choice]") === section) {
										if (p.closest("*[hidden]") === null)
											p.removeAttribute("disabled");
										else
											p.setAttribute("disabled", "disabled");
									}
								} else {
									p.setAttribute("disabled", "disabled");
								};
							});

							section = section.nextElementSibling;
						};
					});

					input.setAttribute("checked","checked");
				}

				var updateIdentifiers = function() {
					var globalIdentifiers = [];

					document.querySelectorAll("[data-xsd2html2xml-primitive='id']:not([disabled])").forEach(function(o) {
						if (o.hasAttribute("value")) {
							globalIdentifiers.push(o.getAttribute("value"));
						}
					});

					globalIdentifiers = globalIdentifiers.filter(
						function uniques(value, index, self) {
							return self.indexOf(value) === index;
						}
					);

					document.querySelectorAll("[data-xsd2html2xml-primitive='idref'], [data-xsd2html2xml-primitive='idrefs']").forEach(function(o) {
						while(o.firstChild) {
							o.removeChild(o.firstChild);
						}

						for (var i=0; i&lt;globalIdentifiers.length; i++) {
							var option = document.createElement('option');
							option.textContent = globalIdentifiers[i];
							option.setAttribute("value", globalIdentifiers[i]);
							o.append(option);
						}
					});
				}

				var pickFile = function(input, file, type) {
					var resetFilePicker = function(input) {
						input.removeAttribute("value");
						input.removeAttribute("type");
						input.setAttribute("type", "file");
					}

					var fileReader = new FileReader();

					fileReader.onloadend = function() {
						if (fileReader.error) {
							alert(fileReader.error);
							resetFilePicker(input);
						} else {
							input.setAttribute("value",
								(type.endsWith(":base64binary"))
								? fileReader.result.substring(fileReader.result.indexOf(",") + 1)
								//convert base64 to base16 (hexBinary)
								: atob(fileReader.result.substring(fileReader.result.indexOf(",") + 1))
							    	.split('')
							    	.map(function (aChar) {
							    		return ('0' + aChar.charCodeAt(0).toString(16)).slice(-2);
							    	})
									.join('')
									.toUpperCase()
							);
						};
					};

					if(file) {
						fileReader.readAsDataURL(file);
					} else {
						resetFilePicker(input);
					}

					if (input.getAttribute("data-xsd2html2xml-required")) input.setAttribute("required", "required");
				}
			</xsl:text>
        </xsl:element>
    </xsl:template>


    <xsl:template name="add-html-populators">
        <xsl:element name="script">
            <xsl:attribute name="type">text/javascript</xsl:attribute>
            <xsl:text disable-output-escaping="yes">
				/* HTML POPULATORS */

				var addHiddenFields = function() {
					document.querySelectorAll("[data-xsd2html2xml-min], [data-xsd2html2xml-max]").forEach(function(o) {
						//add hidden element
						var newNode = o.previousElementSibling.cloneNode(true);

						newNode.setAttribute("hidden", "");

						newNode.querySelectorAll("input, textarea, select").forEach(function(p) {
							p.setAttribute("disabled", "");
						});

						o.parentElement.insertBefore(
							newNode, o
						);
					});
				};

				var ensureMinimum = function() {
					document.querySelectorAll("[data-xsd2html2xml-min], [data-xsd2html2xml-max]").forEach(function(o) {
						//add minimum number of elements
						if (o.hasAttribute("data-xsd2html2xml-min")) {
							//if no minimum, remove element
							if (o.getAttribute("data-xsd2html2xml-min") === "0"
								//check for input elements existing to handle empty elements
								&amp;&amp; o.previousElementSibling.previousElementSibling.querySelector("input, textarea, select")
								//check if element has been populated with data from an xml document
								&amp;&amp; !o.previousElementSibling.previousElementSibling.querySelector("input, textarea, select").hasAttribute("data-xsd2html2xml-filled")) {
								clickRemoveButton(
									o.parentElement.children[0].querySelector("legend &gt; button.remove, span &gt; button.remove")
								);
							//if there is only one allowed element that has been filled, disable the button
							} else if (o.getAttribute("data-xsd2html2xml-max") === "1"
								//check for input elements existing to handle empty elements
								&amp;&amp; o.previousElementSibling.previousElementSibling.querySelector("input, textarea, select")
								//check if element has been populated with data from an xml document
								&amp;&amp; o.previousElementSibling.previousElementSibling.querySelector("input, textarea, select").hasAttribute("data-xsd2html2xml-filled")) {
								o.setAttribute("disabled", "disabled");
							//else, add up to minimum number of elements
							} else {
								var remainder = o.getAttribute("data-xsd2html2xml-min") - (o.parentNode.children.length - 2);

								for (i=0; i&lt;remainder; i++) {
									clickAddButton(o);
								};
							};
						};
					});
				};

				var xmlToHTML = function(root) {
					var xmlDocument;

					//check if form was generated from an XML document
					if (document.querySelector("meta[name='generator'][content='XSD2HTML2XML v3: https://github.com/MichielCM/xsd2html2xml']").getAttribute("data-xsd2html2xml-source")) {
						//parse xml document from attribute
						xmlDocument = new DOMParser().parseFromString(
							document.querySelector("meta[name='generator'][content='XSD2HTML2XML v3: https://github.com/MichielCM/xsd2html2xml']").getAttribute("data-xsd2html2xml-source"),
							"application/xml"
						);

						//start parsing nodes, providing the root node and the corresponding document element
						parseNode(
							xmlDocument.childNodes[0],
							document.querySelector("[data-xsd2html2xml-xpath = '/".concat(xmlDocument.childNodes[0].nodeName).concat("']"))
						);
					};
				};

				var setValue = function(element, value) {
					element.querySelector("input, textarea, select").setAttribute("data-xsd2html2xml-filled", "true");

					if (element.querySelector("input") !== null) {
						if (element.querySelector("input").getAttribute("data-xsd2html2xml-primitive") === "boolean") {
							if (value === "true") {
								element.querySelector("input").setAttribute("checked", "checked");
							};
						} else {
							element.querySelector("input").setAttribute("value", value);
						};

						if (element.querySelector("input").getAttribute("type") === "file") {
							element.querySelector("input").removeAttribute("required");
							element.querySelector("input").setAttribute("data-xsd2html2xml-required", "true");
						};
					};

					if (element.querySelector("textarea") !== null) {
						element.querySelector("textarea").textContent = value;
					};

					if (element.querySelector("select") !== null) {
						if (element.querySelector("select").getAttribute("data-xsd2html2xml-primitive") === "idref"
							|| element.querySelector("select").getAttribute("data-xsd2html2xml-primitive") === "idrefs") {
							globalValuesMap.push({
								object: element.querySelector("select"),
								values: value.split(/\s+/)
							});
							/*var values = value.split(/\\s+/);
							for (var i=0; i&lt;values.length; i++) {
								element.querySelector("select option[value = '".concat(values[i]).concat("']")).setAttribute("selected", "selected");
							}*/
						} else {
							element.querySelector("select option[value = '".concat(value).concat("']")).setAttribute("selected", "selected");
						}
					};
				};

				var parseNode = function(node, element) {
					//iterate through the node's attributes and fill them out
					for (var i=0; i&lt;node.attributes.length; i++) {
						var attribute = element.querySelector(
							"[data-xsd2html2xml-xpath = '".concat(
								element.getAttribute("data-xsd2html2xml-xpath").concat(
									"/@".concat(node.attributes[i].nodeName)
									//"/@*[name() = \"".concat(node.attributes[i].nodeName).concat("\"]")
								)
							).concat("']")
						);

						if (attribute !== null) {
							setValue(attribute, node.attributes[i].nodeValue);
						};
					};

					//if there is only one (non-element) node, it must contain the value; note: this will not work for potential mixed="true" support
					if (node.childNodes.length === 1 &amp;&amp; node.childNodes[0].nodeType === Node.TEXT_NODE) {
						//in the case of complexTypes with simpleContents, select the sub-element that actually contains the input element
						if (element.querySelectorAll("[data-xsd2html2xml-xpath='".concat(element.getAttribute("data-xsd2html2xml-xpath")).concat("']")).length &gt; 0) {
							setValue(element.querySelector("[data-xsd2html2xml-xpath='".concat(element.getAttribute("data-xsd2html2xml-xpath")).concat("']")), node.childNodes[0].nodeValue);
						} else {
							setValue(element, node.childNodes[0].nodeValue);
						};
					//else, iterate through the children
					} else {
						var previousChildName;

						for (var i=0; i&lt;node.childNodes.length; i++) {
							var childNode = node.childNodes[i];

							if (childNode.nodeType === Node.ELEMENT_NODE) {
								//find the corresponding element
								var childElement = element.querySelector(
									"[data-xsd2html2xml-xpath = '".concat(
										element.getAttribute("data-xsd2html2xml-xpath").concat(
											"/".concat(childNode.nodeName)
											//"/*[name() = \"".concat(childNode.nodeName).concat("\"]")
										)
									).concat("']")
								);

								//if there is an add-button (and it is not the first child node being parsed), add an element
								var button;

								if (childElement.parentElement.lastElementChild.nodeName.toLowerCase() === "button") {
									button = childElement.parentElement.lastElementChild;
								} else if (childElement.parentElement.parentElement.parentElement.lastElementChild.nodeName.toLowerCase() === "button"
									&amp;&amp; !childElement.parentElement.parentElement.parentElement.lastElementChild.hasAttribute("data-xsd2html2xml-element")) {
									button = childElement.parentElement.parentElement.parentElement.lastElementChild;
								};

								if (button !== null &amp;&amp; childNode.nodeName === previousChildName) {
									clickAddButton(button);

									parseNode(
										childNode,
										button.previousElementSibling.previousElementSibling
										//childElement.parentElement.lastElementChild.previousElementSibling.previousElementSibling
									);
								//else, use the already generated element
								} else {
									parseNode(
										childNode,
										childElement
									);
								};

								previousChildName = childNode.nodeName;
							}
						};
					}
				};

				var setDynamicValues = function() {
					for (var i=0; i&lt;globalValuesMap.length; i++) {
						for (var j=0; j&lt;globalValuesMap[i].values.length; j++) {
							globalValuesMap[i].object.querySelector(
								"select option[value = '".concat(globalValuesMap[i].values[j]).concat("']")
							).setAttribute("selected", "selected");
						}
					}
				};
			</xsl:text>
        </xsl:element>
    </xsl:template>


    <xsl:template name="add-initial-calls">
        <xsl:element name="script">
            <xsl:attribute name="type">text/javascript</xsl:attribute>
            <xsl:text disable-output-escaping="yes">
				var globalValuesMap = [];

				document.addEventListener("DOMContentLoaded",
					function() {
						/* INITIAL CALLS */

						addHiddenFields();
						xmlToHTML(document);
						updateIdentifiers();
						setDynamicValues();
						setValues();
						ensureMinimum();

						document.querySelectorAll("[data-xsd2html2xml-filled='true']").forEach(function(o) {
							if (o.closest("[data-xsd2html2xml-choice]")) {
								var node = o.closest("[data-xsd2html2xml-choice]").previousElementSibling;
								while (node) {
									if (!node.hasAttribute("data-xsd2html2xml-choice")) {
										node.querySelector("input[type='radio']").click();
										break;
									} else {
										node = node.previousElementSibling;
									};
								};
							};
						});
					}
				);
			</xsl:text>
        </xsl:element>
    </xsl:template>


    <xsl:template name="add-polyfills">
        <xsl:element name="script">
            <xsl:attribute name="type">text/javascript</xsl:attribute>
            <xsl:text disable-output-escaping="yes">
				/* POLYFILLS */

				/* add .matches if not natively supported */
				if (!Element.prototype.matches)
					Element.prototype.matches = Element.prototype.msMatchesSelector ||
												Element.prototype.webkitMatchesSelector;

				/* add .closest if not natively supported */
				if (!Element.prototype.closest)
					Element.prototype.closest = function(s) {
						var el = this;
						do {
							if (el.nodeType !== 1) return null;
							if (el.matches(s)) return el;
							el = el.parentElement || el.parentNode;
						} while (el !== null);
						return null;
					};

				/* add .forEach if not natively supported */
				if (!NodeList.prototype.forEach) {
					NodeList.prototype.forEach = function(callback){
						var i = 0;
						while (i != this.length) {
							callback.apply(this, [this[i], i, this]);
							i++;
						}
					};
				}

        /* add .previousElementSibling if not supported */
        (function (arr) {
          arr.forEach(function (item) {
            if (item.hasOwnProperty('previousElementSibling')) {
              return;
            }
            Object.defineProperty(item, 'previousElementSibling', {
              configurable: true,
              enumerable: true,
              get: function () {
                let el = this;
                while (el = el.previousSibling) {
                  if (el.nodeType === 1) {
                    return el;
                  }
                }
                return null;
              },
              set: undefined
            });
          });
        })([Element.prototype, CharacterData.prototype]);
			</xsl:text>
        </xsl:element>
    </xsl:template>


    <xsl:template name="add-value-fixers">
        <xsl:element name="script">
            <xsl:attribute name="type">text/javascript</xsl:attribute>
            <xsl:text disable-output-escaping="yes">
				/* VALUE FIXERS */

				var setValues = function() {
					/* specifically set values on ranges */
					document.querySelectorAll("[type='range']").forEach(function(o) {
						if (o.getAttribute("value")) {
							o.value = o.getAttribute("value").replace(/\D/g, "");
						} else if (o.getAttribute("min")) {
							o.value = o.getAttribute("min");
						} else if (o.getAttribute("max")) {
							o.value = o.getAttribute("max");
						} else {
							o.value = 0;
							o.onchange();
						};

						o.previousElementSibling.textContent = o.value;
					});

					/* specifically set values on datepickers */
					document.querySelectorAll("[data-xsd2html2xml-primitive='gday']").forEach(function(o) {
						if (o.getAttribute("value")) {
							o.value = o.getAttribute("value").replace(/-+0?/g, "");
						}
					});
					document.querySelectorAll("[data-xsd2html2xml-primitive='gmonth']").forEach(function(o) {
						if (o.getAttribute("value")) {
							o.value = o.getAttribute("value").replace(/-+0?/g, "");
						}
					});
					document.querySelectorAll("[data-xsd2html2xml-primitive='gmonthday']").forEach(function(o) {
						if (o.getAttribute("value")) {
							o.value = new Date().getFullYear().toString().concat(o.getAttribute("value").substring(1));
						}
					});
				};
			</xsl:text>
        </xsl:element>
    </xsl:template>


    <xsl:template name="add-xml-generators">
        <xsl:element name="script">
            <xsl:attribute name="type">text/javascript</xsl:attribute>
            <xsl:text disable-output-escaping="yes">
				/* XML GENERATORS */

				var htmlToXML = function(root) {
					var namespaces = [];
				    var prefixes = [];

				    document.querySelectorAll("[data-xsd2html2xml-namespace]:not([data-xsd2html2xml-namespace=''])").forEach(function(o) {
				    	if (namespaces.indexOf(
				    		o.getAttribute("data-xsd2html2xml-namespace")
				    	) == -1) {
					    	namespaces.push(
					    		o.getAttribute("data-xsd2html2xml-namespace")
					    	);

					    	prefixes.push(
					    		o.getAttribute("data-xsd2html2xml-name").substring(
				    				0, o.getAttribute("data-xsd2html2xml-name").indexOf(":")
				    			)
				    		);
				    	}
				    });

				    var namespaceString = "";

				    namespaces.forEach(function(o,i) {
				    	namespaceString = namespaceString.concat(
				    		"xmlns".concat(
				    			(prefixes[i] == "" ? "=" : ":".concat(prefixes[i].concat("=")))
				    		).concat(
				    			"\"".concat(namespaces[i]).concat("\" ")
				    		)
				    	)
				    });

				    return String.fromCharCode(60).concat("?xml version=\"1.0\"?").concat(String.fromCharCode(62)).concat(getXML(root, false, namespaceString.trim()));
				};

				var getXML = function(parent, attributesOnly, namespaceString) {
				    var xml = "";
				    var children = [].slice.call(parent.children);
				    children.forEach(function(o) {
				        if (!o.hasAttribute("hidden")) {
				            switch (o.getAttribute("data-xsd2html2xml-type")) {
				                case "element":
				                    if (!attributesOnly) xml = xml.concat(String.fromCharCode(60)).concat(o.getAttribute("data-xsd2html2xml-name")).concat(getXML(o, true)).concat(String.fromCharCode(62)).concat(function() {
				                        if (o.nodeName.toLowerCase() === "label") {
				                            return getContent(o);
				                        } else return getXML(o)
				                    }()).concat(String.fromCharCode(60)).concat("/").concat(o.getAttribute("data-xsd2html2xml-name")).concat(String.fromCharCode(62));
				                    break;
				                case "attribute":
				                	if (attributesOnly)
										if (getContent(o)
											|| (o.getElementsByTagName("input").length &gt; 0
												? o.getElementsByTagName("input")[0].getAttribute("data-xsd2html2xml-primitive").toLowerCase() === "boolean"
												: false
											))
											xml = xml.concat(" ").concat(o.getAttribute("data-xsd2html2xml-name")).concat("=\"").concat(getContent(o)).concat("\"");
				                    break;
				                case "content":
				                    if (!attributesOnly) xml = xml.concat(getContent(o));
				                    break;
				                default:
				                    if (!attributesOnly) {
				                    	if (!o.getAttribute("data-xsd2html2xml-choice"))
				                    		xml = xml.concat(getXML(o));

				                    	if (o.getAttribute("data-xsd2html2xml-choice")) {
				                    		var node = o.previousElementSibling;
				                    		while (node.hasAttribute("data-xsd2html2xml-choice")) {
				                    			node = node.previousElementSibling;
				                    		};

				                    		if (node.getElementsByTagName("input")[0].checked)
				                    			xml = xml.concat(getXML(o));
				                    	};
				                    }
				                    break;
				            }
				        }
				    });

				    if (namespaceString) {
				    	xml = xml.substring(0, xml.indexOf(String.fromCharCode(62))).concat(" ").concat(namespaceString).concat(xml.substring(xml.indexOf(String.fromCharCode(62))));
				    }

				    return xml;
				};

				var getContent = function(node) {
				    if (node.getElementsByTagName("input").length != 0) {
				        switch (node.getElementsByTagName("input")[0].getAttribute("type").toLowerCase()) {
				            case "checkbox":
				                return node.getElementsByTagName("input")[0].checked;
				            case "file":
				            case "range":
				            case "date":
				            case "time":
				            case "datetime-local":
				            	return node.getElementsByTagName("input")[0].getAttribute("value");
				            default:
				            	switch (node.getElementsByTagName("input")[0].getAttribute("data-xsd2html2xml-primitive").toLowerCase()) {
						            case "gday":
						            case "gmonth":
						            case "gmonthday":
						            case "gyear":
						            case "gyearmonth":
						            	return node.getElementsByTagName("input")[0].getAttribute("value");
						            default:
						            	return node.getElementsByTagName("input")[0].value;
				            	}
				        }
				    } else if (node.getElementsByTagName("select").length != 0) {
						if (node.getElementsByTagName("select")[0].hasAttribute("multiple")) {
							return [].map.call(node.getElementsByTagName("select")[0].selectedOptions, function(o) {
								return o.getAttribute("value");
							}).join(" ");
						} else if (node.getElementsByTagName("select")[0].getElementsByTagName("option")[node.getElementsByTagName("select")[0].selectedIndex].hasAttribute("value")) {
							return node.getElementsByTagName("select")[0].value;
						} else {
							return null;
						}
				    } else if (node.getElementsByTagName("textarea").length != 0) {
				    	return node.getElementsByTagName("textarea")[0].value;
				    }
				}
			</xsl:text>
        </xsl:element>
    </xsl:template>


    <xsl:template name="init">
        <xsl:call-template name="inform">
            <xsl:with-param name="message">---</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">Running XSD2HTML2XML version 3</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">Michiel Meulendijk (mail@michielmeulendijk.nl) / Leiden University Medical
                Center
            </xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">MIT License</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">https://github.com/MichielCM/xsd2html2xml</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">---</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">XSLT Processor:
                <xsl:value-of select="system-property('xsl:vendor')"/>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">XSLT Version:
                <xsl:value-of select="system-property('xsl:version')"/>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">Debug Options:
                <xsl:value-of select="$config-debug"/>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">---</xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <!-- set output method to HTML. Use version 5 or legacy-compatible doctype to generate HTML5. -->
    <xsl:output doctype-system="about:legacy-compat" indent="yes" method="html" omit-xml-declaration="yes"
                version="5.0"/>

    <!-- set debug options for xsd2html2xml: -->
    <!-- INFO: information messages (through template 'inform') -->
    <!-- STACK: stack trace (through template 'log') -->
    <!-- ERROR: error messages (through template 'throw') -->
    <xsl:param name="config-debug">info stack error</xsl:param>

    <!-- if an XSD supports multiple root elements, specify the position of the one that should be used to generate the form from here -->
    <!-- defaults to 1 -->
    <xsl:param name="config-root">1</xsl:param>

    <!-- choose a JavaScript function to be called when the form is submitted.
	it should accept a string argument containing the xml or html -->
    <xsl:param name="config-callback">console.log</xsl:param>

    <!-- title of the generated document -->
    <xsl:param name="config-title">HTML5 Form - Generated by XSD2HTML2XML v3</xsl:param>

    <!-- custom JavaScript file URL -->
    <xsl:param name="config-script"/>

    <!-- custom CSS file URL -->
    <xsl:param name="config-style"/>

    <!-- specify whether element's annotation/documentation tags should be used for descriptions (works together with config-language) -->
    <!-- defaults to false, i.e. element's @name or @ref (unprefixed) attributes -->
    <xsl:param name="config-documentation">true</xsl:param>

    <!-- optionally specify which annotation/documentation language (determined by xml:lang) should be used -->
    <xsl:param name="config-language"/>


    <!-- adds appinfo data to data-appinfo attributes -->
    <xsl:template name="add-appinfo">
        <xsl:param name="relative-name"/>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">add-appinfo</xsl:with-param>
        </xsl:call-template>

        <xsl:choose>
            <!-- if appinfo is specifically meant for XSD2HTML2XML, add the attributes directly to the element -->
            <xsl:when test="ancestor::*[1]/@source = 'https://github.com/MichielCM/xsd2html2xml'">
                <!-- use local name to remove any colons -->
                <xsl:attribute name="{local-name()}">
                    <xsl:value-of select="."/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <!-- add data attribute if there are no further nodes -->
                <xsl:if test="count(*) = 0">
                    <!-- use local name to remove any colons -->
                    <xsl:attribute name="{concat('data-appinfo-',$relative-name,local-name())}">
                        <xsl:value-of select="."/>
                    </xsl:attribute>
                </xsl:if>

                <!-- call add-appinfo on children, if any -->
                <xsl:for-each select="*">
                    <xsl:call-template name="add-appinfo">
                        <xsl:with-param name="relative-name"
                                        select="concat($relative-name,local-name(ancestor::*[1]),'-')"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- Returns the first value that matches attr name; forward if not found -->
    <xsl:template name="attr-value">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="attr"/> <!-- contains attribute name whose value is to be returned -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">attr-value:
                <xsl:value-of select="$attr"/>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="type">
            <xsl:call-template name="get-base-type"/>
        </xsl:variable>

        <xsl:choose>
            <!-- check if element itself contains attribute -->
            <xsl:when test="@*[contains(.,$attr)]">
                <xsl:value-of select="@*[contains(name(),$attr)]"/>
            </xsl:when>
            <!-- check if element restriction contains attribute -->
            <xsl:when test=".//xs:restriction/*[contains(name(),$attr)]">
                <xsl:value-of select=".//xs:restriction/*[contains(name(),$attr)]/@value"/>
            </xsl:when>
            <!-- else, check for inherited attribute values -->
            <xsl:otherwise>
                <xsl:variable name="namespace">
                    <xsl:call-template name="get-namespace">
                        <xsl:with-param name="namespace-prefix">
                            <xsl:call-template name="get-prefix">
                                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                <xsl:with-param name="string" select="$type"/>
                            </xsl:call-template>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:call-template name="forward">
                    <xsl:with-param name="stylesheet" select="$attr-value-stylesheet"/>
                    <xsl:with-param name="template">attr-value-forwardee</xsl:with-param>

                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-documents">
                        <xsl:choose>
                            <xsl:when
                                    test="(not($namespace-documents = '') and count($namespace-documents//document) &gt; 0 and $namespace-documents//document[1]/@namespace = $namespace) or (contains($type, ':') and starts-with($type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix))">
                                <xsl:call-template name="inform">
                                    <xsl:with-param name="message">Reusing loaded namespace documents</xsl:with-param>
                                </xsl:call-template>

                                <xsl:copy-of select="$namespace-documents"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="get-namespace-documents">
                                    <xsl:with-param name="namespace">
                                        <xsl:call-template name="get-namespace">
                                            <xsl:with-param name="namespace-prefix">
                                                <xsl:call-template name="get-prefix">
                                                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                                    <xsl:with-param name="string" select="$type"/>
                                                </xsl:call-template>
                                            </xsl:with-param>
                                        </xsl:call-template>
                                    </xsl:with-param>
                                    <xsl:with-param name="root-document" select="$root-document"/>
                                    <xsl:with-param name="root-path" select="$root-path"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>

                    <xsl:with-param name="attr" select="$attr"/>
                    <xsl:with-param name="type" select="$type"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- recursive function to use with attr-value -->
    <xsl:template match="xsl:template[@name = 'attr-value-forwardee']" name="attr-value-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="attr"/> <!-- contains attribute name whose value is to be returned -->
        <xsl:param name="type"/> <!-- contains element base type -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="attr-value-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                        <xsl:with-param name="attr" select="$attr"/>
                        <xsl:with-param name="type" select="$type"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">attr-value-forwardee</xsl:with-param>
                </xsl:call-template>

                <!-- retrieve type suffix for use with matching -->
                <xsl:variable name="type-suffix">
                    <xsl:call-template name="get-suffix">
                        <xsl:with-param name="string" select="$type"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- call attr-value on all matching simple types named type suffix -->
                <xsl:for-each
                        select="$namespace-documents//xs:complexType[@name=$type-suffix]      |$namespace-documents//xs:simpleType[@name=$type-suffix]">
                    <xsl:call-template name="attr-value">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                        <xsl:with-param name="attr" select="$attr"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- Returns an element's description from xs:annotation/xs:documentation if it exists, @value in the case of enumerations, or @name otherwise -->
    <xsl:template name="get-description">
        <!-- get corresponding documentation element -->
        <xsl:variable name="documentation">
            <xsl:call-template name="get-documentation"/>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$documentation = ''">
                <xsl:choose>
                    <!-- if no documentation element exists, return @name -->
                    <xsl:when test="@name">
                        <xsl:value-of select="@name"/>
                    </xsl:when>
                    <!-- or @ref, in case of groups -->
                    <xsl:when test="@ref">
                        <xsl:call-template name="get-suffix">
                            <xsl:with-param name="string" select="@ref"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- or @value -->
                    <xsl:when test="@value">
                        <xsl:value-of select="@value"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <!-- return documentation content if it exists -->
            <xsl:otherwise>
                <xsl:value-of select="$documentation"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Returns an element's description from xs:annotation/xs:documentation if it exists, taking into account the specified preferred language -->
    <xsl:template name="get-documentation">
        <xsl:if test="$config-documentation = 'true'">
            <xsl:choose>
                <xsl:when
                        test="not($config-language = '') and xs:annotation/xs:documentation[@xml:lang=$config-language]">
                    <xsl:value-of select="xs:annotation/xs:documentation[@xml:lang=$config-language]/text()"/>
                </xsl:when>
                <xsl:when test="not($config-language = '') and xs:annotation/xs:documentation[not(@xml:lang)]">
                    <xsl:value-of select="xs:annotation/xs:documentation[not(@xml:lang)]/text()"/>
                </xsl:when>
                <xsl:when test="$config-language = '' and xs:annotation/xs:documentation[not(@xml:lang)]">
                    <xsl:value-of select="xs:annotation/xs:documentation[not(@xml:lang)]/text()"/>
                </xsl:when>
                <xsl:when test="$config-language = '' and xs:annotation/xs:documentation">
                    <xsl:value-of select="xs:annotation/xs:documentation/text()"/>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

    <!-- Returns predetermined values for xs:duration specifics found in patterns -->
    <xsl:template name="get-duration-info">
        <xsl:param name="type"/>
        <xsl:param name="pattern"/>

        <xsl:choose>
            <xsl:when test="contains($pattern, 'T') and contains($pattern, 'S')">
                <xsl:if test="$type = 'prefix'">PT</xsl:if>
                <xsl:if test="$type = 'abbreviation'">S</xsl:if>
                <xsl:if test="$type = 'description'">seconds</xsl:if>
            </xsl:when>
            <xsl:when test="contains($pattern, 'T') and contains($pattern, 'M')">
                <xsl:if test="$type = 'prefix'">PT</xsl:if>
                <xsl:if test="$type = 'abbreviation'">M</xsl:if>
                <xsl:if test="$type = 'description'">minutes</xsl:if>
            </xsl:when>
            <xsl:when test="contains($pattern, 'T') and contains($pattern, 'H')">
                <xsl:if test="$type = 'prefix'">PT</xsl:if>
                <xsl:if test="$type = 'abbreviation'">H</xsl:if>
                <xsl:if test="$type = 'description'">hours</xsl:if>
            </xsl:when>
            <xsl:when test="not(contains($pattern, 'T')) and contains($pattern, 'D')">
                <xsl:if test="$type = 'prefix'">P</xsl:if>
                <xsl:if test="$type = 'abbreviation'">D</xsl:if>
                <xsl:if test="$type = 'description'">days</xsl:if>
            </xsl:when>
            <xsl:when test="not(contains($pattern, 'T')) and contains($pattern, 'M')">
                <xsl:if test="$type = 'prefix'">P</xsl:if>
                <xsl:if test="$type = 'abbreviation'">M</xsl:if>
                <xsl:if test="$type = 'description'">months</xsl:if>
            </xsl:when>
            <xsl:when test="not(contains($pattern, 'T')) and contains($pattern, 'Y')">
                <xsl:if test="$type = 'prefix'">P</xsl:if>
                <xsl:if test="$type = 'abbreviation'">Y</xsl:if>
                <xsl:if test="$type = 'description'">years</xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$type = 'prefix'">P</xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- applies templates recursively, overwriting lower-level options -->
    <xsl:template name="set-type-specifics">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">set-type-specifics</xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="type">
            <xsl:call-template name="get-base-type"/>
        </xsl:variable>

        <xsl:if test="not(contains($type, ':')) or (contains($type, ':') and not(starts-with($type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix)))">
            <xsl:variable name="namespace">
                <xsl:call-template name="get-namespace">
                    <xsl:with-param name="namespace-prefix">
                        <xsl:call-template name="get-prefix">
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                            <xsl:with-param name="string" select="$type"/>
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:variable>

            <xsl:call-template name="forward">
                <xsl:with-param name="stylesheet" select="$gui-attributes-stylesheet"/>
                <xsl:with-param name="template">set-type-specifics-forwardee</xsl:with-param>

                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                <xsl:with-param name="namespace-documents">
                    <xsl:choose>
                        <xsl:when
                                test="(not($namespace-documents = '') and count($namespace-documents//document) &gt; 0 and $namespace-documents//document[1]/@namespace = $namespace) or (contains($type, ':') and starts-with($type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix))">
                            <xsl:call-template name="inform">
                                <xsl:with-param name="message">Reusing loaded namespace documents</xsl:with-param>
                            </xsl:call-template>

                            <xsl:copy-of select="$namespace-documents"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="get-namespace-documents">
                                <xsl:with-param name="namespace">
                                    <xsl:call-template name="get-namespace">
                                        <xsl:with-param name="namespace-prefix">
                                            <xsl:call-template name="get-prefix">
                                                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                                <xsl:with-param name="string" select="$type"/>
                                            </xsl:call-template>
                                        </xsl:with-param>
                                    </xsl:call-template>
                                </xsl:with-param>
                                <xsl:with-param name="root-document" select="$root-document"/>
                                <xsl:with-param name="root-path" select="$root-path"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>

                <xsl:with-param name="type-suffix">
                    <xsl:call-template name="get-suffix">
                        <xsl:with-param name="string" select="$type"/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>

        <xsl:apply-templates select=".//xs:restriction/xs:minInclusive"/>
        <xsl:apply-templates select=".//xs:restriction/xs:maxInclusive"/>

        <xsl:apply-templates select=".//xs:restriction/xs:minExclusive"/>
        <xsl:apply-templates select=".//xs:restriction/xs:maxExclusive"/>

        <xsl:apply-templates select=".//xs:restriction/xs:pattern"/>
        <xsl:apply-templates select=".//xs:restriction/xs:length"/>
        <xsl:apply-templates select=".//xs:restriction/xs:maxLength"/>
    </xsl:template>

    <xsl:template match="xsl:template[@name = 'set-type-specifics-forwardee']" name="set-type-specifics-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="type-suffix"/> <!-- contains element's base type suffix -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">set-type-specifics-recursively</xsl:with-param>
        </xsl:call-template>

        <xsl:for-each
                select="$namespace-documents//xs:simpleType[@name=$type-suffix]    |$namespace-documents//xs:complexType[@name=$type-suffix]">
            <xsl:call-template name="set-type-specifics">
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- sets default values for xs:* types, but does not override already specified values -->
    <xsl:template name="set-type-defaults">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="type"/> <!-- contains element's primitive type -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">set-type-defaults</xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="fractionDigits">
            <xsl:call-template name="attr-value">
                <xsl:with-param name="attr"><xsl:value-of
                        select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>fractionDigits
                </xsl:with-param>
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$type = 'decimal'">
                <xsl:attribute name="step">
                    <xsl:choose>
                        <xsl:when test="$fractionDigits!='' and $fractionDigits!='0'">
                            <xsl:value-of
                                    select="concat('0.',substring('00000000000000000000',1,$fractionDigits - 1),'1')"/>
                        </xsl:when>
                        <xsl:otherwise>0.1</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="allow-dot">true</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'float'">
                <xsl:attribute name="step">
                    <xsl:choose>
                        <xsl:when test="$fractionDigits!='' and $fractionDigits!='0'">
                            <xsl:value-of
                                    select="concat('0.',substring('00000000000000000000',1,$fractionDigits - 1),'1')"/>
                        </xsl:when>
                        <xsl:otherwise>0.1</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="allow-dot">true</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'double'">
                <xsl:attribute name="step">
                    <xsl:choose>
                        <xsl:when test="$fractionDigits!='' and $fractionDigits!='0'">
                            <xsl:value-of
                                    select="concat('0.',substring('00000000000000000000',1,$fractionDigits - 1),'1')"/>
                        </xsl:when>
                        <xsl:otherwise>0.1</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="allow-dot">true</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'byte'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">-128</xsl:with-param>
                    <xsl:with-param name="max-value">127</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'unsignedbyte'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">0</xsl:with-param>
                    <xsl:with-param name="max-value">255</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix"/>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'short'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">-32768</xsl:with-param>
                    <xsl:with-param name="max-value">32767</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'unsignedshort'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">0</xsl:with-param>
                    <xsl:with-param name="max-value">65535</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix"/>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'int'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">-2147483648</xsl:with-param>
                    <xsl:with-param name="max-value">2147483647</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'integer'">
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'nonpositiveinteger'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="max-value">0</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'nonnegativeinteger'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">0</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix"/>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'positiveinteger'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">1</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix"/>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'negativeinteger'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="max-value">-1</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'unsignedint'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">0</xsl:with-param>
                    <xsl:with-param name="max-value">4294967295</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix"/>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'long'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">-9223372036854775808</xsl:with-param>
                    <xsl:with-param name="max-value">9223372036854775807</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">[-]?</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'unsignedlong'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">0</xsl:with-param>
                    <xsl:with-param name="max-value">18446744073709551615</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix"/>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'datetime'">
                <xsl:attribute name="step">1</xsl:attribute>
            </xsl:when>
            <xsl:when test="$type = 'time'">
                <xsl:attribute name="step">1</xsl:attribute>
            </xsl:when>
            <xsl:when test="$type = 'gday'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">1</xsl:with-param>
                    <xsl:with-param name="max-value">31</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:attribute name="step">1</xsl:attribute>
            </xsl:when>
            <xsl:when test="$type = 'gmonth'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">1</xsl:with-param>
                    <xsl:with-param name="max-value">12</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:attribute name="step">1</xsl:attribute>
            </xsl:when>
            <xsl:when test="$type = 'gyear'">
                <xsl:call-template name="set-numeric-range">
                    <xsl:with-param name="min-value">1000</xsl:with-param>
                    <xsl:with-param name="max-value">9999</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
                <xsl:attribute name="step">1</xsl:attribute>
            </xsl:when>
            <xsl:when test="$type = 'duration'">
                <xsl:attribute name="step">1</xsl:attribute>
            </xsl:when>
            <xsl:when test="$type = 'language'">
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">([a-zA-Z]{2}|[iI]-[a-zA-Z]+|[xX]-[a-zA-Z]{1,8})(-[a-zA-Z]{1,8})*
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'id'">
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="prefix">(?!_)[_A-Za-z][-._A-Za-z0-9]*</xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="set-pattern">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- sets min and max attributes if they have not been specified explicitly -->
    <xsl:template name="set-numeric-range">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="min-value"/>
        <xsl:param name="max-value"/>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">set-numeric-range</xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="minInclusive">
            <xsl:call-template name="attr-value">
                <xsl:with-param name="attr"><xsl:value-of
                        select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>minInclusive
                </xsl:with-param>
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="minExclusive">
            <xsl:call-template name="attr-value">
                <xsl:with-param name="attr"><xsl:value-of
                        select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>minExclusive
                </xsl:with-param>
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="$minInclusive = '' and $minExclusive = '' and not($min-value = '')">
            <xsl:attribute name="min">
                <xsl:value-of select="$min-value"/>
            </xsl:attribute>
        </xsl:if>

        <xsl:variable name="maxInclusive">
            <xsl:call-template name="attr-value">
                <xsl:with-param name="attr"><xsl:value-of
                        select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>maxInclusive
                </xsl:with-param>
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="maxExclusive">
            <xsl:call-template name="attr-value">
                <xsl:with-param name="attr"><xsl:value-of
                        select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>maxExclusive
                </xsl:with-param>
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="$maxInclusive = '' and $maxExclusive = '' and not($max-value = '')">
            <xsl:attribute name="max">
                <xsl:value-of select="$max-value"/>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>

    <!-- sets pattern attribute if it has not been specified explicitly -->
    <!-- numeric types (depending on totalDigits and fractionDigits) get regex patterns allowing digits and not counting the - and . -->
    <!-- other types (depending on minLength, maxLength, and length) get simpler regex patterns allowing any characters -->
    <xsl:template name="set-pattern">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="prefix">.</xsl:param>
        <xsl:param name="allow-dot">false</xsl:param>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">set-pattern</xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="pattern">
            <xsl:call-template name="attr-value">
                <xsl:with-param name="attr"><xsl:value-of
                        select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>pattern
                </xsl:with-param>
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="$pattern=''">
            <xsl:variable name="length">
                <xsl:call-template name="attr-value">
                    <xsl:with-param name="attr"><xsl:value-of
                            select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>length
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:variable>

            <xsl:variable name="minLength">
                <xsl:call-template name="attr-value">
                    <xsl:with-param name="attr"><xsl:value-of
                            select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>minLength
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:variable>

            <xsl:variable name="maxLength">
                <xsl:call-template name="attr-value">
                    <xsl:with-param name="attr"><xsl:value-of
                            select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>maxLength
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:variable>

            <xsl:variable name="totalDigits">
                <xsl:call-template name="attr-value">
                    <xsl:with-param name="attr"><xsl:value-of
                            select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>totalDigits
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:variable>

            <xsl:variable name="fractionDigits">
                <xsl:call-template name="attr-value">
                    <xsl:with-param name="attr"><xsl:value-of
                            select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>fractionDigits
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:variable>

            <xsl:attribute name="pattern">
                <xsl:choose>
                    <xsl:when test="$totalDigits!='' and $fractionDigits!=''">
                        <xsl:value-of
                                select="concat($prefix,'(?!\d{',$totalDigits + 1,'})(?!.*\.\d{',$totalDigits + 1 - $fractionDigits,',})[\d.]{0,',$totalDigits + 1,'}')"/>
                    </xsl:when>
                    <xsl:when test="$totalDigits!='' and $allow-dot='true'">
                        <xsl:value-of
                                select="concat($prefix,'(?!\d{',$totalDigits + 1,'})[\d.]{0,',$totalDigits + 1,'}')"/>
                    </xsl:when>
                    <xsl:when test="$totalDigits!='' and $allow-dot='false'">
                        <xsl:value-of select="concat($prefix,'(?!\d{',$totalDigits,'})[\d]{0,',$totalDigits,'}')"/>
                    </xsl:when>
                    <xsl:when test="$fractionDigits!=''">
                        <xsl:value-of select="concat($prefix,'\d*(?:[.][\d]{0,',$fractionDigits,'})?')"/>
                    </xsl:when>
                    <xsl:when test="not($length='')">
                        <xsl:value-of select="concat($prefix,'{',$length,'}')"/>
                    </xsl:when>
                    <!-- override lengths if pattern already ends with a number indicator -->
                    <xsl:when test="substring($prefix, string-length($prefix)) = '*'">
                        <xsl:value-of select="$prefix"/>
                    </xsl:when>
                    <xsl:when test="$minLength=''">
                        <xsl:value-of select="concat($prefix,'{0,',$maxLength,'}')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($prefix,'{',$minLength,',',$maxLength,'}')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xs:minInclusive">
        <xsl:attribute name="min">
            <xsl:value-of
                    select="translate(@value,translate(@value, '0123456789.-', ''), '')"/> <!-- use double-translate function to extract numbers from possible regex input (e.g. for xs:duration) -->
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xs:maxInclusive">
        <xsl:attribute name="max">
            <xsl:value-of
                    select="translate(@value,translate(@value, '0123456789.-', ''), '')"/> <!-- use double-translate function to extract numbers from possible regex input (e.g. for xs:duration) -->
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xs:minExclusive">
        <xsl:attribute name="min">
            <xsl:value-of
                    select="number(translate(@value,translate(@value, '0123456789.-', ''), '')) + 1"/> <!-- use double-translate function to extract numbers from possible regex input (e.g. for xs:duration) -->
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xs:maxExclusive">
        <xsl:attribute name="max">
            <xsl:value-of
                    select="number(translate(@value,translate(@value, '0123456789.-', ''), '')) - 1"/> <!-- use double-translate function to extract numbers from possible regex input (e.g. for xs:duration) -->
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xs:enumeration">
        <xsl:param name="default"/>
        <xsl:param name="disabled"/>

        <xsl:variable name="description">
            <xsl:call-template name="get-description"/>
        </xsl:variable>

        <xsl:element name="option">
            <xsl:if test="$default = @value">
                <xsl:attribute name="selected">selected</xsl:attribute>
            </xsl:if>

            <xsl:if test="$disabled = 'true' and not($default = @value)">
                <xsl:attribute name="disabled">disabled</xsl:attribute>
            </xsl:if>

            <xsl:attribute name="value">
                <xsl:value-of select="@value"/>
            </xsl:attribute>

            <xsl:value-of select="$description"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="xs:pattern">
        <xsl:attribute name="pattern">
            <xsl:value-of select="@value"/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="xs:length|xs:maxLength">
        <xsl:attribute name="maxlength">
            <xsl:value-of select="@value"/>
        </xsl:attribute>
    </xsl:template>


    <!-- adds a remove button for dynamic elements -->
    <xsl:template name="add-remove-button">
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->

        <!-- <xsl:if test="(not($min-occurs = '') or not($max-occurs = '')) and not($min-occurs = $max-occurs) and not($min-occurs = '1' and $max-occurs = '') and not($max-occurs = '1' and $min-occurs = '')"> -->
        <xsl:if test="(number($min-occurs) or $min-occurs = '0' or number($max-occurs) or $max-occurs = 'unbounded') and not($min-occurs = $max-occurs) and not($min-occurs = '1' and $max-occurs = '') and not($max-occurs = '1' and $min-occurs = '')">
            <xsl:element name="button">
                <xsl:attribute name="type">button</xsl:attribute>
                <xsl:attribute name="class">remove</xsl:attribute>
                <xsl:attribute name="onclick">clickRemoveButton(this);</xsl:attribute>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- adds and add button for dynamic elements -->
    <xsl:template name="add-add-button">
        <xsl:param name="description"/>
        <xsl:param
                name="disabled"/> <!-- indicates if the button should be disabled by default; used when the max number of maxOccurs has been reached in xml-doc -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->

        <!-- <xsl:if test="(not($min-occurs = '') or not($max-occurs = '')) and not($min-occurs = $max-occurs) and not($min-occurs = '1' and $max-occurs = '') and not($max-occurs = '1' and $min-occurs = '')"> -->
        <xsl:if test="(number($min-occurs) or $min-occurs = '0' or number($max-occurs) or $max-occurs = 'unbounded') and not($min-occurs = $max-occurs) and not($min-occurs = '1' and $max-occurs = '') and not($max-occurs = '1' and $min-occurs = '')">
            <xsl:element name="button">
                <xsl:attribute name="type">button</xsl:attribute>
                <xsl:attribute name="class">add</xsl:attribute>
                <xsl:if test="$disabled = 'true'">
                    <xsl:attribute name="disabled">disabled</xsl:attribute>
                </xsl:if>
                <xsl:attribute name="data-xsd2html2xml-min">
                    <xsl:choose>
                        <xsl:when test="$min-occurs = '0' or number($min-occurs)">
                            <xsl:value-of select="$min-occurs"/>
                        </xsl:when>
                        <xsl:otherwise>1</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="data-xsd2html2xml-max">
                    <xsl:choose>
                        <xsl:when test="$max-occurs = '0' or number($max-occurs) or $max-occurs = 'unbounded'">
                            <xsl:value-of select="$max-occurs"/>
                        </xsl:when>
                        <xsl:otherwise>1</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="onclick">clickAddButton(this);</xsl:attribute>
                <xsl:value-of select="$description"/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- adds a radio button for choice groups -->
    <xsl:template name="add-choice-button">
        <xsl:param name="name"/>
        <xsl:param name="description"/>
        <xsl:param name="disabled">false</xsl:param>

        <xsl:element name="label">
            <xsl:element name="input">
                <xsl:attribute name="type">radio</xsl:attribute>
                <xsl:attribute name="name">
                    <xsl:value-of select="$name"/>
                </xsl:attribute>
                <xsl:attribute name="required">required</xsl:attribute>
                <xsl:if test="$disabled = 'true'">
                    <xsl:attribute name="disabled">disabled</xsl:attribute>
                </xsl:if>
                <xsl:attribute name="onclick">clickRadioInput(this, '<xsl:value-of select="$name"/>');
                </xsl:attribute>
                <xsl:attribute name="data-xsd2html2xml-description">
                    <xsl:value-of select="$description"/>
                </xsl:attribute>
            </xsl:element>

            <xsl:element name="span">
                <xsl:value-of select="$description"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>


    <xsl:template name="log">
        <xsl:param name="reference"/>

        <xsl:if test="contains($config-debug, 'stack')">
            <xsl:message>
                <xsl:text>RAN </xsl:text>
                <xsl:value-of select="substring(concat($reference, '                              '), 1, 30)"/>

                <xsl:if test="name()">
                    <xsl:text> ON </xsl:text>
                    <xsl:value-of select="substring(concat(name(), '                    '), 1, 20)"/>
                </xsl:if>

                <xsl:if test="@name">
                    <xsl:text> NAMED </xsl:text>
                    <xsl:value-of select="substring(concat(@name, '                    '), 1, 20)"/>
                </xsl:if>

                <xsl:if test="@ref">
                    <xsl:text> REFER </xsl:text>
                    <xsl:value-of select="substring(concat(@ref, '                    '), 1, 20)"/>
                </xsl:if>

                <xsl:if test="@type">
                    <xsl:text> OF TYPE </xsl:text>
                    <xsl:value-of select="substring(concat(@type, '                    '), 1, 20)"/>
                </xsl:if>
            </xsl:message>
        </xsl:if>
    </xsl:template>

    <xsl:template name="inform">
        <xsl:param name="message"/>

        <xsl:if test="contains($config-debug, 'info')">
            <xsl:message>
                <xsl:text>INF </xsl:text>
                <xsl:value-of select="$message"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>

    <xsl:template name="throw">
        <xsl:param name="message"/>

        <xsl:if test="contains($config-debug, 'error')">
            <xsl:message>
                <xsl:text>ERR </xsl:text>
                <xsl:value-of select="$message"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>


    <!-- Returns namespace name corresponding to supplied prefix -->
    <!-- Optionally returns targetNamespace if no namespace is specified -->
    <xsl:template name="get-namespace">
        <xsl:param name="namespace-prefix"/> <!-- Prefix of namespace that should be returned -->
        <xsl:param name="default-targetnamespace">true
        </xsl:param> <!-- optionally return targetNamespace if no namespace is specified -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-namespace</xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="namespace">
            <xsl:for-each select="namespace::*">
                <xsl:choose>
                    <xsl:when test="contains($namespace-prefix, ':')">
                        <xsl:if test="name() = substring-before($namespace-prefix,':')">
                            <xsl:value-of select="."/>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="name() = $namespace-prefix">
                            <xsl:value-of select="."/>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$namespace = '' and $default-targetnamespace = 'true'">
                <xsl:value-of select="(//xs:schema)[1]/@targetNamespace"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$namespace"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- removes duplicate document elements -->
    <xsl:template match="xsl:template[@name = 'remove-duplicates']" name="remove-duplicates">
        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">remove-duplicates</xsl:with-param>
        </xsl:call-template>

        <xsl:element name="documents">
            <xsl:for-each select="$namespace-documents//document">
                <xsl:variable name="url" select="@url"/>

                <!-- copy document only if it has no preceding siblings with the same url -->
                <xsl:if test="count(preceding-sibling::document[@url=$url]) = 0">
                    <xsl:copy-of select="."/>
                </xsl:if>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <!-- returns documents belonging to a specific namespace -->
    <xsl:template name="get-namespace-documents">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->

        <xsl:param name="namespace"/> <!-- namespace name whose documents are returned -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-namespace-documents</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$namespaces-stylesheet"/>
            <xsl:with-param name="template">remove-duplicates</xsl:with-param>

            <xsl:with-param name="namespace-documents">
                <xsl:call-template name="get-namespace-documents-recursively">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>

                    <xsl:with-param name="namespace" select="$namespace"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- Returns an element's namespace documents recursively -->
    <xsl:template name="get-namespace-documents-recursively">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->

        <xsl:param name="namespace"/> <!-- namespace name whose documents are returned -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-namespace-documents-recursively</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="inform">
            <xsl:with-param name="message">
                <xsl:choose>
                    <xsl:when test="$namespace = ''">
                        <xsl:text>Resolving documents for default namespace</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>Resolving documents for namespace </xsl:text>
                        <xsl:value-of select="$namespace"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="target-namespace">
            <xsl:value-of select="(//xs:schema)[1]/@targetNamespace"/>
        </xsl:variable>

        <xsl:element name="documents">
            <xsl:if test="$namespace = $target-namespace">
                <!-- add current document -->
                <xsl:call-template name="inform">
                    <xsl:with-param name="message">
                        <xsl:text>Resolving calling document</xsl:text>
                    </xsl:with-param>
                </xsl:call-template>

                <xsl:element name="document">
                    <xsl:attribute name="namespace">
                        <xsl:value-of select="$namespace"/>
                    </xsl:attribute>

                    <xsl:copy-of select="(//xs:schema)[1]"/>
                </xsl:element>
            </xsl:if>

            <xsl:call-template name="add-namespace-document-recursively">
                <xsl:with-param name="document" select="//xs:schema"/>
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="namespace" select="$namespace"/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>

    <!-- recursively returns documents from specific include or import elements -->
    <xsl:template name="add-namespace-document-recursively">
        <xsl:param name="document"/>
        <xsl:param name="root-document"/>
        <xsl:param name="namespace"/>

        <!-- add each document referenced through include or import -->
        <xsl:for-each select="$document//xs:include|$document//xs:import[@namespace = $namespace]">
            <!-- add only include elements that have the correct namespace -->
            <xsl:if test="local-name() = 'import' or     (local-name() = 'include' and      (not($namespace = '') and $document/@targetNamespace = $namespace) or      ($namespace = '' and count($document[not(@targetNamespace)]) &gt; 0))">

                <xsl:call-template name="inform">
                    <xsl:with-param name="message">
                        <xsl:text>Resolving </xsl:text>
                        <xsl:value-of select="string(@schemaLocation)"/>
                    </xsl:with-param>
                </xsl:call-template>

                <xsl:element name="document">
                    <xsl:attribute name="url">
                        <xsl:value-of select="string(@schemaLocation)"/>
                    </xsl:attribute>

                    <xsl:attribute name="namespace">
                        <xsl:value-of select="$namespace"/>
                    </xsl:attribute>

                    <xsl:copy-of select="document(string(@schemaLocation), $root-document|node())"/>
                </xsl:element>

                <!-- add documents recursively: add documents in referenced documents -->
                <xsl:call-template name="add-namespace-document-recursively">
                    <xsl:with-param name="document"
                                    select="document(string(@schemaLocation), $root-document|node())//xs:schema"/>
                    <xsl:with-param name="root-document"
                                    select="document(string(@schemaLocation), $root-document|node())"/>
                    <xsl:with-param name="namespace" select="$namespace"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- Returns the current element's namespace documents -->
    <!-- Shortcut method for getting prefix, getting namespace, and loading namespace documents -->
    <xsl:template name="get-my-namespace-documents">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-my-namespace-documents</xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="type">
            <xsl:call-template name="get-type"/>
        </xsl:variable>

        <xsl:if test="not(contains($type, ':')) or not(starts-with($type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix))">
            <xsl:call-template name="get-namespace-documents">
                <xsl:with-param name="namespace">
                    <xsl:call-template name="get-namespace">
                        <xsl:with-param name="namespace-prefix">
                            <xsl:call-template name="get-prefix">
                                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                <xsl:with-param name="string" select="$type"/>
                                <xsl:with-param name="include-colon">true</xsl:with-param>
                            </xsl:call-template>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:with-param>
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>


    <!-- forwards all provided parameters to $template in $stylesheet; forwards $namespace-documents as nodeset -->
    <xsl:template name="forward">
        <xsl:param
                name="stylesheet"/> <!-- stylesheet file in which template is declared; variable declared in xsdToQuasarform.xsl -->
        <xsl:param name="template"/> <!-- template name to be called; must contain @name attribute in declaration -->

        <xsl:param name="namespace-documents"/> <!-- namespace documents as result tree fragment -->

        <!-- miscellanerous parameters -->
        <xsl:param name="root-document"/>
        <xsl:param name="root-path"/>
        <xsl:param name="root-namespaces"/>
        <xsl:param name="namespace-prefix"/>
        <xsl:param name="id"/>
        <xsl:param name="ref"/>
        <xsl:param name="ref-suffix"/>
        <xsl:param name="base"/>
        <xsl:param name="attr"/>
        <xsl:param name="min-occurs"/>
        <xsl:param name="max-occurs"/>
        <xsl:param name="choice"/>
        <xsl:param name="local-namespace"/>
        <xsl:param name="local-namespace-prefix"/>
        <xsl:param name="description"/>
        <xsl:param name="count"/>
        <xsl:param name="index"/>
        <xsl:param name="simple"/>
        <xsl:param name="invisible"/>
        <xsl:param name="default"/>
        <xsl:param name="disabled"/>
        <xsl:param name="type"/>
        <xsl:param name="type-suffix"/>
        <xsl:param name="reference"/>
        <xsl:param name="xpath"/>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">fwd (EXSLT):
                <xsl:value-of select="$template"/>
            </xsl:with-param>
        </xsl:call-template>

        <!-- use EXSLT node-set extension for namespace-documents -->
        <xsl:apply-templates select="$stylesheet/*/xsl:template[@name=$template]">
            <!-- calling node is provided as parameter $node -->
            <xsl:with-param name="node" select="."/>

            <!-- namespace documents are forwarded as nodeset -->
            <xsl:with-param name="namespace-documents" select="exsl:node-set($namespace-documents)"/>

            <!-- miscellaneous parameters are forwarded as they are -->
            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="ref" select="$ref"/>
            <xsl:with-param name="ref-suffix" select="$ref-suffix"/>
            <xsl:with-param name="base" select="$base"/>
            <xsl:with-param name="attr" select="$attr"/>
            <xsl:with-param name="min-occurs" select="$min-occurs"/>
            <xsl:with-param name="max-occurs" select="$max-occurs"/>
            <xsl:with-param name="choice" select="$choice"/>
            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>
            <xsl:with-param name="local-namespace" select="$local-namespace"/>
            <xsl:with-param name="local-namespace-prefix" select="$local-namespace-prefix"/>
            <xsl:with-param name="description" select="$description"/>
            <xsl:with-param name="simple" select="$simple"/>
            <xsl:with-param name="count" select="$count"/>
            <xsl:with-param name="index" select="$index"/>
            <xsl:with-param name="invisible" select="$invisible"/>
            <xsl:with-param name="default" select="$default"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="type-suffix" select="$type-suffix"/>
            <xsl:with-param name="reference" select="$reference"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- forwards all provided parameters to $template in $stylesheet; forwards $root-namespaces as nodeset -->
    <xsl:template name="forward-root">
        <xsl:param
                name="stylesheet"/> <!-- stylesheet file in which template is declared; variable declared in xsdToQuasarform.xsl -->
        <xsl:param name="template"/> <!-- template name to be called; must contain @name attribute in declaration -->

        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param
                name="root-namespaces"/> <!-- contains root document's namespaces and prefixes as result tree fragment -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">fwd-root (EXSLT):
                <xsl:value-of select="$template"/>
            </xsl:with-param>
        </xsl:call-template>

        <!-- use EXSLT node-set extension for root-namespaces -->
        <xsl:apply-templates select="$stylesheet/*/xsl:template[@name=$template]">
            <!-- calling node is provided as parameter $node -->
            <xsl:with-param name="node" select="."/>

            <!-- root namespaces are forwarded as nodeset -->
            <xsl:with-param name="root-namespaces" select="exsl:node-set($root-namespaces)"/>

            <!-- miscellaneous parameters are forwarded as they are -->
            <xsl:with-param name="root-document" select="$root-document"/>
        </xsl:apply-templates>
    </xsl:template>


    <!-- match root element -->
    <xsl:template match="/*" mode="serialize">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>

        <!-- add namespaces -->
        <xsl:for-each select="namespace::*">
            <xsl:text> xmlns</xsl:text>

            <xsl:if test="not(name() = '')">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="name()"/>
            </xsl:if>

            <xsl:text>="</xsl:text>
            <xsl:value-of select="."/>
            <xsl:text>"</xsl:text>
        </xsl:for-each>

        <xsl:apply-templates mode="serialize" select="@*"/>

        <xsl:text>&gt;</xsl:text>

        <xsl:apply-templates mode="serialize"/>

        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
    </xsl:template>

    <!-- match all other elements -->
    <xsl:template match="*" mode="serialize">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:apply-templates mode="serialize" select="@*"/>
        <xsl:choose>
            <xsl:when test="node()">
                <xsl:text>&gt;</xsl:text>
                <xsl:apply-templates mode="serialize"/>
                <xsl:text>&lt;/</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>&gt;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> /&gt;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- match attributes -->
    <xsl:template match="@*" mode="serialize">
        <xsl:text> </xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>="</xsl:text>
        <xsl:call-template name="double-escape">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
        <xsl:text>"</xsl:text>
    </xsl:template>

    <!-- match content -->
    <xsl:template match="text()" mode="serialize">
        <xsl:call-template name="double-escape">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </xsl:template>

    <!-- doubly escapes text (e.g. &lt; => &amp;lt;) -->
    <xsl:template name="double-escape">
        <xsl:param name="text"/>

        <xsl:call-template name="replace">
            <xsl:with-param name="find" select="'&lt;'"/>
            <xsl:with-param name="replace" select="'&amp;lt;'"/>
            <xsl:with-param name="text">
                <xsl:call-template name="replace">
                    <xsl:with-param name="find" select="'&gt;'"/>
                    <xsl:with-param name="replace" select="'&amp;gt;'"/>
                    <xsl:with-param name="text">
                        <xsl:call-template name="replace">
                            <xsl:with-param name="find" select="'&quot;'"/>
                            <xsl:with-param name="replace" select="'&amp;quot;'"/>
                            <xsl:with-param name="text">
                                <xsl:call-template name="replace">
                                    <xsl:with-param name="find" select="&quot;'&quot;"/>
                                    <xsl:with-param name="replace" select="'&amp;apos;'"/>
                                    <xsl:with-param name="text">
                                        <xsl:call-template name="replace">
                                            <xsl:with-param name="find" select="'&amp;'"/>
                                            <xsl:with-param name="replace" select="'&amp;amp;'"/>
                                            <xsl:with-param name="text" select="$text"/>
                                        </xsl:call-template>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <!-- replaces strings with replaces -->
    <xsl:template name="replace">
        <xsl:param name="text"/>
        <xsl:param name="find"/>
        <xsl:param name="replace"/>

        <xsl:choose>
            <xsl:when test="contains($text, $find)">
                <xsl:value-of select="substring-before($text, $find)"/>
                <xsl:value-of select="$replace"/>
                <xsl:call-template name="replace">
                    <xsl:with-param name="text" select="substring-after($text, $find)"/>
                    <xsl:with-param name="find" select="$find"/>
                    <xsl:with-param name="replace" select="$replace"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="has-prefix">
        <xsl:param name="string"/>

        <xsl:value-of select="contains($string, ':')"/>
    </xsl:template>

    <!-- Returns the prefix of a string -->
    <!-- Useful for extracting namespace prefixes -->
    <xsl:template name="get-prefix">
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="default-empty">true</xsl:param>
        <xsl:param name="exclude-schema">true</xsl:param>
        <xsl:param name="include-colon">false</xsl:param>
        <xsl:param name="string"/>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-prefix</xsl:with-param>
        </xsl:call-template>

        <xsl:choose>
            <xsl:when test="contains($string, ':')">
                <xsl:if test="not($exclude-schema = 'true' and (contains($string, ':') and starts-with($string, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix)))">
                    <xsl:choose>
                        <xsl:when test="$include-colon = 'true'">
                            <xsl:value-of select="substring-before($string, ':')"/><xsl:text>:</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="substring-before($string, ':')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not($default-empty = 'true')">
                    <xsl:value-of select="$string"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Returns the substring of a string after its prefix -->
    <!-- Useful for stripping names off their namespace prefixes -->
    <xsl:template name="get-suffix">
        <xsl:param name="string"/>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-suffix</xsl:with-param>
        </xsl:call-template>

        <xsl:choose>
            <xsl:when test="contains($string, ':')">
                <xsl:value-of select="substring-after($string, ':')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$string"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- Returns the type directly specified by the calling node -->
    <xsl:template name="get-type">
        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-type</xsl:with-param>
        </xsl:call-template>

        <xsl:if test="@type">
            <xsl:value-of select="@type"/>
        </xsl:if>
    </xsl:template>

    <!-- Returns the base type (e.g. @type, extensions' @base, restrictions' @base) of the calling node -->
    <xsl:template name="get-base-type">
        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-base-type</xsl:with-param>
        </xsl:call-template>

        <xsl:choose>
            <xsl:when test="@type">
                <xsl:value-of select="@type"/>
            </xsl:when>
            <xsl:when test="xs:simpleType/xs:restriction/@base">
                <xsl:value-of select="xs:simpleType/xs:restriction/@base"/>
            </xsl:when>
            <xsl:when test="xs:restriction/@base">
                <xsl:value-of select="xs:restriction/@base"/>
            </xsl:when>
            <xsl:when test="xs:complexType/xs:simpleContent/xs:restriction/@base">
                <xsl:value-of select="xs:complexType/xs:simpleContent/xs:restriction/@base"/>
            </xsl:when>
            <xsl:when test="xs:simpleContent/xs:restriction/@base">
                <xsl:value-of select="xs:simpleContent/xs:restriction/@base"/>
            </xsl:when>
            <xsl:when test="xs:complexType/xs:simpleContent/xs:extension/@base">
                <xsl:value-of select="xs:complexType/xs:simpleContent/xs:extension/@base"/>
            </xsl:when>
            <xsl:when test="xs:simpleContent/xs:extension/@base">
                <xsl:value-of select="xs:simpleContent/xs:extension/@base"/>
            </xsl:when>
            <xsl:when test="xs:complexType/xs:complexContent/xs:extension/@base">
                <xsl:value-of select="xs:complexType/xs:complexContent/xs:extension/@base"/>
            </xsl:when>
            <xsl:when test="xs:complexContent/xs:extension/@base">
                <xsl:value-of select="xs:complexContent/xs:extension/@base"/>
            </xsl:when>
            <xsl:when test="xs:simpleType/xs:union/@memberTypes">
                <xsl:value-of select="xs:simpleType/xs:union/@memberTypes"/>
            </xsl:when>
            <xsl:when test="xs:union/@memberTypes">
                <xsl:value-of select="xs:simpleType/xs:union/@memberTypes"/>
            </xsl:when>
            <xsl:when test="@ref">
                <xsl:value-of
                        select="@ref"/> <!-- a @ref attribute does not contain a type but an element reference. It does contain the prefix of the namespace where the element's type is declared, so it is required to look up the element specification -->
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- Returns the original xs:* type specified by the calling node, in lower case -->
    <xsl:template name="get-primitive-type">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">get-primitive-type</xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="type">
            <xsl:call-template name="get-base-type"/>
        </xsl:variable>

        <xsl:choose>
            <xsl:when
                    test="not(contains($type, ':')) or (contains($type, ':') and not(starts-with($type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix)))">
                <xsl:variable name="namespace">
                    <xsl:call-template name="get-namespace">
                        <xsl:with-param name="namespace-prefix">
                            <xsl:call-template name="get-prefix">
                                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                <xsl:with-param name="string" select="$type"/>
                            </xsl:call-template>
                        </xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:call-template name="forward">
                    <xsl:with-param name="stylesheet" select="$types-stylesheet"/>
                    <xsl:with-param name="template">get-primitive-type-forwardee</xsl:with-param>

                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-documents">
                        <xsl:choose>
                            <xsl:when
                                    test="(not($namespace-documents = '') and count($namespace-documents//document) &gt; 0 and $namespace-documents//document[1]/@namespace = $namespace) or (contains($type, ':') and starts-with($type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix))">
                                <xsl:call-template name="inform">
                                    <xsl:with-param name="message">Reusing loaded namespace documents</xsl:with-param>
                                </xsl:call-template>

                                <xsl:copy-of select="$namespace-documents"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:call-template name="get-namespace-documents">
                                    <xsl:with-param name="namespace">
                                        <xsl:call-template name="get-namespace">
                                            <xsl:with-param name="namespace-prefix">
                                                <xsl:call-template name="get-prefix">
                                                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                                    <xsl:with-param name="string" select="$type"/>
                                                </xsl:call-template>
                                            </xsl:with-param>
                                        </xsl:call-template>
                                    </xsl:with-param>
                                    <xsl:with-param name="root-document" select="$root-document"/>
                                    <xsl:with-param name="root-path" select="$root-path"/>
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>

                    <xsl:with-param name="type-suffix">
                        <xsl:call-template name="get-suffix">
                            <xsl:with-param name="string" select="$type"/>
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="translate($type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="xsl:template[@name = 'get-primitive-type-forwardee']" name="get-primitive-type-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="type-suffix"/> <!-- contains element base type -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="get-primitive-type-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                        <xsl:with-param name="type-suffix" select="$type-suffix"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">get-primitive-type-recursively</xsl:with-param>
                </xsl:call-template>

                <!-- call get-primitive-type on all matching types named type suffix -->
                <xsl:for-each
                        select="$namespace-documents//xs:simpleType[@name=$type-suffix]      |$namespace-documents//xs:complexType[@name=$type-suffix]">
                    <xsl:call-template name="get-primitive-type">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="xs:all">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">all</xsl:with-param>
        </xsl:call-template>

        <xsl:apply-templates select="xs:element">
            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:apply-templates>
    </xsl:template>


    <!-- handles groups existing of other attributes; forwards them with their referenced attribute's namespace documents -->
    <xsl:template match="xs:attributeGroup[@ref]">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">attributeGroup[@ref]</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$attributeGroup-stylesheet"/>
            <xsl:with-param name="template">attributeGroup-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <!-- retrieve namespace documents belonging to the referenced attribute -->
                <xsl:call-template name="get-namespace-documents">
                    <xsl:with-param name="namespace">
                        <xsl:call-template name="get-namespace">
                            <xsl:with-param name="namespace-prefix">
                                <xsl:call-template name="get-prefix">
                                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                    <xsl:with-param name="string" select="@ref"/>
                                </xsl:call-template>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="namespace-prefix">
                <xsl:call-template name="get-prefix">
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="string" select="@type"/>
                    <xsl:with-param name="include-colon">true</xsl:with-param>
                </xsl:call-template>
            </xsl:with-param>

            <xsl:with-param name="ref" select="@ref"/>
            <xsl:with-param name="ref-suffix">
                <xsl:call-template name="get-suffix">
                    <xsl:with-param name="string" select="@ref"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:call-template>
    </xsl:template>

    <!-- handles groups existing of other attributes; note that 'ref' is used as id overriding local-name() -->
    <xsl:template match="xsl:template[@name = 'attributeGroup-forwardee']" name="attributeGroup-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in attribute namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="ref"/> <!-- contains element reference -->
        <xsl:param name="ref-suffix"/> <!-- contains referenced attribute's suffix -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="attributeGroup-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="ref" select="$ref"/>
                        <xsl:with-param name="ref-suffix" select="$ref-suffix"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">attributeGroup[@ref]-forwardee</xsl:with-param>
                </xsl:call-template>

                <!-- find the referenced attribute through the id and let the matching templates handle it -->
                <xsl:apply-templates
                        select="$namespace-documents//xs:attributeGroup[@name=$ref-suffix]/xs:attribute      |$namespace-documents//xs:attributeGroup[@name=$ref-suffix]/xs:attributeGroup      |$namespace-documents//xs:attributeGroup[@name=$ref-suffix]/xs:anyAttribute">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                    <xsl:with-param name="id" select="$ref"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="xpath" select="$xpath"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- handle attribute as simple element, without option for minOccurs or maxOccurs -->
    <xsl:template match="xs:attribute">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">attribute</xsl:with-param>
        </xsl:call-template>

        <!-- determine local namespace -->
        <xsl:variable name="local-namespace">
            <xsl:call-template name="get-namespace">
                <xsl:with-param name="namespace-prefix">
                    <xsl:call-template name="get-prefix">
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                        <xsl:with-param name="string" select="@name"/>
                        <xsl:with-param name="include-colon">true</xsl:with-param>
                    </xsl:call-template>
                </xsl:with-param>
                <xsl:with-param name="default-targetnamespace">true</xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <!-- treat attribute as a simple element without dynamic occurrences -->
        <xsl:call-template name="handle-simple-element">
            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>
            <xsl:with-param name="local-namespace" select="$local-namespace"/>
            <xsl:with-param name="local-namespace-prefix">
                <xsl:choose>
                    <!-- no prefix if attributeFormDefault is unqualified (default) -->
                    <xsl:when
                            test="not(//xs:schema/@attributeFormDefault) or //xs:schema/@attributeFormDefault = 'unqualified'">
                        <xsl:text/>
                    </xsl:when>
                    <!-- use prefix from root namespaces if available -->
                    <xsl:when test="$root-namespaces//root-namespace[@namespace=$local-namespace]">
                        <xsl:value-of select="$root-namespaces//root-namespace[@namespace=$local-namespace]/@prefix"/>
                    </xsl:when>
                    <!-- else generate a new namespace prefix -->
                    <!-- <xsl:otherwise>
						<xsl:value-of select="generate-id()" />
						<xsl:text>:</xsl:text>
					</xsl:otherwise> -->
                </xsl:choose>
            </xsl:with-param>

            <xsl:with-param name="id" select="@name"/>
            <xsl:with-param name="description">
                <xsl:call-template name="get-description"/>
            </xsl:with-param>
            <xsl:with-param name="static">true</xsl:with-param>
            <xsl:with-param name="attribute">true</xsl:with-param>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath">
                <xsl:choose>
                    <xsl:when
                            test="not(//xs:schema/@attributeFormDefault) or //xs:schema/@attributeFormDefault = 'unqualified'">
                        <!-- <xsl:value-of select="concat($xpath,'/@*[name() = &quot;',@name,'&quot;]')" /> -->
                        <xsl:value-of select="concat($xpath,'/@',@name)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- <xsl:value-of select="concat($xpath,'/@*[name() = &quot;',$namespace-prefix,@name,'&quot;]')" /> -->
                        <xsl:value-of select="concat($xpath,'/@',$namespace-prefix,@name)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <xsl:template match="xs:choice">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">choice</xsl:with-param>
        </xsl:call-template>

        <!-- add radio button if $choice is specified -->
        <xsl:if test="not($choice = '') and not($choice = 'true')">
            <xsl:call-template name="add-choice-button">
                <!-- $choice contains a unique id and is used for the options name -->
                <xsl:with-param name="name" select="$choice"/>
                <xsl:with-param name="description">
                    <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                </xsl:with-param>
                <xsl:with-param name="disabled" select="$disabled"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:apply-templates select="xs:element|xs:group|xs:choice|xs:sequence|xs:any">
            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

            <xsl:with-param name="choice" select="generate-id()"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:apply-templates>
    </xsl:template>


    <!-- handles elements referencing other elements; forwards them with their referenced element's or attribute's namespace documents -->
    <xsl:template match="xs:element[@ref]|xs:attribute[@ref]">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:element[@ref]|xs:attribute[@ref]</xsl:with-param>
        </xsl:call-template>

        <!-- forward -->
        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$element-attribute-stylesheet"/>
            <xsl:with-param name="template">element-attribute-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <!-- retrieve namespace documents belonging to the referenced element or attribute -->
                <xsl:call-template name="get-namespace-documents">
                    <xsl:with-param name="namespace">
                        <xsl:call-template name="get-namespace">
                            <xsl:with-param name="namespace-prefix">
                                <xsl:call-template name="get-prefix">
                                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                    <xsl:with-param name="string" select="@ref"/>
                                </xsl:call-template>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="namespace-prefix">
                <xsl:call-template name="get-prefix">
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="string" select="@ref"/>
                    <xsl:with-param name="include-colon">true</xsl:with-param>
                </xsl:call-template>
            </xsl:with-param>

            <xsl:with-param name="ref-suffix">
                <xsl:call-template name="get-suffix">
                    <xsl:with-param name="string" select="@ref"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="min-occurs" select="@minOccurs"/>
            <xsl:with-param name="max-occurs" select="@maxOccurs"/>
            <xsl:with-param name="choice" select="$choice"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:call-template>
    </xsl:template>

    <!-- handles elements referencing other elements -->
    <xsl:template match="xsl:template[@name = 'element-attribute-forwardee']" name="element-attribute-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="ref-suffix"/> <!-- contains referenced element's suffix -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="element-attribute-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix"/>

                        <xsl:with-param name="ref-suffix" select="$ref-suffix"/>
                        <xsl:with-param name="min-occurs" select="$min-occurs"/>
                        <xsl:with-param name="max-occurs" select="$max-occurs"/>
                        <xsl:with-param name="choice" select="$choice"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">xs:element[@ref]|xs:attribute[@ref]-recursively</xsl:with-param>
                </xsl:call-template>

                <!-- add radio button if $choice is specified -->
                <xsl:if test="not($choice = '') and not($choice = 'true')">
                    <xsl:call-template name="add-choice-button">
                        <!-- $choice contains a unique id and is used for the options name -->
                        <xsl:with-param name="name" select="$choice"/>
                        <xsl:with-param name="description">
                            <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                        </xsl:with-param>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:if>

                <!-- find the referenced element or attribute through the reference's suffix and let the matching templates handle it -->
                <xsl:apply-templates select="$namespace-documents//*[@name=$ref-suffix]">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-prefix"/>

                    <xsl:with-param name="id" select="$ref-suffix"/>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                    <xsl:with-param name="choice">
                        <xsl:if test="not($choice = '')">true</xsl:if>
                    </xsl:with-param>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="xpath" select="$xpath"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- handle complex elements, which optionally contain simple content; forwards them with their namespace documents -->
    <xsl:template match="xs:element[xs:complexType/*[not(self::xs:simpleContent)]]">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id" select="@name"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="min-occurs"
                   select="@minOccurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"
                   select="@maxOccurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param name="simple"/> <!-- indicates if an element allows simple content -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:element[xs:complexType/*[not(self::xs:simpleContent)]]</xsl:with-param>
        </xsl:call-template>

        <!-- forward -->
        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$element-complexType-stylesheet"/>
            <xsl:with-param name="template">element-complexType-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <!-- retrieve element's namespace documents -->
                <xsl:call-template name="get-my-namespace-documents">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="min-occurs" select="$min-occurs"/>
            <xsl:with-param name="max-occurs" select="$max-occurs"/>
            <xsl:with-param name="simple" select="$simple"/>
            <xsl:with-param name="choice" select="$choice"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:call-template>
    </xsl:template>

    <!-- handle complex elements, which optionally contain simple content -->
    <xsl:template match="xsl:template[@name = 'element-complexType-forwardee']" name="element-complexType-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param name="simple"/> <!-- indicates if an element allows simple content -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled"/> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="element-complexType-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="min-occurs" select="$min-occurs"/>
                        <xsl:with-param name="max-occurs" select="$max-occurs"/>
                        <xsl:with-param name="simple" select="$simple"/>
                        <xsl:with-param name="choice" select="$choice"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">
                        xs:element[xs:complexType/*[not(self::xs:simpleContent)]]-forwardee
                    </xsl:with-param>
                </xsl:call-template>

                <!-- add radio button if $choice is specified -->
                <xsl:if test="not($choice = '') and not($choice = 'true')">
                    <xsl:call-template name="add-choice-button">
                        <!-- $choice contains a unique id and is used for the options name -->
                        <xsl:with-param name="name" select="$choice"/>
                        <xsl:with-param name="description">
                            <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                        </xsl:with-param>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:if>

                <xsl:call-template name="handle-complex-elements">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                    <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                    <xsl:with-param name="simple" select="$simple"/>
                    <xsl:with-param name="choice">
                        <xsl:if test="not($choice = '')">true</xsl:if>
                    </xsl:with-param>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="xpath" select="$xpath"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- handle complex elements with simple content; forwards them with their namespace documents -->
    <xsl:template match="xs:element[xs:complexType/xs:simpleContent]">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id" select="@name"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="min-occurs"
                   select="@minOccurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"
                   select="@maxOccurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:element[xs:complexType/xs:simpleContent]</xsl:with-param>
        </xsl:call-template>

        <!-- forward -->
        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$element-simpleContent-stylesheet"/>
            <xsl:with-param name="template">element-simpleContent-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <!-- retrieve element's namespace documents -->
                <xsl:call-template name="get-my-namespace-documents">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="min-occurs" select="$min-occurs"/>
            <xsl:with-param name="max-occurs" select="$max-occurs"/>
            <xsl:with-param name="choice" select="$choice"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xsl:template[@name = 'element-simpleContent-forwardee']"
                  name="element-simpleContent-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id" select="@name"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled"/> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="element-simpleContent-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="min-occurs" select="$min-occurs"/>
                        <xsl:with-param name="max-occurs" select="$max-occurs"/>
                        <xsl:with-param name="choice" select="$choice"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">xs:element[xs:complexType/xs:simpleContent]-forwardee
                    </xsl:with-param>
                </xsl:call-template>

                <!-- add radio button if $choice is specified -->
                <xsl:if test="not($choice = '') and not($choice = 'true')">
                    <xsl:call-template name="add-choice-button">
                        <!-- $choice contains a unique id and is used for the options name -->
                        <xsl:with-param name="name" select="$choice"/>
                        <xsl:with-param name="description">
                            <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                        </xsl:with-param>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:if>

                <xsl:call-template name="handle-complex-elements">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                    <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                    <xsl:with-param name="simple">true</xsl:with-param>
                    <xsl:with-param name="choice">
                        <xsl:if test="not($choice = '')">true</xsl:if>
                    </xsl:with-param>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="xpath" select="$xpath"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- handle complex elements with simple content -->
    <xsl:template match="xs:element[xs:simpleType]">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id" select="@name"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="min-occurs"
                   select="@minOccurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"
                   select="@maxOccurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:element[xs:simpleType]</xsl:with-param>
        </xsl:call-template>

        <!-- forward -->
        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$element-simpleType-stylesheet"/>
            <xsl:with-param name="template">element-simpleType-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <!-- retrieve element's namespace documents -->
                <xsl:call-template name="get-my-namespace-documents">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="min-occurs" select="$min-occurs"/>
            <xsl:with-param name="max-occurs" select="$max-occurs"/>
            <xsl:with-param name="choice" select="$choice"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xsl:template[@name = 'element-simpleType-forwardee']" name="element-simpleType-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id" select="@name"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled"/> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="element-simpleType-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="min-occurs" select="$min-occurs"/>
                        <xsl:with-param name="max-occurs" select="$max-occurs"/>
                        <xsl:with-param name="choice" select="$choice"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">xs:element[xs:simpleType]-forwardee</xsl:with-param>
                </xsl:call-template>

                <!-- add radio button if $choice is specified -->
                <xsl:if test="not($choice = '') and not($choice = 'true')">
                    <xsl:call-template name="add-choice-button">
                        <!-- $choice contains a unique id and is used for the options name -->
                        <xsl:with-param name="name" select="$choice"/>
                        <xsl:with-param name="description">
                            <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                        </xsl:with-param>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:if>

                <xsl:call-template name="handle-simple-elements">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                    <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                    <xsl:with-param name="choice">
                        <xsl:if test="not($choice = '')">true</xsl:if>
                    </xsl:with-param>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="xpath" select="$xpath"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- handle elements with type attribute; forward them with their namespace documents -->
    <xsl:template match="xs:element[@type]">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id" select="@name"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="min-occurs"
                   select="@minOccurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"
                   select="@maxOccurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:element[@type]</xsl:with-param>
        </xsl:call-template>

        <!-- forward -->
        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$element-stylesheet"/>
            <xsl:with-param name="template">element-type-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <!-- retrieve element's namespace documents -->
                <xsl:call-template name="get-my-namespace-documents">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

            <xsl:with-param name="id" select="$id"/>
            <xsl:with-param name="type-suffix">
                <!-- determine type suffix to find appropriate simpleType or complexType -->
                <xsl:call-template name="get-suffix">
                    <xsl:with-param name="string" select="@type"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="min-occurs" select="$min-occurs"/>
            <xsl:with-param name="max-occurs" select="$max-occurs"/>
            <xsl:with-param name="choice" select="$choice"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:call-template>
    </xsl:template>

    <!-- handle elements with type attribute; determine if they're complex or simple and process them accordingly -->
    <xsl:template match="xsl:template[@name = 'element-type-forwardee']" name="element-type-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id" select="@name"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="type-suffix"/> <!-- contains element type suffix -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled"/> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="element-type-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="type-suffix" select="$type-suffix"/>
                        <xsl:with-param name="min-occurs" select="$min-occurs"/>
                        <xsl:with-param name="max-occurs" select="$max-occurs"/>
                        <xsl:with-param name="choice" select="$choice"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">xs:element[@type]-forwardee</xsl:with-param>
                </xsl:call-template>

                <!-- add radio button if $choice is specified -->
                <xsl:if test="not($choice = '') and not($choice = 'true')">
                    <xsl:call-template name="add-choice-button">
                        <!-- $choice contains a unique id and is used for the options name -->
                        <xsl:with-param name="name" select="$choice"/>
                        <xsl:with-param name="description">
                            <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                        </xsl:with-param>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:if>

                <!-- determine appropriate type and send them to the respective handler -->
                <xsl:choose>
                    <!-- complexType with simpleContent: treated as simple element -->
                    <xsl:when test="$namespace-documents//xs:complexType[@name=$type-suffix]/xs:simpleContent">
                        <xsl:call-template name="handle-complex-elements">
                            <xsl:with-param name="root-document" select="$root-document"/>
                            <xsl:with-param name="root-path" select="$root-path"/>
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                            <xsl:with-param name="id" select="$id"/>
                            <xsl:with-param name="min-occurs" select="$min-occurs"/>
                            <xsl:with-param name="max-occurs" select="$max-occurs"/>
                            <xsl:with-param name="simple">true</xsl:with-param>
                            <xsl:with-param name="choice">
                                <xsl:if test="not($choice = '')">true</xsl:if>
                            </xsl:with-param>
                            <xsl:with-param name="disabled" select="$disabled"/>
                            <xsl:with-param name="xpath" select="$xpath"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- complexType: treated as complex element -->
                    <xsl:when test="$namespace-documents//xs:complexType[@name=$type-suffix]">
                        <xsl:call-template name="handle-complex-elements">
                            <xsl:with-param name="root-document" select="$root-document"/>
                            <xsl:with-param name="root-path" select="$root-path"/>
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                            <xsl:with-param name="id" select="$id"/>
                            <xsl:with-param name="min-occurs" select="$min-occurs"/>
                            <xsl:with-param name="max-occurs" select="$max-occurs"/>
                            <xsl:with-param name="simple">false</xsl:with-param>
                            <xsl:with-param name="choice">
                                <xsl:if test="not($choice = '')">true</xsl:if>
                            </xsl:with-param>
                            <xsl:with-param name="disabled" select="$disabled"/>
                            <xsl:with-param name="xpath" select="$xpath"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- simpleType: treated as simple element -->
                    <xsl:when test="$namespace-documents//xs:simpleType[@name=$type-suffix]">
                        <xsl:call-template name="handle-simple-elements">
                            <xsl:with-param name="root-document" select="$root-document"/>
                            <xsl:with-param name="root-path" select="$root-path"/>
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                            <xsl:with-param name="id" select="$id"/>
                            <xsl:with-param name="min-occurs" select="$min-occurs"/>
                            <xsl:with-param name="max-occurs" select="$max-occurs"/>
                            <xsl:with-param name="choice">
                                <xsl:if test="not($choice = '')">true</xsl:if>
                            </xsl:with-param>
                            <xsl:with-param name="disabled" select="$disabled"/>
                            <xsl:with-param name="xpath" select="$xpath"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- primitive: treated as simple element -->
                    <xsl:when
                            test="contains(@type, ':') and starts-with(@type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix)">
                        <!-- <xsl:when test="substring-before(@type, ':') = 'xs'"> -->
                        <xsl:call-template name="handle-simple-elements">
                            <xsl:with-param name="root-document" select="$root-document"/>
                            <xsl:with-param name="root-path" select="$root-path"/>
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                            <xsl:with-param name="id" select="$id"/>
                            <xsl:with-param name="min-occurs" select="$min-occurs"/>
                            <xsl:with-param name="max-occurs" select="$max-occurs"/>
                            <xsl:with-param name="choice">
                                <xsl:if test="not($choice = '')">true</xsl:if>
                            </xsl:with-param>
                            <xsl:with-param name="disabled" select="$disabled"/>
                            <xsl:with-param name="xpath" select="$xpath"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- if no type matching the element's type suffix was found, throw an error -->
                    <xsl:otherwise>
                        <xsl:call-template name="throw">
                            <xsl:with-param name="message">
                                <xsl:text>No appropriate handler was found for element with type suffix </xsl:text>
                                <xsl:value-of select="$type-suffix"/>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- handles groups existing of other elements; note that 'ref' is used as id overriding local-name() -->
    <xsl:template match="xs:group[@ref]">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:group[@ref]</xsl:with-param>
        </xsl:call-template>

        <!-- forward -->
        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$group-stylesheet"/>
            <xsl:with-param name="template">group-ref-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <!-- retrieve namespace documents belonging to the referenced attribute -->
                <xsl:call-template name="get-namespace-documents">
                    <xsl:with-param name="namespace">
                        <xsl:call-template name="get-namespace">
                            <xsl:with-param name="namespace-prefix">
                                <xsl:call-template name="get-prefix">
                                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                    <xsl:with-param name="string" select="@ref"/>
                                </xsl:call-template>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="namespace-prefix">
                <xsl:call-template name="get-prefix">
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="string" select="@ref"/>
                    <xsl:with-param name="include-colon">true</xsl:with-param>
                </xsl:call-template>
            </xsl:with-param>

            <xsl:with-param name="ref" select="@ref"/>
            <xsl:with-param name="min-occurs" select="@minOccurs"/>
            <xsl:with-param name="max-occurs" select="@maxOccurs"/>
            <xsl:with-param name="choice" select="$choice"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xsl:template[@name = 'group-ref-forwardee']" name="group-ref-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="ref"/> <!-- contains element reference -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled"/> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="group-ref-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="ref" select="$ref"/>
                        <xsl:with-param name="min-occurs" select="$min-occurs"/>
                        <xsl:with-param name="max-occurs" select="$max-occurs"/>
                        <xsl:with-param name="choice" select="$choice"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">xs:group[@ref]-forwardee</xsl:with-param>
                </xsl:call-template>

                <!-- add radio button if $choice is specified -->
                <xsl:if test="not($choice = '') and not($choice = 'true')">
                    <xsl:call-template name="add-choice-button">
                        <!-- $choice contains a unique id and is used for the options name -->
                        <xsl:with-param name="name" select="$choice"/>
                        <xsl:with-param name="description">
                            <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                        </xsl:with-param>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:if>

                <xsl:call-template name="handle-complex-elements">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                    <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                    <xsl:with-param name="id" select="$ref"/>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                    <xsl:with-param name="simple">false</xsl:with-param>
                    <xsl:with-param name="choice">
                        <xsl:if test="not($choice = '')">true</xsl:if>
                    </xsl:with-param>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="reference">true</xsl:with-param>
                    <xsl:with-param name="xpath" select="$xpath"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="xs:sequence">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:sequence</xsl:with-param>
        </xsl:call-template>

        <!-- add radio button if $choice is specified -->
        <xsl:if test="not($choice = '') and not($choice = 'true')">
            <xsl:call-template name="add-choice-button">
                <!-- $choice contains a unique id and is used for the options name -->
                <xsl:with-param name="name" select="$choice"/>
                <xsl:with-param name="description">
                    <xsl:value-of select="count(preceding-sibling::*) + 1"/>
                </xsl:with-param>
                <xsl:with-param name="disabled" select="$disabled"/>
            </xsl:call-template>
        </xsl:if>

        <xsl:apply-templates select="xs:element|xs:group|xs:choice|xs:sequence|xs:any">
            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

            <xsl:with-param name="choice">
                <xsl:if test="not($choice = '')">true</xsl:if>
            </xsl:with-param>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:apply-templates>
    </xsl:template>


    <xsl:template match="xs:any|xs:anyAttribute">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">xs:any|xs:anyAttribute</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="throw">
            <xsl:with-param name="message">
                <xsl:text>Element or attribute '</xsl:text>
                <xsl:value-of select="local-name() "/>
                <xsl:text>' not supported</xsl:text>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>


    <!-- handle complex elements, which optionally contain simple content -->
    <!-- handle minOccurs and maxOccurs, calls handle-complex-element for further processing -->
    <xsl:template name="handle-complex-elements">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id"/> <!-- contains node name, or references node name in case of groups; select="@name" -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param name="simple"/> <!-- indicates if an element allows simple content -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param name="reference">false
        </xsl:param> <!-- identifies elements that only refer to other elements (e.g. xs:group) -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <!-- ensure any declarations within annotation elements are ignored -->
        <xsl:if test="count(ancestor::xs:annotation) = 0">
            <xsl:call-template name="log">
                <xsl:with-param name="reference">handle-complex-elements</xsl:with-param>
            </xsl:call-template>

            <!-- determine type namespace prefix -->
            <xsl:variable name="type-namespace-prefix">
                <xsl:choose>
                    <!-- reset it if the current element has a non-default prefix -->
                    <xsl:when
                            test="contains(@type, ':') and not(starts-with(@type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix))">
                        <xsl:call-template name="get-prefix">
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                            <xsl:with-param name="string" select="@type"/>
                            <xsl:with-param name="include-colon">true</xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- otherwise, use the inherited prefix -->
                    <xsl:otherwise>
                        <xsl:value-of select="$namespace-prefix"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- determine locally declared namespace -->
            <xsl:variable name="local-namespace">
                <xsl:call-template name="get-namespace">
                    <xsl:with-param name="namespace-prefix">
                        <xsl:call-template name="get-prefix">
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                            <xsl:with-param name="string" select="@name"/>
                            <xsl:with-param name="include-colon">true</xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="default-targetnamespace">true</xsl:with-param>
                </xsl:call-template>
            </xsl:variable>

            <!-- extract locally declared namespace prefix from schema declarations -->
            <xsl:variable name="local-namespace-prefix">
                <xsl:choose>
                    <xsl:when test="$root-namespaces//root-namespace[@namespace=$local-namespace]">
                        <xsl:value-of select="$root-namespaces//root-namespace[@namespace=$local-namespace]/@prefix"/>
                    </xsl:when>
                    <!-- <xsl:otherwise>
						<xsl:value-of select="generate-id()" />
						<xsl:text>:</xsl:text>
					</xsl:otherwise> -->
                </xsl:choose>
            </xsl:variable>

            <!-- wrap complex elements in section elements -->
            <xsl:element name="section">
                <!-- add an attribute to indicate a choice element -->
                <xsl:if test="$choice = 'true'">
                    <xsl:attribute name="data-xsd2html2xml-choice">true</xsl:attribute>
                </xsl:if>

                <!-- call handle-complex-element with loaded documents -->
                <xsl:call-template name="handle-complex-element">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                    <xsl:with-param name="namespace-prefix" select="$type-namespace-prefix"/>
                    <xsl:with-param name="local-namespace" select="$local-namespace"/>
                    <xsl:with-param name="local-namespace-prefix" select="$local-namespace-prefix"/>

                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="description">
                        <xsl:call-template name="get-description"/>
                    </xsl:with-param>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                    <xsl:with-param name="simple" select="$simple"/>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="reference" select="$reference"/>
                    <xsl:with-param name="xpath">
                        <xsl:choose>
                            <xsl:when test="$reference = 'true'">
                                <xsl:value-of select="$xpath"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- <xsl:value-of select="concat($xpath,'/*[name() = &quot;',$local-namespace-prefix,$id,'&quot;]')" /> -->
                                <xsl:value-of select="concat($xpath,'/',$local-namespace-prefix,$id)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>

                <!-- add another element to be used for dynamically inserted elements -->
                <xsl:call-template name="add-add-button">
                    <xsl:with-param name="description">
                        <xsl:call-template name="get-description"/>
                    </xsl:with-param>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- handle complex element -->
    <xsl:template match="xsl:template[@name = 'handle-complex-element']" name="handle-complex-element">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->
        <xsl:param name="local-namespace"/>
        <xsl:param name="local-namespace-prefix"/>

        <xsl:param name="id"/> <!-- contains the 'name' attribute of the element; select="$node/@name" -->
        <xsl:param
                name="description"/> <!-- contains the node's description, either @name or annotation/documentation -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param name="simple"/> <!-- indicates whether this complex element has simple content -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param name="reference"/> <!-- identifies elements that only refer to other elements (e.g. xs:group) -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="handle-complex-element">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>
                        <xsl:with-param name="local-namespace" select="$local-namespace"/>
                        <xsl:with-param name="local-namespace-prefix" select="$local-namespace-prefix"/>

                        <xsl:with-param name="id" select="$id"/>
                        <xsl:with-param name="description" select="$description"/>
                        <xsl:with-param name="min-occurs" select="$min-occurs"/>
                        <xsl:with-param name="max-occurs" select="$max-occurs"/>
                        <xsl:with-param name="simple" select="$simple"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="reference" select="$reference"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">handle-complex-element</xsl:with-param>
                </xsl:call-template>

                <xsl:variable name="type-suffix">
                    <xsl:call-template name="get-suffix">
                        <xsl:with-param name="string" select="@type"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- wrap complex element in fieldset element -->
                <xsl:element name="fieldset">
                    <!-- add attributes for XML generation -->
                    <xsl:if test="not($reference = 'true')">
                        <xsl:attribute name="data-xsd2html2xml-namespace">
                            <xsl:value-of select="$local-namespace"/>
                        </xsl:attribute>
                        <xsl:attribute name="data-xsd2html2xml-type">
                            <xsl:value-of select="local-name()"/>
                        </xsl:attribute>
                        <xsl:attribute name="data-xsd2html2xml-name">
                            <xsl:value-of select="concat($local-namespace-prefix, @name)"/>
                        </xsl:attribute>
                        <xsl:attribute name="data-xsd2html2xml-xpath">
                            <xsl:value-of select="$xpath"/>
                        </xsl:attribute>
                    </xsl:if>

                    <!-- add custom appinfo data -->
                    <xsl:for-each select="xs:annotation/xs:appinfo/*">
                        <xsl:call-template name="add-appinfo"/>
                    </xsl:for-each>

                    <!-- use a legend element to contain the description -->
                    <xsl:element name="legend">
                        <xsl:value-of select="$description"/>
                        <xsl:call-template name="add-remove-button">
                            <xsl:with-param name="min-occurs" select="$min-occurs"/>
                            <xsl:with-param name="max-occurs" select="$max-occurs"/>
                        </xsl:call-template>
                    </xsl:element>

                    <xsl:variable name="ref-suffix">
                        <xsl:call-template name="get-suffix">
                            <xsl:with-param name="string" select="@ref"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- let child elements be handled by their own templates -->
                    <xsl:apply-templates
                            select="xs:complexType/xs:sequence       |xs:complexType/xs:all       |xs:complexType/xs:choice       |xs:complexType/xs:attribute       |xs:complexType/xs:attributeGroup       |xs:complexType/xs:complexContent/xs:restriction/xs:sequence       |xs:complexType/xs:complexContent/xs:restriction/xs:all       |xs:complexType/xs:complexContent/xs:restriction/xs:choice       |xs:complexType/xs:complexContent/xs:restriction/xs:attribute       |xs:complexType/xs:complexContent/xs:restriction/xs:attributeGroup       |xs:complexType/xs:simpleContent/xs:restriction/xs:attribute       |xs:complexType/xs:simpleContent/xs:restriction/xs:attributeGroup       |xs:complexType/xs:simpleContent/xs:restriction/xs:anyAttribute       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:sequence       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:all       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:choice       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:attribute       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:attributeGroup       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:anyAttribute       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:complexContent/xs:restriction/xs:sequence       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:complexContent/xs:restriction/xs:all       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:complexContent/xs:restriction/xs:choice       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:complexContent/xs:restriction/xs:attribute       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:complexContent/xs:restriction/xs:attributeGroup       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:simpleContent/xs:restriction/xs:attribute       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:simpleContent/xs:restriction/xs:attributeGroup       |$namespace-documents//xs:complexType[@name=$type-suffix]/xs:simpleContent/xs:restriction/xs:anyAttribute       |$namespace-documents//xs:group[@name=$ref-suffix]/*">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:apply-templates>

                    <!-- add simple element if the element allows simpleContent -->
                    <xsl:if test="$simple = 'true'">
                        <xsl:call-template name="handle-simple-element">
                            <xsl:with-param name="root-document" select="$root-document"/>
                            <xsl:with-param name="root-path" select="$root-path"/>
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                            <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>
                            <xsl:with-param name="local-namespace" select="$local-namespace"/>
                            <xsl:with-param name="local-namespace-prefix" select="$local-namespace-prefix"/>

                            <xsl:with-param name="description" select="$description"/>
                            <xsl:with-param name="static">true</xsl:with-param>
                            <xsl:with-param name="node-type">content</xsl:with-param>
                            <xsl:with-param name="disabled" select="$disabled"/>
                            <xsl:with-param name="xpath" select="$xpath"/>
                        </xsl:call-template>
                    </xsl:if>

                    <!-- add inherited extensions to the element -->
                    <xsl:call-template name="handle-extensions">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>
                        <xsl:with-param name="base">
                            <xsl:value-of
                                    select="*/*/xs:extension/@base         |$namespace-documents//xs:complexType[@name=$type-suffix]/*/xs:extension/@base"/>
                        </xsl:with-param>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>

                    <!-- add added elements -->
                    <xsl:apply-templates
                            select="*/*/xs:extension/*       |$namespace-documents//xs:complexType[@name=$type-suffix]/*/xs:extension/*">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:apply-templates>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="generate-input">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="description"/> <!-- contains preferred description for element -->
        <xsl:param name="type"/> <!-- contains primitive type -->
        <xsl:param name="attribute"/> <!-- boolean indicating whether or not node is an attribute -->
        <xsl:param name="disabled"/> <!-- boolean indicating whether or not generated element should be disabled -->
        <xsl:param name="pattern"/> <!-- regex pattern to be applied to element input -->
        <xsl:param
                name="min-length"/> <!-- minLength attribute used to determine if generated element should be optional -->
        <xsl:param name="whitespace"/> <!-- whitespace rule to be applied to element input -->

        <xsl:element name="input">
            <xsl:attribute name="type">
                <!-- primive type determines the input element type -->
                <xsl:choose>
                    <xsl:when
                            test="$type = 'string' or $type = 'normalizedstring' or $type = 'token' or $type = 'language'">
                        <xsl:text>text</xsl:text>
                    </xsl:when>
                    <xsl:when
                            test="$type = 'decimal' or $type = 'float' or $type = 'double' or $type = 'integer' or $type = 'byte' or $type = 'int' or $type = 'long' or $type = 'positiveinteger' or $type = 'negativeinteger' or $type = 'nonpositiveinteger' or $type = 'nonnegativeinteger' or $type = 'short' or $type = 'unsignedlong' or $type = 'unsignedint' or $type = 'unsignedshort' or $type = 'unsignedbyte' or $type = 'gday' or $type = 'gmonth' or $type = 'gyear'">
                        <xsl:text>number</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'boolean'">
                        <xsl:text>checkbox</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'datetime'">
                        <xsl:text>datetime-local</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'date' or $type = 'gmonthday'">
                        <xsl:text>date</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'time'">
                        <xsl:text>time</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'gyearmonth'">
                        <xsl:text>month</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'anyuri'">
                        <xsl:text>url</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'base64binary' or $type = 'hexbinary'">
                        <xsl:text>file</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'duration'">
                        <xsl:text>range</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>text</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>

            <!-- specifically set the value attribute in the HTML to enable XSLT processing of the form contents -->
            <xsl:attribute name="onchange">
                <xsl:choose>
                    <xsl:when test="$type = 'boolean'"> <!-- Use the checked value of checkboxes -->
                        <xsl:text>if (this.checked) { this.setAttribute("checked","checked") } else { this.removeAttribute("checked") }</xsl:text>
                    </xsl:when>
                    <xsl:when
                            test="$type = 'base64binary' or $type = 'hexbinary'"> <!-- Use the FileReader API to set the value of file inputs -->
                        <xsl:text>pickFile(this, arguments[0].target.files[0], "</xsl:text>
                        <xsl:value-of select="$type"/>
                        <xsl:text>");</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'datetime' or $type = 'time'">
                        <xsl:text>if (this.value) { this.setAttribute("value", (this.value.match(/.*\d\d:\d\d:\d\d/) ? this.value : this.value.concat(":00"))); } else { this.removeAttribute("value"); };</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'gday'">
                        <xsl:text>if (this.value) { this.setAttribute("value", (this.value.length == 2 ? "---" : "---0").concat(this.value)); } else { this.removeAttribute("value"); };</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'gmonth'">
                        <xsl:text>if (this.value) { this.setAttribute("value", (this.value.length == 2 ? "--" : "--0").concat(this.value)); } else { this.removeAttribute("value"); };</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'gmonthday'">
                        <xsl:text>if (this.value) { this.setAttribute("value", this.value.replace(/^\d+/, "-")); } else { this.removeAttribute("value"); };</xsl:text>
                    </xsl:when>
                    <xsl:when test="$type = 'duration'"> <!-- Use the output element for ranges -->
                        <xsl:text>this.setAttribute("value", "</xsl:text>
                        <xsl:call-template name="get-duration-info">
                            <xsl:with-param name="type">prefix</xsl:with-param>
                            <xsl:with-param name="pattern" select="$pattern"/>
                        </xsl:call-template>
                        ".concat(this.value).concat("
                        <xsl:call-template name="get-duration-info">
                            <xsl:with-param name="type">abbreviation</xsl:with-param>
                            <xsl:with-param name="pattern" select="$pattern"/>
                        </xsl:call-template>
                        <xsl:text>")); this.previousElementSibling.textContent = this.value;</xsl:text>
                    </xsl:when>
                    <xsl:otherwise> <!-- Use value if otherwise -->
                        <xsl:text>if (this.value) { this.setAttribute("value", this.value</xsl:text>
                        <xsl:if test="$whitespace = 'replace'">.replace(/\s/g, " ")</xsl:if>
                        <xsl:if test="$whitespace = 'collapse'">.replace(/\s+/g, " ").trim()</xsl:if>
                        <xsl:text>); } else { this.removeAttribute("value"); };</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>

            <!-- attribute can have optional use=required values; normal elements are always required -->
            <xsl:if test="($attribute = 'true' and @use = 'required') or not($attribute = 'true')">
                <xsl:choose><!-- in case of base64binary or hexbinary, default values cannot be set to an input[type=file] element; because of this, a required attribute on these elements is omitted when fixed, default, or data is found -->
                    <xsl:when
                            test="($type = 'base64binary' or $type = 'hexbinary') and (@fixed or @default)"> <!-- or (not($invisible = 'true')) -->
                        <xsl:attribute name="data-xsd2html2xml-required">true</xsl:attribute>
                    </xsl:when>
                    <xsl:when test="$type = 'string' or $type = 'normalizedstring' or $type = 'token'">
                        <xsl:if test="$min-length = '' or $min-length &gt; 0">
                            <xsl:attribute name="required">required</xsl:attribute>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="not($type = 'boolean')">
                        <xsl:attribute name="required">required</xsl:attribute>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>

            <!-- attributes can be prohibited, rendered as readonly -->
            <xsl:if test="@use = 'prohibited'">
                <xsl:attribute name="readonly">readonly</xsl:attribute>
            </xsl:if>

            <xsl:call-template name="set-type-specifics">
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>

            <xsl:call-template name="set-type-defaults">
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                <xsl:with-param name="type">
                    <xsl:value-of select="$type"/>
                </xsl:with-param>
            </xsl:call-template>

            <!-- disabled elements are used to omit invisible placeholders from inclusion in the validation and generated xml data -->
            <xsl:if test="$disabled = 'true'">
                <xsl:attribute name="disabled">disabled</xsl:attribute>
            </xsl:if>

            <xsl:attribute name="data-xsd2html2xml-primitive">
                <xsl:value-of select="$type"/>
            </xsl:attribute>

            <xsl:attribute name="data-xsd2html2xml-description">
                <xsl:value-of select="$description"/>
            </xsl:attribute>

            <xsl:if test="$type = 'duration'">
                <xsl:attribute name="data-xsd2html2xml-duration">
                    <xsl:call-template name="get-duration-info">
                        <xsl:with-param name="type">description</xsl:with-param>
                        <xsl:with-param name="pattern" select="$pattern"/>
                    </xsl:call-template>
                </xsl:attribute>
            </xsl:if>

            <xsl:if test="@fixed">
                <xsl:attribute name="readonly">readonly</xsl:attribute>
            </xsl:if>

            <xsl:choose>
                <!-- use fixed attribute as data if specified -->
                <xsl:when test="@fixed">
                    <xsl:choose>
                        <xsl:when test="$type = 'boolean'">
                            <xsl:if test="@fixed = 'true'">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="value">
                                <xsl:value-of select="@fixed"/>
                            </xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <!-- use default attribute as data if specified; overridden later if populated -->
                <xsl:when test="@default">
                    <xsl:choose>
                        <xsl:when test="$type = 'boolean'">
                            <xsl:if test="@default = 'true'">
                                <xsl:attribute name="checked">checked</xsl:attribute>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="value">
                                <xsl:value-of select="@default"/>
                            </xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>


    <xsl:template name="generate-select">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="description"/> <!-- contains preferred description for element -->
        <xsl:param name="type"/> <!-- contains primitive type -->
        <xsl:param name="attribute"/> <!-- boolean indicating whether or not node is an attribute -->
        <xsl:param
                name="multiple"/> <!-- boolean indicating whether or not generated element should be able to allow for multiple values -->
        <xsl:param name="disabled"/> <!-- boolean indicating whether or not generated element should be disabled -->

        <xsl:element name="select">
            <xsl:attribute name="onchange">
                <xsl:text>this.childNodes.forEach(function(o) { if (o.nodeType == Node.ELEMENT_NODE) o.removeAttribute("selected"); }); this.children[this.selectedIndex].setAttribute("selected","selected");</xsl:text>
            </xsl:attribute>

            <!-- attribute can have optional use=required values; normal elements are always required -->
            <xsl:choose>
                <xsl:when test="$attribute = 'true'">
                    <xsl:if test="@use = 'required'">
                        <xsl:attribute name="required">required</xsl:attribute>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="required">required</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>

            <!-- disabled elements are used to omit invisible placeholders from inclusion in the validation and generated xml data -->
            <xsl:if test="$disabled = 'true'">
                <xsl:attribute name="disabled">disabled</xsl:attribute>
            </xsl:if>

            <xsl:attribute name="data-xsd2html2xml-description">
                <xsl:value-of select="$description"/>
            </xsl:attribute>

            <!-- <xsl:if test="not($invisible = 'true')">
				<xsl:attribute name="data-xsd2html2xml-filled">true</xsl:attribute>
			</xsl:if> -->

            <!-- add multiple keyword if several selections are allowed -->
            <xsl:if test="$multiple = 'true'">
                <xsl:attribute name="multiple">multiple</xsl:attribute>
            </xsl:if>

            <xsl:attribute name="data-xsd2html2xml-primitive">
                <xsl:value-of select="$type"/>
            </xsl:attribute>

            <!-- add option to select no value in case of optional attribute -->
            <xsl:if test="$attribute = 'true' and @use = 'optional'">
                <xsl:element name="option">-</xsl:element>
            </xsl:if>

            <!-- add options for each value; populate the element if there is corresponding data, or fill it with a fixed or default value -->
            <xsl:call-template name="handle-enumerations">
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                <xsl:with-param name="default">
                    <xsl:choose>
                        <xsl:when test="@default">
                            <xsl:value-of select="@default"/>
                        </xsl:when>
                        <xsl:when test="@fixed">
                            <xsl:value-of select="@fixed"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="disabled">
                    <xsl:choose>
                        <xsl:when test="@fixed">true</xsl:when>
                        <xsl:otherwise>false</xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>

    <!-- Recursively searches for xs:enumeration elements and applies templates on them -->
    <xsl:template name="handle-enumerations">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="default"/>
        <xsl:param name="disabled">false</xsl:param>

        <xsl:apply-templates select=".//xs:restriction/xs:enumeration">
            <xsl:with-param name="default" select="$default"/>
            <xsl:with-param name="disabled" select="$disabled"/>
        </xsl:apply-templates>

        <xsl:variable name="namespace">
            <xsl:call-template name="get-namespace">
                <xsl:with-param name="namespace-prefix">
                    <xsl:call-template name="get-prefix">
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                        <xsl:with-param name="string" select="@type"/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$enumerations-stylesheet"/>
            <xsl:with-param name="template">handle-enumerations-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <xsl:choose>
                    <xsl:when
                            test="(not($namespace-documents = '') and count($namespace-documents//document) &gt; 0 and $namespace-documents//document[1]/@namespace = $namespace) or (contains(@type, ':') and starts-with(@type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix))">
                        <xsl:call-template name="inform">
                            <xsl:with-param name="message">Reusing loaded namespace documents</xsl:with-param>
                        </xsl:call-template>

                        <xsl:copy-of select="$namespace-documents"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="get-namespace-documents">
                            <xsl:with-param name="namespace">
                                <xsl:call-template name="get-namespace">
                                    <xsl:with-param name="namespace-prefix">
                                        <xsl:call-template name="get-prefix">
                                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                            <xsl:with-param name="string" select="@type"/>
                                        </xsl:call-template>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:with-param>
                            <xsl:with-param name="root-document" select="$root-document"/>
                            <xsl:with-param name="root-path" select="$root-path"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>

            <xsl:with-param name="type-suffix">
                <xsl:call-template name="get-suffix">
                    <xsl:with-param name="string" select="@type"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="default" select="$default"/>
            <xsl:with-param name="disabled" select="$disabled"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xsl:template[@name = 'handle-enumerations-forwardee']" name="handle-enumerations-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="type-suffix"/>
        <xsl:param name="default"/>
        <xsl:param name="disabled"/>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">handle-enumerations-forwardee</xsl:with-param>
        </xsl:call-template>

        <xsl:for-each select="$namespace-documents//xs:simpleType[@name=$type-suffix]">
            <xsl:call-template name="handle-enumerations">
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                <xsl:with-param name="default" select="$default"/>
                <xsl:with-param name="disabled" select="$disabled"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="handle-extensions">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="base"/> <!-- contains element's base type -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">handle-extensions</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="forward">
            <xsl:with-param name="stylesheet" select="$extensions-stylesheet"/>
            <xsl:with-param name="template">handle-extensions-forwardee</xsl:with-param>

            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents">
                <xsl:call-template name="get-namespace-documents">
                    <xsl:with-param name="namespace">
                        <xsl:call-template name="get-namespace">
                            <xsl:with-param name="namespace-prefix">
                                <xsl:call-template name="get-prefix">
                                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                                    <xsl:with-param name="string" select="$base"/>
                                </xsl:call-template>
                            </xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="namespace-prefix">
                <xsl:call-template name="get-prefix">
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="string" select="$base"/>
                    <xsl:with-param name="include-colon">true</xsl:with-param>
                </xsl:call-template>
            </xsl:with-param>

            <xsl:with-param name="base" select="$base"/>
            <xsl:with-param name="disabled" select="$disabled"/>
            <xsl:with-param name="xpath" select="$xpath"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xsl:template[@name = 'handle-extensions-forwardee']" name="handle-extensions-forwardee">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="base"/> <!-- contains element's base type -->
        <xsl:param name="disabled"/> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:param name="node"/>

        <xsl:choose>
            <!-- if called from forward, call it again with with $node as calling node -->
            <xsl:when test="name() = 'xsl:template'">
                <xsl:for-each select="$node">
                    <xsl:call-template name="handle-extensions-forwardee">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="base" select="$base"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:when>
            <!-- else continue processing -->
            <xsl:otherwise>
                <xsl:call-template name="log">
                    <xsl:with-param name="reference">handle-extensions-forwardee</xsl:with-param>
                </xsl:call-template>

                <xsl:variable name="base-suffix">
                    <xsl:call-template name="get-suffix">
                        <xsl:with-param name="string" select="$base"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- add inherited extensions -->
                <xsl:for-each select="$namespace-documents//*[@name=$base-suffix]/*/xs:extension">
                    <xsl:call-template name="handle-extensions">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                        <xsl:with-param name="base" select="@base"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                        <xsl:with-param name="xpath" select="$xpath"/>
                    </xsl:call-template>
                </xsl:for-each>

                <!-- add added elements -->
                <xsl:apply-templates
                        select="$namespace-documents//*[@name=$base-suffix]/*      |$namespace-documents//*[@name=$base-suffix]/*/*/*">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-prefix" select="$namespace-prefix"/>

                    <xsl:with-param name="disabled" select="$disabled"/>
                    <xsl:with-param name="xpath" select="$xpath"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template name="generate-textarea">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="description"/> <!-- contains preferred description for element -->
        <xsl:param
                name="min-length"/> <!-- minLength attribute used to determine if generated element should be optional -->
        <xsl:param name="attribute"/> <!-- boolean indicating whether or not node is an attribute -->
        <xsl:param name="disabled"/> <!-- boolean indicating whether or not generated element should be disabled -->
        <xsl:param name="whitespace"/> <!-- whitespace rule to be applied to element input -->

        <xsl:element name="textarea">
            <xsl:attribute name="onchange">
                <xsl:text>this.textContent = this.value</xsl:text>
                <xsl:if test="$whitespace = 'replace'">.replace(/\s/g, " ")</xsl:if>
                <xsl:if test="$whitespace = 'collapse'">.replace(/\s+/g, " ").trim()</xsl:if>
            </xsl:attribute>

            <!-- attribute can have optional use=required values; normal elements are always required -->
            <xsl:choose>
                <xsl:when test="$attribute = 'true'">
                    <xsl:if test="@use = 'required'">
                        <xsl:attribute name="required">required</xsl:attribute>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="$min-length = '' or $min-length &gt; 0">
                    <xsl:attribute name="required">required</xsl:attribute>
                </xsl:when>
            </xsl:choose>

            <!-- attributes can be prohibited, rendered as readonly -->
            <xsl:if test="@use = 'prohibited'">
                <xsl:attribute name="readonly">readonly</xsl:attribute>
            </xsl:if>

            <xsl:attribute name="data-xsd2html2xml-description">
                <xsl:value-of select="$description"/>
            </xsl:attribute>

            <xsl:call-template name="set-type-specifics">
                <xsl:with-param name="root-document" select="$root-document"/>
                <xsl:with-param name="root-path" select="$root-path"/>
                <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
            </xsl:call-template>

            <!-- disabled elements are used to omit invisible placeholders from inclusion in the validation and generated xml data -->
            <xsl:if test="$disabled = 'true'">
                <xsl:attribute name="disabled">disabled</xsl:attribute>
            </xsl:if>

            <!-- populate the element if there is corresponding data, or fill it with a fixed or default value -->
            <xsl:choose>
                <xsl:when test="@fixed">
                    <xsl:attribute name="readonly">readonly</xsl:attribute>
                    <xsl:value-of select="@fixed"/>
                </xsl:when>
                <xsl:when test="@default">
                    <xsl:value-of select="@default"/>
                </xsl:when>
            </xsl:choose>
        </xsl:element>
    </xsl:template>


    <xsl:template match="xsl:template[@name = 'handle-root-element']" name="handle-root-element">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->

        <xsl:param name="node"/>

        <xsl:call-template name="log">
            <xsl:with-param name="reference">handle-root-element</xsl:with-param>
        </xsl:call-template>

        <xsl:apply-templates select="$node">
            <xsl:with-param name="root-document" select="$root-document"/>
            <xsl:with-param name="root-path" select="$root-path"/>
            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

            <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
        </xsl:apply-templates>
    </xsl:template>


    <!-- handle simple elements -->
    <!-- handle minOccurs and maxOccurs, calls handle-simple-element for further processing -->
    <xsl:template name="handle-simple-elements">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->

        <xsl:param name="id"/> <!-- contains node name, or references node name in case of groups; select="@name" -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param
                name="choice"/> <!-- handles xs:choice elements and descendants; contains a unique ID for radio buttons of the same group to share -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <!-- ensure any declarations within annotation elements are ignored -->
        <xsl:if test="count(ancestor::xs:annotation) = 0">
            <xsl:call-template name="log">
                <xsl:with-param name="reference">handle-simple-elements</xsl:with-param>
            </xsl:call-template>

            <!-- determine type namespace-prefix -->
            <xsl:variable name="type-namespace-prefix">
                <xsl:choose>
                    <!-- reset it if the current element has a non-default prefix -->
                    <xsl:when
                            test="contains(@type, ':') and not(starts-with(@type, $root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix))">
                        <xsl:call-template name="get-prefix">
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                            <xsl:with-param name="string" select="@type"/>
                            <xsl:with-param name="include-colon">true</xsl:with-param>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- otherwise, use the inherited prefix -->
                    <xsl:otherwise>
                        <xsl:value-of select="$namespace-prefix"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- determine locally declared namespace -->
            <xsl:variable name="local-namespace">
                <xsl:call-template name="get-namespace">
                    <xsl:with-param name="namespace-prefix">
                        <xsl:call-template name="get-prefix">
                            <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                            <xsl:with-param name="string" select="@name"/>
                            <xsl:with-param name="include-colon">true</xsl:with-param>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="default-targetnamespace">true</xsl:with-param>
                </xsl:call-template>
            </xsl:variable>

            <!-- extract locally declared namespace prefix from schema declarations -->
            <xsl:variable name="local-namespace-prefix">
                <xsl:choose>
                    <xsl:when test="$root-namespaces//root-namespace[@namespace=$local-namespace]">
                        <xsl:value-of select="$root-namespaces//root-namespace[@namespace=$local-namespace]/@prefix"/>
                    </xsl:when>
                    <!-- <xsl:otherwise>
						<xsl:value-of select="generate-id()" />
						<xsl:text>:</xsl:text>
					</xsl:otherwise> -->
                </xsl:choose>
            </xsl:variable>

            <!-- wrap simple element in section element -->
            <xsl:element name="section">
                <!-- add an attribute to indicate a choice element -->
                <xsl:if test="$choice = 'true'">
                    <xsl:attribute name="data-xsd2html2xml-choice">true</xsl:attribute>
                </xsl:if>

                <xsl:call-template name="handle-simple-element">
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                    <xsl:with-param name="namespace-prefix" select="$type-namespace-prefix"/>
                    <xsl:with-param name="local-namespace" select="$local-namespace"/>
                    <xsl:with-param name="local-namespace-prefix" select="$local-namespace-prefix"/>

                    <xsl:with-param name="id" select="$id"/>
                    <xsl:with-param name="description">
                        <xsl:call-template name="get-description"/>
                    </xsl:with-param>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                    <xsl:with-param name="static">false</xsl:with-param>
                    <xsl:with-param name="disabled" select="$disabled"/>
                    <!-- <xsl:with-param name="xpath" select="concat($xpath,'/*[name() = &quot;',$local-namespace-prefix,@name,'&quot;]')" /> -->
                    <xsl:with-param name="xpath" select="concat($xpath,'/',$local-namespace-prefix,@name)"/>
                </xsl:call-template>

                <!-- add another element to be used for dynamically inserted elements -->
                <xsl:call-template name="add-add-button">
                    <xsl:with-param name="description">
                        <xsl:call-template name="get-description"/>
                    </xsl:with-param>
                    <xsl:with-param name="min-occurs" select="$min-occurs"/>
                    <xsl:with-param name="max-occurs" select="$max-occurs"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- handle simple element -->
    <xsl:template name="handle-simple-element">
        <xsl:param name="root-document"/> <!-- contains root document -->
        <xsl:param name="root-path"/> <!-- contains path from root to included and imported documents -->
        <xsl:param name="root-namespaces"/> <!-- contains root document's namespaces and prefixes -->

        <xsl:param name="namespace-documents"/> <!-- contains all documents in element namespace -->
        <xsl:param name="namespace-prefix"/> <!-- contains inherited namespace prefix -->
        <xsl:param name="local-namespace"/>
        <xsl:param name="local-namespace-prefix"/>

        <xsl:param name="id" select="@name"/> <!-- contains node name, or references node name in case of groups -->
        <xsl:param name="min-occurs"/> <!-- contains @minOccurs attribute (for referenced elements) -->
        <xsl:param name="max-occurs"/> <!-- contains @maxOccurs attribute (for referenced elements) -->
        <xsl:param name="description"/> <!-- contains preferred description for element -->
        <xsl:param name="static"/> <!-- indicates whether or not the element may be removed or is 'static' -->
        <xsl:param name="attribute">false</xsl:param> <!-- indicates if the node is an element or an attribute -->
        <xsl:param name="disabled">false
        </xsl:param> <!-- is used to disable elements that are copies for additional occurrences -->
        <xsl:param name="node-type"
                   select="local-name()"/> <!-- contains the element name, or 'content' in the case of simple content -->
        <xsl:param
                name="xpath"/> <!-- contains an XPath query relative to the current node, to be used with xml document -->

        <xsl:call-template name="log">
            <xsl:with-param name="reference">handle-simple-element</xsl:with-param>
        </xsl:call-template>

        <xsl:variable name="type"> <!-- holds the primive type (xs:*) with which the element type will be determined -->
            <xsl:call-template name="get-suffix">
                <xsl:with-param name="string">
                    <xsl:call-template name="get-primitive-type">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>

        <xsl:element name="label">
            <!-- metadata required for compiling the xml when the form is submitted -->
            <xsl:attribute name="data-xsd2html2xml-namespace">
                <xsl:value-of select="$local-namespace"/>
            </xsl:attribute>
            <xsl:attribute name="data-xsd2html2xml-type">
                <xsl:value-of select="$node-type"/>
            </xsl:attribute>
            <xsl:attribute name="data-xsd2html2xml-name">
                <xsl:value-of select="concat($local-namespace-prefix, @name)"/>
            </xsl:attribute>
            <xsl:attribute name="data-xsd2html2xml-xpath">
                <xsl:value-of select="$xpath"/>
            </xsl:attribute>

            <!-- add custom appinfo data -->
            <xsl:for-each select="xs:annotation/xs:appinfo/*">
                <xsl:call-template name="add-appinfo"/>
            </xsl:for-each>

            <!-- pattern is used later to determine multiline text fields -->
            <xsl:variable name="pattern">
                <xsl:call-template name="attr-value">
                    <xsl:with-param name="attr"><xsl:value-of
                            select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>pattern
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:variable>

            <!-- minlength is used later to determine optional text fields -->
            <xsl:variable name="min-length">
                <xsl:call-template name="attr-value">
                    <xsl:with-param name="attr"><xsl:value-of
                            select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>minLength
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:variable>

            <!-- enumerations are rendered as select elements -->
            <xsl:variable name="choice">
                <xsl:call-template name="attr-value">
                    <xsl:with-param name="attr"><xsl:value-of
                            select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>enumeration
                    </xsl:with-param>
                    <xsl:with-param name="root-document" select="$root-document"/>
                    <xsl:with-param name="root-path" select="$root-path"/>
                    <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                    <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                </xsl:call-template>
            </xsl:variable>

            <!-- in case of xs:duration, an output element is added to show the selected value of the user -->
            <xsl:if test="$type = 'duration'">
                <xsl:element name="output">
                    <xsl:attribute name="data-xsd2html2xml-description">
                        <xsl:value-of select="$description"/>
                    </xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="@fixed">
                            <xsl:value-of select="translate(@fixed,translate(@fixed, '0123456789.-', ''), '')"/>
                        </xsl:when>
                        <xsl:when test="@default">
                            <xsl:value-of select="translate(@default,translate(@default, '0123456789.-', ''), '')"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:element>
            </xsl:if>

            <!-- handling whitespace as it is specified or default based on type -->
            <xsl:variable name="whitespace">
                <xsl:variable name="specified-whitespace">
                    <xsl:call-template name="attr-value">
                        <xsl:with-param name="attr"><xsl:value-of
                                select="$root-namespaces//root-namespace[@namespace = 'http://www.w3.org/2001/XMLSchema']/@prefix"/>whiteSpace
                        </xsl:with-param>
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>
                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:choose>
                    <xsl:when test="not($specified-whitespace = '')">
                        <xsl:value-of select="$specified-whitespace"/>
                    </xsl:when>
                    <xsl:when test="$type = 'string'">preserve</xsl:when>
                    <xsl:when test="$type = 'normalizedstring'">replace</xsl:when>
                    <xsl:otherwise>collapse</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:choose>
                <!-- enumerations are rendered as select elements -->
                <xsl:when test="not($choice='') or $type='idref' or $type='idrefs'">
                    <xsl:call-template name="generate-select">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                        <xsl:with-param name="description" select="$description"/>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="attribute" select="$attribute"/>
                        <xsl:with-param name="multiple">
                            <xsl:choose>
                                <xsl:when test="$type='idrefs'">true</xsl:when>
                                <xsl:otherwise>false</xsl:otherwise>
                            </xsl:choose>
                        </xsl:with-param>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:when>
                <!-- multiline patterns are rendered as textarea elements -->
                <xsl:when test="contains($pattern,'\n')">
                    <xsl:call-template name="generate-textarea">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                        <xsl:with-param name="description" select="$description"/>
                        <xsl:with-param name="min-length" select="$min-length"/>
                        <xsl:with-param name="whitespace" select="$whitespace"/>
                        <xsl:with-param name="attribute" select="$attribute"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:when>
                <!-- all other primitive types become input elements -->
                <xsl:otherwise>
                    <xsl:call-template name="generate-input">
                        <xsl:with-param name="root-document" select="$root-document"/>
                        <xsl:with-param name="root-path" select="$root-path"/>
                        <xsl:with-param name="root-namespaces" select="$root-namespaces"/>

                        <xsl:with-param name="namespace-documents" select="$namespace-documents"/>

                        <xsl:with-param name="description" select="$description"/>
                        <xsl:with-param name="pattern" select="$pattern"/>
                        <xsl:with-param name="min-length" select="$min-length"/>
                        <xsl:with-param name="whitespace" select="$whitespace"/>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="attribute" select="$attribute"/>
                        <xsl:with-param name="disabled" select="$disabled"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

            <!-- add label description and GUI widgets -->
            <xsl:element name="span">
                <xsl:value-of select="$description"/>
                <!-- <xsl:if test="$type = 'duration'">
					<xsl:text> (</xsl:text>
					<xsl:call-template name="get-duration-info">
						<xsl:with-param name="type">description</xsl:with-param>
						<xsl:with-param name="pattern" select="$pattern" />
					</xsl:call-template>
					<xsl:text>)</xsl:text>
				</xsl:if> -->
                <xsl:if test="not($static = 'true')"> <!-- non-static elements with variable occurrences can be removed -->
                    <xsl:call-template name="add-remove-button">
                        <xsl:with-param name="min-occurs" select="$min-occurs"/>
                        <xsl:with-param name="max-occurs" select="$max-occurs"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:element>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
