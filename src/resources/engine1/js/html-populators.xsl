<?xml version="1.0"?>
<xsl:stylesheet
	version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">

	<xsl:template name="add-html-populators">
		<xsl:element name="script">
			<xsl:attribute name="type">text/javascript</xsl:attribute>
			<xsl:text disable-output-escaping="yes">
				/* HTML POPULATORS */

				// Add import button for spatials_elements node
				const initImportButtons = function() {
				    const importTypeMessages = {
				        START: 'import-start',
				        CONTINUE: 'import-continue'
				    }

                    document.querySelectorAll("[data-xsd2html2xml-name='EnSpa2:spatials_elements']").forEach(function(fieldsetElement) {
                        console.log('element')

				  		const legendElement = fieldsetElement.firstElementChild;
						const sectionElement = fieldsetElement.querySelector('section:last-of-type');
						const buttons = sectionElement.getElementsByClassName('add');

                        let addContourButton;
                        for(const b of buttons){
                            if(b.innerHTML == 'Элемент контура'){
                                addContourButton = b;
                                break
                            }
                        }


						let button = legendElement.querySelector('*');
						if(!button){
							button = document.createElement('button');
							button.classList.add('import');
							button.type='button';
							button.textContent = 'Импорт координат';

							legendElement.appendChild(button);
						}


						button.onclick = (e) => {
					        e.stopPropagation();

					        const getContourNodes = () =>{
					            return Array.from(sectionElement.childNodes).slice(1,sectionElement.childNodes.length - 2);
					        }

					        // Clear coordinates from node
					        // No need touch hidden fieldset, this node for clone
					        let contourNodes = getContourNodes();
					        console.log(contourNodes)
					        for (let contourNode of contourNodes){
					       	    sectionElement.removeChild(contourNode);
					        }

					        const message = {type:importTypeMessages.START};
							window.parent.postMessage(message);

                            const importListener = (event)=> {
								console.log('generate nodes', event);
								if(event?.data?.type === importTypeMessages.CONTINUE){
								    console.log('got import result for genetate nodes');
								    window.removeEventListener('message', importListener);

									// Generate nodes
									if(event?.data?.value) {
										console.log(event?.data?.value);

                                        // Create contours nodes
										const contours = JSON.parse(event?.data?.value);
										for(const contour of contours){
											addContourButton.click();
										}

                                        // Reinit contours
										contourNodes = getContourNodes();

										// Create coordinate nodes for every contour
										const addCoordButtons = contourNodes.map((cn, i)=> {
										    return {
										        btn: cn.lastElementChild.lastElementChild.lastElementChild.lastElementChild,
										        count: contours[i].length
										    }
										})
										console.log(addCoordButtons);
										for(const addCoordButton of addCoordButtons){
										    for(let i = 0; i &lt; addCoordButton.count - 1; i++){
										        addCoordButton.btn.click();
										    }
										}

                                        const getOrdGeopointZacrep = (fieldNode, name)=>{
										    return fieldNode.find(f =>{
												const selectRes = f.querySelectorAll(`${name}`)
												if (selectRes?.length){return selectRes[0]?.lastElementChild}
											})
										}
										const getCoordinateInput = (fieldNode, name)=>{
										    return fieldNode.find(f =>{
												const selectRes = f.querySelectorAll(`${name}`)
												if (selectRes?.length){return selectRes[0]?.lastElementChild}
											})?.lastElementChild?.lastElementChild
										}

										const opredMethod = {
                                                        "Геодезический метод":692001000000,
                                                        "Фотограмметрический метод":692002000000,
                                                        "Картометрический метод":692003000000,
                                                        "Иное описание": 692004000000,
                                                        "Метод спутниковых геодезических измерений (определений)":692005000000,
                                                        "Аналитический метод":692006000000
                                                    }

										// Fill coordinates
										for (const contourNode of contourNodes){
										    const coordinateNodes = contourNode.lastElementChild.lastElementChild.lastElementChild.childNodes;
										    const coordContour = contours[i];

										    for(let i = 1; i &lt; coordinateNodes.length - 2; i++){
												const fieldsCoordinateNones = Array.from(coordinateNodes[i].childNodes).filter(n=>n.nodeName =='SECTION');
												const coord = coordContour[i - 1];
												if (coord){

                                                const xInput = getCoordinateInput(fieldsCoordinateNones,"[data-xsd2html2xml-name='EnSpa2:x']");
                                                const yInput = getCoordinateInput(fieldsCoordinateNones,"[data-xsd2html2xml-name='EnSpa2:y']");
                                                const ordNmbInput = getCoordinateInput(fieldsCoordinateNones,"[data-xsd2html2xml-name='EnSpa2:ord_nmb']");
                                                const ordNmbGeopointInput = getCoordinateInput(fieldsCoordinateNones,"[data-xsd2html2xml-name='EnSpa2:num_geopoint']");
                                                const ordGeopointZacrep = getOrdGeopointZacrep(fieldsCoordinateNones,"[data-xsd2html2xml-name='EnSpa2:geopoint_zacrep']");

                                                const ordGeopointOpredSelect = getCoordinateInput(fieldsCoordinateNones,"[data-xsd2html2xml-name='EnSpa2:geopoint_opred']");
                                                const ordDeltaGeopointInput = getCoordinateInput(fieldsCoordinateNones,"[data-xsd2html2xml-name='EnSpa2:delta_geopoint']");


                                                if(xInput &amp;&amp; coord[1]) {xInput.value = Number(coord[1])};
                                                if(yInput &amp;&amp; coord[2]) {yInput.value = Number(coord[2])};
                                                if(ordNmbInput &amp;&amp; coord[6]) {ordNmbInput.value = coord[6]};
                                                if(ordNmbGeopointInput &amp;&amp; coord[7]) {ordNmbGeopointInput.value = coord[7]};
                                                if(ordGeopointZacrep &amp;&amp; coord[8]) {ordGeopointZacrep?.lastElementChild?.click(); ordGeopointZacrep.firstElementChild.lastElementChild.value = coord[8]};
                                                if(ordGeopointOpredSelect &amp;&amp; coord[3]) {ordGeopointOpredSelect.value = opredMethod[coord[3]]};
                                                if(ordDeltaGeopointInput &amp;&amp; coord[4]) {ordDeltaGeopointInput.value = coord[4]};
                                                }

										    }
										}
									}
							    }
							}
							window.addEventListener('message', importListener);
						}
                    });
                }

				// Mark required fields
				var markRequiredFields = function() {
                    document.querySelectorAll("[required]").forEach(function(p) {
                        p.parentElement.classList.add('reqc')
                    });
                }

				// Set custom message during validation
				var setCustomValidity = function() {
				    document.querySelectorAll("input, textarea, select").forEach(function(p) {
						if(p.pattern) p.title = p.pattern
					});
				}


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
					// function checks if some field in fieldset (recursive) is filled
					function isFilled(fieldset) {
						if (!fieldset) {
							return null;
						}
						//check for input elements existing to handle empty elements
						if (!fieldset.querySelector("input, textarea, select")) {
							return null;
						}
						//check if element has been populated with data from an xml document
						const filledElement = ['input', 'textarea', 'select'].findIndex(
							tag =&gt; !!fieldset.querySelector(`${tag}[data-xsd2html2xml-filled]`)
						);
						return filledElement &gt;= 0;
					}
					document.querySelectorAll("[data-xsd2html2xml-min], [data-xsd2html2xml-max]").forEach(function(o) {
						//add minimum number of elements
						if (o.hasAttribute("data-xsd2html2xml-min")) {
							//if no minimum, remove element
							if (
								o.getAttribute("data-xsd2html2xml-min") === "0"
								&amp;&amp; isFilled(o.previousElementSibling?.previousElementSibling) === false
							) {
								clickRemoveButton(
									o.parentElement.children[0].querySelector("legend &gt; button.remove, span &gt; button.remove")
								);
							//if there is only one allowed element that has been filled, disable the button
							} else if (
								o.getAttribute("data-xsd2html2xml-max") === "1"
								&amp;&amp; isFilled(o.previousElementSibling?.previousElementSibling) === true
							) {
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
					// function updates field value (not used for radio)
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
							try{element.querySelector("select option[value = '".concat(value).concat("']")).setAttribute("selected", "selected");
							}catch(e){console.log('Отсутствует функция setAttribute на элементе1', e)}
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
							try{globalValuesMap[i].object.querySelector(
								"select option[value = '".concat(globalValuesMap[i].values[j]).concat("']")
							).setAttribute("selected", "selected");
							}catch(e){
								console.log('Отсутствует функция setAttribute на элементе2', e)
							}
						}
					}
				};
			</xsl:text>
		</xsl:element>
	</xsl:template>

</xsl:stylesheet>
